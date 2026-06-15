import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { db } from "../lib/admin";

/**
 * When {uid} blocks {blockedUid}, sever the follow relationship both ways so
 * neither keeps seeing the other via the graph. Deleting the edges lets
 * onFollowWrite fix both users' follower/following counters.
 */
export const onBlockCreate = onDocumentCreated(
  "users/{uid}/blocks/{blockedUid}",
  async (event) => {
    const { uid, blockedUid } = event.params;
    const edges = [
      db.doc(`follows/${uid}_${blockedUid}`),
      db.doc(`follows/${blockedUid}_${uid}`),
    ];
    await Promise.all(
      edges.map((ref) =>
        ref.delete().catch((e) => console.error("onBlockCreate: unfollow", e))
      )
    );
  }
);
