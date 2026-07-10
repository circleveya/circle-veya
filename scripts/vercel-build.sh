#!/usr/bin/env bash
# Vercel Build-Skript für Flutter Web
# Vercel läuft oft als root – Flutter darf das nicht. Build daher als User "vercel".
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_USER="${BUILD_USER:-vercel}"
FLUTTER_HOME="${FLUTTER_HOME:-/tmp/flutter-sdk}"
PUB_CACHE="${PUB_CACHE:-/tmp/pub-cache}"
DART_DEFINE_FILE="${PROJECT_DIR}/dart_define.json"
WORK_DIR=""

log() {
  echo "==> $*"
}

ensure_build_user() {
  if [ "$(id -u)" -ne 0 ]; then
    return 0
  fi

  if id "$BUILD_USER" &>/dev/null; then
    return 0
  fi

  log "Build-User '$BUILD_USER' anlegen (Flutter darf nicht als root laufen)..."
  if command -v useradd &>/dev/null; then
    useradd -m -s /bin/bash "$BUILD_USER"
  elif command -v adduser &>/dev/null; then
    adduser --disabled-password --gecos "Vercel Flutter Build" "$BUILD_USER"
  else
    log "WARNUNG: Kein useradd/adduser – versuche Build als root"
  fi
}

install_flutter_sdk() {
  log "Flutter SDK installieren nach $FLUTTER_HOME ..."
  mkdir -p "$(dirname "$FLUTTER_HOME")" "$PUB_CACHE"

  if [ ! -x "$FLUTTER_HOME/bin/flutter" ]; then
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
  fi

  git config --global --add safe.directory "$FLUTTER_HOME" || true
  git config --global --add safe.directory "$PROJECT_DIR" || true
}

write_dart_define() {
  if [ -z "${SUPABASE_URL:-}" ] || [ -z "${SUPABASE_ANON_KEY:-}" ]; then
    echo "FEHLER: SUPABASE_URL und SUPABASE_ANON_KEY müssen in Vercel → Settings → Environment Variables gesetzt sein."
    exit 1
  fi

  SUPABASE_URL="$(printf '%s' "${SUPABASE_URL}" | tr -d '[:space:]')"
  SUPABASE_ANON_KEY="$(printf '%s' "${SUPABASE_ANON_KEY}" | tr -d '[:space:]')"

  if [[ "$SUPABASE_URL" == *"supabase.com/dashboard"* ]]; then
    echo "FEHLER: SUPABASE_URL ist die Dashboard-URL – bitte API-URL verwenden:"
    echo "       https://unvmyeqvhnmhlkxtkjgo.supabase.co"
    exit 1
  fi

  if [[ "$SUPABASE_URL" != *".supabase.co"* ]]; then
    echo "FEHLER: SUPABASE_URL muss auf .supabase.co enden."
    exit 1
  fi

  log "dart_define.json aus Vercel-Umgebungsvariablen erzeugen..."
  cat > "$DART_DEFINE_FILE" <<EOF
{
  "SUPABASE_URL": "${SUPABASE_URL}",
  "SUPABASE_ANON_KEY": "${SUPABASE_ANON_KEY}",
  "USE_MOCK_LOCATION": "${USE_MOCK_LOCATION:-true}"
}
EOF
}

# Vercel-Mount /vercel/path0 lässt oft kein chown zu → in Home-Verzeichnis kopieren
prepare_workdir() {
  if [ "$(id -u)" -ne 0 ] || ! id "$BUILD_USER" &>/dev/null; then
    WORK_DIR="$PROJECT_DIR"
    return 0
  fi

  local build_user_home
  build_user_home="$(getent passwd "$BUILD_USER" | cut -d: -f6)"
  if [ -z "$build_user_home" ]; then
    build_user_home="/home/$BUILD_USER"
  fi

  WORK_DIR="$build_user_home/circle-build"
  log "Projekt nach $WORK_DIR kopieren (Vercel-Mount ist für Build-User oft nicht beschreibbar)..."
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"
  # Inhalt kopieren, nicht den Mount-Punkt selbst chownen
  cp -a "$PROJECT_DIR"/. "$WORK_DIR"/
  chown -R "$BUILD_USER:$BUILD_USER" "$FLUTTER_HOME" "$PUB_CACHE" "$WORK_DIR"
}

run_flutter() {
  local flutter_path="$FLUTTER_HOME/bin/flutter"
  local target_dir="${WORK_DIR:-$PROJECT_DIR}"
  local build_user_home

  if [ "$(id -u)" -eq 0 ] && id "$BUILD_USER" &>/dev/null; then
    build_user_home="$(getent passwd "$BUILD_USER" | cut -d: -f6)"
    if [ -z "$build_user_home" ]; then
      build_user_home="/home/$BUILD_USER"
    fi

    local cmd="cd '$target_dir' && '$flutter_path' $*"

    if command -v runuser &>/dev/null; then
      runuser -u "$BUILD_USER" -- env \
        HOME="$build_user_home" \
        PATH="$FLUTTER_HOME/bin:$PATH" \
        PUB_CACHE="$PUB_CACHE" \
        FLUTTER_HOME="$FLUTTER_HOME" \
        CI=true \
        FLUTTER_SUPPRESS_ANALYTICS=true \
        bash -lc "$cmd"
      return
    fi

    su -s /bin/bash "$BUILD_USER" -c "
      export HOME='$build_user_home'
      export PATH='$FLUTTER_HOME/bin:\$PATH'
      export PUB_CACHE='$PUB_CACHE'
      export FLUTTER_HOME='$FLUTTER_HOME'
      export CI=true
      export FLUTTER_SUPPRESS_ANALYTICS=true
      $cmd
    "
    return
  fi

  export PATH="$FLUTTER_HOME/bin:$PATH"
  export PUB_CACHE
  export FLUTTER_HOME
  export CI=true
  export FLUTTER_SUPPRESS_ANALYTICS=true
  cd "$target_dir"
  "$flutter_path" "$@"
}

copy_build_output() {
  local target_dir="${WORK_DIR:-$PROJECT_DIR}"
  if [ "$target_dir" = "$PROJECT_DIR" ]; then
    return 0
  fi

  if [ ! -d "$target_dir/build/web" ]; then
    echo "FEHLER: build/web wurde nicht erzeugt in $target_dir"
    exit 1
  fi

  log "Build-Output zurück nach $PROJECT_DIR/build/web kopieren..."
  rm -rf "$PROJECT_DIR/build/web"
  mkdir -p "$PROJECT_DIR/build"
  cp -a "$target_dir/build/web" "$PROJECT_DIR/build/web"
}

main() {
  log "Projekt: $PROJECT_DIR"
  log "UID: $(id -u) ($(id -un))"

  ensure_build_user
  install_flutter_sdk
  write_dart_define
  prepare_workdir

  log "Flutter Web Build..."
  run_flutter --version
  run_flutter config --enable-web --no-analytics
  run_flutter precache --web
  run_flutter pub get
  run_flutter build web --release --dart-define-from-file=dart_define.json

  copy_build_output

  if [ ! -d "$PROJECT_DIR/build/web" ]; then
    echo "FEHLER: build/web wurde nicht erzeugt."
    exit 1
  fi

  log "Build fertig: build/web"
  exit 0
}

main "$@"
