import * as functions from "firebase-functions";

export const testAuth = functions
  .region("asia-south1")
  .https.onCall((data, context) => {
    console.log("🔥 TEST FUNCTION CALLED");
    console.log("📦 Data:", data);
    console.log("🔐 Context Auth:", context.auth);

    if (!context.auth) {
      console.error("❌ AUTH IS NULL");
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication required"
      );
    }

    console.log("✅ UID:", context.auth.uid);
    console.log("✅ Token:", context.auth.token);

    return {
      success: true,
      uid: context.auth.uid,
      email: context.auth.token.email || null,
      timestamp: new Date().toISOString(),
      receivedData: data,
    };
  });
