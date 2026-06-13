import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";

/** Host ends a live stream. */
export const endLiveStream = onCall({ enforceAppCheck: true }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

  const streamId = String(req.data?.streamId ?? "");
  const ref = db.doc(`liveStreams/${streamId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Stream not found.");
  if (snap.get("hostId") !== uid) {
    throw new HttpsError("permission-denied", "Only the host can end the stream.");
  }

  await ref.update({ status: "ended", endedAt: FieldValue.serverTimestamp() });
  return { ok: true };
});

/** Viewer leaves: decrement the live viewer count. */
export const leaveLiveStream = onCall({ enforceAppCheck: true }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");
  const streamId = String(req.data?.streamId ?? "");
  const ref = db.doc(`liveStreams/${streamId}`);
  const snap = await ref.get();
  if (snap.exists && snap.get("status") === "live") {
    await ref.update({ viewerCount: FieldValue.increment(-1) });
  }
  return { ok: true };
});
