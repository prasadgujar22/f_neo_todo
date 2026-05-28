#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  git clone https://github.com/flutter/flutter.git --branch stable --depth 1 /tmp/flutter
  export PATH="$PATH:/tmp/flutter/bin"
fi

flutter config --enable-web
flutter pub get

SUPABASE_URL_VALUE="${SUPABASE_URL:-${VITE_SUPABASE_URL:-}}"
SUPABASE_ANON_KEY_VALUE="${SUPABASE_ANON_KEY:-${VITE_SUPABASE_ANON_KEY:-}}"

flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL_VALUE" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY_VALUE" \
  --dart-define=VITE_SUPABASE_URL="$SUPABASE_URL_VALUE" \
  --dart-define=VITE_SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY_VALUE"
