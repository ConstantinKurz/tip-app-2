import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

/**
 * Cloud Function to update a user's email in Firebase Authentication.
 * Only callable by admins.
 */
export const updateUserEmail = functions.https.onCall(async (data, context) => {
  console.log("═══════════════════════════════════════════════════");
  console.log("🚀 updateUserEmail STARTED");
  console.log("📥 Raw data received:", data);
  console.log("🔐 Auth context:", context.auth?.uid || "NO AUTH");

  // STEP 1: Check authentication
  console.log("📍 STEP 1: Checking authentication...");
  if (!context.auth) {
    console.error("❌ STEP 1 FAILED: No auth context");
    throw new functions.https.HttpsError("unauthenticated", "Du musst eingeloggt sein.");
  }
  console.log("✅ STEP 1 PASSED: User authenticated as", context.auth.uid);

  // STEP 2: Check admin status
  console.log("📍 STEP 2: Checking admin status...");
  try {
    const callerDoc = await admin.firestore()
      .collection("users")
      .doc(context.auth.uid)
      .get();

    console.log("📄 Firestore doc exists:", callerDoc.exists);
    const callerData = callerDoc.data();
    console.log("📄 Caller data:", callerData);

    if (!callerData) {
      console.error("❌ STEP 2 FAILED: No user data found");
      throw new functions.https.HttpsError("permission-denied", "Benutzer nicht gefunden.");
    }

    if (!callerData.admin) {
      console.error("❌ STEP 2 FAILED: User is not admin. admin field =", callerData.admin);
      throw new functions.https.HttpsError("permission-denied", "Nur Admins können E-Mails ändern.");
    }
    console.log("✅ STEP 2 PASSED: User is admin");
  } catch (firestoreError) {
    console.error("❌ STEP 2 EXCEPTION:", firestoreError);
    throw new functions.https.HttpsError("internal", "Fehler beim Prüfen der Admin-Rechte.");
  }

  // STEP 3: Validate input
  console.log("📍 STEP 3: Validating input...");
  const { userId, newEmail } = data;
  console.log("📝 userId:", userId, "newEmail:", newEmail);

  if (!userId || typeof userId !== "string") {
    console.error("❌ STEP 3 FAILED: Invalid userId");
    throw new functions.https.HttpsError("invalid-argument", "userId muss angegeben werden.");
  }

  if (!newEmail || typeof newEmail !== "string") {
    console.error("❌ STEP 3 FAILED: Invalid newEmail");
    throw new functions.https.HttpsError("invalid-argument", "newEmail muss angegeben werden.");
  }

  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(newEmail)) {
    console.error("❌ STEP 3 FAILED: Invalid email format");
    throw new functions.https.HttpsError("invalid-argument", "Ungültiges E-Mail-Format.");
  }
  console.log("✅ STEP 3 PASSED: Input validated");

  // STEP 4: Update Firebase Auth
  console.log("📍 STEP 4: Updating Firebase Auth...");
  try {
    await admin.auth().updateUser(userId, { email: newEmail });
    console.log("✅ STEP 4 PASSED: Firebase Auth updated");
  } catch (authError: unknown) {
    console.error("❌ STEP 4 FAILED: Firebase Auth error:", authError);
    const errorCode = (authError as { code?: string }).code;
    console.error("   Error code:", errorCode);

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
  console.log("📍 STEP 5: Updating Firestore...");
  try {
    await admin.firestore()
      .collection("users")
      .doc(userId)
      .update({ email: newEmail });
    console.log("✅ STEP 5 PASSED: Firestore updated");
  } catch (firestoreError) {
    console.error("❌ STEP 5 FAILED: Firestore error:", firestoreError);
    console.warn("⚠️ Auth updated but Firestore failed - inconsistent state!");
  }

  console.log("═══════════════════════════════════════════════════");
  console.log("🎉 updateUserEmail COMPLETED SUCCESSFULLY");
  console.log("═══════════════════════════════════════════════════");

  return { success: true, message: "E-Mail erfolgreich geändert." };
});

// ═══════════════════════════════════════════════════════════════════════════
// Joker-Limit Validierung
// Wird bei jedem Tip-Write ausgeführt und korrigiert überschrittene Limits
// ═══════════════════════════════════════════════════════════════════════════

// Joker-Limits pro matchDay/Phase (MUSS mit Flutter MatchPhase übereinstimmen!)
// matchDay 1-3: Vorrunde (groupStage)
// matchDay 4: 16tel-Finale (roundOf16)
// matchDay 5: 8tel-Finale (roundOf8)
// matchDay 6: Viertelfinale (quarterFinal)
// matchDay 7: Halbfinale (semiFinal)
// matchDay 8: Finale (finalStage)
const JOKER_LIMITS: Record<number, number> = {
  1: 0, 2: 0, 3: 0,  // Vorrunde: 0 Joker
  4: 2,              // 16tel-Finale: 2 Joker
  5: 3,              // 8tel-Finale: 3 Joker
  6: 2,              // Viertelfinale: 2 Joker
  7: 2, 8: 2,        // Halbfinale + Finale: zusammen 2 Joker
};

/**
 * Cloud Function: Validiert Joker-Limits bei jedem Tip-Schreibvorgang
 * Wenn ein User mehr Joker setzt als erlaubt, wird der Joker automatisch entfernt.
 */
export const validateJokerLimit = functions.firestore
  .document("tips/{tipId}")
  .onWrite(async (change, context) => {
    // Nur bei Create/Update prüfen (nicht bei Delete)
    if (!change.after.exists) {
      return null;
    }

    const newData = change.after.data();
    if (!newData) {
      return null;
    }

    // ⚡ PERFORMANCE: Wenn kein Joker gesetzt → sofort abbrechen (häufigster Fall!)
    if (!newData.joker) {
      return null;
    }

    // ⚡ PERFORMANCE: Wenn Update und Joker sich nicht geändert hat → nichts zu tun
    const oldData = change.before.exists ? change.before.data() : null;
    if (oldData && oldData.joker === true && newData.joker === true) {
      return null;
    }

    const userId = newData.userId;
    const matchId = newData.matchId;
    const tipId = context.params.tipId;

    if (!matchId) {
      console.warn(`⚠️ [validateJokerLimit] No matchId in tip ${tipId}, skipping`);
      return null;
    }

    // ✅ Match nachschlagen um matchDay zu bekommen
    const matchDoc = await admin.firestore()
      .collection("matches")
      .doc(matchId)
      .get();

    if (!matchDoc.exists) {
      console.warn(`⚠️ [validateJokerLimit] Match ${matchId} not found, skipping`);
      return null;
    }

    const matchData = matchDoc.data();
    const matchDay = matchData?.matchDay;

    if (matchDay === undefined || matchDay === null) {
      console.warn(`⚠️ [validateJokerLimit] Match ${matchId} has no matchDay, skipping`);
      return null;
    }

    console.log(`🎯 [validateJokerLimit] Checking joker for user ${userId}, matchDay ${matchDay}, tipId ${tipId}`);

    // Maximale Joker für diesen matchDay
    const maxJokers = JOKER_LIMITS[matchDay] || 1;

    // matchDay 7+8 (Halbfinale + Finale) teilen sich 2 Joker
    const matchDaysToCheck = (matchDay === 7 || matchDay === 8) ? [7, 8] : [matchDay];

    // ✅ Alle Matches für diese matchDays holen
    const matchesSnapshot = await admin.firestore()
      .collection("matches")
      .where("matchDay", "in", matchDaysToCheck)
      .get();

    const matchIdsForPhase = matchesSnapshot.docs.map((doc) => doc.id);

    if (matchIdsForPhase.length === 0) {
      console.warn(`⚠️ [validateJokerLimit] No matches found for matchDays ${matchDaysToCheck.join(",")}`);
      return null;
    }

    // ✅ Zähle existierende Joker für diesen User in dieser Phase
    const tipsSnapshot = await admin.firestore()
      .collection("tips")
      .where("userId", "==", userId)
      .where("matchId", "in", matchIdsForPhase)
      .where("joker", "==", true)
      .get();

    // Filtere das aktuelle Dokument raus (falls es ein Update ist)
    const existingJokers = tipsSnapshot.docs.filter((doc) => doc.id !== tipId).length;

    console.log(`📊 [validateJokerLimit] User ${userId} has ${existingJokers} existing jokers (max: ${maxJokers}) for matchDays ${matchDaysToCheck.join(",")}`);

    if (existingJokers >= maxJokers) {
      // ❌ Limit überschritten → Joker entfernen
      console.warn(`🚫 [validateJokerLimit] User ${userId} exceeded joker limit (${existingJokers}/${maxJokers}) for matchDay ${matchDay}. Removing joker from tip ${tipId}.`);

      await change.after.ref.update({ joker: false });

      console.log(`✅ [validateJokerLimit] Joker removed from tip ${tipId}`);
      return { corrected: true, reason: "joker_limit_exceeded" };
    }

    console.log(`✅ [validateJokerLimit] Joker valid for tip ${tipId}`);
    return { corrected: false };
  });
