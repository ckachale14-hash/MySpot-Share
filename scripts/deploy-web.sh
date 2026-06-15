#!/usr/bin/env bash
#
# Build and deploy the Flutter web app to Firebase Hosting.
# Deploy the backend first (scripts/deploy.sh) so the app has live services.
#
# Usage: scripts/deploy-web.sh [dev|staging|prod]   (default: dev)
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
ALIAS="${1:-dev}"

echo "▶ Building Flutter web (release)"
( cd app && flutter build web --release )

echo "▶ Deploying web to Firebase Hosting (project '$ALIAS')"
firebase deploy --only hosting --project "$ALIAS"

echo
echo "✅ Web is live — see the Hosting URL above (https://<project>.web.app)."
