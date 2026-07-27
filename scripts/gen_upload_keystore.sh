#!/usr/bin/env bash
# One-time: create a Play *upload* keystore for any app.
# Play App Signing holds the real app-signing key; this is the upload key you
# sign AABs with. Store it outside the repo and back it up — losing it means
# asking Google to reset your upload key.
#
# Usage: scripts/gen_upload_keystore.sh [output.jks]
#   App name for the cert is read from .env.play (APP_NAME) if present.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# .env.play resolution: $ENV_PLAY_PATH (explicit) > $KIT_DIR/.env.play (copy-in
# kit, legacy) > $PWD/.env.play (kit installed elsewhere, e.g. as a plugin).
ENV_PLAY="${ENV_PLAY_PATH:-}"
if [[ -z "$ENV_PLAY" ]]; then
  for c in "$KIT_DIR/.env.play" "$PWD/.env.play"; do
    [[ -f "$c" ]] && { ENV_PLAY="$c"; break; }
  done
fi
[[ -n "$ENV_PLAY" && -f "$ENV_PLAY" ]] && { set -a; source "$ENV_PLAY"; set +a; }

OUT="${1:-${KEYSTORE_PATH:-$HOME/.config/play/upload.jks}}"
ALIAS="${KEY_ALIAS:-upload}"
APP_NAME="${APP_NAME:-App}"
mkdir -p "$(dirname "$OUT")"

[[ -f "$OUT" ]] && { echo "Refusing to overwrite existing keystore: $OUT" >&2; exit 1; }
command -v keytool >/dev/null || { echo "keytool not found (install a JDK)" >&2; exit 1; }

read -rsp "Keystore password (also used for the key): " PW; echo
[[ ${#PW} -ge 6 ]] || { echo "password must be >= 6 chars" >&2; exit 1; }

keytool -genkeypair -v \
  -keystore "$OUT" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PW" -keypass "$PW" \
  -dname "CN=$APP_NAME, OU=Mobile, O=$APP_NAME, L=, ST=, C="

echo
echo "Created $OUT (alias: $ALIAS)"
echo "Set in .env.play: KEYSTORE_PATH=\"$OUT\"  KEY_ALIAS=\"$ALIAS\"  and the password above."
