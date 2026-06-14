import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { pushEnabled, sendPush } from "../lib/notifications";

/**
 * On a new message: update the conversation's lastMessage + updatedAt, increment
 * each other member's unread counter, and push to their devices.
 */
export const onMessageCreate = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const msg = snap.data();
    const conversationId = event.params.conversationId;
    const senderId = msg.senderId as string;

    const convRef = db.doc(`conversations/${conversationId}`);
    const convSnap = await convRef.get();
    if (!convSnap.exists) return;
    const conv = convSnap.data() as Record<string, any>;
    const ids = (conv.memberIds as string[] | undefined) ?? [];

    const preview =
      msg.type === "image" ? "📷 Photo" : ((msg.text as string) ?? "");

    const update: Record<string, unknown> = {
      lastMessage: {
        text: preview,
        senderId,
        type: msg.type ?? "text",
        createdAt: msg.createdAt ?? FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    };
    for (const uid of ids) {
      if (uid !== senderId) update[`unread.${uid}`] = FieldValue.increment(1);
    }
    await convRef.update(update);

    // Push to other members.
    const senderName =
      (conv.members?.[senderId]?.displayName as string | undefined) ?? "New message";
    await Promise.all(
      ids
        .filter((uid) => uid !== senderId)
        .map(async (uid) => {
          if (!(await pushEnabled(uid, "message"))) return;
          await sendPush(uid, senderName, preview, {
            type: "message",
            conversationId,
          });
        })
    );
  }
);
