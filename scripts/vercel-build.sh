#!/usr/bin/env bash
# Vercel Build-Skript für Flutter Web
set -euo pipefail

echo "==> Flutter installieren..."
export FLUTTER_HOME="/tmp/flutter"
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi
export PATH="$FLUTTER_HOME/bin:$PATH"

flutter --version
flutter config --enable-web
flutter precache --web

if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
  echo "FEHLER: SUPABASE_URL und SUPABASE_ANON_KEY müssen in Vercel → Settings → Environment Variables gesetzt sein."
  exit 1
fi

echo "==> dart-define aus Vercel-Umgebungsvariablen erzeugen..."
cat > dart_define.vercel.json <<EOF
{
  "SUPABASE_URL": "${SUPABASE_URL}",
  "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY}",
  "USE_MOCK_LOCATION": "${USE_MOCK_LOCATION:-true}"
}
EOF

echo "==> Flutter Web Build..."
flutter pub get
flutter build web \
  --release \
  --dart-define-from-file=dart_define.vercel.json

echo "==> Build fertig: build/web"
