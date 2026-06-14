import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { db, adminAuth } from "./admin";

/** Merge custom claims without clobbering existing ones. */
async function mergeClaims(uid: string, patch: Record<string, unknown>): Promise<void> {
  const user = await adminAuth.getUser(uid);
  await adminAuth.setCustomUserClaims(uid, { ...(user.customClaims ?? {}), ...patch });
}

/** Grant a verified badge to a user (mirror field + claim). */
export async function grantUserVerification(uid: string): Promise<void> {
  await db.doc(`users/${uid}`).set({ verified: true }, { merge: true });
  await mergeClaims(uid, { verified: true });
}

/** Grant a verified badge to a business (owner keeps their own user status). */
export async function grantBusinessVerification(businessId: string): Promise<void> {
  await db.doc(`businesses/${businessId}`).set({ verified: true }, { merge: true });
}

/** Activate a premium plan (entitlement doc + mirror + claim). */
export async function grantPremium(uid: string, plan: string, provider: string): Promise<void> {
  const renews = Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 3600 * 1000));
  await db.doc(`subscriptions/${uid}`).set(
    {
      plan,
      status: "active",
      provider,
      entitlements: ["premium", plan],
      startedAt: FieldValue.serverTimestamp(),
      renewsAt: renews,
    },
    { merge: true }
  );
  await db.doc(`users/${uid}`).set({ premium: true }, { merge: true });
  await mergeClaims(uid, { premium: true, plan });
}

/** Revoke premium (cancellation / expiration). */
export async function revokePremium(uid: string, status: string): Promise<void> {
  await db.doc(`subscriptions/${uid}`).set({ status }, { merge: true });
  await db.doc(`users/${uid}`).set({ premium: false }, { merge: true });
  await mergeClaims(uid, { premium: false });
}
