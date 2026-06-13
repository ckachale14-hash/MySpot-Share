/**
 * MySpot Cloud Functions — entry point.
 * Add new functions here as the backend grows (see docs/10-cloud-functions.md).
 */

// Auth & identity
export { onUserCreate } from "./auth/onUserCreate";
export { claimHandle } from "./auth/claimHandle";
export { setUserRole } from "./auth/setUserRole";

// AI proxy
export { aiAssist } from "./ai/aiAssist";

// Roadmap (wire up in later phases):
// export { onPostCreate } from "./feed/onPostCreate";
// export { stripeWebhook } from "./payments/stripeWebhook";
// export { createLiveStream } from "./live/createLiveStream";
