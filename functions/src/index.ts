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
// Joker-Limit Validierung (OPTIMIERT für Mobile Performance)
// Nutzt denormalisierte Counter im User-Dokument statt alle Tips zu durchsuchen
// ═══════════════════════════════════════════════════════════════════════════

// Joker-Limits pro matchDay/Phase (MUSS mit Flutter MatchPhase übereinstimmen!)
const JOKER_LIMITS: Record<number, number> = {
  1: 0, 2: 0, 3: 0,  // Vorrunde: 0 Joker
  4: 2,              // 16tel-Finale: 2 Joker
  5: 3,              // 8tel-Finale: 3 Joker
  6: 2,              // Viertelfinale: 2 Joker
  7: 2, 8: 2,        // Halbfinale + Finale: zusammen 2 Joker
};

// ⚡ Hilfsfunktion: Counter-Key für matchDay (7+8 teilen sich einen Key)
function getJokerCounterKey(matchDay: number): string {
  return (matchDay === 7 || matchDay === 8) ? "7_8" : String(matchDay);
}

// ⚡ Cache für Match → MatchDay Mapping (reduziert DB-Reads)
const matchDayCache: Map<string, number> = new Map();

/**
 * ⚡ OPTIMIERTE Cloud Function: Synchronisiert Joker-Counter im User-Dokument
 * Wird bei jedem Tip-Write ausgeführt, aber ist extrem schnell durch Counter-Nutzung
 */
export const validateJokerLimit = functions.firestore
  .document("tips/{tipId}")
  .onWrite(async (change, context) => {
    const tipId = context.params.tipId;
    
    // Bei Delete: Joker-Counter dekrementieren falls nötig
    if (!change.after.exists) {
      const oldData = change.before.data();
      if (oldData?.joker && oldData?.userId && oldData?.matchId) {
        await updateJokerCounter(oldData.userId, oldData.matchId, -1);
      }
      return null;
    }

    const newData = change.after.data();
    if (!newData) return null;

    const oldData = change.before.exists ? change.before.data() : null;
    const oldJoker = oldData?.joker === true;
    const newJoker = newData.joker === true;

    // ⚡ FAST PATH: Keine Joker-Änderung → nichts zu tun
    if (oldJoker === newJoker) {
      return null;
    }

    const userId = newData.userId;
    const matchId = newData.matchId;

    if (!userId || !matchId) {
      console.warn(`⚠️ [validateJokerLimit] Missing userId or matchId in tip ${tipId}`);
      return null;
    }

    // Joker wurde hinzugefügt
    if (!oldJoker && newJoker) {
      // ⚡ Hole matchDay (aus Cache oder DB)
      const matchDay = await getMatchDay(matchId);
      if (matchDay === null) {
        console.warn(`⚠️ [validateJokerLimit] Could not get matchDay for ${matchId}`);
        return null;
      }

      const counterKey = getJokerCounterKey(matchDay);
      const maxJokers = JOKER_LIMITS[matchDay] || 1;

      // ⚡ Lese aktuellen Counter aus User-Dokument (1 Read statt N Queries!)
      const userRef = admin.firestore().collection("users").doc(userId);
      const userDoc = await userRef.get();
      const jokerCounters = userDoc.data()?.jokerCounters || {};
      const currentCount = jokerCounters[counterKey] || 0;

      console.log(`🎯 [validateJokerLimit] User ${userId}: ${currentCount}/${maxJokers} jokers for key ${counterKey}`);

      if (currentCount >= maxJokers) {
        // ❌ Limit überschritten → Joker entfernen
        console.warn(`🚫 [validateJokerLimit] Limit exceeded! Removing joker from tip ${tipId}`);
        await change.after.ref.update({ joker: false });
        return { corrected: true, reason: "joker_limit_exceeded" };
      }

      // ✅ Counter inkrementieren
      await userRef.set({
        jokerCounters: { [counterKey]: currentCount + 1 }
      }, { merge: true });

      console.log(`✅ [validateJokerLimit] Joker added, counter updated: ${counterKey} = ${currentCount + 1}`);
      return { corrected: false };
    }

    // Joker wurde entfernt
    if (oldJoker && !newJoker) {
      await updateJokerCounter(userId, matchId, -1);
      console.log(`✅ [validateJokerLimit] Joker removed from tip ${tipId}`);
    }

    return { corrected: false };
  });

/**
 * ⚡ Hilfsfunktion: Holt matchDay für ein Match (mit Caching)
 */
async function getMatchDay(matchId: string): Promise<number | null> {
  // Check Cache
  if (matchDayCache.has(matchId)) {
    return matchDayCache.get(matchId)!;
  }

  const matchDoc = await admin.firestore().collection("matches").doc(matchId).get();
  if (!matchDoc.exists) return null;

  const matchDay = matchDoc.data()?.matchDay;
  if (matchDay === undefined || matchDay === null) return null;

  // Cache für 5 Minuten (Cloud Function Instance Lifetime)
  matchDayCache.set(matchId, matchDay);
  return matchDay;
}

/**
 * ⚡ Hilfsfunktion: Aktualisiert Joker-Counter für einen User
 */
async function updateJokerCounter(userId: string, matchId: string, delta: number): Promise<void> {
  const matchDay = await getMatchDay(matchId);
  if (matchDay === null) return;

  const counterKey = getJokerCounterKey(matchDay);
  const userRef = admin.firestore().collection("users").doc(userId);

  await admin.firestore().runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    const jokerCounters = userDoc.data()?.jokerCounters || {};
    const currentCount = jokerCounters[counterKey] || 0;
    const newCount = Math.max(0, currentCount + delta);

    transaction.set(userRef, {
      jokerCounters: { [counterKey]: newCount }
    }, { merge: true });
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// Admin Function: Initialisiert Joker-Counter für alle User (einmalig ausführen!)
// ═══════════════════════════════════════════════════════════════════════════

/**
 * Admin-Only: Berechnet und setzt alle Joker-Counter neu
 * Aufruf: firebase functions:call rebuildJokerCounters
 */
export const rebuildJokerCounters = functions.https.onCall(async (data, context) => {
  // Admin-Check
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentifizierung erforderlich");
  }

  const callerDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!callerDoc.data()?.admin) {
    throw new functions.https.HttpsError("permission-denied", "Nur Admins können dies ausführen");
  }

  console.log("🔧 [rebuildJokerCounters] Starting rebuild...");

  // 1. Alle Matches laden für matchDay-Mapping
  const matchesSnapshot = await admin.firestore().collection("matches").get();
  const matchDayMap: Record<string, number> = {};
  matchesSnapshot.docs.forEach((doc) => {
    matchDayMap[doc.id] = doc.data().matchDay;
  });

  console.log(`📦 [rebuildJokerCounters] Loaded ${Object.keys(matchDayMap).length} matches`);

  // 2. Alle Tips mit Joker laden
  const tipsSnapshot = await admin.firestore()
    .collection("tips")
    .where("joker", "==", true)
    .get();

  console.log(`🃏 [rebuildJokerCounters] Found ${tipsSnapshot.docs.length} joker tips`);

  // 3. Counter pro User berechnen
  const userCounters: Record<string, Record<string, number>> = {};

  for (const tipDoc of tipsSnapshot.docs) {
    const tip = tipDoc.data();
    const userId = tip.userId;
    const matchId = tip.matchId;
    const matchDay = matchDayMap[matchId];

    if (!userId || matchDay === undefined) continue;

    const counterKey = getJokerCounterKey(matchDay);

    if (!userCounters[userId]) {
      userCounters[userId] = {};
    }
    userCounters[userId][counterKey] = (userCounters[userId][counterKey] || 0) + 1;
  }

  console.log(`👥 [rebuildJokerCounters] Calculated counters for ${Object.keys(userCounters).length} users`);

  // 4. Counter in Firestore schreiben (Batch)
  const batch = admin.firestore().batch();
  let updateCount = 0;

  for (const [userId, counters] of Object.entries(userCounters)) {
    const userRef = admin.firestore().collection("users").doc(userId);
    batch.set(userRef, { jokerCounters: counters }, { merge: true });
    updateCount++;
  }

  await batch.commit();

  console.log(`✅ [rebuildJokerCounters] Updated ${updateCount} users`);

  return {
    success: true,
    usersUpdated: updateCount,
    jokerTipsProcessed: tipsSnapshot.docs.length,
    message: `Joker-Counter für ${updateCount} User aktualisiert`,
  };
});
