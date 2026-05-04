const admin = require("firebase-admin");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {logger} = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();
const ROLE_ADMIN_KEY = "role:admin";
const ROLE_MANAGER_KEY = "role:manager";

exports.onAttendanceWritten = onDocumentUpdated("attendance/{attendanceId}", async (event) => {
  logger.info("🔥 FUNCTION TRIGGERED", {function: "onAttendanceWritten"});
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
    recipientKeys: [ROLE_ADMIN_KEY],
    sourceCollection: "attendance",
    sourceId: event.params.attendanceId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });
});

exports.onSiteAssigned = onDocumentUpdated("sites/{siteId}", async (event) => {
  logger.info("🔥 FUNCTION TRIGGERED", {function: "onSiteAssigned", siteId: event.params.siteId});
  const beforeSite = event.data.before.exists ? event.data.before.data() : null;
  const afterSite = event.data.after.exists ? event.data.after.data() : null;

  if (!afterSite) {
    return;
  }

  const beforeManagerId = normalizeValue(beforeSite && beforeSite.managerId);
  const afterManagerId = normalizeValue(afterSite.managerId);
  if (!afterManagerId || beforeManagerId === afterManagerId) {
    return;
  }

  const managerName = await resolveManagerName(afterManagerId);
  const siteName = firstDefined(afterSite.name, afterSite.siteName, "assigned site");

  await db.collection("notifications").add({
    title: "New Site Assigned",
    message: `You have been assigned to ${siteName}.`,
    type: "alert",
    recipientKeys: [ROLE_MANAGER_KEY, userRecipientKey(afterManagerId)],
    targetRole: "manager",
    targetUserId: afterManagerId,
    metadata: {
      siteId: event.params.siteId,
      siteName,
      managerId: afterManagerId,
      managerName,
    },
    sourceCollection: "sites",
    sourceId: event.params.siteId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });

});

exports.onSiteVisitCreated = onDocumentCreated("site_visits/{visitId}", async (event) => {
  logger.info("🔥 FUNCTION TRIGGERED", {function: "onSiteVisitCreated", visitId: event.params.visitId});
  const visit = event.data.data();
  const managerName = firstDefined(visit.managerName, visit.manager, visit.createdBy, "Manager");
  const siteName = firstDefined(visit.siteName, visit.site, visit.locationName, "assigned site");
  await notifyAdminsAboutVisit({
    sourceCollection: "site_visits",
    sourceId: event.params.visitId,
    managerName,
    siteName,
    visitLabel: "site visit",
  });
});

exports.onVisitCreated = onDocumentCreated("field_visits/{visitId}", async (event) => {
  logger.info("🔥 FUNCTION TRIGGERED", {function: "onVisitCreated", visitId: event.params.visitId});
  const visit = event.data.data();
  const managerName = firstDefined(visit.managerName, visit.manager, visit.createdBy, "Manager");
  const siteName = firstDefined(visit.siteName, visit.site, visit.locationName, "assigned site");
  await notifyAdminsAboutVisit({
    sourceCollection: "field_visits",
    sourceId: event.params.visitId,
    managerName,
    siteName,
    visitLabel: "field visit",
  });
});

exports.onNotificationCreated = onDocumentCreated("notifications/{notificationId}", async (event) => {
  logger.info("🔥 FUNCTION TRIGGERED", {
    function: "onNotificationCreated",
    notificationId: event.params.notificationId,
  });
  const notification = event.data.data();
  const recipientKeys = Array.isArray(notification.recipientKeys) ?
    notification.recipientKeys
        .map((value) => `${value}`.trim())
        .filter((value) => value.length > 0) :
    [];

  if (recipientKeys.length === 0) {
    logger.info("Notification has no recipients", {notificationId: event.params.notificationId});
    return;
  }

  const tokenSnapshots = await Promise.all([
    ...recipientKeys.map((recipientKey) => db
        .collection("admin_notification_tokens")
        .where("recipientKeys", "array-contains", recipientKey)
        .where("notificationsEnabled", "==", true)
        .get()),
    ...recipientKeys.map((recipientKey) => db
        .collection("manager_notification_tokens")
        .where("recipientKeys", "array-contains", recipientKey)
        .where("notificationsEnabled", "==", true)
        .get()),
  ]);

  const tokenDocs = new Map();
  tokenSnapshots.forEach((snapshot) => {
    snapshot.docs.forEach((doc) => {
      tokenDocs.set(doc.id, doc);
    });
  });

  const tokens = [...tokenDocs.values()]
      .map((doc) => doc.data().token)
      .filter((token) => typeof token === "string" && token.length > 0);

  if (tokens.length === 0) {
    logger.info("No notification tokens found.", {recipientKeys});
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
      invalidTokens.flatMap((token) => [
        db.collection("admin_notification_tokens").doc(token).delete().catch(() => null),
        db.collection("manager_notification_tokens").doc(token).delete().catch(() => null),
      ]),
  );
});

async function notifyAdminsAboutVisit({
  sourceCollection,
  sourceId,
  managerName,
  siteName,
  visitLabel,
}) {
  await db.collection("notifications").add({
    title: "Visit Created",
    message: `${managerName} created a ${visitLabel} for ${siteName}.`,
    type: "visit",
    recipientKeys: [ROLE_ADMIN_KEY],
    sourceCollection,
    sourceId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    isRead: false,
  });
}

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

async function resolveManagerName(managerId) {
  if (!managerId) {
    return "Manager";
  }

  try {
    const managerDoc = await db.collection("managers").doc(managerId).get();
    if (!managerDoc.exists) {
      return "Manager";
    }
    return firstDefined(managerDoc.data().name, "Manager");
  } catch (error) {
    logger.error("Unable to resolve manager name", error);
    return "Manager";
  }
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

function userRecipientKey(userId) {
  return `user:${userId}`;
}

function isInvalidTokenError(error) {
  if (!error || !error.code) {
    return false;
  }

  return error.code === "messaging/invalid-registration-token" ||
      error.code === "messaging/registration-token-not-registered";
}
