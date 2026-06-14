import { HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin";

// Per-plan daily AI request limits. Tune in Remote Config later.
const DAILY_LIMIT: Record<string, number> = {
  free: 20,
  pro: 200,
  business: 1000,
};

/**
 * Atomically enforce a per-user, per-day AI request quota by plan.
 * Throws `resource-exhausted` when the limit is reached.
 */
export async function assertWithinQuota(
  uid: string,
  plan: string,
  _task: string
): Promise<void> {
  const day = new Date().toISOString().slice(0, 10); // YYYY-MM-DD
  const ref = db.doc(`users/${uid}/aiUsage/${day}`);
  const limit = DAILY_LIMIT[plan] ?? DAILY_LIMIT.free;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const used = (snap.exists ? (snap.get("count") as number) : 0) ?? 0;
    if (used >= limit) {
      throw new HttpsError(
        "resource-exhausted",
        "Daily AI limit reached. Upgrade your plan for more."
      );
    }
    tx.set(
      ref,
      { count: FieldValue.increment(1), updatedAt: FieldValue.serverTimestamp() },
      { merge: true }
    );
  });
}

/** Record usage for billing/abuse analytics. */
export async function logAiUsage(
  uid: string,
  tier: string,
  usage: unknown
): Promise<void> {
  await db.collection("aiUsageLog").add({
    uid,
    tier,
    usage: usage ?? null,
    at: FieldValue.serverTimestamp(),
  });
}
