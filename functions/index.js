const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Firestore trigger: runs when a new post is created
exports.sendNotificationOnNewPost = functions.firestore
  .document("posts/{postId}")
  .onCreate(async (snap, context) => {
    const postData = snap.data();

    const payload = {
      notification: {
        title: "New Post Alert 🚀",
        body: postData.heading || "A new post has been added!",
      },
    };

    try {
      // 1️⃣ Get all user tokens from Firestore
      const usersSnapshot = await admin.firestore().collection('users').get();
      const tokens = usersSnapshot.docs
        .map(doc => doc.data().fcmToken)
        .filter(token => !!token); // remove null/undefined

      if (tokens.length === 0) {
        console.log("No tokens found, skipping notification");
        return null;
      }

      // 2️⃣ Send notification to all tokens
      const response = await admin.messaging().sendToDevice(tokens, payload);
      console.log("Notifications sent successfully:", response);
    } catch (error) {
      console.error("Error sending notification:", error);
    }
  });
