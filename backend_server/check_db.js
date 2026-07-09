const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function checkData() {
  const usersSnap = await db.collection("users").where("geohash", "!=", "").limit(5).get();
  console.log(`Found ${usersSnap.size} users with geohash`);
  usersSnap.forEach(doc => {
    console.log("User:", doc.id, doc.data());
  });
}

checkData().catch(console.error);
