import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getStorage } from "firebase-admin/storage";

/**
 * Admin/moderator: mint a short-lived signed URL to review a private KYC document.
 * KYC files are not publicly readable (see storage.rules) — review always goes
 * through this server-minted URL.
 */
export const getVerificationDocUrl = onCall({ enforceAppCheck: false }, async (req) => {
  const role = req.auth?.token.role;
  if (role !== "admin" && role !== "moderator") {
    throw new HttpsError("permission-denied", "Moderators only.");
  }
  const path = String(req.data?.path ?? "");
  if (!path.startsWith("verification/")) {
    throw new HttpsError("invalid-argument", "Invalid document path.");
  }

  const [url] = await getStorage()
    .bucket()
    .file(path)
    .getSignedUrl({ action: "read", expires: Date.now() + 15 * 60 * 1000 });

  return { url };
});
