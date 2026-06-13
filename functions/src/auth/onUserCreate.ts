import * as functionsV1 from "firebase-functions/v1";
import { FieldValue } from "firebase-admin/firestore";
import { db, adminAuth } from "../lib/admin";

/**
 * Provision a new user on sign-up:
 *  - create the public users/{uid} document with safe defaults
 *  - create the private PII subdocument
 *  - reserve a unique default @handle
 *  - set default custom claims { role, plan, verified }
 *
 * (Classic v1 Auth onCreate trigger — fires after the account exists.)
 */
export const onUserCreate = functionsV1.auth.user().onCreate(async (user) => {
  const uid = user.uid;
  const handle = await reserveDefaultHandle(uid);

  await db.doc(`users/${uid}`).set(
    {
      uid,
      handle,
      displayName: user.displayName ?? "New Member",
      bio: "",
      photoUrl: user.photoURL ?? "",
      coverUrl: "",
      accountType: "personal",
      industry: "",
      verified: false,
      premium: false,
      role: "user",
      onboardingComplete: false,
      followerCount: 0,
      followingCount: 0,
      postCount: 0,
      isNewUser: true,
      createdAt: FieldValue.serverTimestamp(),
      lastActiveAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await db.doc(`users/${uid}/private/profile`).set(
    {
      email: user.email ?? null,
      phone: user.phoneNumber ?? null,
      fcmTokens: [],
    },
    { merge: true }
  );

  await adminAuth.setCustomUserClaims(uid, {
    role: "user",
    plan: "free",
    verified: false,
  });
});

/** Reserve `user_<short-uid>` in handles/{handle}; fall back to a suffixed variant. */
async function reserveDefaultHandle(uid: string): Promise<string> {
  const base = `user_${uid.slice(0, 8).toLowerCase()}`;
  const ref = db.doc(`handles/${base}`);
  try {
    await ref.create({ uid, createdAt: FieldValue.serverTimestamp() });
    return base;
  } catch {
    const alt = `${base}${Math.floor(Math.random() * 9000 + 1000)}`;
    await db
      .doc(`handles/${alt}`)
      .set({ uid, createdAt: FieldValue.serverTimestamp() });
    return alt;
  }
}
