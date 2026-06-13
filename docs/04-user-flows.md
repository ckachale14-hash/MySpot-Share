# 04 · User Flows

Each flow notes the **trust-critical** steps (★ = server-authoritative). Diagrams
are intentionally implementation-near so they double as build checklists.

---

## 1. Onboarding & authentication

```
Launch ─► Splash (App Check init, auth state check)
        │
        ├─ returning, valid session ─────────────► Home (FYP)
        │
        └─ new / signed out ─► Welcome
              ├─ Email / Phone / Google / Apple
              │      └─ Auth success ★ (Auth onCreate Function provisions
              │             users/{uid} + users/{uid}/private + claims)
              └─ First-run profile setup
                    • handle (uniqueness via handles/{handle})
                    • accountType: personal / business_owner / creator / investor
                    • industry + interests  ◄── seeds FYP & "People You May Know"
                    • optional: photo, bio, location (opt-in)
                    • optional: enter referral code  ──► referrals attribution ★
                    └─► Home (FYP) + "Follow 5 to get started" nudge
```

**Why interests at signup:** the FYP and "People You May Know" engines are
cold-start-sensitive. Capturing `industry` + a few interest tags immediately
gives the ranker signal on day one.

---

## 2. Create & engage with content

### 2.1 Compose a post
```
Tap (+) ─► Composer
   ├─ type: text / image / video / article / poll / business update
   ├─ attach media ─► upload to users/{uid}/posts/{postId}/... (size-capped)
   ├─ optional: AI assist (improve / rewrite / generate)  ──► §AI flow
   ├─ #hashtags, @mentions, visibility (public/followers)
   └─ Publish ─► write posts/{postId}
           └─ onCreate(posts) ★: counters, hashtag increment, fan-out,
              Algolia sync, FYP signals
```

### 2.2 Engage
```
Like     ─► create posts/{id}/likes/{uid}   ──► Function batches likeCount ★
Comment  ─► create posts/{id}/comments/{id} ──► commentCount ★ + notify author
Share    ─► repost / external share          ──► shareCount ★ + referral link
Save     ─► users/{uid}/saved/{postId}       (private)
Follow   ─► follows/{uid}_{authorId}         ──► counts ★ + notify + fan-out
Report   ─► reports/{id} (status=open)       ──► moderation queue
```

### 2.3 Founder Journey (flagship)
```
Tap "Share my journey" ─► guided multi-step editor
   • title, industry, current stage
   • startup capital (with "keep private" toggle)
   • timeline milestones (add as you grow)
   • challenges / mistakes / lessons
   • optional AI: "help me tell my story"  ──► §AI flow
   └─ Publish ─► founderJourneys/{id}  ──► appears in Journeys tab + profile
```

---

## 3. Verification & payment ★ (trust-critical)

The client can **request** verification but never **grant** it. Payment is
confirmed by a provider **webhook**, not by the client reporting success.

```
Profile ─► "Get Verified" ─► Verification intro (benefits, fee, requirements)
   │
   ├─ Upload required documents ─► verification/{uid}/...  (PRIVATE storage)
   ├─ callable startVerification() ★
   │      └─ create verificationRequests/{id} = pending_payment
   │
   ├─ Pay the fee
   │     • MOBILE  : RevenueCat / StoreKit / Play Billing   (store policy)
   │     • WEB     : Flutterwave / Paystack / Stripe (cards, bank, USSD, mobile money)
   │
   ├─ PROVIDER webhook ─► verifyPayment() ★
   │      • validate signature + amount + idempotency
   │      • write payments/{id} (succeeded)
   │      • verificationRequests/{id}: paid ─► in_review
   │
   ├─ Admin panel: reviewer approves / rejects ★
   │      • approve ─► users/{uid}.verified = true + claim {verified:true}
   │      • adminAudit entry + notification
   │
   └─ User sees blue tick; gains priority placement & premium surfaces
```

> **The verification process only begins after successful payment confirmation**
> — enforced because `in_review` is reachable **only** from `paid`, which is set
> **only** by the webhook Function. See [07 Monetization](07-monetization.md) for
> the store-compliance nuance (digital good → native IAP on mobile).

---

## 4. Personalized FYP (For You Page)

```
Open Home ─► FYP service requests a ranked page
   │
   ├─ Candidate generation (server/ranking function):
   │     • followed authors' recent posts
   │     • posts in user's industries/interests
   │     • trending (hashtags/score) + fresh "new user" content
   │     • eligible sponsored posts (ads)
   │
   ├─ Ranking score (MVP heuristic):
   │     score = w1·affinity(author,user)
   │           + w2·engagementVelocity(post)
   │           + w3·recencyDecay(createdAt)
   │           + w4·interestMatch(post,user)
   │           − w5·seenPenalty
   │     (weights in Remote Config; ads inserted at fixed cadence)
   │
   ├─ Client renders; engagement events stream back ─► users/{uid}/interests ★
   └─ Ranker continuously improves from likes/comments/shares/saves/dwell
```

**Evolution path:** heuristic (P1) → Vertex AI embeddings + vector match for
content/user similarity (P4). Keep the scoring behind a function so the formula
can change without a client release.

---

## 5. Discovery surfaces

| Surface | Source |
|---------|--------|
| **People You May Know** | same `industry`, mutual follows, similar engagement, optional location |
| **New Users Discovery** | `users` where `isNewUser == true` ordered by `createdAt` |
| **Trending** | `hashtags` by `score` |
| **Business Directory** | `businesses` by `category` / `ratingAvg`, searchable (Algolia) |
| **Journeys** | `founderJourneys` by industry / featured |
| **Search** | Algolia federated: people · businesses · posts · videos · hashtags + filters |

---

## 6. Messaging (realtime)

```
Open chat with user/business
   ├─ find-or-create conversations/{cid} (memberIds = [me, them])
   ├─ listen conversations/{cid}/messages (realtime)
   ├─ send message ─► create message (rules: sender==me ∧ me ∈ members)
   │      └─ onCreate(messages) ★: lastMessage, unread++ (others), push
   ├─ attach image/video/file ─► users/{uid}/chat/{cid}/...
   └─ group chats: same model, type=group, title/photo
```

---

## 7. Live streaming

```
"Go Live" ─► callable createLiveStream() ★ (liveStreams/{id}=live + host Agora token)
   ├─ Broadcast (Agora video) + live chat/reactions (subcollection or RTM)
   ├─ Viewers ─► callable joinLiveStream() ★ (viewer token) ─► subscribe
   ├─ viewerCount / peakViewers maintained ★
   └─ End ─► finalize stream; optional VOD ─► Mux playbackId
```

Use cases surfaced in UI: business discussions, product launches, Q&A,
entrepreneurship lessons.

---

## 8. Advertising (advertiser flow)

```
Business ─► Ads Manager (in-app summary; full creation in web portal)
   ├─ Create campaign (objective, budget, schedule, targeting)
   │      └─ adCampaigns/{id}=draft
   ├─ Add creatives (feed/story/video/listing) ─► ads/{adId}
   ├─ Fund campaign ─► Flutterwave/Paystack/Stripe (web)  ──► payments ★ ─► status=active
   ├─ Admin review ★ ─► active / rejected
   ├─ Serving: ranking layer inserts eligible active ads into feeds/stories
   │      └─ impressions/clicks metered ★ → metrics + spend (budget caps)
   └─ Advertiser dashboard: impressions, clicks, CTR, spend
```

See the [monetization doc](07-monetization.md) on why **ad spend uses
Flutterwave/Paystack/Stripe via the web portal**, not in-app IAP.

---

## 9. Invite friends & referrals

```
Profile ─► Invite ─► share via WhatsApp / Facebook / Instagram / Email / SMS / link
   ├─ Branch link carries referralCode (deferred deep link — installs survive)
   ├─ New user opens link ─► install ─► code applied at signup ★
   └─ referrals/{code}.signups++  ──► reward logic (Function)
```

> ⚠️ **Not Firebase Dynamic Links** (retired). Use **Branch** (or AppsFlyer) for
> install-attributed, deferred deep links. See [06 Integrations](06-integrations.md#6-deep-links--referrals).

---

## 10. Notifications

```
Trigger (like/comment/follow/mention/message/verification/ad/live/system)
   └─ Function ★: write users/{uid}/notifications/{id} + send FCM to fcmTokens
        ├─ in-app: realtime notification center (unread badge)
        └─ push: deep-links into the relevant screen
```

---

## 11. Admin & moderation

```
Admin panel (Flutter Web, gated by claim role=admin/moderator)
   ├─ User management: suspend, set role, force-logout
   ├─ Verification approvals: review docs (signed URLs) ─► approve/reject ★
   ├─ Ad management: review/approve/pause creatives ★
   ├─ Content moderation: reports queue ─► remove post / warn / ban ★
   ├─ Revenue: payments, subscriptions, ad spend, payouts
   └─ Analytics: DAU/MAU, retention, funnels, top content
   (every privileged action ─► adminAudit ★)
```
