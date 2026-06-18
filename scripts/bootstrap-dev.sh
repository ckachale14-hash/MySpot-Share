#!/usr/bin/env bash
#
# One-shot dev bootstrap: wire Firebase -> deploy backend -> seed demo data, so
# you go from a fresh clone to a running, populated app in the fewest steps.
#
# Prereqs (GO-LIVE Phase 0): flutter, node 20, java 21, the Firebase CLI and
# FlutterFire CLI installed, `firebase login` done, and a Firebase project on the
# Blaze plan. This deploys to your REAL project (the dev one) — it's additive
# (rules/functions + idempotent demo data), not destructive.
#
# Usage:
#   scripts/bootstrap-dev.sh [PROJECT_ID]     # default: the 'dev' alias in .firebaserc
#
# Re-run knobs (env): SKIP_CONFIGURE=1  SKIP_DEPLOY=1  SKIP_SEED=1
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

step() { printf '\n\033[1;34m▶ %s\033[0m\n' "$1"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "✗ missing required tool: $1"; exit 1; }; }

step "Checking tools"
need flutter; need node; need firebase
echo "  flutter, node, firebase ✓"

# Resolve the target project: arg, else the 'dev' alias in .firebaserc.
PROJECT_ID="${1:-}"
if [ -z "$PROJECT_ID" ]; then
  PROJECT_ID="$(node -e "try{process.stdout.write((JSON.parse(require('fs').readFileSync('.firebaserc','utf8')).projects||{}).dev||'')}catch(e){}")"
fi
[ -n "$PROJECT_ID" ] || { echo "✗ No project id. Pass one: scripts/bootstrap-dev.sh <project-id>"; exit 1; }
echo "  Target Firebase project: $PROJECT_ID"

step "Verifying Firebase login"
firebase projects:list >/dev/null 2>&1 || { echo "✗ Run 'firebase login' first."; exit 1; }
echo "  Logged in ✓"

# 1) Wire the app — regenerates app/lib/firebase_options.dart with real values.
if [ "${SKIP_CONFIGURE:-}" != "1" ]; then
  step "flutterfire configure (app/lib/firebase_options.dart + platform files)"
  need flutterfire || { echo "  install it: dart pub global activate flutterfire_cli"; exit 1; }
  ( cd app && flutterfire configure --project="$PROJECT_ID" --platforms=android,ios,web --yes )
fi

# 2) Secret — functions reference OPENAI_API_KEY at deploy time, so it must exist.
if [ "${SKIP_DEPLOY:-}" != "1" ]; then
  step "Ensuring the OPENAI_API_KEY secret"
  if firebase functions:secrets:access OPENAI_API_KEY --project "$PROJECT_ID" >/dev/null 2>&1; then
    echo "  Already set ✓"
  else
    echo "  Not set — you'll be prompted (input hidden):"
    firebase functions:secrets:set OPENAI_API_KEY --project "$PROJECT_ID"
  fi

  # 3) Deploy backend (functions are built by the firebase.json predeploy hook).
  step "Deploying rules, indexes, storage, database, functions"
  ( cd functions && npm install )
  firebase deploy \
    --only firestore:rules,firestore:indexes,storage,database,functions \
    --project "$PROJECT_ID"
fi

# 4) Seed demo data (best-effort — a live project needs Admin credentials).
if [ "${SKIP_SEED:-}" != "1" ]; then
  step "Seeding demo data"
  ( cd seed && npm install --silent )
  if GCLOUD_PROJECT="$PROJECT_ID" node seed/seed.js; then
    echo "  Seeded ✓"
  else
    echo "  ⚠ Seeding a live project needs Admin credentials. Either:"
    echo "      gcloud auth application-default login"
    echo "      GCLOUD_PROJECT=$PROJECT_ID node seed/seed.js"
    echo "    …or seed the local emulator instead:"
    echo "      firebase emulators:exec --only firestore --project demo-myspot \"node seed/seed.js\""
  fi
fi

step "Bootstrap complete"
cat <<EONEXT
Next:
  • Configure the TTL policy on stories.expiresAt (Firestore -> TTL).
  • App Check: register the debug token printed at first launch.
  • Run the app:       cd app && flutter run
  • Or deploy the web: scripts/deploy-web.sh dev
Full checklist: docs/GO-LIVE.md
EONEXT
