# 17 · Firebase & Infrastructure Cost Estimates

> **These are planning estimates, not quotes.** Real cost depends on per-user
> activity (reads/writes, media, AI, live minutes). The value here is the
> **cost model** and the **mitigations** — so you can forecast and control spend.

## 1. The cost drivers (what actually moves the bill)

| Driver | Billed on | Risk |
|--------|-----------|------|
| **Firestore reads** | per document read | 🔴 highest — feeds multiply reads |
| Firestore writes/deletes | per document | 🟠 counters, fan-out |
| Firestore storage | GB-month | 🟢 small |
| **Network egress** | GB out | 🔴 media & API responses |
| **Cloud Storage egress** | GB downloaded | 🔴 if serving media directly |
| Cloud Functions | invocations + GB-sec + CPU + egress | 🟠 scales with triggers/AI proxy |
| **Phone-auth SMS (OTP)** | per SMS | 🔴 expensive in Africa at scale |
| **Live video (Agora)** | per host+viewer **minute** | 🔴 grows with concurrent viewers |
| **Video transcode/CDN (Mux)** | encoding + delivery | 🟠 offloads Storage egress |
| **AI (OpenAI/video)** | per token / image / video | 🔴 video, 🟠 text/image |
| Algolia search | records + searches | 🟠 |
| Payment fees | % per transaction (Flutterwave/Paystack/Stripe/stores) | revenue-linked |
| FCM, Hosting, Remote Config, App Check | mostly free / negligible | 🟢 |

> **Firestore reads are the #1 surprise.** A feed that reads 50 posts + authors +
> like-state naively can be hundreds of reads per refresh. Denormalization,
> caching, and pagination are what keep this affordable.

## 2. Illustrative monthly ranges

Rough order-of-magnitude for the **Firebase + core vendors** bill (USD), assuming
good architecture (denormalized feed, CDN media, mobile-money over SMS where
possible, AI premium-gated). Heavy video/AI usage can move these materially.

| Scale (MAU) | Firebase (Firestore/Functions/Storage) | Media CDN (Mux) | AI (OpenAI) | Live (Agora) | SMS OTP | **Indicative total** |
|-------------|------------------------------------------|-----------------|-------------|--------------|---------|----------------------|
| **10K** | low hundreds | low hundreds | tens–low hundreds | usage-based | low hundreds¹ | **~$0.5–2K** |
| **100K** | low–mid thousands | thousands | hundreds–low thousands | thousands | thousands¹ | **~$5–20K** |
| **1M** | tens of thousands | tens of thousands | thousands–tens of thousands | tens of thousands | high (mitigate!) | **~$50–200K+** |

¹ **SMS OTP is a major lever** — prefer email/Google/Apple and **WhatsApp/mobile-money
identity** where possible, cache sessions, and rate-limit OTP to control it.

These ranges are intentionally wide. **Build the cost model below into a
spreadsheet driven by your real per-user-action assumptions** and refresh it with
production telemetry.

## 3. Cost model (use this, not the table)

```
monthly_cost ≈
    reads_per_DAU·DAU·30·$/read
  + writes_per_DAU·DAU·30·$/write
  + media_GB_served·$/GB_CDN
  + functions_invocations·$/invoke + GB_sec·$/GB_sec
  + OTP_count·$/SMS
  + live_minutes·(hosts+viewers)·$/min
  + ai_text_tokens·$/tok + ai_images·$/img + ai_videos·$/video
  + storage_GB·$/GB_month + search_units
```
Instrument each term with Analytics/usage logs; the dominant terms are
**reads**, **media egress**, **AI**, **live minutes**, and **SMS**.

## 4. Mitigations (architecture = cost control)

| Lever | Saving |
|-------|--------|
| **Denormalize** author/like-state onto posts | fewer reads per feed render |
| **Paginate + cache** FYP pages; client offline cache | fewer repeat reads |
| **Bundle reads**; precompute trending/home on schedule | fewer per-request reads |
| **Serve media via CDN (Mux/Cloudflare)**, not Storage egress | big egress saving + African PoPs |
| **Image compression + "data saver" mode** | less egress (and better UX in Africa) |
| **Batch counter updates** (or shard) | fewer writes on hot docs |
| **Premium-gate + credit-meter AI**; cheapest viable model tier | AI cost capped + monetized |
| **Cap live minutes per plan**; adaptive/low bitrate | Agora cost control |
| **Minimize SMS OTP** (social/email auth, session reuse, rate limits) | SMS saving |
| **Algolia search-only key + tuned indices** | search cost control |
| **BigQuery for analytics** (don't query Firestore for analytics) | avoids read blowups |

## 5. Guardrails (turn these on day one)

- **Billing budgets + alerts** (e.g. 50/80/100% thresholds) on the GCP project.
- **Per-resource alerts**: Functions error rate, Storage/Function egress, AI spend.
- **Per-user/global rate limits & quotas** (AI, messaging, OTP, live).
- **Blaze plan** is required (Functions/outbound); watch egress and reads dashboards weekly.
- **App Check** to stop bots inflating reads/AI/ad metrics (bots are a cost, not just a security issue).

## 6. Vendor pricing to track (check current rates)

Firestore (reads/writes/storage/egress), Cloud Functions, Cloud Storage egress,
Identity Platform **phone-auth SMS**, OpenAI (token/image/video), Agora
(per-minute), Mux/Cloudflare Stream, Algolia, Flutterwave/Paystack/Stripe (%/txn),
RevenueCat (% above free tier). Re-baseline quarterly — vendor pricing changes.
