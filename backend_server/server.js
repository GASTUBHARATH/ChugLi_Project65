require("dotenv").config();
const admin = require("firebase-admin");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { geohashQueryBounds, distanceBetween } = require("geofire-common");

// Initialize Firebase Admin.
// For local testing, download a service account key from:
// Firebase Console -> Project Settings -> Service Accounts -> Generate new private key
// Save it in this directory as `serviceAccountKey.json`
try {
  const serviceAccount = require("./serviceAccountKey.json");
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log("✅ Firebase Admin initialized with service account.");
} catch (e) {
  // Fallback to application default credentials (useful when deployed on Render if ENV vars are used)
  admin.initializeApp();
  console.log("⚠️ No serviceAccountKey.json found. Using default credentials.");
}

const db = getFirestore();
const OUTER_RADIUS_KM = 10;
const CATEGORY_EMOJI = {
  Question: "❓",
  Help: "🆘",
  Funny: "😂",
  Confession: "🎤",
  Food: "🍕",
  Networking: "🤝",
  College: "🎓",
};

function haversineKm(lat1, lon1, lat2, lon2) {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
    Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLon / 2) *
    Math.sin(dLon / 2);
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// Helper to clean up stale tokens safely (Firestore limits array-contains-any to 10 elements)
async function cleanUpStaleTokens(staleTokens) {
  if (staleTokens.length === 0) return;

  const chunkedTokens = [];
  for (let i = 0; i < staleTokens.length; i += 10) {
    chunkedTokens.push(staleTokens.slice(i, i + 10));
  }

  for (const chunk of chunkedTokens) {
    const usersWithStale = await db.collection("users").where("fcmTokens", "array-contains-any", chunk).get();
    if (usersWithStale.empty) continue;

    const batch = db.batch();
    for (const doc of usersWithStale.docs) {
      const tokens = doc.data().fcmTokens ?? [];
      const cleaned = tokens.filter((t) => !staleTokens.includes(t));
      batch.update(doc.ref, { fcmTokens: cleaned });
    }
    await batch.commit();
  }
  console.log(`🧹 Removed ${staleTokens.length} stale tokens.`);
}

// Keep track of the start time (minus 1 hour for server sleep cycles)
// This prevents reading the entire database on startup while avoiding missed events.
const startTimeMillis = Date.now() - 60 * 60 * 1000;
const START_TIME = admin.firestore.Timestamp.fromMillis(startTimeMillis);

console.log("🎧 Listening for new rooms...");

// Set up a real-time listener on the 'rooms' collection
db.collection("rooms")
  .where("createdAt", ">", START_TIME)
  .onSnapshot(async (snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
      // We only care about newly created rooms
      if (change.type === "added") {
        const room = change.doc.data();
        const roomId = change.doc.id;

        // Prevent duplicate notifications if the server restarts
        if (room.notificationSent) return;

        // Mark as sent immediately to avoid race conditions
        db.collection("rooms").doc(roomId).update({ notificationSent: true }).catch(console.error);

        await processNewRoom(roomId, room);
      }
    });
  }, (err) => {
    console.error("❌ Error listening to Firestore:", err);
  });

async function processNewRoom(roomId, room) {
  const roomLat = room.latitude;
  const roomLon = room.longitude;
  const roomTitle = room.title ?? "New Room Nearby";
  const roomCategory = room.category ?? "General";
  const creatorUid = room.createdBy ?? "";
  const visibility = room.visibility ?? "Public";

  if (visibility !== "Public") return;
  if (roomLat == null || roomLon == null) return;

  console.log(`\n🔔 New room "${roomTitle}" detected. Querying nearby users...`);

  // Build geohash bounding box
  const center = [roomLat, roomLon];
  const bounds = geohashQueryBounds(center, OUTER_RADIUS_KM * 1000);

  // Query users within each geohash bound
  const promises = bounds.map(([start, end]) =>
    db.collection("users")
      .orderBy("geohash")
      .startAt(start)
      .endAt(end)
      .get()
  );

  const snapshots = await Promise.all(promises);

  const creatorTokens = new Set();
  if (creatorUid) {
    try {
      const creatorDoc = await db.collection("users").doc(creatorUid).get();
      if (creatorDoc.exists) {
        for (const t of (creatorDoc.data().fcmTokens ?? [])) {
          creatorTokens.add(t);
        }
      }
    } catch (e) {
      console.error("Error fetching creator tokens:", e);
    }
  }

  const seenUids = new Set();
  const tokensToSend = [];

  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      const uid = doc.id;

      if (seenUids.has(uid) || uid === creatorUid) continue;
      seenUids.add(uid);

      const userData = doc.data();
      const userLat = userData.lastLocation?.latitude;
      const userLon = userData.lastLocation?.longitude;
      const radiusPref = userData.radiusPreference ?? 0.5;
      const fcmTokens = userData.fcmTokens ?? [];

      if (!userLat || !userLon || fcmTokens.length === 0) continue;

      const distKm = haversineKm(userLat, userLon, roomLat, roomLon);
      if (distKm > radiusPref) continue;

      for (const token of fcmTokens) {
        if (token && typeof token === "string" && !creatorTokens.has(token)) {
          tokensToSend.push(token);
        }
      }
    }
  }

  if (tokensToSend.length === 0) {
    console.log("No nearby users with FCM tokens found.");
    return;
  }

  console.log(`Sending notifications to ${tokensToSend.length} device(s)...`);

  const emoji = CATEGORY_EMOJI[roomCategory] ?? "💬";
  
  // FCM allows max 500 tokens per multicast — batch them
  const BATCH_SIZE = 500;
  let totalSent = 0;
  let totalFailed = 0;

  for (let i = 0; i < tokensToSend.length; i += BATCH_SIZE) {
    const batch = tokensToSend.slice(i, i + BATCH_SIZE);

    const message = {
      notification: {
        title: `${emoji} New room nearby!`,
        body: `"${roomTitle}" just opened in your area. Tap to join!`,
      },
      data: {
        type: "new_room",
        roomId: roomId,
        roomTitle: roomTitle,
        roomCategory: roomCategory,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "nearby_rooms",
          defaultSound: true,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      tokens: batch,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(message);
      totalSent += response.successCount;
      totalFailed += response.failureCount;

      // Clean up stale tokens
      const staleTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code ?? "";
          if (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token") {
            staleTokens.push(batch[idx]);
          }
        }
      });

      await cleanUpStaleTokens(staleTokens);
    } catch (err) {
      console.error("❌ FCM send failed for batch:", err);
    }
  }

  console.log(`✅ FCM result: ${totalSent} sent, ${totalFailed} failed.`);
}

// Keep the Node.js process alive and satisfy Render's port binding requirement
const http = require("http");
const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "text/plain" });
  res.end("Notification server is running OK.\n");
});

server.listen(PORT, () => {
  console.log(`🚀 Dummy HTTP server listening on port ${PORT}`);
});

// ── Broadcast listener ────────────────────────────────────────────────────────
// Listens for new documents in the `broadcasts` collection (created by admin).
// When a new broadcast is detected, it sends an FCM push notification to ALL
// users who have an fcmToken stored in their Firestore user document.

const broadcastStartTimeMillis = Date.now() - 60 * 60 * 1000;
const BROADCAST_START_TIME = admin.firestore.Timestamp.fromMillis(broadcastStartTimeMillis);

console.log("📣 Listening for new broadcasts...");

db.collection("broadcasts")
  .where("createdAt", ">", BROADCAST_START_TIME)
  .onSnapshot(async (snapshot) => {
    snapshot.docChanges().forEach(async (change) => {
      if (change.type === "added") {
        const broadcast = change.doc.data();
        const broadcastId = change.doc.id;

        if (broadcast.notificationSent) return;
        
        db.collection("broadcasts").doc(broadcastId).update({ notificationSent: true }).catch(console.error);

        await processBroadcast(broadcastId, broadcast);
      }
    });
  }, (err) => {
    console.error("❌ Error listening to broadcasts:", err);
  });

async function processBroadcast(broadcastId, broadcast) {
  const title = broadcast.title ?? "📣 Announcement";
  const message = broadcast.message ?? "";
  const target = broadcast.target ?? "all"; // "all" or "active_rooms"
  const createdBy = broadcast.createdBy ?? "Admin";

  console.log(`\n📣 New broadcast "${title}" from ${createdBy} (target: ${target})`);

  let tokensToSend = [];

  if (target === "active_rooms") {
    // Send only to users who are currently in an active room
    tokensToSend = await getTokensForActiveRoomUsers();
  } else {
    // Send to ALL users who have FCM tokens
    tokensToSend = await getAllUserTokens();
  }

  if (tokensToSend.length === 0) {
    console.log("ℹ️  No users with FCM tokens found for this broadcast.");
    return;
  }

  console.log(`📲 Sending broadcast to ${tokensToSend.length} device(s)...`);

  // FCM allows max 500 tokens per multicast — batch them
  const BATCH_SIZE = 500;
  let totalSent = 0;
  let totalFailed = 0;

  for (let i = 0; i < tokensToSend.length; i += BATCH_SIZE) {
    const batch = tokensToSend.slice(i, i + BATCH_SIZE);

    const fcmMessage = {
      notification: {
        title: title,
        body: message,
      },
      data: {
        type: "broadcast",
        broadcastId: broadcastId,
        broadcastTitle: title,
        broadcastMessage: message,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "broadcasts",
          defaultSound: true,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      tokens: batch,
    };

    try {
      const response = await getMessaging().sendEachForMulticast(fcmMessage);
      totalSent += response.successCount;
      totalFailed += response.failureCount;

      // Clean up stale tokens
      const staleTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const code = resp.error?.code ?? "";
          if (
            code === "messaging/registration-token-not-registered" ||
            code === "messaging/invalid-registration-token"
          ) {
            staleTokens.push(batch[idx]);
          }
        }
      });

      if (staleTokens.length > 0) {
        await cleanUpStaleTokens(staleTokens);
      }
    } catch (err) {
      console.error("❌ FCM broadcast send failed:", err);
    }
  }

  console.log(`✅ Broadcast complete: ${totalSent} sent, ${totalFailed} failed.`);
}

// Get FCM tokens from ALL users in the system
async function getAllUserTokens() {
  const snapshot = await db.collection("users").get();
  const tokens = [];
  for (const doc of snapshot.docs) {
    const fcmTokens = doc.data().fcmTokens ?? [];
    for (const token of fcmTokens) {
      if (token && typeof token === "string") {
        tokens.push(token);
      }
    }
  }
  return tokens;
}

// Get FCM tokens only from users currently inside an active room
async function getTokensForActiveRoomUsers() {
  // Query rooms that are currently active (not expired)
  const now = admin.firestore.Timestamp.now();
  const roomsSnap = await db
    .collection("rooms")
    .where("expiresAt", ">", now)
    .get();

  const uidsInRooms = new Set();
  for (const roomDoc of roomsSnap.docs) {
    // Get participants sub-collection
    const participantsSnap = await roomDoc.ref.collection("participants").get();
    for (const p of participantsSnap.docs) {
      uidsInRooms.add(p.id);
    }
  }

  if (uidsInRooms.size === 0) return [];

  // Get tokens for those UIDs
  const tokens = [];
  const uidArray = Array.from(uidsInRooms);

  // Firestore `in` queries allow max 30 items — batch them
  for (let i = 0; i < uidArray.length; i += 30) {
    const batchUids = uidArray.slice(i, i + 30);
    const usersSnap = await db
      .collection("users")
      .where(admin.firestore.FieldPath.documentId(), "in", batchUids)
      .get();
    for (const doc of usersSnap.docs) {
      const fcmTokens = doc.data().fcmTokens ?? [];
      for (const token of fcmTokens) {
        if (token && typeof token === "string") {
          tokens.push(token);
        }
      }
    }
  }

  return tokens;
}

// ── Mention & Reply notification listener ─────────────────────────────────────
// The Flutter client writes a doc to users/{uid}/notifications/ whenever a
// user is replied to or @mentioned. We pick up new docs here and send the FCM.

const notifStartTime = admin.firestore.Timestamp.fromMillis(Date.now() - 60 * 60 * 1000);

console.log("💬 Listening for mention/reply notifications...");

db.collectionGroup("notifications")
  .where("createdAt", ">", notifStartTime)
  .where("notificationSent", "==", false)
  .onSnapshot(async (snapshot) => {
    for (const change of snapshot.docChanges()) {
      if (change.type !== "added") continue;

      const notif = change.doc.data();
      const notifRef = change.doc.ref;

      // Dedup guard — skip if already processed.
      if (notif.notificationSent) continue;

      // Immediately mark as sent to prevent duplicate deliveries on reconnect.
      notifRef.update({ notificationSent: true }).catch(console.error);

      // Path: users/{targetUid}/notifications/{notifId}
      // parent      = notifications collection ref under a user doc
      // parent.parent = the user DocumentReference  →  .id = targetUid
      const targetUid = notifRef.parent?.parent?.id;
      if (!targetUid) {
        console.warn("⚠️  Could not resolve targetUid from notification path:", notifRef.path);
        continue;
      }

      await sendMentionReplyNotification(targetUid, notif);
    }
  }, (err) => {
    console.error("❌ Error listening to notifications collectionGroup:", err);
  });

async function sendMentionReplyNotification(targetUid, notif) {
  try {
    const userDoc = await db.collection("users").doc(targetUid).get();
    if (!userDoc.exists) return;

    const fcmTokens = userDoc.data().fcmTokens ?? [];
    if (fcmTokens.length === 0) {
      console.log(`ℹ️  User ${targetUid} has no FCM tokens — skipping.`);
      return;
    }

    const type        = notif.type ?? "mention";
    const sender      = notif.senderHandle ?? "Someone";
    const roomTitle   = notif.roomTitle ?? "a room";
    const roomId      = notif.roomId ?? "";
    const preview     = notif.messagePreview ?? `In: ${roomTitle}`;

    const title = type === "reply"
      ? `💬 ${sender} replied to you`
      : `🔔 ${sender} mentioned you`;

    // Body: show a short message preview, fallback to room name.
    const body = preview.length > 0 ? preview : `In room: ${roomTitle}`;

    console.log(`\n📲 Sending ${type} notification to uid=${targetUid} from @${sender}`);

    const message = {
      notification: { title, body },
      data: {
        type,
        roomId,
        roomTitle,
        senderHandle: sender,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "mentions_replies",
          defaultSound: true,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
      tokens: fcmTokens,
    };

    const response = await getMessaging().sendEachForMulticast(message);
    console.log(`✅ ${type} notification: ${response.successCount} sent, ${response.failureCount} failed.`);

    // Clean up any stale / invalid tokens.
    const staleTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const code = resp.error?.code ?? "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          staleTokens.push(fcmTokens[idx]);
        }
      }
    });
    if (staleTokens.length > 0) {
      await cleanUpStaleTokens(staleTokens);
    }
  } catch (err) {
    console.error(`❌ sendMentionReplyNotification failed for uid=${targetUid}:`, err);
  }
}
