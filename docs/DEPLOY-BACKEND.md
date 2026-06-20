# Deploying the MySpot backend (Cloud Functions + rules)

The Vercel deploy only ships the **Flutter web frontend**. The backend —
Cloud Functions, Firestore/Storage rules and indexes — is a **separate deploy**
that has never been run for `portionspot-motors`. That is why:

- **Posting silently does nothing** — your profile doc `users/{uid}` is created
  by the `onUserCreate` function, which isn't deployed, so the app has no author
  to post as.
- **"Improve with AI" / "Go Live" fail** with `[firebase_functions/internal]` —
  those callables aren't deployed (and need config/secrets).

Run the steps below **from your own machine** (this can't be done from the web
session — it needs your Firebase login and your real secret values).

> First: `git checkout claude/laughing-hamilton-uqctzc && git pull` so you have
> the code changes that go with this guide (App Check relaxed, model fallbacks).

---

## 0. One-time prerequisites

1. **Upgrade the project to the Blaze (pay-as-you-go) plan.** Functions v2 and
   Secret Manager require it. Firebase Console → ⚙️ → Usage and billing → Modify
   plan. (Has a free monthly allowance; you only pay past it.)
2. Install the CLI and log in:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase use portionspot-motors
   ```

## 1. Install deps + non-secret config

```bash
cd functions
npm install
cp .env.example .env       # already has working OpenAI model IDs
# Only if you'll use Go Live: set AGORA_APP_ID=<your Agora app id> in functions/.env
```

## 2. Set secrets (Secret Manager)

A full `deploy` requires **every** secret referenced in code to exist, even for
features you aren't using yet. Use your **real** key where it matters and a
throwaway value (`unused`) for the rest — the dormant functions (payments,
video) just won't run until you set real values. Each command prompts you to
paste the value:

```bash
# Real — needed for AI. Your OpenAI account must have billing enabled.
firebase functions:secrets:set OPENAI_API_KEY

# Real only if you're enabling Go Live (else paste: unused)
firebase functions:secrets:set AGORA_APP_CERTIFICATE

# Throwaway for now (paste: unused) — payments/video, not used yet
firebase functions:secrets:set PAYSTACK_SECRET
firebase functions:secrets:set FLUTTERWAVE_WEBHOOK_HASH
firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH
firebase functions:secrets:set AI_VIDEO_API_KEY
```

## 3. Deploy

From the **repo root**:

```bash
firebase deploy --only functions,firestore,storage --project portionspot-motors
```

The first deploy enables required Google APIs and can take several minutes. It
also publishes your Firestore security rules and indexes (needed for the feed).

## 4. Fix your existing account (do this once, after deploy)

Your current login was created **before** `onUserCreate` existed, so it has no
profile doc and still can't post. After the deploy, give yourself a profile by
re-provisioning:

- **Easiest:** sign out, then create a **new** account — `onUserCreate` now runs
  and provisions the profile + default handle. You'll land in onboarding.
- **Or:** Firebase Console → Authentication → delete your user → sign up again.

New users from now on are provisioned automatically.

## 5. Verify

- Sign up fresh → you should be routed to **profile setup** (onboarding).
- Post some text → it appears in the feed (writes straight to Firestore).
- "Improve with AI" → works once `OPENAI_API_KEY` is a real, funded key.
- "Go Live" → works once `AGORA_APP_ID` (.env) + `AGORA_APP_CERTIFICATE` (secret)
  are real.

Tail logs while testing: `cd functions && npm run logs`.

---

## What changed in code (this branch)

- **App Check relaxed:** `enforceAppCheck` is now `false` on every callable, so
  the deployed web app (which sends no App Check token) can call them. This is a
  *temporary* convenience — see below.
- **AI model fallbacks:** `aiAssist`/`generateImage` fall back to working OpenAI
  model IDs if the `AI_MODEL_*` env vars are unset, so a missing model can't
  cause the `internal` error. `functions/.env.example` now has real IDs.

---

## Automated deploys (GitHub Actions)

`.github/workflows/deploy-backend.yml` redeploys the backend automatically on
every push to `main` that touches `functions/**` or the rules, and you can also
run it on demand from the repo's **Actions** tab → **Deploy backend** → **Run
workflow**. After it's set up you never have to run `firebase deploy` by hand.

It needs **one** repository secret — a Google Cloud service-account key. (The
function runtime secrets you set in step 2 stay in Secret Manager; CI doesn't
need their values, only permission to deploy.)

### One-time setup

1. **Create a service account + key** (Cloud Console → IAM & Admin → Service
   Accounts → Create, for project `portionspot-motors`). Grant it these roles —
   the simplest reliable set for deploying v2 functions + rules:
   - Firebase Admin
   - Cloud Functions Admin
   - Cloud Run Admin
   - Artifact Registry Administrator
   - Service Account User
   - Secret Manager Admin

   (If you'd rather not fiddle with roles, **Editor** + **Firebase Admin** +
   **Service Account User** also works.) Then **Keys → Add key → JSON** and
   download the file.

   Or via gcloud:
   ```bash
   gcloud iam service-accounts create gh-deployer \
     --project portionspot-motors --display-name "GitHub deployer"
   SA=gh-deployer@portionspot-motors.iam.gserviceaccount.com
   for r in firebase.admin cloudfunctions.admin run.admin \
            artifactregistry.admin iam.serviceAccountUser secretmanager.admin; do
     gcloud projects add-iam-policy-binding portionspot-motors \
       --member "serviceAccount:$SA" --role "roles/$r"
   done
   gcloud iam service-accounts keys create key.json --iam-account "$SA"
   ```

2. **Add the key as a repo secret.** GitHub → repo **Settings** → Secrets and
   variables → **Actions** → New repository secret:
   - Name: `FIREBASE_SERVICE_ACCOUNT`
   - Value: the **entire contents** of the JSON key file.

3. Push to `main` (or run the workflow manually). Done — backend changes now
   ship automatically.

> Still do step 2 of the manual guide (`firebase functions:secrets:set …`) once,
> so the runtime secrets exist in Secret Manager before the first CI deploy.

---

## Before a real launch — re-enable App Check

1. Create a **reCAPTCHA v3** site key, register it in Firebase Console → App
   Check → your web app.
2. Add `RECAPTCHA_V3_SITE_KEY` to the Vercel project env (Production) and redeploy
   the web app (`main.dart` already activates App Check on web when it's set).
3. Flip `enforceAppCheck` back to `true` on the callables and redeploy functions.
