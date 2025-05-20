import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";

admin.initializeApp();

// Correct path pattern based on your Firestore structure
export const onTimetableUpdate = onDocumentWritten({
  region: "asia-south1",
  // This matches: Modified_TimeTable/{docId}/subcollections/{dayDoc}
  // where docId contains department, section, semester info
  document: "Modified_TimeTable/{timetableDocId}/{dayCollection}/{dayDoc}",
  memory: "256MiB",
  timeoutSeconds: 60,
  retry: false,
}, async (event) => {
  logger.info("Cloud Function triggered", {
    eventId: event.id,
    params: event.params,
    hasAfterData: !!event.data?.after,
    hasBeforeData: !!event.data?.before,
  });

  try {
    const {timetableDocId, dayCollection, dayDoc} = event.params;
    logger.info("Extracted parameters", {
      timetableDocId,
      dayCollection,
      dayDoc,
    });

    // Get the parent document to extract department, section, semester
    const parentDoc = await admin
      .firestore()
      .doc(`Modified_TimeTable/${timetableDocId}`)
      .get();

    if (!parentDoc.exists) {
      logger.error("Parent timetable document not found", {timetableDocId});
      return null;
    }

    const parentData = parentDoc.data();
    let {department, section, semester} = parentData || {};

    // Normalize section value like "Section A" → "A"
    if (typeof section === "string") {
      const match = section.match(/([A-Z])$/i);
      if (match) {
        section = match[1].toUpperCase();
      }
    }

    logger.info("Extracted timetable info", {
      department,
      section,
      semester,
    });

    if (!department || !section || !semester) {
      logger.error("Missing required fields in parent document", {
        department,
        section,
        semester,
        parentData,
      });
      return null;
    }

    logger.info("Extracted timetable info", {
      department,
      section,
      semester,
    });

    const newData = event.data?.after?.data();
    const previousData = event.data?.before?.data();

    logger.info("Document data check", {
      hasNewData: !!newData,
      hasPreviousData: !!previousData,
      newDataKeys: newData ? Object.keys(newData) : [],
      previousDataKeys: previousData ? Object.keys(previousData) : [],
    });

    if (!newData) {
      logger.warn("No new data found in the document");
      return null;
    }

    if (!previousData) {
      logger.info("This is a new document creation, skipping comparison");
      return null;
    }
    /**
     * Compares old and new data to find changes in time slots.
     * @param {Record<string, TimeSlotData>} oldData - The previous timetable
     * @param {Record<string, TimeSlotData>} newData - The updated timetable
     * @return {TimeSlotChange[]} Array of detected changes in time slots
     */
    const changes = findChanges(previousData, newData);
    logger.info(`Found ${changes.length} changes`, {changes});

    if (changes.length === 0) {
      logger.info("No significant changes detected");
      return null;
    }

    // Parse semester number - handle different formats
    let semesterNumber: number;
    if (typeof semester === "number") {
      semesterNumber = semester;
    } else if (typeof semester === "string") {
      // Handle "Semester 7" or just "7"
      const match = semester.match(/(\d+)/);
      if (match) {
        semesterNumber = parseInt(match[1]);
      } else {
        logger.error("Unable to parse semester number", {semester});
        return null;
      }
    } else {
      logger.error("Invalid semester format", {semester});
      return null;
    }

    logger.info("Querying students with filters", {
      department,
      section,
      semester: semesterNumber,
    });

    const studentsSnapshot = await admin
      .firestore()
      .collection("Students")
      .where("department", "==", department)
      .where("section", "==", section)
      .where("semester", "==", semesterNumber)
      .get();

    logger.info(`Found ${studentsSnapshot.size} students`);

    const tokens: string[] = [];
    studentsSnapshot.forEach((doc) => {
      const student = doc.data();
      logger.info("Student document:", student); // log student if needed
      if (student.tokenId && typeof student.tokenId === "string") {
        tokens.push(student.tokenId);
      }
    });

    logger.info(`Collected ${tokens.length} tokens`);

    logger.info(`Collected ${tokens.length} tokens from` +
    `${studentsSnapshot.size} students`);

    if (tokens.length === 0) {
      logger.warn("No valid tokens found for notification");
      return null;
    }

    for (const change of changes) {
      logger.info("Preparing to send notification", {
        change,
        targetTokens: tokens,
      });
      const notification = {
        title: getNotificationTitle(change.type),
        body: formatNotificationBody(change, dayCollection),
        data: {
          type: change.type,
          department: String(department),
          section: String(section),
          semester: String(semester),
          day: dayCollection,
          timeSlot: change.timeSlot,
          course: change.course || "",
          teacher: change.teacher || "",
        },
      };

      const message = {
        notification,
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          ...Object.entries(notification.data).reduce((acc, [key, value]) => {
            acc[key] = String(value);
            return acc;
          }, {} as Record<string, string>,),
        },
        tokens,
      };

      try {
        const response = await admin.messaging().sendMulticast(message);
        logger.info("Notifications sent", {
          successCount: response.successCount,
          failureCount: response.failureCount,
          totalTokens: tokens.length,
          changeType: change.type,
        });

        if (response.failureCount > 0) {
          logger.warn("Some notifications failed", {
            failures: response.responses
              .map((resp, index) => ({token: tokens[index],
                error: resp.error}),)
              .filter((item) => item.error),
          });
        }
      } catch (error) {
        logger.error("Error sending notifications", {
          error: error instanceof Error ? error.message : String(error),
          changeType: change.type,
        });
      }
    }

    logger.info("Function execution completed successfully");
    return null;
  } catch (error) {
    logger.error("Error in timetable update function", {
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
    });
    return null;
  }
});

interface TimeSlotChange {
  type: "CANCELLED" | "RESCHEDULED" | "EXTRA_CLASS" | "MODIFIED";
  timeSlot: string;
  course: string;
  teacher: string;
  originalCourse?: string;
  reason?: string;
}

interface TimeSlotData {
  course: string;
  teacher: string;
  isExtraClass?: boolean;
  isRescheduled?: boolean;
  originalCourse?: string;
  reason?: string;
}

/**
 * Compares old and new data to find changes in time slots.
 * @param {Record<string, TimeSlotData>} oldData - The previous timetable data
 * @param {Record<string, TimeSlotData>} newData - The updated timetable data
 * @return {TimeSlotChange[]} Array of detected changes in time slots
 */
function findChanges(
  oldData: Record<string, TimeSlotData>,
  newData: Record<string, TimeSlotData>
): TimeSlotChange[] {
  const changes: TimeSlotChange[] = [];
  const allTimeSlots = new Set([...Object.keys(oldData),
    ...Object.keys(newData)]);

  allTimeSlots.forEach((timeSlot) => {
    const oldSlot = oldData[timeSlot];
    const newSlot = newData[timeSlot];

    // Handle deleted slots
    if (oldSlot && !newSlot) {
      changes.push({
        type: "CANCELLED",
        timeSlot,
        course: oldSlot.course,
        teacher: oldSlot.teacher,
        originalCourse: oldSlot.course,
        reason: "Time slot removed",
      });
      return;
    }

    // Handle new slots
    if (!oldSlot && newSlot) {
      changes.push({
        type: newSlot.isExtraClass ? "EXTRA_CLASS" : "MODIFIED",
        timeSlot,
        course: newSlot.course,
        teacher: newSlot.teacher,
        reason: "New time slot added",
      });
      return;
    }

    // Handle modified slots
    if (oldSlot && newSlot && JSON.stringify(oldSlot) !==
      JSON.stringify(newSlot)) {
      let type: TimeSlotChange["type"] = "MODIFIED";

      if (newSlot.course === "Cancelled" || newSlot.course === "Free") {
        type = "CANCELLED";
      } else if (newSlot.isExtraClass) {
        type = "EXTRA_CLASS";
      } else if (newSlot.isRescheduled) {
        type = "RESCHEDULED";
      }

      changes.push({
        type,
        timeSlot,
        course: newSlot.course,
        teacher: newSlot.teacher,
        originalCourse: newSlot.originalCourse || oldSlot.course,
        reason: newSlot.reason,
      });
    }
  });

  return changes;
}

/**
 * Gets the notification title based on change type.
 * @param {string} type - The type of change detected
 * @return {string} The appropriate notification title
 */
function getNotificationTitle(type: TimeSlotChange["type"]): string {
  switch (type) {
  case "CANCELLED":
    return "Class Cancelled";
  case "RESCHEDULED":
    return "Class Rescheduled";
  case "EXTRA_CLASS":
    return "Extra Class Added";
  default:
    return "Timetable Update";
  }
}

/**
 * Formats the notification body message.
 * @param {TimeSlotChange} change - The change object containing details
 * @param {string} day - The day of the week for the timetable update
 * @return {string} The formatted notification body message
 */
function formatNotificationBody(
  change: TimeSlotChange,
  day: string
): string {
  const dayName = day.charAt(0).toUpperCase() + day.slice(1);

  switch (change.type) {
  case "CANCELLED":
    return `${change.originalCourse || change.course}` +
    `class at ${change.timeSlot} on ` +
          `${dayName} has been cancelled${change.teacher ?
            `by ${change.teacher}` : ""}`;
  case "EXTRA_CLASS":
    return `Extra ${change.course} class scheduled at ${change.timeSlot} ` +
        `on ${dayName}${change.teacher ? ` by ${change.teacher}` : ""}`;
  case "RESCHEDULED":
    return `${change.course} class has been rescheduled to` +
          `${change.timeSlot} on ${dayName}${change.teacher ?
            `by ${change.teacher}` : ""}`;
  default:
    return `${change.course} class at ${change.timeSlot} on ` +
        `${dayName} has been modified`;
  }
}
