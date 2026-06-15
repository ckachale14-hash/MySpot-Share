# MySpot Share — Architecture Diagram

One Dart codebase (Flutter) on the client; a serverless Firebase backend; external
services reached **only** from Cloud Functions. Clients read/write their own data
directly (guarded by Security Rules); money, identity, and ranking are written
**only** by Cloud Functions — that's the trust boundary.

![MySpot Share architecture](./brand/architecture.png)

> The Mermaid source below renders on GitHub and is the editable version of the
> diagram above.

```mermaid
flowchart TB
  subgraph CLIENT["📱 Flutter app — iOS · Android · Web (one Dart codebase)"]
    direction TB
    UI["UI layer · Material 3 (brand theme)<br/>features/ — 20 areas, 64 screens"]
    STATE["Riverpod state · go_router navigation"]
    REPO["Repository layer<br/>domain interfaces ⟶ data implementations"]
    UI --> STATE --> REPO
  end

  subgraph FB["☁️ Firebase / Google Cloud — serverless backend"]
    direction TB
    AUTH["Firebase Auth<br/>email · Google · Apple · Phone OTP"]
    FS[("Cloud Firestore<br/>primary database")]
    ST[("Cloud Storage<br/>media")]
    RTDB[("Realtime DB<br/>presence")]
    FCM["Cloud Messaging (push)"]
    CF["Cloud Functions · TypeScript / Node 20<br/>31 functions: triggers · callables · webhooks"]
    OBS["App Check · Remote Config<br/>Crashlytics · Analytics · Performance"]
  end

  subgraph EXT["🔌 External services — server-side only (secrets in Secret Manager)"]
    direction TB
    OPENAI["OpenAI<br/>assist · image · video · moderation"]
    AGORA["Agora<br/>live streaming (RTC tokens)"]
    PAY["Paystack · Flutterwave<br/>+ mobile money (web)"]
    IAP["RevenueCat + Apple / Google<br/>in-app purchases (mobile)"]
  end

  REPO -- "Firebase SDKs · App Check enforced" --> AUTH
  REPO -- "read/write OWN data · Security Rules" --> FS
  REPO --> ST
  REPO --> RTDB
  REPO -- "callable functions" --> CF

  FS -- "onWrite triggers" --> CF
  CF == "privileged writes:<br/>money · identity · ranking" ==> FS
  CF --> FCM
  CF --> OPENAI
  CF --> AGORA
  CF -- "initialize payment" --> PAY
  PAY -. "signed webhook" .-> CF
  IAP -. "signed webhook" .-> CF
  FCM -. "push notification" .-> CLIENT
```

**Reading the trust boundary**
- Thin solid arrows = the client acting as itself (constrained by `firestore.rules`
  + App Check). It can read feeds and write its own posts/messages, but **cannot**
  grant itself `verified`/`premium`/`role` or change counters/ranking.
- The thick arrow = Cloud Functions writing with admin privileges — the only path
  that sets money, identity, or ranking, triggered by Firestore writes or by
  signature-verified payment webhooks.
- Dotted arrows = asynchronous callbacks (webhooks in, push out).

See `docs/01`–`docs/18` for the per-area detail (data model, rules, functions
catalog, recommendation engine, costs, scaling).
