#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get

if [ -n "${VERCEL:-}" ] && [ -z "${API_BASE_URL:-}" ]; then
  echo "ERROR: API_BASE_URL is required for Vercel builds."
  echo "Set it in Project Settings -> Environment Variables."
  exit 1
fi

if [ -n "${API_BASE_URL:-}" ]; then
  flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL}"
else
  flutter build web --release
fi
