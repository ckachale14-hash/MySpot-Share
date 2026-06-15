# MySpot Share — Go-Live Runbook

The single, ordered checklist that takes the project from *compiles* to *running
against a real backend*, then to the stores. `SETUP.md` has the per-step detail;
this is the do-this-in-order page. Estimated first run: **half a day**.

> The app is already compile-verified and CI-green. Everything below is
> **configuration** — your accounts, secrets, and a deploy — not code.

---

## Phase 0 — Tools & accounts
- [ ] Install **Flutter (stable)**, **Node 20**, **Java 21**, **Firebase CLI**
      (`npm i -g firebase-tools`), **FlutterFire CLI**
      (`dart pub global activate flutterfire_cli`).
- [ ] `firebase login`
- [ ] *(to ship to stores)* Apple Developer ($99/yr), Google Play ($25 once).
- [ ] *(recommended)* a domain for hosting the Privacy/Terms pages + branded email.

## Phase 1 — Firebase project
- [ ] Create the **`myspot-dev`** project (console or `firebase projects:create`);
      upgrade it to the **Blaze** plan (required for Functions/outbound).
- [ ] Enable: **Authentication** (Email/Password, Google, Apple, Phone),
      **Firestore**, **Storage**, **Functions**, **Realtime Database**,
      **App Check**, **Cloud Messaging**, **Remote Config**.
- [ ] Confirm aliases in [`.firebaserc`](../.firebaserc) (`dev` → `myspot-dev`);
      add `staging`/`prod` later. `firebase use dev`.

## Phase 2 — Wire the app to Firebase
- [ ] `cd app && flutterfire configure --project=myspot-dev`
      → regenerates `lib/firebase_options.dart` with real values (the committed
      file is a placeholder).
- [ ] Add the platform config the CLI references: `google-services.json`
      (Android) and `GoogleService-Info.plist` (iOS) — both gitignored.

## Phase 3 — Config & secrets  *(do this BEFORE deploying functions)*
- [ ] `cp functions/.env.example functions/.env` and fill in the **OpenAI model
      IDs** and **`AGORA_APP_ID`** (non-secret).
- [ ] Set secrets (only those you use):
  ```bash
  firebase functions:secrets:set OPENAI_API_KEY
  firebase functions:secrets:set PAYSTACK_SECRET            # init + webhook HMAC
  firebase functions:secrets:set FLUTTERWAVE_WEBHOOK_HASH
  firebase functions:secrets:set AGORA_APP_CERTIFICATE      # live token signing
  firebase functions:secrets:set REVENUECAT_WEBHOOK_AUTH    # mobile IAP webhook
  firebase functions:secrets:set AI_VIDEO_API_KEY           # if AI video enabled
  ```

## Phase 4 — Deploy the backend
- [ ] `scripts/preflight.sh` → must end **“Preflight passed”**.
- [ ] `scripts/deploy.sh dev` (rules, indexes, storage, database, functions).
- [ ] Configure the **TTL policy** on `stories.expiresAt`
      (Firestore → TTL, or `gcloud firestore fields ttls update`).
- [ ] **App Check:** register the debug token printed at first launch (dev), then
      turn on enforcement for callables/services before launch.

## Phase 5 — External services
- [ ] **Agora:** create a project; set `AGORA_APP_ID` (.env) + `AGORA_APP_CERTIFICATE` (secret).
- [ ] **RevenueCat:** app + an entitlement named **`premium`**, an offering with
      `pro`/`business` packages, and a **non-renewing `verification`** product;
      set the webhook URL with an `Authorization: Bearer` header matching
      `REVENUECAT_WEBHOOK_AUTH`. Put the public SDK keys in
      `app/lib/core/config/app_config.dart`.
- [ ] **Paystack / Flutterwave:** accounts + webhook URLs pointing at the
      deployed `paystackWebhook` / `flutterwaveWebhook` functions.
- [ ] **OpenAI:** confirm model IDs in `.env`/Remote Config and **set a hard
      monthly spend cap** in the OpenAI dashboard.

## Phase 6 — Run & smoke test
- [ ] *(optional)* `firebase emulators:start` for a fully local run.
- [ ] `cd app && flutter run` on a device/emulator.
- [ ] Smoke test the golden path:
      **sign up → onboarding (handle + profile) → post → like/comment →
      message → go premium (store sandbox) → receive a push**.
- [ ] Verify `onUserCreate` provisioned the `users/{uid}` doc, a default
      `@handle`, and custom claims; deleting a test account triggers
      `onUserDelete` cleanup.

## Phase 7 — Guardrails (turn on day one)
- [ ] **GCP billing budget + alerts** at 50/80/100%.
- [ ] **OpenAI hard spend cap** (Phase 5).
- [ ] **App Check enforcement** on (Phase 4).
- [ ] Prefer email/Google/Apple sign-in; **rate-limit phone OTP** (SMS costs).
- [ ] Watch the **reads / egress / functions** dashboards weekly.

## Phase 7b — Frontend: run, build, deploy

The Flutter client ships to three targets from one codebase.

**Run (dev)**
```bash
cd app
flutter run -d chrome        # web in the browser
flutter run                  # attached Android/iOS device or emulator
```

**Build**
```bash
flutter build web --release          # → app/build/web   (PWA, branded icons/manifest)
flutter build appbundle --release    # → Android .aab for Play
flutter build ipa --release          # → iOS archive for App Store (needs a Mac + Xcode)
```

**Deploy the web** (fastest way to share a test build — Firebase Hosting, same
project, free tier):
```bash
scripts/deploy-web.sh dev            # build + deploy → https://<project>.web.app
```
Hosting is configured in `firebase.json` (SPA rewrite to `index.html`). Vercel /
Netlify also work — point them at `app/build/web`.

## Phase 8 — Store prep (when ready)
- [ ] Host **Privacy Policy** & **Terms** (sources in `docs/legal/`); fill the
      `{{PLACEHOLDERS}}`; set `AppConfig.privacyUrl/termsUrl` and the store
      listings to those URLs. Have the legal docs reviewed by an attorney.
- [ ] Confirm **bundle IDs** (set to `com.myspotshare.app`) and **signing**.
  - **Android:** generate an upload keystore and create `android/key.properties`
    (template: `app/android/key.properties.example`). The build is already wired
    to use it and falls back to debug signing when it's absent:
    ```bash
    keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
      -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    cp app/android/key.properties.example app/android/key.properties   # then fill in
    ```
    Keep the `.jks` safe — losing it blocks Play updates. Both are gitignored.
  - **iOS:** signing is configured in Xcode (Runner → Signing & Capabilities):
    select your team and a bundle ID; certificates/profiles are managed by Apple.
- [ ] Store listings, screenshots, **Play Data Safety** / **Apple privacy**
      labels (mirror the Privacy Policy).
- [ ] `flutter build appbundle` / `flutter build ipa` → submit for review.

---

### Quick reference
```bash
scripts/preflight.sh          # verify everything is green locally
scripts/deploy.sh dev         # deploy backend to myspot-dev
scripts/deploy-web.sh dev     # build + deploy the web app to Firebase Hosting
cd app && flutter run         # run the app on a device/emulator
firebase emulators:start      # fully local stack (optional)
```
See also: [`SETUP.md`](../SETUP.md) (detail), [`docs/17`](17-firebase-cost-estimates.md)
(costs), [`docs/architecture-diagram.md`](architecture-diagram.md) (system map).
