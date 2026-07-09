const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

async function testFCM() {
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
    android: {
      priority: "high",
      notification: {
        channelId: "nearby_rooms",
        priority: "high",
        defaultSound: true,
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
      },
    },
    tokens: ["dummy_token_12345"],
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log("Success! No error thrown. Responses:", response.responses.map(r => r.error));
  } catch (err) {
    console.error("FCM API ERROR:", err);
  }
}

testFCM().catch(console.error);
