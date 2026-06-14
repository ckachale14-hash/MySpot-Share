/**
 * Server-authoritative pricing. Amounts are in the smallest currency unit
 * (e.g. kobo for NGN, cents for USD). Localize/override via Remote Config later.
 * The client never sends amounts — the server decides, so prices can't be tampered.
 */
export type Purpose = "verification" | "premium";
export type Plan = "pro" | "business";

export const VERIFICATION_FEE = { amount: 500000, currency: "NGN" }; // ₦5,000

export const PLAN_PRICES: Record<Plan, { amount: number; currency: string }> = {
  pro: { amount: 250000, currency: "NGN" }, // ₦2,500 / mo
  business: { amount: 1000000, currency: "NGN" }, // ₦10,000 / mo
};

export function priceFor(purpose: Purpose, plan?: Plan): { amount: number; currency: string } {
  if (purpose === "premium") return PLAN_PRICES[plan ?? "pro"];
  return VERIFICATION_FEE;
}
