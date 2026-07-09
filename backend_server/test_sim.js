const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");
const { geohashQueryBounds } = require("geofire-common");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

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

async function simulate() {
  const roomLat = 37.4219983;
  const roomLon = -122.084;
  const creatorUid = "ZaiVp3SzC5csFUKL0iJxFSQwxvz1"; // creator of surya room
  
  const center = [roomLat, roomLon];
  const bounds = geohashQueryBounds(center, 10 * 1000); // 10km

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
      
      console.log("Found in bound:", uid);

      if (seenUids.has(uid) || uid === creatorUid) {
        console.log("Skipped due to seen or creator");
        continue;
      }
      seenUids.add(uid);

      const userData = doc.data();
      const userLat = userData.lastLocation?.latitude;
      const userLon = userData.lastLocation?.longitude;
      const radiusPref = userData.radiusPreference ?? 0.5;
      const fcmTokens = userData.fcmTokens ?? [];

      if (!userLat || !userLon || fcmTokens.length === 0) {
        console.log("Skipped due to missing data", { userLat, userLon, tokens: fcmTokens.length });
        continue;
      }

      const distKm = haversineKm(userLat, userLon, roomLat, roomLon);
      console.log(`User ${uid} distance: ${distKm} km, pref: ${radiusPref} km`);
      if (distKm > radiusPref) continue;

      for (const token of fcmTokens) {
        if (token && typeof token === "string") {
          tokensToSend.push(token);
        }
      }
    }
  }

  console.log("Tokens to send:", tokensToSend.length);
  
  // Dry run payload
  const message = {
    notification: {
      title: `❓ New room nearby!`,
      body: `"surya" just opened in your area. Tap to join!`,
    },
    data: {
      type: "new_room",
      roomId: "26FqbnRFTLPIOCTkWshD",
      roomTitle: "surya",
      roomCategory: "Question",
    },
    tokens: tokensToSend,
  };
  
  if (tokensToSend.length > 0) {
    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log("Dry run success:", response.successCount);
    } catch(e) {
      console.error("Dry run error:", e);
    }
  }
}

simulate().catch(console.error);
