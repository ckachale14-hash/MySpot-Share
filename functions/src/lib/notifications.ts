import { FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import { db } from "./admin";

export type Actor = {
  uid: string;
  handle?: string;
  displayName?: string;
  photoUrl?: string;
};

export type NotificationType =
  | "like"
  | "comment"
  | "follow"
  | "mention"
  | "system";

/**
 * Send an FCM push to a user's registered devices (no in-app notification doc).
 * Best-effort: prunes tokens that fail. Use for messages and transient pings.
 */
export async function sendPush(
  uid: string,
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<void> {
  try {
    const snap = await db.doc(`users/${uid}/private/profile`).get();
    const tokens = (snap.get("fcmTokens") as string[] | undefined) ?? [];
    if (tokens.length === 0) return;

    const res = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title, body },
      data,
    });

    const stale: string[] = [];
    res.responses.forEach((r, i) => {
      if (!r.success) stale.push(tokens[i]);
    });
    if (stale.length) {
      await db
        .doc(`users/${uid}/private/profile`)
        .update({ fcmTokens: FieldValue.arrayRemove(...stale) });
    }
  } catch (e) {
    console.error("sendPush failed", e);
  }
}

/**
 * Write an in-app notification to the recipient and best-effort send a push.
 * Never throws into the calling trigger.
 */
export async function notify(params: {
  toUid: string;
  type: NotificationType;
  actor: Actor;
  postId?: string;
  text?: string;
}): Promise<void> {
  const { toUid, type, actor, postId, text } = params;
  if (toUid === actor.uid) return; // don't notify yourself

  try {
    await db.collection(`users/${toUid}/notifications`).add({
      type,
      actor,
      postId: postId ?? null,
      text: text ?? null,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (e) {
    console.error("notify: failed to write notification doc", e);
    return;
  }

  await sendPush(toUid, pushTitle(type, actor), text ?? pushBody(type, actor), {
    type,
    postId: postId ?? "",
    actorUid: actor.uid,
  });
}

function pushTitle(type: NotificationType, actor: Actor): string {
  const name = actor.displayName || `@${actor.handle ?? "someone"}`;
  switch (type) {
    case "like":
      return `${name} liked your post`;
    case "comment":
      return `${name} commented`;
    case "follow":
      return `${name} followed you`;
    case "mention":
      return `${name} mentioned you`;
    default:
      return "MySpot";
  }
}

function pushBody(type: NotificationType, actor: Actor): string {
  switch (type) {
    case "follow":
      return "Tap to view their profile.";
    case "mention":
      return "Tap to see the post.";
    default:
      return "Tap to open MySpot.";
  }
}
