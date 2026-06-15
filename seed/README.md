# Demo / seed data

Idempotent demo content so the feed, discover, journeys, business directory, and
stories look alive for screenshots and first-run. Re-running overwrites (fixed
`seed_*` document ids), so it's safe to run repeatedly.

What it creates: 8 demo founders/investors (with avatars), 8 posts (text, image,
poll, article) + comments, 3 Founder Journeys, 4 businesses + reviews, 5 stories,
and a follow graph. Images use public placeholders (`pravatar`, `picsum`).

## Run against the emulator (recommended)

```bash
cd seed && npm install
# one-shot (starts the emulator, seeds, exits):
firebase emulators:exec --only firestore --project demo-myspot "node seed.js"
# …or with the emulator already running:
FIRESTORE_EMULATOR_HOST=localhost:8080 node seed.js
```

## Run against a dev project (writes for real)

Uses the Admin SDK, so it can set verified/premium/counters directly. Needs admin
credentials (a service account or `gcloud auth application-default login`):

```bash
cd seed && npm install
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccount.json \
GCLOUD_PROJECT=myspot-dev node seed.js
```

## Also populate Messages + Notifications for your test account

The global content shows for any signed-in user. To also fill the **Messages** and
**Notifications** tabs for your own test login, pass your uid (find it in the
Firebase Auth console or `users/{uid}`):

```bash
SEED_FOR_UID=<your-test-uid> node seed.js
```

> Note: the demo users are Firestore documents, not real Auth accounts — they
> populate feeds and profiles, but you sign in with your own account.
