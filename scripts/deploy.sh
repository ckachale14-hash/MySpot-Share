#!/usr/bin/env bash
#
# Deploy the backend (rules, indexes, storage, database, functions) to a
# Firebase project alias defined in .firebaserc (dev | staging | prod).
#
# IMPORTANT: set the function secrets FIRST (see docs/GO-LIVE.md, Phase 3),
# or the functions deploy will fail because secrets are referenced at deploy time.
#
# Usage: scripts/deploy.sh [dev|staging|prod]   (default: dev)
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ALIAS="${1:-dev}"

echo "▶ Target Firebase project: alias '$ALIAS'"
firebase use "$ALIAS"

echo "▶ Building Cloud Functions"
( cd functions && npm ci && npm run build )

echo "▶ Deploying rules, indexes, storage, database, functions"
firebase deploy \
  --only firestore:rules,firestore:indexes,storage,database,functions \
  --project "$ALIAS"

echo
echo "✅ Backend deployed to '$ALIAS'."
echo "   Remaining manual steps (one-time): configure the TTL policy on"
echo "   stories.expiresAt, and turn on App Check enforcement. See docs/GO-LIVE.md."
