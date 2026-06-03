#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"
API_BASE_URL="${API_BASE_URL:?API_BASE_URL is required}"

if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$HOME/flutter"
fi

export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release --dart-define=API_BASE_URL="$API_BASE_URL"
