#!/usr/bin/env bash
# One-time: create a GCP project + service account for the Play Developer API,
# enable the API, and download a JSON key. Replaces the manual GCP-console
# clicking. The ONLY remaining manual step is linking the SA in Play Console
# (Google has no API for that) — this script prints the email to paste there.
#
# Usage: scripts/setup_gcp_service_account.sh [PROJECT_ID]
#   PROJECT_ID defaults to a slug derived from APP_NAME in .env.play.
#   Requires: gcloud (authenticated: `gcloud auth login`).
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
[[ -f "$KIT_DIR/.env.play" ]] && { set -a; source "$KIT_DIR/.env.play"; set +a; }

command -v gcloud >/dev/null || { echo "gcloud not found (install Google Cloud SDK)" >&2; exit 1; }

SLUG="$(echo "${APP_NAME:-play-app}" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
PROJECT_ID="${1:-$SLUG}"
SA_NAME="play-publisher"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
KEY_OUT="${PLAY_SERVICE_ACCOUNT_JSON:-$HOME/.config/play/service-account.json}"
mkdir -p "$(dirname "$KEY_OUT")"

[[ -f "$KEY_OUT" ]] && { echo "Refusing to overwrite existing key: $KEY_OUT" >&2; exit 1; }

echo "==> Creating project '$PROJECT_ID' (skips if it exists)"
gcloud projects create "$PROJECT_ID" --name="$PROJECT_ID" 2>/dev/null \
  || echo "   (project already exists or name taken — continuing)"

echo "==> Enabling Android Publisher API"
gcloud services enable androidpublisher.googleapis.com --project="$PROJECT_ID"

echo "==> Creating service account '$SA_NAME'"
gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT_ID" --display-name="$SA_NAME" 2>/dev/null \
  || echo "   (service account already exists — continuing)"

echo "==> Creating JSON key -> $KEY_OUT"
gcloud iam service-accounts keys create "$KEY_OUT" \
  --iam-account="$SA_EMAIL" --project="$PROJECT_ID"
chmod 600 "$KEY_OUT"

cat <<EOF

Done. JSON key saved to: $KEY_OUT
Set in .env.play: PLAY_SERVICE_ACCOUNT_JSON="$KEY_OUT"

MANUAL STEP (no API exists): Play Console -> Users and permissions ->
Invite new users -> $SA_EMAIL -> grant "Release apps to testing tracks"
(+ "Release to production" if needed) for this app -> Send invite.
EOF
