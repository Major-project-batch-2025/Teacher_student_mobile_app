import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {logger} from "firebase-functions";

admin.initializeApp();

// Correct path pattern based on your Firestore structure
export const onTimetableUpdate = onDocumentWritten({
  document: "Modified_TimeTable/{timetableDocId}/{dayCollection}/{dayDoc}",
  memory: "256MiB",
  timeoutSeconds: 60,
  retry: false,
}, async (event) => {
  const startTime = Date.now();
  logger.info("=== CLOUD FUNCTION STARTED ===", {
    eventId: event.id,
    timestamp: new Date().toISOString(),
    functionName: "onTimetableUpdate",
  });

  logger.info("Event details received", {
    eventId: event.id,
    eventType: event.type,
    params: event.params,
    hasAfterData: !!event.data?.after,
    hasBeforeData: !!event.data?.before,
    documentPath: `Modified_TimeTable/${event.params.timetableDocId}/` +
    `${event.params.dayCollection}/${event.params.dayDoc}`,
  });

  try {
    // Step 1: Extract parameters
    logger.info("STEP 1: Extracting parameters from event");
    const {timetableDocId, dayCollection, dayDoc} = event.params;
    logger.info("Parameters extracted successfully", {
      timetableDocId,
      dayCollection,
      dayDoc,
      parameterCount: Object.keys(event.params).length,
    });

    // Step 2: Fetch parent document
    logger.info("STEP 2: Fetching parent timetable document");
    const parentDocPath = `Modified_TimeTable/${timetableDocId}`;
    logger.info("Querying parent document", {
      path: parentDocPath,
    });

    const parentDoc = await admin
      .firestore()
      .doc(parentDocPath)
      .get();

    logger.info("Parent document query completed", {
      exists: parentDoc.exists,
      hasData: !!parentDoc.data(),
      documentId: parentDoc.id,
    });

    if (!parentDoc.exists) {
      logger.error("FAILURE: Parent timetable document not found", {
        timetableDocId,
        searchPath: parentDocPath,
        reason: "Document does not exist in Firestore",
      });
      return null;
    }

    // Step 3: Extract parent document data
    logger.info("STEP 3: Extracting data from parent document");
    const parentData = parentDoc.data();
    logger.info("Parent document data retrieved", {
      hasData: !!parentData,
      dataKeys: parentData ? Object.keys(parentData) : [],
      rawData: parentData,
    });

    let {department, section, semester} = parentData || {};
    logger.info("Initial field extraction", {
      department: {value: department, type: typeof department},
      section: {value: section, type: typeof section},
      semester: {value: semester, type: typeof semester},
    });

    // Step 4: Normalize section format
    logger.info("STEP 4: Normalizing section format");
    const originalSection = section;
    if (typeof section === "string" && !section.startsWith("Section")) {
      section = `Section ${section.trim()}`;
      logger.info("Section normalized", {
        original: originalSection,
        normalized: section,
      });
    } else {
      logger.info("Section format already correct or invalid", {
        section,
        type: typeof section,
      });
    }

    logger.info("Final extracted timetable info", {
      department,
      section,
      semester,
    });

    // Step 5: Validate required fields
    logger.info("STEP 5: Validating required fields");
    const validationResults = {
      department: !!department,
      section: !!section,
      semester: !!semester,
    };
    logger.info("Field validation results", validationResults);

    if (!department || !section || !semester) {
      logger.error("FAILURE: Missing required fields in parent document", {
        department: {present: !!department, value: department},
        section: {present: !!section, value: section},
        semester: {present: !!semester, value: semester},
        parentData,
        validationResults,
      });
      return null;
    }

    // Step 6: Extract document data
    logger.info("STEP 6: Extracting document data from event");
    const newData = event.data?.after?.data();
    const previousData = event.data?.before?.data();

    logger.info("Document data extraction results", {
      hasNewData: !!newData,
      hasPreviousData: !!previousData,
      newDataKeys: newData ? Object.keys(newData) : [],
      previousDataKeys: previousData ? Object.keys(previousData) : [],
      newDataSize: newData ? Object.keys(newData).length : 0,
      previousDataSize: previousData ? Object.keys(previousData).length : 0,
    });

    if (newData) {
      logger.info("New data content preview", {
        sampleEntries: Object.entries(newData).slice(0, 3),
        totalEntries: Object.keys(newData).length,
      });
    }

    if (previousData) {
      logger.info("Previous data content preview", {
        sampleEntries: Object.entries(previousData).slice(0, 3),
        totalEntries: Object.keys(previousData).length,
      });
    }

    if (!newData) {
      logger.warn("EARLY EXIT: No new data found in the document", {
        eventType: event.type,
        reason: "newData is null or undefined",
      });
      return null;
    }

    // Step 7: Handle document creation vs update
    logger.info("STEP 7: Determining operation type");
    if (!previousData) {
      logger.info("OPERATION TYPE: New document creation detected", {
        reason: "No previous data found",
        action: "Treating as new schedule addition",
      });
    } else {
      logger.info("OPERATION TYPE: Document update detected", {
        reason: "Both previous and new data found",
        action: "Proceeding with change detection",
      });
    }

    // Step 8: Find changes
    logger.info("STEP 8: Analyzing changes between old and new data");
    const changeDetectionStart = Date.now();
    const changes = findChanges(previousData || {}, newData);
    const changeDetectionTime = Date.now() - changeDetectionStart;

    logger.info("Change detection completed", {
      changesFound: changes.length,
      detectionTimeMs: changeDetectionTime,
      changes: changes.map((c) => ({
        type: c.type,
        timeSlot: c.timeSlot,
        course: c.course,
        teacher: c.teacher,
      })),
    });

    if (changes.length === 0) {
      logger.info("EARLY EXIT: No significant changes detected", {
        reason: "Change detection returned empty array",
        comparedDataSizes: {
          previous: previousData ? Object.keys(previousData).length : 0,
          new: Object.keys(newData).length,
        },
      });
      return null;
    }

    // Step 9: Parse semester number
    logger.info("STEP 9: Parsing semester number");
    let semesterNumber: number;
    logger.info("Semester parsing input", {
      semester,
      type: typeof semester,
    });

    if (typeof semester === "number") {
      semesterNumber = semester;
      logger.info("Semester parsed as number", {
        original: semester,
        parsed: semesterNumber,
      });
    } else if (typeof semester === "string") {
      logger.info("Parsing semester string", {
        originalString: semester,
      });

      const match = semester.match(/(\d+)/);
      if (match) {
        semesterNumber = parseInt(match[1]);
        logger.info("Semester number extracted from string", {
          originalString: semester,
          matchedPattern: match[0],
          parsedNumber: semesterNumber,
        });
      } else {
        logger.error("FAILURE: Unable to parse semester number from string", {
          semester,
          reason: "No numeric pattern found in string",
        });
        return null;
      }
    } else {
      logger.error("FAILURE: Invalid semester format", {
        semester,
        type: typeof semester,
        reason: "Semester must be number or string",
      });
      return null;
    }

    // Step 10: Query students
    logger.info("STEP 10: Querying students from database");
    const queryFilters = {
      department,
      section,
      semester: semesterNumber,
    };
    logger.info("Student query filters", queryFilters);

    const queryStart = Date.now();
    const studentsSnapshot = await admin
      .firestore()
      .collection("Students")
      .where("department", "==", department)
      .where("section", "==", section)
      .where("semester", "==", semesterNumber)
      .get();
    const queryTime = Date.now() - queryStart;

    logger.info("Student query completed", {
      studentsFound: studentsSnapshot.size,
      queryTimeMs: queryTime,
      isEmpty: studentsSnapshot.empty,
    });

    if (studentsSnapshot.empty) {
      logger.warn("No students found matching criteria", {
        filters: queryFilters,
        possibleReasons: [
          "No students registered for this combination",
          "Filter values don't match database records",
          "Case sensitivity issues",
        ],
      });
    }

    const studentIds = studentsSnapshot.docs.map((doc) => doc.id);
    logger.info("Student document IDs retrieved", {
      studentIds: studentIds.slice(0, 10), // Log first
      totalCount: studentIds.length,
      showingFirst: Math.min(10, studentIds.length),
    });

    // Step 11: Extract FCM tokens
    logger.info("STEP 11: Extracting FCM tokens from student documents");
    const tokens: string[] = [];
    const studentsWithoutTokens: string[] = [];
    const tokenValidationResults: Array<{
      studentId: string;
      hasToken: boolean;
      tokenLength: number;
      isValid: boolean;
      reason?: string;
    }> = [];

    logger.info("Starting token extraction process", {
      totalStudents: studentsSnapshot.size,
    });

    studentsSnapshot.forEach((doc) => {
      const student = doc.data();
      const studentId = doc.id;

      logger.info(`Processing student token: ${studentId}`, {
        studentId,
        hasTokenIdField: "tokenId" in student,
        tokenIdType: typeof student.tokenId,
        tokenIdValue: student.tokenId ?
          `${String(student.tokenId).substring(0, 20)}...` : "null",
      });

      const validationResult = {
        studentId,
        hasToken: !!student.tokenId,
        tokenLength: student.tokenId ? String(student.tokenId).length : 0,
        isValid: false,
        reason: "",
      };

      // FCM tokens are typically 163+ characters long
      if (student.tokenId &&
          typeof student.tokenId === "string" &&
          student.tokenId.trim() !== "" &&
          student.tokenId.length > 100) {
        validationResult.isValid = true;
        validationResult.reason = "Valid FCM token";

        logger.info(`Valid token found for student ${studentId}`, {
          tokenLength: student.tokenId.length,
          tokenPreview: `${student.tokenId.substring(0, 20)}...`,
        });

        tokens.push(student.tokenId.trim());
      } else {
        studentsWithoutTokens.push(studentId);

        if (!student.tokenId) {
          validationResult.reason = "Token field missing";
        } else if (typeof student.tokenId !== "string") {
          validationResult.reason = `Token is ${typeof student.tokenId}` +
            ", expected string";
        } else if (student.tokenId.trim() === "") {
          validationResult.reason = "Token is empty string";
        } else if (student.tokenId.length <= 100) {
          validationResult.reason = "Token too short (" +
            `${student.tokenId.length} chars)`;
        }

        logger.warn(`Invalid or missing token for student ${studentId}`, {
          tokenIdPresent: !!student.tokenId,
          tokenLength: student.tokenId ? student.tokenId.length : 0,
          tokenType: typeof student.tokenId,
          tokenPreview: student.tokenId ?
            `${student.tokenId.substring(0, 10)}...` : "null",
          reason: validationResult.reason,
        });
      }

      tokenValidationResults.push(validationResult);
    });

    // Step 12: Log token collection summary
    logger.info("STEP 12: Token collection summary", {
      totalStudents: studentsSnapshot.size,
      validTokens: tokens.length,
      invalidTokens: studentsWithoutTokens.length,
      validationRate: `${((tokens.length / studentsSnapshot.size)*
         100).toFixed(1)}%`,
    });

    if (studentsWithoutTokens.length > 0) {
      logger.warn("Students without valid tokens detailed breakdown", {
        count: studentsWithoutTokens.length,
        studentIds: studentsWithoutTokens,
        reasons: tokenValidationResults
          .filter((r) => !r.isValid)
          .reduce((acc, r) => {
            if (r.reason) {
              acc[r.reason] = (acc[r.reason] || 0) + 1;
            }
            return acc;
          }, {} as Record<string, number>),
      });
    }

    if (tokens.length === 0) {
      logger.warn("EARLY EXIT: No valid tokens found for notification", {
        totalStudentsQueried: studentsSnapshot.size,
        studentsWithoutTokens: studentsWithoutTokens.length,
        reason: "Cannot send notifications without valid FCM tokens",
      });
      return null;
    }

    // Step 13: Process each change and send notifications
    logger.info("STEP 13: Processing changes and sending notifications", {
      changesCount: changes.length,
      targetTokens: tokens.length,
    });

    const BATCH_SIZE = 500;
    const totalBatches = Math.ceil(tokens.length / BATCH_SIZE);

    logger.info("Notification batching configuration", {
      batchSize: BATCH_SIZE,
      totalTokens: tokens.length,
      totalBatches,
    });

    for (let changeIndex = 0; changeIndex < changes.length; changeIndex++) {
      const change = changes[changeIndex];
      logger.info(`Processing change ${changeIndex + 1}/${changes.length}`, {
        change: {
          type: change.type,
          timeSlot: change.timeSlot,
          course: change.course,
          teacher: change.teacher,
          originalCourse: change.originalCourse,
          reason: change.reason,
        },
        targetTokens: tokens.length,
      });

      // Step 14: Send notifications in batches
      logger.info("STEP 14: Sending notifications in batches");

      for (let i = 0; i < tokens.length; i += BATCH_SIZE) {
        const batchNumber = Math.floor(i / BATCH_SIZE) + 1;
        const batchTokens = tokens.slice(i, i + BATCH_SIZE);

        logger.info(`Processing batch ${batchNumber}/${totalBatches}`, {
          batchNumber,
          batchSize: batchTokens.length,
          startIndex: i,
          endIndex: Math.min(i + BATCH_SIZE - 1, tokens.length - 1),
          changeIndex: changeIndex + 1,
        });

        try {
          // Step 15: Prepare notification message
          logger.info("STEP 15: Preparing notification message");

          const notificationTitle = getNotificationTitle(change.type);
          const notificationBody =
            formatNotificationBody(change, dayCollection);

          const message = {
            notification: {
              title: notificationTitle,
              body: notificationBody,
            },
            data: {
              click_action: "FLUTTER_NOTIFICATION_CLICK",
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

          logger.info("Notification message prepared", {
            title: message.notification.title,
            bodyLength: message.notification.body.length,
            dataFields: Object.keys(message.data).length,
            notification: message.notification,
            data: message.data,
          });

          // Step 16: Send FCM messages
          logger.info("STEP 16: Sending FCM messages");

          const sendStart = Date.now();
          const response = await admin.messaging().sendEach(
            batchTokens.map((token) => ({
              ...message,
              token: token,
            }))
          );
          const sendTime = Date.now() - sendStart;

          logger.info("FCM batch sent", {
            batchNumber,
            batchSize: batchTokens.length,
            successCount: response.successCount,
            failureCount: response.failureCount,
            sendTimeMs: sendTime,
            successRate: `${((response.successCount / batchTokens.length) *
               100).toFixed(1)}%`,
          });

          // Step 17: Handle failed messages
          if (response.failureCount > 0) {
            logger.info("STEP 17: Processing failed messages");

            const failureReasons: Record<string, number> = {};
            const invalidTokens: string[] = [];

            response.responses.forEach((resp, idx) => {
              if (!resp.success && resp.error) {
                const errorCode = resp.error.code || "unknown";
                const errorMessage = resp.error.message || "No message";

                failureReasons[errorCode] =
                (failureReasons[errorCode] || 0) + 1;

                logger.error(`Failed to send message to token ${idx + 1}`, {
                  tokenIndex: idx,
                  tokenPreview: `${batchTokens[idx].substring(0, 20)}...`,
                  errorCode,
                  errorMessage,
                  batchNumber,
                });

                // Track invalid tokens
                if (errorCode === "messaging/invalid-registration-token" ||
                    errorCode === "messaging/registration-" +
                    "token-not-registered") {
                  invalidTokens.push(batchTokens[idx]);
                  logger.warn("Invalid token detected for cleanup", {
                    tokenPreview: `${batchTokens[idx].substring(0, 20)}...`,
                    errorCode,
                  });
                }
              }
            });

            logger.warn("Batch failure summary", {
              batchNumber,
              totalFailures: response.failureCount,
              failureReasons,
              invalidTokensCount: invalidTokens.length,
            });
          } else {
            logger.info("All messages in batch sent successfully", {
              batchNumber,
              successCount: response.successCount,
            });
          }
        } catch (error) {
          logger.error("Error sending FCM batch", {
            batchNumber,
            batchSize: batchTokens.length,
            changeIndex: changeIndex + 1,
            error: error instanceof Error ? {
              message: error.message,
              name: error.name,
              stack: error.stack,
            } : String(error),
          });
        }
      }

      logger.info(`Completed processing change ${changeIndex + 1}` +
        `/${changes.length}`, {
        changeType: change.type,
        totalBatchesSent: totalBatches,
      });
    }

    // Step 18: Function completion
    const totalExecutionTime = Date.now() - startTime;
    logger.info("=== CLOUD FUNCTION COMPLETED SUCCESSFULLY ===", {
      totalExecutionTimeMs: totalExecutionTime,
      totalExecutionTimeSeconds: (totalExecutionTime / 1000).toFixed(2),
      changesProcessed: changes.length,
      studentsNotified: tokens.length,
      batchesSent: totalBatches * changes.length,
      timestamp: new Date().toISOString(),
    });

    return null;
  } catch (error) {
    const totalExecutionTime = Date.now() - startTime;
    logger.error("=== CLOUD FUNCTION FAILED ===", {
      executionTimeMs: totalExecutionTime,
      error: error instanceof Error ? {
        message: error.message,
        name: error.name,
        stack: error.stack,
      } : String(error),
      timestamp: new Date().toISOString(),
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
  logger.info("Starting change detection", {
    oldDataKeys: Object.keys(oldData).length,
    newDataKeys: Object.keys(newData).length,
  });

  const changes: TimeSlotChange[] = [];
  const allTimeSlots = new Set([...Object.keys(oldData),
    ...Object.keys(newData)]);

  logger.info("Change detection scope", {
    totalTimeSlots: allTimeSlots.size,
    oldSlots: Object.keys(oldData),
    newSlots: Object.keys(newData),
  });

  allTimeSlots.forEach((timeSlot) => {
    const oldSlot = oldData[timeSlot];
    const newSlot = newData[timeSlot];

    logger.info(`Analyzing time slot: ${timeSlot}`, {
      hasOldSlot: !!oldSlot,
      hasNewSlot: !!newSlot,
      oldSlot: oldSlot || null,
      newSlot: newSlot || null,
    });

    // Handle deleted slots
    if (oldSlot && !newSlot) {
      const change = {
        type: "CANCELLED" as const,
        timeSlot,
        course: oldSlot.course,
        teacher: oldSlot.teacher,
        originalCourse: oldSlot.course,
        reason: "Time slot removed",
      };
      changes.push(change);
      logger.info(`Change detected - SLOT DELETED: ${timeSlot}`, change);
      return;
    }

    // Handle new slots
    if (!oldSlot && newSlot) {
      const change = {
        type: (newSlot.isExtraClass ?
          "EXTRA_CLASS" : "MODIFIED") as TimeSlotChange["type"],
        timeSlot,
        course: newSlot.course,
        teacher: newSlot.teacher,
        reason: "New time slot added",
      };
      changes.push(change);
      logger.info(`Change detected - NEW SLOT: ${timeSlot}`, change);
      return;
    }

    // Handle modified slots
    if (oldSlot && newSlot) {
      const oldJson = JSON.stringify(oldSlot);
      const newJson = JSON.stringify(newSlot);

      logger.info(`Comparing slot data for ${timeSlot}`, {
        oldJson,
        newJson,
        areEqual: oldJson === newJson,
      });

      if (oldJson !== newJson) {
        let type: TimeSlotChange["type"] = "MODIFIED";

        if (newSlot.course === "Cancelled" || newSlot.course === "Free") {
          type = "CANCELLED";
        } else if (newSlot.isExtraClass) {
          type = "EXTRA_CLASS";
        } else if (newSlot.isRescheduled) {
          type = "RESCHEDULED";
        }

        const change = {
          type,
          timeSlot,
          course: newSlot.course,
          teacher: newSlot.teacher,
          originalCourse: newSlot.originalCourse || oldSlot.course,
          reason: newSlot.reason,
        };
        changes.push(change);
        logger.info(`Change detected - SLOT MODIFIED: ${timeSlot}`, {
          changeType: type,
          change,
          differences: {
            course: oldSlot.course !== newSlot.course ?
              {old: oldSlot.course, new: newSlot.course} : null,
            teacher: oldSlot.teacher !== newSlot.teacher ?
              {old: oldSlot.teacher, new: newSlot.teacher} : null,
            isExtraClass: oldSlot.isExtraClass !== newSlot.isExtraClass ?
              {old: oldSlot.isExtraClass, new: newSlot.isExtraClass} : null,
            isRescheduled: oldSlot.isRescheduled !== newSlot.isRescheduled ?
              {old: oldSlot.isRescheduled, new: newSlot.isRescheduled} : null,
          },
        });
      } else {
        logger.info(`No changes detected for slot: ${timeSlot}`);
      }
    }
  });

  logger.info("Change detection completed", {
    totalChanges: changes.length,
    changeTypes: changes.reduce((acc, change) => {
      acc[change.type] = (acc[change.type] || 0) + 1;
      return acc;
    }, {} as Record<string, number>),
  });

  return changes;
}

/**
 * Gets the notification title based on change type.
 * @param {string} type - The type of change detected
 * @return {string} The appropriate notification title
 */
function getNotificationTitle(type: TimeSlotChange["type"]): string {
  logger.info("Generating notification title", {type});

  let title: string;
  switch (type) {
  case "CANCELLED":
    title = "Class Cancelled";
    break;
  case "RESCHEDULED":
    title = "Class Rescheduled";
    break;
  case "EXTRA_CLASS":
    title = "Extra Class Added";
    break;
  default:
    title = "Timetable Update";
    break;
  }

  logger.info("Notification title generated", {type, title});
  return title;
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
  logger.info("Formatting notification body", {
    changeType: change.type,
    day,
    timeSlot: change.timeSlot,
    course: change.course,
  });

  const dayName = day.charAt(0).toUpperCase() + day.slice(1);
  let body: string;

  switch (change.type) {
  case "CANCELLED":
    body = `${change.originalCourse || change.course}
     class at ${change.timeSlot} on ${dayName} 
     has been cancelled${change.teacher ?
    ` by ${change.teacher}` : ""}`;
    break;
  case "EXTRA_CLASS":
    body = `Extra ${change.course} class scheduled at ${change.timeSlot}
     on ${dayName}${change.teacher ? ` by ${change.teacher}` : ""}`;
    break;
  case "RESCHEDULED":
    body = `${change.course} class has been rescheduled to ${change.timeSlot}
     on ${dayName}${change.teacher ? ` by ${change.teacher}` : ""}`;
    break;
  default:
    body = `${change.course} class at ${change.timeSlot}
     on ${dayName} has been modified`;
    break;
  }

  logger.info("Notification body formatted", {
    changeType: change.type,
    bodyLength: body.length,
    body: body.substring(0, 100) + (body.length > 100 ? "..." : ""),
  });

  return body;
}
