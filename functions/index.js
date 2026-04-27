const admin = require("firebase-admin");
const {onDocumentCreated, onDocumentWritten} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

exports.onAttendanceWritten = onDocumentWritten("attendance/{attendanceId}", async (event) => {
  const beforeData = event.data.before.exists ? event.data.before.data() : null;
  const afterData = event.data.after.exists ? event.data.after.data() : null;

  if (!afterData) {
    return;
  }

  const eventPayload = buildAttendanceNotification(beforeData, afterData);
  if (!eventPayload) {
    return;
  }

  await db.collection("notifications").add({
    ...eventPayload,
    sourceCollection: "attendance",
    sourceId: event.params.attendanceId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });
});

exports.onSiteVisitCreated = onDocumentCreated("site_visits/{visitId}", async (event) => {
  const visit = event.data.data();
  const managerName = firstDefined(visit.managerName, visit.manager, visit.createdBy, "Manager");
  const siteName = firstDefined(visit.siteName, visit.site, visit.locationName, "assigned site");

  await db.collection("notifications").add({
    title: "Site Visit Submitted",
    message: `${managerName} submitted a site visit for ${siteName}.`,
    type: "visit",
    sourceCollection: "site_visits",
    sourceId: event.params.visitId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });
});

exports.onNotificationCreated = onDocumentCreated("notifications/{notificationId}", async (event) => {
  const notification = event.data.data();
  const tokensSnapshot = await db
      .collection("admin_notification_tokens")
      .where("role", "==", "admin")
      .where("notificationsEnabled", "==", true)
      .get();

  const tokens = tokensSnapshot.docs
      .map((doc) => doc.data().token)
      .filter((token) => typeof token === "string" && token.length > 0);

  if (tokens.length === 0) {
    logger.info("No admin notification tokens found.");
    return;
  }

  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: notification.title || "GuardGrey Notification",
      body: notification.message || "",
    },
    data: {
      notificationId: event.params.notificationId,
      type: notification.type || "alert",
    },
    android: {
      priority: "high",
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
        },
      },
    },
  });

  const invalidTokens = [];
  response.responses.forEach((result, index) => {
    if (!result.success) {
      logger.error("Failed to send notification", result.error);
      if (isInvalidTokenError(result.error)) {
        invalidTokens.push(tokens[index]);
      }
    }
  });

  await Promise.all(
      invalidTokens.map((token) => db.collection("admin_notification_tokens").doc(token).delete()),
  );
});

function buildAttendanceNotification(beforeData, afterData) {
  const managerName = firstDefined(
      afterData.managerName,
      afterData.name,
      afterData.employeeName,
      "Manager",
  );
  const siteName = firstDefined(afterData.siteName, afterData.site, afterData.locationName, "");

  const beforeCheckIn = normalizeValue(beforeData && firstDefined(beforeData.checkIn, beforeData.checkInAt));
  const afterCheckIn = normalizeValue(firstDefined(afterData.checkIn, afterData.checkInAt));
  const beforeCheckOut = normalizeValue(beforeData && firstDefined(beforeData.checkOut, beforeData.checkOutAt));
  const afterCheckOut = normalizeValue(firstDefined(afterData.checkOut, afterData.checkOutAt));
  const status = firstDefined(afterData.status, "updated");

  if (!beforeData && afterCheckIn) {
    return {
      title: "Manager Checked In",
      message: buildSiteMessage(`${managerName} checked in`, siteName),
      type: "attendance",
    };
  }

  if (!beforeCheckIn && afterCheckIn) {
    return {
      title: "Manager Checked In",
      message: buildSiteMessage(`${managerName} checked in`, siteName),
      type: "attendance",
    };
  }

  if (!beforeCheckOut && afterCheckOut) {
    return {
      title: "Manager Checked Out",
      message: buildSiteMessage(`${managerName} checked out`, siteName),
      type: "attendance",
    };
  }

  return {
    title: "Attendance Updated",
    message: `${managerName} attendance was updated to ${status}.`,
    type: "attendance",
  };
}

function buildSiteMessage(prefix, siteName) {
  return siteName ? `${prefix} at ${siteName}.` : `${prefix}.`;
}

function firstDefined(...values) {
  for (const value of values) {
    if (value !== undefined && value !== null && `${value}`.trim().length > 0) {
      return `${value}`.trim();
    }
  }
  return "";
}

function normalizeValue(value) {
  if (value === undefined || value === null) {
    return null;
  }

  const stringValue = `${value}`.trim();
  if (!stringValue || stringValue === "-") {
    return null;
  }

  return stringValue;
}

function isInvalidTokenError(error) {
  if (!error || !error.code) {
    return false;
  }

  return error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered";
}
