import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { mintRtcToken } from "../lib/agora";

const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

/** Host starts a live stream: create the doc and mint a publisher token. */
export const createLiveStream = onCall(
  { secrets: [AGORA_APP_CERTIFICATE], enforceAppCheck: false },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const title = String(req.data?.title ?? "Live");
    const category = String(req.data?.category ?? "");

    const userSnap = await db.doc(`users/${uid}`).get();
    const u = userSnap.data() ?? {};
    const ref = db.collection("liveStreams").doc();
    const channel = ref.id;

    await ref.set({
      hostId: uid,
      host: {
        uid,
        handle: u.handle ?? "",
        displayName: u.displayName ?? "",
        photoUrl: u.photoUrl ?? "",
        verified: u.verified ?? false,
      },
      title,
      category,
      status: "live",
      agoraChannel: channel,
      viewerCount: 0,
      peakViewers: 0,
      startedAt: FieldValue.serverTimestamp(),
    });

    const appId = process.env.AGORA_APP_ID ?? "";
    const token =
      appId && AGORA_APP_CERTIFICATE.value()
        ? mintRtcToken({
            appId,
            appCertificate: AGORA_APP_CERTIFICATE.value(),
            channel,
            uid: 0,
            publisher: true,
          })
        : "";

    return { streamId: ref.id, channel, token, appId, uid: 0 };
  }
);
