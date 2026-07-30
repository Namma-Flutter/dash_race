#!/usr/bin/env bash
# Vercel build for the Flutter web display.
#
# Set these in Vercel → Project Settings → Environment Variables (they become
# shell vars during the build and are baked into the bundle via --dart-define):
#   NAKAMA_HOST  NAKAMA_PORT  NAKAMA_SSL  NAKAMA_SERVER_KEY  CONTROLLER_URL
#
# (Vercel has no native Flutter runtime, so we fetch the SDK during the build.)
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b "$FLUTTER_VERSION" --depth 1
fi
export PATH="$PATH:$(pwd)/flutter/bin"

flutter --version
flutter pub get

flutter build web --release \
  --dart-define=NAKAMA_HOST="${NAKAMA_HOST:-localhost}" \
  --dart-define=NAKAMA_PORT="${NAKAMA_PORT:-443}" \
  --dart-define=NAKAMA_SSL="${NAKAMA_SSL:-true}" \
  --dart-define=NAKAMA_SERVER_KEY="${NAKAMA_SERVER_KEY:-defaultkey}" \
  --dart-define=CONTROLLER_URL="${CONTROLLER_URL:-}"
