# MySpot Share — App Store Listing Kit

Copy, screenshot plan, and store-form answers for the App Store and Google Play.
Grounded in the actual feature set. Character limits noted in `()`; trim per store.

> Draft marketing copy — review for accuracy and local claims before submitting.

---

## 1. Names & taglines

| Field | Limit | Value |
|-------|-------|-------|
| App name (Play title / App Store name) | 30 | **MySpot Share** *(or “MySpot Share: Entrepreneurs”, 28)* |
| App Store subtitle | 30 | **Where entrepreneurs grow** (24) |
| Play short description | 80 | **Connect with entrepreneurs, share your founder journey, and grow your business.** (78) |
| App Store promo text (updatable, no review) | 170 | **Join a fast-growing community of African founders, investors, and customers. Share your journey, go live, and grow — now with AI-assisted posts and verified profiles.** |

**Keywords** (App Store, ≤100 chars, comma-separated, no spaces after commas):
`entrepreneur,business,networking,startup,founder,investor,mentor,small business,africa,marketing`

## 2. Full description (both stores, ~4000 chars)

> **MySpot Share is where entrepreneurs connect, learn, and grow.**
>
> Whether you're starting your first business, scaling a company, looking for
> investors, or searching for products and services you can trust — MySpot Share
> is the network built for you, starting in Africa and expanding worldwide.
>
> **⭐ Share your Founder Journey**
> Tell the real story of how you started — the capital, the mistakes, the lessons.
> Inspire others and build a following around your experience, not just your wins.
>
> **🤝 Connect with the right people**
> Find and follow entrepreneurs, business owners, professionals, mentors, and
> investors. Discover people and businesses by industry and interest.
>
> **📣 Post, discuss, and go viral**
> Share updates, articles, images, and polls. A personalized For-You feed surfaces
> the content and people that matter to you.
>
> **🎥 Go live**
> Host launches, Q&As, and discussions with live streaming, and react in real time.
>
> **💬 Message and build community**
> Direct and group chats to connect with customers, partners, and collaborators.
>
> **🏢 List your business**
> Create a business profile in the directory, collect reviews, and get discovered.
>
> **✨ Create faster with AI**
> Polish your posts and generate images with built-in AI assistance.
>
> **✔️ Get verified & go Premium**
> Stand out with a verified badge, unlock higher AI limits, advanced analytics, and
> priority placement.
>
> Join MySpot Share and turn your hustle into a network. Your spot. Your story.
> Your growth.

## 3. Categories & rating
- **App Store:** Primary **Business**, Secondary **Social Networking**.
- **Google Play:** Category **Business** (or Social).
- **Age rating:** target **{{MIN_AGE}}+** (matches Terms/Privacy). Likely **17+/Teen**
  due to user-generated content, messaging, and commerce — confirm via each store's
  rating questionnaire (UGC + social features).

## 4. "What's new" (first release)
> Welcome to MySpot Share — the network for entrepreneurs! Share your Founder
> Journey, connect with founders and investors, post and go live, list your
> business, and create with AI. This is our first release — tell us what you'd
> love to see next.

---

## 5. Screenshot plan (shot list)

Order for conversion: lead with the hook (community + Founder Journey), then breadth.
Add a short benefit caption banner above each (brand blue `#0052B4`, white text).

| # | Screen | Caption |
|---|--------|---------|
| 1 | Home feed | **Your business network, reimagined** |
| 2 | Founder Journey detail | **Share how you *really* started** |
| 3 | Discover / People & businesses | **Find investors, mentors & customers** |
| 4 | Live stream | **Go live with your audience** |
| 5 | Article / composer with AI | **Create posts faster with AI** |
| 6 | Messages (incl. group) | **Connect and build community** |
| 7 | Profile with verified badge / Premium | **Stand out — get verified** |
| 8 | Business directory | **List your business, get discovered** |

**Required sizes**
- **App Store:** 6.7" (1290×2796) and 6.5" (1242×2688) iPhone; 5.5" (1242×2208)
  optional; iPad 12.9" (2048×2732) if iPad-enabled. 3–10 each.
- **Google Play:** min 2 phone screenshots (1080×1920+); 7" & 10" tablet sets if
  supporting tablets; **feature graphic 1024×500** (see `docs/brand/feature-graphic.png`).
- *(optional)* App preview video (15–30s).

**How to capture:** run on the relevant simulator/emulator and use seeded demo
data; `flutter screenshot` or the device screenshot, then add caption banners.

---

## 6. Store form answers

**Data safety (Play) / Privacy nutrition labels (Apple)** — mirror
[`docs/legal/PRIVACY.md`](legal/PRIVACY.md):

| Data | Collected | Linked to you | Purpose | Sold |
|------|-----------|---------------|---------|------|
| Name, @handle, photo, bio | Yes | Yes | App functionality | No |
| Email / phone | Yes | Yes | Account, auth | No |
| User content (posts, messages, media) | Yes | Yes | App functionality | No |
| Identity/verification docs (if applying) | Yes | Yes | Verification | No |
| Purchase history | Yes | Yes | Purchases, support | No |
| Usage & diagnostics | Yes | Yes | Analytics, crash, performance | No |
| Approx. device info / push token | Yes | Yes | Notifications, functionality | No |

- Encrypted in transit: **Yes**. Account deletion available in-app: **Yes**
  (*Settings → Delete account*). Provide the deletion path/URL where asked.
- Payment card data: handled by processors; **not** collected by the app.

**Support & URLs**
- Support email: **{{SUPPORT_EMAIL}}** · Marketing URL: **{{SITE_URL}}**
- Privacy Policy URL: **{{PRIVACY_URL}}** · Terms URL: **{{TERMS_URL}}**
  (host `docs/legal/*` and set the same in `AppConfig`).

## 7. Asset checklist
- [x] App icon (all platforms) — generated.
- [x] Feature graphic 1024×500 — `docs/brand/feature-graphic.png`.
- [ ] Screenshots per the shot list (each required size).
- [ ] *(optional)* preview video.
- [ ] Listing copy filled with final URLs/emails and `{{PLACEHOLDERS}}` replaced.
