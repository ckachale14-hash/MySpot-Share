/**
 * MySpot Cloud Functions — entry point.
 * Add new functions here as the backend grows (see docs/10-cloud-functions.md).
 */

// Auth & identity
export { onUserCreate } from "./auth/onUserCreate";
export { claimHandle } from "./auth/claimHandle";
export { setUserRole } from "./auth/setUserRole";
export { registerDevice } from "./auth/registerDevice";

// Feed & engagement (P1)
export { onPostCreate, onPostDelete } from "./feed/onPostWrite";
export { onLikeWrite } from "./engagement/onLikeWrite";
export { onCommentCreate, onCommentDelete } from "./engagement/onCommentWrite";
export { onFollowWrite } from "./engagement/onFollowWrite";

// Messaging (P3)
export { onMessageCreate } from "./messaging/onMessageCreate";

// Business directory
export { onReviewWrite } from "./business/onReviewWrite";

// Monetization (P2)
export { startVerification } from "./verification/startVerification";
export { approveVerification } from "./verification/approveVerification";
export { initializePayment } from "./billing/initializePayment";
export { paystackWebhook } from "./billing/paystackWebhook";
export { flutterwaveWebhook } from "./billing/flutterwaveWebhook";
export { getVerificationDocUrl } from "./admin/getVerificationDocUrl";

// Live streaming (P3)
export { createLiveStream } from "./live/createLiveStream";
export { joinLiveStream } from "./live/joinLiveStream";
export { endLiveStream, leaveLiveStream } from "./live/endLiveStream";

// Advertising (P3)
export { initializeAdPayment } from "./ads/initializeAdPayment";
export { approveCampaign } from "./ads/approveCampaign";
export { meterAdEvent } from "./ads/meterAdEvent";

// AI proxy
export { aiAssist } from "./ai/aiAssist";
export { generateImage } from "./ai/generateImage";
