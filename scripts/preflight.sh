#!/usr/bin/env bash
#
# Local verification — run before deploying. Proves the backend typechecks,
# the app analyzes/tests, and the Firestore rules pass against the emulator.
#
# Prereqs: Flutter, Node 20, Java 21, and the Firebase CLI on PATH.
# Usage:   scripts/preflight.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "▶ Cloud Functions: install + typecheck (tsc)"
( cd functions && npm install --silent && npm run build )

echo "▶ Flutter: pub get + analyze + test"
( cd app && flutter pub get && flutter analyze && flutter test )

echo "▶ Firestore rules: emulator tests (needs Java 21)"
( cd test && npm install --silent )
firebase emulators:exec --only firestore --project demo-myspot \
  "npm --prefix test test"

echo
echo "✅ Preflight passed — the repo is green and safe to deploy."
