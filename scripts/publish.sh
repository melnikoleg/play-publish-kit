#!/usr/bin/env bash
# Build a signed Flutter AAB and upload it to a Google Play track.
# App-agnostic: all config comes from `.env.play` (next to this kit). No code edits.
#
# Usage:
#   scripts/publish.sh [track] [flags]
#
#   track             internal (default) | alpha (closed) | beta (open) | production
#
#   --bump            Increment the +build number in the project's pubspec.yaml
#   --rollout=0.1     Staged rollout fraction (production only; 0<f<=1)
#   --no-build        Upload the existing AAB without rebuilding
#   --upload-metadata Push fastlane/metadata store listing + changelog too
#   --upload-images   Push icon/featureGraphic/screenshots too (see below)
#   --dry-run         Build, then validate the upload without committing it
#
# Graphics for --upload-images live under fastlane/metadata/android/en-US/images/:
#   icon.png (512x512), featureGraphic.png (1024x500), phoneScreenshots/1.png...
# This is the only non-manual path for graphics — Play Console's own upload
# widgets are native OS file pickers with no accessible DOM file input, so
# browser automation cannot drive them. Put the files in place and use this
# flag instead of the Console UI.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ── Args ──────────────────────────────────────────────────────────────────────
TRACK="internal"
BUMP=0; NO_BUILD=0; DRY_RUN=0; UPLOAD_META=0; UPLOAD_IMAGES=0; ROLLOUT=""
for arg in "$@"; do
  case "$arg" in
    internal|alpha|beta|production) TRACK="$arg" ;;
    --bump) BUMP=1 ;;
    --no-build) NO_BUILD=1 ;;
    --dry-run) DRY_RUN=1 ;;
    --upload-metadata) UPLOAD_META=1 ;;
    --upload-images) UPLOAD_IMAGES=1 ;;
    --rollout=*) ROLLOUT="${arg#*=}" ;;
    *) echo "Unknown arg: $arg" >&2; exit 1 ;;
  esac
done

# ── Config ────────────────────────────────────────────────────────────────────
[[ -f "$KIT_DIR/.env.play" ]] || { echo "Missing $KIT_DIR/.env.play — copy .env.play.example and fill it in." >&2; exit 1; }
set -a; source "$KIT_DIR/.env.play"; set +a

PROJECT_DIR="${PROJECT_DIR:-$PWD}"
FLAVOR="${FLAVOR:-}"

# ── Preflight ─────────────────────────────────────────────────────────────────
fail() { echo "preflight: $1" >&2; exit 1; }
command -v flutter >/dev/null || fail "flutter not on PATH"
command -v bundle  >/dev/null || fail "bundler not found (gem install bundler)"
[[ -f "$PROJECT_DIR/pubspec.yaml" ]] || fail "no pubspec.yaml in PROJECT_DIR=$PROJECT_DIR"
for v in APP_PACKAGE KEYSTORE_PATH KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD PLAY_SERVICE_ACCOUNT_JSON; do
  [[ -n "${!v:-}" ]] || fail "$v unset in .env.play"
done
[[ -f "$KEYSTORE_PATH" ]] || fail "keystore not found: $KEYSTORE_PATH (run scripts/gen_upload_keystore.sh)"
[[ -f "$PLAY_SERVICE_ACCOUNT_JSON" ]] || fail "service account json not found: $PLAY_SERVICE_ACCOUNT_JSON"
# Rollout fraction must be 0<f<=1 whenever set (e.g. 0.1, .5, 1). Rejects 0 / 0.0.
[[ -z "$ROLLOUT" ]] || [[ "$ROLLOUT" =~ ^(0?\.[0-9]*[1-9][0-9]*|1|1\.0+)$ ]] || fail "invalid --rollout=$ROLLOUT (use 0<f<=1, e.g. 0.1)"

export APP_PACKAGE KEYSTORE_PATH KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD PLAY_SERVICE_ACCOUNT_JSON

# ── Resolve AAB path ──────────────────────────────────────────────────────────
if [[ -n "${AAB_PATH:-}" ]]; then
  AAB="$AAB_PATH"
elif [[ -n "$FLAVOR" ]]; then
  AAB="$PROJECT_DIR/build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
else
  AAB="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
fi

# ── Version bump ──────────────────────────────────────────────────────────────
if [[ "$BUMP" == 1 ]]; then
  before="$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" || true)"
  perl -i -pe 's/^(version:\s*\d+\.\d+\.\d+\+)(\d+)/$1.($2+1)/e' "$PROJECT_DIR/pubspec.yaml"
  after="$(grep '^version:' "$PROJECT_DIR/pubspec.yaml" || true)"
  [[ "$before" != "$after" ]] || fail "--bump: no 'version: x.y.z+N' line to increment (found: ${before:-none}). Add a +build number to pubspec.yaml."
  echo "==> bumped: $after"
fi

# ── Build ─────────────────────────────────────────────────────────────────────
if [[ "$NO_BUILD" == 0 ]]; then
  build_args=(appbundle --release)
  [[ -n "$FLAVOR" ]] && build_args+=(--flavor "$FLAVOR")
  for kv in ${DART_DEFINES:-}; do build_args+=(--dart-define="$kv"); done
  echo "==> (cd $PROJECT_DIR) flutter pub get"
  ( cd "$PROJECT_DIR" && flutter pub get && \
    echo "==> flutter build ${build_args[*]}" && flutter build "${build_args[@]}" )
fi
[[ -f "$AAB" ]] || fail "AAB missing: $AAB"
echo "==> AAB: $AAB"

# ── Upload ────────────────────────────────────────────────────────────────────
fl_args=("track:$TRACK" "aab:$AAB")
[[ -n "$ROLLOUT" ]] && fl_args+=("rollout:$ROLLOUT")
[[ "$DRY_RUN" == 1 ]] && fl_args+=("dry_run:true")
if [[ "$UPLOAD_META" == 1 ]]; then fl_args+=("skip_metadata:false"); else fl_args+=("skip_metadata:true"); fi
if [[ "$UPLOAD_IMAGES" == 1 ]]; then fl_args+=("skip_images:false"); else fl_args+=("skip_images:true"); fi

echo "==> (cd $KIT_DIR) fastlane deploy ${fl_args[*]}"
( cd "$KIT_DIR" && bundle exec fastlane deploy "${fl_args[@]}" )

[[ "$DRY_RUN" == 1 ]] && echo "Done (dry-run, nothing committed). Track: $TRACK" || echo "Done. Uploaded to: $TRACK"
