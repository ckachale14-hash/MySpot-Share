import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "../lib/admin";
import { mintRtcToken } from "../lib/agora";

const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

/** Viewer joins a live stream: mint a subscriber token and bump viewer count. */
export const joinLiveStream = onCall(
  { secrets: [AGORA_APP_CERTIFICATE], enforceAppCheck: true },
  async (req) => {
    const uid = req.auth?.uid;
    if (!uid) throw new HttpsError("unauthenticated", "Sign in required.");

    const streamId = String(req.data?.streamId ?? "");
    const ref = db.doc(`liveStreams/${streamId}`);
    const snap = await ref.get();
    if (!snap.exists || snap.get("status") !== "live") {
      throw new HttpsError("failed-precondition", "Stream is not live.");
    }
    const channel = snap.get("agoraChannel") as string;

    // Distinct positive Agora uid per viewer.
    const agoraUid = Math.floor(Math.random() * 1_000_000_000) + 1;

    await ref.update({
      viewerCount: FieldValue.increment(1),
      peakViewers: FieldValue.increment(1), // approximate; reconciled on end
    });

    const appId = process.env.AGORA_APP_ID ?? "";
    const token =
      appId && AGORA_APP_CERTIFICATE.value()
        ? mintRtcToken({
            appId,
            appCertificate: AGORA_APP_CERTIFICATE.value(),
            channel,
            uid: agoraUid,
            publisher: false,
          })
        : "";

    return { channel, token, appId, uid: agoraUid };
  }
);
