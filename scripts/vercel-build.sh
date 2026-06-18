#!/usr/bin/env bash
#
# Vercel build for the MySpot Flutter web app.
#
# Vercel has no native Flutter runtime, so we fetch the SDK on the build machine,
# then build the web bundle. Firebase web config + the App Check reCAPTCHA key are
# injected at compile time via --dart-define, sourced from the Vercel project's
# Environment Variables (so no real keys live in git). Missing values fall back to
# the REPLACE_* placeholders in lib/firebase_options.dart.
#
# Vercel config (vercel.json) points `outputDirectory` at app/build/web.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"

if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
  echo "▶ Cloning Flutter SDK ($FLUTTER_VERSION)…"
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

# Flutter refuses to run as root-owned without this in some CI images.
git config --global --add safe.directory "$FLUTTER_HOME" || true

echo "▶ flutter --version"
flutter --version
flutter config --enable-web

cd "$(dirname "$0")/../app"

echo "▶ flutter pub get"
flutter pub get

# Build only the --dart-define flags whose env var is set, so unset values keep
# the in-code defaults instead of being overridden with an empty string.
DEFINES=()
add_define() {
  local key="$1"
  local val="${2:-}"
  if [ -n "$val" ]; then
    DEFINES+=("--dart-define=$key=$val")
  fi
}
add_define FIREBASE_WEB_API_KEY       "${FIREBASE_WEB_API_KEY:-}"
add_define FIREBASE_WEB_APP_ID        "${FIREBASE_WEB_APP_ID:-}"
add_define FIREBASE_MESSAGING_SENDER_ID "${FIREBASE_MESSAGING_SENDER_ID:-}"
add_define FIREBASE_PROJECT_ID        "${FIREBASE_PROJECT_ID:-}"
add_define FIREBASE_AUTH_DOMAIN       "${FIREBASE_AUTH_DOMAIN:-}"
add_define FIREBASE_STORAGE_BUCKET    "${FIREBASE_STORAGE_BUCKET:-}"
add_define RECAPTCHA_V3_SITE_KEY      "${RECAPTCHA_V3_SITE_KEY:-}"

echo "▶ Building web (release) with ${#DEFINES[@]} dart-define(s)"
flutter build web --release ${DEFINES[@]+"${DEFINES[@]}"}

echo "✅ Web build complete → app/build/web"
