import * as functionsV1 from "firebase-functions/v1";
import { db } from "../lib/admin";

/**
 * GDPR / account-deletion cleanup. When a Firebase Auth account is deleted,
 * remove the personal data we control:
 *  - the users/{uid} document tree (profile, private PII, notifications,
 *    saved bookmarks, home-feed cache, interest signals)
 *  - reserved @handles
 *  - authored content (posts, stories, founder journeys) and owned businesses
 *  - follow edges in both directions — the onFollowWrite trigger keeps the
 *    other party's follower/following counters consistent as each edge goes.
 *
 * Payment and subscription ledgers are intentionally retained for legal/audit
 * reasons; they hold no profile PII beyond the uid.
 */
export const onUserDelete = functionsV1
  .runWith({ timeoutSeconds: 540, memory: "512MB" })
  .auth.user()
  .onDelete(async (user) => {
    const uid = user.uid;

    // 1. The entire user document subtree.
    await db.recursiveDelete(db.doc(`users/${uid}`));

    // 2. Authored content + owned businesses (these have subcollections).
    await recursiveDeleteEach(
      db.collection("posts").where("authorId", "==", uid)
    );
    await recursiveDeleteEach(
      db.collection("businesses").where("ownerId", "==", uid)
    );
    await recursiveDeleteEach(
      db.collection("founderJourneys").where("authorId", "==", uid)
    );

    // 3. Flat docs (no subcollections) — batch delete.
    await deleteEach(db.collection("stories").where("authorId", "==", uid));
    await deleteEach(db.collection("handles").where("uid", "==", uid));
    await deleteEach(db.collection("follows").where("followerId", "==", uid));
    await deleteEach(db.collection("follows").where("followingId", "==", uid));
  });

/** Delete each document matched by a query (paged), including its subtree. */
async function recursiveDeleteEach(
  query: FirebaseFirestore.Query
): Promise<void> {
  for (;;) {
    const snap = await query.limit(100).get();
    if (snap.empty) break;
    await Promise.all(snap.docs.map((d) => db.recursiveDelete(d.ref)));
    if (snap.size < 100) break;
  }
}

/** Batch-delete each document matched by a query (no subcollections). */
async function deleteEach(query: FirebaseFirestore.Query): Promise<void> {
  for (;;) {
    const snap = await query.limit(400).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (snap.size < 400) break;
  }
}
