# 07 · Monetization Strategy

The platform earns from **verification fees, premium subscriptions, and
advertising**, with room for transaction/marketplace fees later. The hard part
isn't the business model — it's **getting paid without violating app-store
policy**. Read §4 carefully; it has killed many social apps in review.

---

## 1. Revenue streams

| Stream | What | Who pays | Channel |
|--------|------|----------|---------|
| **Verification** | Blue tick for users & businesses | individuals, businesses | mobile: IAP · web: Stripe/Razorpay |
| **Premium subscription** | Pro / Business plans (analytics, visibility, AI quotas, badge) | power users, businesses | mobile: IAP · web: Stripe |
| **Advertising** | Sponsored posts, story ads, video ads, sponsored listings, boosts | advertisers/businesses | **web/portal: Stripe/Razorpay** |
| **AI add-ons** | Higher AI quotas, image/video generation | creators, businesses | bundled in premium; overage via portal |
| **Future** | Marketplace/transaction fees, lead-gen, events/tickets, recruiting | various | various |

> "Advertising payments and the verification fee should go directly into the
> company account" — handled by routing to your Stripe/Razorpay account
> (web/B2B) and your developer payout account (IAP), reconciled in the
> `payments` ledger and admin **Revenue** dashboard.

---

## 2. Plans (illustrative — tune per market)

| | **Free** | **Pro** | **Business** |
|---|---|---|---|
| Post / connect / message | ✅ | ✅ | ✅ |
| AI writing assistant | basic quota (Haiku/Sonnet) | high quota | highest + Opus long-form |
| AI image generation | — | limited | included |
| Verified badge | add-on (one-time/period fee) | included | included |
| Analytics & business insights | — | advanced | advanced + audience |
| Priority placement / visibility | — | ✅ | ✅✅ |
| Ads manager | — | self-serve | self-serve + team |
| Support | community | priority | priority |

Price by market (e.g. India via Razorpay/UPI at localized price points; global
via Stripe/IAP). Keep prices in Remote Config + store products.

---

## 3. Verification economics (the requested flow)

- A **fee** unlocks the *application*, then **review** decides the outcome.
- **Payment first, review second** — enforced server-side (`pending_payment →
  paid → in_review → approved/rejected`); only the webhook sets `paid`.
- Decide policy: is the fee **one-time** or **recurring** (annual re-verification)?
  Recurring fits the subscription/store model better and is recommended.
- **Refund posture:** define up front whether a *rejected* application is
  refunded; reflect in store metadata to avoid review issues.

---

## 4. ⚠️ App-store compliance (do not skip)

Apple App Store (Guideline 3.1.1) and Google Play (Payments policy) require that
**digital goods/services consumed within the app** be sold through **their
billing** (StoreKit / Play Billing). Steering users to external payment for
in-app digital goods can get the app **rejected or removed**.

**How that maps here:**

| Item | Nature | Mobile channel | Web channel |
|------|--------|----------------|-------------|
| Premium subscription | in-app digital service | **IAP (RevenueCat)** ✅ required | Stripe (web sign-up) |
| Verification badge | in-app digital service | **IAP** ✅ required | Stripe/Razorpay (web) |
| **Advertising spend** | purchase of advertising / B2B service | **web advertiser portal (Stripe/Razorpay)** | ✅ |
| AI add-ons sold standalone | in-app digital service | **IAP** | Stripe |

Why advertising can use external billing: buying **ads/promotion** is a
business/advertising service (comparable to how social platforms run ad
purchases via web dashboards), generally outside the consumer-IAP requirement —
**but keep ad creation in a separate web "Ads Manager" portal** and don't sell
consumer-style "boost my post" purchases through in-app external links, which
*are* treated as in-app digital goods. When in doubt, sell consumer-facing
in-app purchases via IAP.

**Implementation guardrails:**
- Use **RevenueCat** to abstract StoreKit/Play and unify entitlements + webhooks.
- Mobile app: **no external payment links** for premium/verification.
- Web: full Stripe/Razorpay for advertiser portal and (optionally) web sign-ups.
- Honor recent external-link allowances (e.g. reader/anti-steering changes)
  **only** after legal/policy review per platform and region — don't design the
  core flow around them.

> This is a **legal/policy** matter as much as engineering. Validate the exact
> approach with current Apple/Google policy and counsel before launch.

---

## 5. Money flow & ledger

```
Purchase ─► provider ─► WEBHOOK ─► Function:
   • verify signature + amount + idempotency (providerRef)
   • payments/{id} append (immutable; provider, purpose, amount, status)
   • grant: subscriptions/{uid} / users.verified / ad campaign funding
   • set custom claims (premium/verified)
   • notify user + adminAudit
```
- `payments` is an **append-only ledger** — the basis for the admin **Revenue**
  view, reconciliation, and refunds.
- **Refunds/chargebacks** arrive as webhooks too → revoke entitlement, write a
  `refunded` ledger entry.
- **Ad spend metering:** impressions/clicks decrement `budget.spent`; pause
  campaign at cap.

---

## 6. Anti-abuse & trust

- Verification requires **paid + reviewed documents** → reduces impersonation.
- App Check + rate limits → block fake-engagement bots that would poison FYP and
  ad metrics.
- Ad review queue → no malicious/scam creatives.
- Transparent **"Sponsored"** labeling on ads (also a store/ad-policy requirement).

---

## 7. KPIs to instrument from day one

| Category | Metrics |
|----------|---------|
| Growth | installs, signups, **referral-attributed signups**, DAU/MAU, stickiness |
| Engagement | posts/user, journeys created, likes/comments/shares, session length, FYP dwell |
| Monetization | verification conversion, premium MRR/ARPU, churn, ad fill & CTR, AI usage cost/user |
| Retention | D1/D7/D30 retention, cohort curves |
| Trust | report rate, time-to-moderate, verification approval rate |

Wire these via Analytics + the admin dashboard so monetization decisions are
data-driven, not guesses.

---

## 8. Phasing (aligns with [roadmap](08-roadmap.md))

1. **P2:** Verification (IAP + web) + premium (IAP) + ledger + admin revenue view.
2. **P3:** Advertising portal (Stripe/Razorpay) + ad serving + AI add-ons.
3. **P4:** Marketplace/transaction fees, audience insights, advanced ad targeting.

Stand up the **payment ledger and webhook verification early** — it underpins
every revenue stream and is the riskiest integration to retrofit.
