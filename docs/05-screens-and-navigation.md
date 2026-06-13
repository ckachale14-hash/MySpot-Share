# 05 · Screens & Navigation

## 1. Navigation model

A **5-tab bottom navigation** shell with a central compose action — familiar to
users of Instagram/TikTok/LinkedIn, optimized for a feed-first business network.
Routing via **go_router** with deep links into every shareable surface.

```
RootShell (StatefulShellRoute — preserves per-tab state)
├── 🏠 Home            /home          FYP feed + stories bar
├── 🔍 Discover        /discover      search, trending, people, journeys, businesses
├── ➕ Create          /create        modal composer (post/story/journey/live/ad)
├── 💬 Messages        /messages      conversations list → chat
└── 👤 Profile         /profile       own profile, settings, premium, verification

Global overlays: Notifications (/notifications), Live viewer (/live/:id),
Search (/search), Settings (/settings).
```

### Route table (deep-linkable)

| Route | Screen | Notes |
|-------|--------|-------|
| `/` `/home` | Home / FYP | stories bar + ranked feed |
| `/post/:id` | Post detail | comments, share |
| `/journey/:id` | Founder Journey detail | timeline view |
| `/u/:handle` | User profile | public |
| `/b/:businessId` | Business profile | directory entry |
| `/discover` | Discover hub | tabs: For You · People · Journeys · Businesses · Trending |
| `/search?q=` | Search results | federated (Algolia) |
| `/create` | Composer | sheet with type switch |
| `/messages` | Conversations | |
| `/chat/:cid` | Chat thread | realtime |
| `/notifications` | Notification center | |
| `/live/:id` | Live viewer/host | Agora |
| `/profile` | My profile | |
| `/settings/*` | Settings tree | account, privacy, notifications, blocked |
| `/verify` | Verification flow | paid |
| `/premium` | Premium/paywall | plans |
| `/ads` | Ads manager (summary) | links to web portal for full create |
| `/admin/*` | Admin panel | **web only**, role-gated |

---

## 2. Screen inventory by area

### Auth & onboarding
- Splash, Welcome, Sign-in (email/phone/Google/Apple), OTP, Profile setup
  (handle, account type, industry/interests, photo, referral), Permissions primer.

### Home / Feed
- **Home (FYP):** stories bar, ranked feed (text/image/video/article/poll/ad
  cards), pull-to-refresh, infinite scroll, inline like/comment/share/save.
- **Post detail:** media, body, comment thread, engagement bar.
- **Story viewer:** tap-through, progress bars, reactions, reply, 24h expiry.
- **Story composer:** image/video/text/promo, stickers/CTA.

### Discover & search
- **Discover hub** (tabbed): For You, People You May Know, New Users, Journeys,
  Business Directory, Trending hashtags.
- **Search:** unified results with filters (people, businesses, posts, videos,
  industries, hashtags).

### Profiles
- **User profile:** cover/avatar, bio, links, verified tick, counts, tabs
  (Posts · Journeys · Media · About), Follow/Message buttons.
- **Business profile:** logo/cover, description, products/services, contact,
  reviews & rating, Follow/Contact/Visit.
- **Edit profile / Edit business.**

### Founder Journeys ⭐
- **Journeys feed**, **Journey detail** (timeline, capital, lessons),
  **Journey editor** (guided, incremental, AI-assisted).

### Create
- **Composer sheet:** switch between Post / Story / Journey / Go Live / Promote.
- **AI assist panel:** improve, rewrite, fix grammar, generate caption/article,
  tone selector (premium tiers unlock more).

### Messaging
- **Conversations list** (unread badges, last message preview).
- **Chat thread** (text/media/files, read receipts, typing).
- **New message / New group**.

### Live
- **Live host** (preview, go live, viewer count, live chat moderation).
- **Live viewer** (video, chat, reactions, share, follow host).
- **Live discovery** (currently live, by viewers).

### Notifications
- **Notification center** (grouped: engagement, follows, messages, verification,
  ads, live, system), unread management.

### Monetization
- **Verification flow:** intro → upload docs → pay → status.
- **Premium paywall:** plan comparison (Free / Pro / Business), purchase.
- **Ads manager (in-app summary):** campaigns list, metrics; deep link to web
  portal for full campaign creation.

### Settings
- Account, Privacy (visibility, blocked users), Notification preferences,
  Security (2FA — future), Language, Help, About, Logout, Delete account.

### Admin (web)
- Dashboard (KPIs), Users, Verification queue, Ads review, Reports/moderation,
  Revenue, Analytics, Audit log.

---

## 3. Design system

> Brief: **professional, modern, clean, premium, business-focused, fast.**
> Reads like LinkedIn's trust + Instagram/TikTok's energy, tuned for entrepreneurs.

| Token | Direction |
|-------|-----------|
| **Theme** | Light + dark; Material 3 (`useMaterial3: true`) as base, customized |
| **Primary** | A confident, trustworthy brand color (deep indigo/blue family) with an energetic accent (amber/teal) for CTAs & "live"/"verified" highlights |
| **Verified** | Distinct blue tick treatment; premium surfaces get a subtle accent ring |
| **Typography** | Clean grotesque/sans (e.g. Inter/General Sans) for UI; readable serif optional for long-form **articles & journeys** |
| **Shape** | 12–16px radii, soft elevation, generous whitespace — "premium, not cluttered" |
| **Motion** | Fast, purposeful micro-interactions (like burst, story progress, live pulse); 150–250ms |
| **Density** | Comfortable; thumb-reachable primary actions |
| **Components** | Centralized widget library: `PostCard`, `StoryRing`, `JourneyTimeline`, `UserTile`, `BusinessCard`, `VerifiedBadge`, `EngagementBar`, `AdCard`, `LiveBadge` |
| **Accessibility** | WCAG AA contrast, scalable text, semantic labels, RTL-ready |
| **Skeletons** | Shimmer placeholders on every async surface (feed, profile, chat) |

The design system lives in `app/lib/core/theme/` and a shared widget catalog in
`app/lib/core/widgets/` so screens compose from one source of truth (see
[09 Flutter Architecture](09-flutter-architecture.md)).

---

## 4. Key UX principles

1. **Founder story is one tap from anywhere** — a persistent "Share your journey"
   entry in the composer and profile; it's the platform's signature behavior.
2. **Optimistic UI** — likes/follows/sends reflect instantly; reconcile on
   listener.
3. **Trust signals everywhere** — verified ticks, ratings, "new entrepreneur"
   badges build confidence in a business context.
4. **Progressive monetization** — premium/verification surfaced contextually
   (e.g. analytics teaser on your post), never naggy.
5. **Empty states that teach** — first-run feed, empty inbox, no journeys yet →
   each guides the user to the next valuable action.
