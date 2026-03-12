const admin = require("firebase-admin");

admin.initializeApp();

async function setAdmin(email) {
  try {
    const user = await admin.auth().getUserByEmail(email);

    await admin.auth().setCustomUserClaims(user.uid, {
      admin: true
    });

    console.log("✅ Admin role assigned to:", email);
    process.exit();
  } catch (error) {
    console.error("❌ Error:", error.message);
    process.exit(1);
  }
}

const email = process.argv[2];

if (!email) {
  console.log("Usage: node scripts/setAdminRole.js admin@email.com");
  process.exit(1);
}

setAdmin(email);