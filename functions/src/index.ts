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

// AI proxy
export { aiAssist } from "./ai/aiAssist";

// Roadmap (wire up in later phases):
// export { stripeWebhook } from "./payments/stripeWebhook";
// export { createLiveStream } from "./live/createLiveStream";
