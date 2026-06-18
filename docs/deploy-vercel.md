# Deploying the MySpot web app to Vercel

The Flutter web client can be hosted on Vercel (alongside, or instead of, Firebase
Hosting). Vercel has **no native Flutter runtime**, so the build fetches the
Flutter SDK and compiles the web bundle. All config is in the repo:

- [`vercel.json`](../vercel.json) — build command, output dir, SPA rewrite.
- [`scripts/vercel-build.sh`](../scripts/vercel-build.sh) — fetches Flutter, runs
  `flutter build web --release`, forwards env vars as `--dart-define`s.

## One-time setup (GitHub auto-deploy)

1. **Vercel → Add New → Project → Import** this GitHub repo.
2. **Root Directory:** leave as the repo root (`./`). `vercel.json` handles the
   rest; do **not** set it to `app/`.
3. **Framework Preset:** Other (auto-detected from `vercel.json`).
4. Add the **Environment Variables** below (Project → Settings → Environment
   Variables), then **Deploy**. Every push to the connected branch redeploys.

## Environment variables

Firebase **web** keys are public-by-design (they ship in the client bundle), so
these are safe to expose — they're kept out of git only to avoid baking a specific
project into the source. Grab them from **Firebase Console → Project settings →
General → Your apps → Web app → SDK setup and configuration**.

| Variable | Source (Firebase web config) |
|---|---|
| `FIREBASE_WEB_API_KEY` | `apiKey` |
| `FIREBASE_WEB_APP_ID` | `appId` |
| `FIREBASE_MESSAGING_SENDER_ID` | `messagingSenderId` |
| `FIREBASE_PROJECT_ID` | `projectId` |
| `FIREBASE_AUTH_DOMAIN` | `authDomain` |
| `FIREBASE_STORAGE_BUCKET` | `storageBucket` |
| `RECAPTCHA_V3_SITE_KEY` | App Check reCAPTCHA v3 site key (optional) |

If a variable is unset, the build falls back to the `REPLACE_*` placeholder in
`lib/firebase_options.dart` and Firebase calls will fail at runtime — so set at
least the six `FIREBASE_*` values before a real deploy.

`RECAPTCHA_V3_SITE_KEY` is optional: when present the app enables Firebase **App
Check** on web (register the site key in Firebase Console → App Check → your web
app). When absent, the app still boots but App Check is off on web.

## After the first deploy

- Add the Vercel domain (e.g. `myspot.vercel.app` and any custom domain) to
  **Firebase Console → Authentication → Settings → Authorized domains**, or Google
  / email sign-in will be rejected as an unauthorized origin.
- If you enforce App Check on callables/services, the web app must send a valid
  App Check token — make sure `RECAPTCHA_V3_SITE_KEY` is set and the domain is
  registered, otherwise backend calls will be blocked.

## Build/runtime notes

- First build clones the Flutter `stable` SDK (a few minutes). Override the
  channel/tag with a `FLUTTER_VERSION` env var if you need to pin it.
- `vercel.json` rewrites all unmatched paths to `/index.html` for SPA routing;
  static assets are still served directly because rewrites run after the
  filesystem check.
