# 16 · Admin Panel

A **web** dashboard for operations, trust & safety, and revenue. Built as
**Flutter Web** on **Firebase Hosting** (reuses the app's `domain/`+`data/`
layers), gated by the `admin`/`moderator` **custom claim**. Every privileged
action writes to `adminAudit`.

## 1. Access & security

- Auth + **custom claim** `role ∈ {moderator, admin}` (set via `setUserRole`
  callable; mirrored to `users/{uid}.role`).
- Rules already grant moderators/admins the needed reads/writes; the panel uses
  the **same Firestore + Functions** (no separate backend).
- Sensitive operations (role changes, refunds, KYC approval) are **Functions**,
  re-checking the claim and writing an audit record.
- **KYC documents** are read via **server-minted signed URLs** (never public
  read) — see [03 §Storage](03-security-rules.md#6-storage-rules-highlights).

## 2. Modules

| Module | Capabilities | Backing |
|--------|-------------|---------|
| **Dashboard** | DAU/MAU, signups, revenue, live streams, report backlog, AI spend | Analytics + aggregates |
| **User management** | search, view, suspend/ban, set role, force logout, view audit | `users`, `setUserRole`, `adminAction` |
| **Verification approvals** | review queue, view KYC docs (signed URLs), approve/reject | `verificationRequests`, `approveVerification` |
| **Advertisement management** | review/approve/pause creatives, view spend & metrics, refund | `adCampaigns`/`ads`, `approveAd` |
| **Featured listings** | manage paid directory slots & schedule | `businesses`, listings inventory |
| **Revenue tracking** | payments ledger, subscriptions, ad/credit revenue, payouts, refunds, multi-currency | `payments`, `subscriptions` |
| **Analytics** | retention/cohorts, funnels, top content, creator reach, FYP health | Analytics/BigQuery export |
| **Reports / moderation** | triage `reports` queue, view flagged content, remove/warn/ban, resolve | `reports`, `adminAction`, `moderateContent` |
| **Content moderation tools** | review AI-flagged + reported items, bulk actions | moderation pipeline |
| **Live ops** | view active streams, end/moderate, ban from live | `liveStreams` |
| **Config / flags** | toggle features, AI quotas, FYP weights, ad cadence | Remote Config |
| **Audit log** | immutable record of every admin action | `adminAudit` |

## 3. Verification review (trust-critical)

```
Queue: verificationRequests where status == in_review (oldest first)
  → open request → view KYC docs via signed URLs (Admin SDK)
  → Approve → approveVerification() ★ : users.verified=true + claim + audit + notify
  → Reject  → status=rejected + reason + audit + notify (refund policy applies)
```
Only Functions advance state; the panel triggers them — never writes the grant
directly.

## 4. Moderation workflow

```
Sources: user reports + AI auto-flags
  → triage queue (severity, type, target)
  → action: dismiss · warn · remove content (removed=true) · suspend · ban
  → audit every action; notify affected user where appropriate
SLA: track time-to-moderate; auto-escalate high-severity (safety) items.
```

## 5. Revenue & finance

- **Append-only `payments` ledger** is the source of truth (multi-currency:
  KES/NGN/GHS/ZAR/USD…). Reconcile against provider dashboards
  (Flutterwave/Paystack/Stripe/RevenueCat).
- Track MRR/ARPU, ad revenue, **AI-credit revenue vs AI cost** (margin), churn,
  refunds/chargebacks (which revoke entitlements via webhook).
- **Payouts** (advertiser refunds, creator programs) handled out-of-band and
  recorded; mobile-money disbursement where relevant.

## 6. Analytics

Enable **BigQuery export** (Firebase Analytics + Firestore) for ad-hoc analysis
and dashboards (Looker Studio). Surface the [KPIs](07-monetization.md#7-kpis-to-instrument-from-day-one)
and FYP-health metrics ([12 §11](12-recommendation-engine.md#11-metrics-to-watch)).

## 7. Build notes

- Flutter Web target sharing `domain/`+`data/` with the app (a separate
  `admin/` entrypoint or a role-gated build flavor).
- Responsive, data-table-heavy UI; server-side pagination on large collections.
- Phase: **Admin v1 in P2** (users, verification, reports, revenue), deepened in
  P3–P4 (ads, analytics, live ops) per [08 Roadmap](08-roadmap.md).
