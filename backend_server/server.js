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

// Keep track of the start time so we don't process old rooms on startup
const START_TIME = admin.firestore.Timestamp.now();

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
        if (token && typeof token === "string") {
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
        priority: "high",
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
    tokens: tokensToSend,
  };

  try {
    const response = await getMessaging().sendEachForMulticast(message);
    console.log(`FCM result: ${response.successCount} sent, ${response.failureCount} failed.`);

    // Clean up stale tokens
    const staleTokens = [];
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const code = resp.error?.code ?? "";
        if (code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token") {
          staleTokens.push(tokensToSend[idx]);
        }
      }
    });

    if (staleTokens.length > 0) {
      const usersWithStale = await db.collection("users").where("fcmTokens", "array-contains-any", staleTokens).get();
      const batch = db.batch();
      for (const doc of usersWithStale.docs) {
        const tokens = doc.data().fcmTokens ?? [];
        const cleaned = tokens.filter((t) => !staleTokens.includes(t));
        batch.update(doc.ref, { fcmTokens: cleaned });
      }
      await batch.commit();
      console.log(`Removed ${staleTokens.length} stale tokens.`);
    }
  } catch (err) {
    console.error("FCM send failed:", err);
  }
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
