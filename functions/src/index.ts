import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

export const onTimetableUpdate = onDocumentWritten(
  // eslint-disable-next-line max-len
  "Modified_TimeTable/{department}/{section}/{semester}/{dayCollection}/{dayDoc}",
  async (event) => {
    try {
      const {department, section, semester, dayCollection} = event.params;

      const newData = event.data?.after?.data();
      const previousData = event.data?.before?.data();

      if (!newData || !previousData) {
        console.log("No data found in the document");
        return null;
      }

      const changes = findChanges(previousData, newData);
      if (changes.length === 0) {
        console.log("No significant changes detected");
        return null;
      }

      const studentsSnapshot = await admin
        .firestore()
        .collection("Students")
        .where("department", "==", department)
        .where("section", "==", section)
        .where("semester", "==", parseInt(semester.replace("Semester ", "")))
        .get();

      if (studentsSnapshot.empty) {
        console.log("No students found in this section");
        return null;
      }

      const tokens: string[] = [];
      studentsSnapshot.forEach((doc) => {
        const student = doc.data();
        if (student.tokenId) {
          tokens.push(student.tokenId);
        }
      });

      if (tokens.length === 0) {
        console.log("No tokens found for notification");
        return null;
      }

      for (const change of changes) {
        const notification = {
          title: getNotificationTitle(change.type),
          body: formatNotificationBody(change, dayCollection),
          data: {
            type: change.type,
            department,
            section,
            semester,
            day: dayCollection,
            timeSlot: change.timeSlot,
            course: change.course,
            teacher: change.teacher,
          },
        };

        const message = {
          notification,
          data: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            ...notification.data,
          },
          tokens,
        };

        try {
          const response = await admin.messaging().sendMulticast(message);
          console.log(
            `Notifications sent: ${response.successCount}/${tokens.length}`
          );
        } catch (error) {
          console.error("Error sending notifications:", error);
        }
      }

      return null;
    } catch (error) {
      console.error("Error in timetable update function:", error);
      return null;
    }
  }
);

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
 * @param {Record<string, TimeSlotData>} oldData - Previous timetable data
 * @param {Record<string, TimeSlotData>} newData - Updated timetable data
 * @return {TimeSlotChange[]} Array of detected changes
 */
function findChanges(
  oldData: Record<string, TimeSlotData>,
  newData: Record<string, TimeSlotData>
): TimeSlotChange[] {
  const changes: TimeSlotChange[] = [];

  Object.keys(newData).forEach((timeSlot) => {
    const oldSlot = oldData[timeSlot] || {};
    const newSlot = newData[timeSlot];

    if (JSON.stringify(oldSlot) !== JSON.stringify(newSlot)) {
      let type: TimeSlotChange["type"] = "MODIFIED";

      if (newSlot.course === "Cancelled") {
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
        originalCourse: newSlot.originalCourse,
        reason: newSlot.reason,
      });
    }
  });

  return changes;
}

/**
 * @param {TimeSlotChange["type"]} type - Type of timetable change
 * @return {string} Formatted notification title
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
 * @param {TimeSlotChange} change - The timetable change details
 * @param {string} day - The day of the change
 * @return {string} Formatted notification message
 */
function formatNotificationBody(
  change: TimeSlotChange,
  day: string
): string {
  const dayName = day.charAt(0).toUpperCase() + day.slice(1);

  switch (change.type) {
  case "CANCELLED":
    return `${change.originalCourse} class at ${change.timeSlot} on ` +
        `${dayName} has been cancelled by ${change.teacher}`;
  case "EXTRA_CLASS":
    return `Extra ${change.course} class scheduled at ${change.timeSlot} ` +
        `on ${dayName} by ${change.teacher}`;
  case "RESCHEDULED":
    return `${change.course} class has been rescheduled to ` +
        `${change.timeSlot} on ${dayName} by ${change.teacher}`;
  default:
    return `${change.course} class at ${change.timeSlot} on ` +
        `${dayName} has been modified`;
  }
}
