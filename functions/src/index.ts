import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Cloud Function to update a user's email in Firebase Authentication.
 * Only callable by admins.
 */
export const updateUserEmail = functions.https.onCall(async (data, context) => {
  functions.logger.info("═══════════════════════════════════════════════════");
  functions.logger.info("🚀 updateUserEmail STARTED");
  functions.logger.info("📥 Raw data received:", JSON.stringify(data));
  functions.logger.info("🔐 Auth context:", context.auth ? `uid=${context.auth.uid}` : "NO AUTH");

  // STEP 1: Check authentication
  functions.logger.info("📍 STEP 1: Checking authentication...");
  if (!context.auth) {
    functions.logger.error("❌ STEP 1 FAILED: No auth context");
    throw new functions.https.HttpsError("unauthenticated", "Du musst eingeloggt sein.");
  }
  functions.logger.info("✅ STEP 1 PASSED: User authenticated as", context.auth.uid);

  // STEP 2: Check admin status
  functions.logger.info("📍 STEP 2: Checking admin status...");
  try {
    const callerDoc = await admin.firestore()
      .collection("users")
      .doc(context.auth.uid)
      .get();

    functions.logger.info("📄 Firestore doc exists:", callerDoc.exists);
    const callerData = callerDoc.data();
    functions.logger.info("📄 Caller data:", JSON.stringify(callerData));

    if (!callerData) {
      functions.logger.error("❌ STEP 2 FAILED: No user data found");
      throw new functions.https.HttpsError("permission-denied", "Benutzer nicht gefunden.");
    }

    if (!callerData.admin) {
      functions.logger.error("❌ STEP 2 FAILED: User is not admin. admin field =", callerData.admin);
      throw new functions.https.HttpsError("permission-denied", "Nur Admins können E-Mails ändern.");
    }
    functions.logger.info("✅ STEP 2 PASSED: User is admin");
  } catch (firestoreError) {
    functions.logger.error("❌ STEP 2 EXCEPTION:", firestoreError);
    throw new functions.https.HttpsError("internal", "Fehler beim Prüfen der Admin-Rechte.");
  }

  // STEP 3: Validate input
  functions.logger.info("📍 STEP 3: Validating input...");
  const { userId, newEmail } = data;
  functions.logger.info("📝 userId:", userId, "newEmail:", newEmail);

  if (!userId || typeof userId !== "string") {
    functions.logger.error("❌ STEP 3 FAILED: Invalid userId");
    throw new functions.https.HttpsError("invalid-argument", "userId muss angegeben werden.");
  }

  if (!newEmail || typeof newEmail !== "string") {
    functions.logger.error("❌ STEP 3 FAILED: Invalid newEmail");
    throw new functions.https.HttpsError("invalid-argument", "newEmail muss angegeben werden.");
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(newEmail)) {
    functions.logger.error("❌ STEP 3 FAILED: Invalid email format");
    throw new functions.https.HttpsError("invalid-argument", "Ungültiges E-Mail-Format.");
  }
  functions.logger.info("✅ STEP 3 PASSED: Input validated");

  // STEP 4: Update Firebase Auth
  functions.logger.info("📍 STEP 4: Updating Firebase Auth...");
  try {
    await admin.auth().updateUser(userId, { email: newEmail });
    functions.logger.info("✅ STEP 4 PASSED: Firebase Auth updated");
  } catch (authError: unknown) {
    functions.logger.error("❌ STEP 4 FAILED: Firebase Auth error:", authError);
    const errorCode = (authError as { code?: string }).code;
    functions.logger.error("   Error code:", errorCode);

    if (errorCode === "auth/email-already-exists") {
      throw new functions.https.HttpsError("already-exists", "Diese E-Mail wird bereits verwendet.");
    }
    if (errorCode === "auth/invalid-email") {
      throw new functions.https.HttpsError("invalid-argument", "Ungültiges E-Mail-Format.");
    }
    if (errorCode === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found", "Benutzer nicht gefunden.");
    }
    throw new functions.https.HttpsError("internal", `Auth-Fehler: ${errorCode}`);
  }

  // STEP 5: Update Firestore
  functions.logger.info("📍 STEP 5: Updating Firestore...");
  try {
    await admin.firestore()
      .collection("users")
      .doc(userId)
      .update({ email: newEmail });
    functions.logger.info("✅ STEP 5 PASSED: Firestore updated");
  } catch (firestoreError) {
    functions.logger.error("❌ STEP 5 FAILED: Firestore error:", firestoreError);
    // Auth was already updated, so we log but don't fail completely
    functions.logger.warn("⚠️ Auth updated but Firestore failed - inconsistent state!");
  }

  functions.logger.info("═══════════════════════════════════════════════════");
  functions.logger.info("🎉 updateUserEmail COMPLETED SUCCESSFULLY");
  functions.logger.info("═══════════════════════════════════════════════════");

  return { success: true, message: "E-Mail erfolgreich geändert." };
});
