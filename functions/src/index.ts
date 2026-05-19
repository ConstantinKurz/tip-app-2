import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Cloud Function to update a user's email in Firebase Authentication.
 * Only callable by admins.
 *
 * @param data - { userId: string, newEmail: string }
 * @returns { success: boolean }
 */
export const updateUserEmail = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Du musst eingeloggt sein."
    );
  }

  // Check if caller is admin
  const callerDoc = await admin.firestore()
    .collection("users")
    .doc(context.auth.uid)
    .get();

  const callerData = callerDoc.data();
  if (!callerData || !callerData.admin) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Nur Admins können E-Mails ändern."
    );
  }

  // Validate input
  const { userId, newEmail } = data;

  if (!userId || typeof userId !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "userId muss angegeben werden."
    );
  }

  if (!newEmail || typeof newEmail !== "string") {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "newEmail muss angegeben werden."
    );
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(newEmail)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Ungültiges E-Mail-Format."
    );
  }

  try {
    // Update email in Firebase Authentication
    await admin.auth().updateUser(userId, { email: newEmail });

    // Update email in Firestore
    await admin.firestore()
      .collection("users")
      .doc(userId)
      .update({ email: newEmail });

    functions.logger.info(`Email updated for user ${userId} to ${newEmail} by admin ${context.auth.uid}`);

    return { success: true, message: "E-Mail erfolgreich geändert." };
  } catch (error: unknown) {
    functions.logger.error(`Error updating email for user ${userId}:`, error);

    if (error instanceof Error) {
      // Handle specific Firebase Auth errors
      const errorCode = (error as { code?: string }).code;
      if (errorCode === "auth/email-already-exists") {
        throw new functions.https.HttpsError(
          "already-exists",
          "Diese E-Mail wird bereits verwendet."
        );
      }
      if (errorCode === "auth/invalid-email") {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Ungültiges E-Mail-Format."
        );
      }
      if (errorCode === "auth/user-not-found") {
        throw new functions.https.HttpsError(
          "not-found",
          "Benutzer nicht gefunden."
        );
      }
    }

    throw new functions.https.HttpsError(
      "internal",
      "Fehler beim Ändern der E-Mail."
    );
  }
});
