#!/usr/bin/env bash
# Build a signed Flutter AAB and upload it to a Google Play track.
# App-agnostic: all config comes from `.env.play` (next to this kit). No code edits.
#
# Usage:
#   scripts/publish.sh [track] [flags]
#   scripts/publish.sh promote [--from=internal] [--to=production] [--rollout=0.1] [--dry-run]
#   scripts/publish.sh rollout (--set=0.5 | --halt | --complete) [--version-code=N] [--dry-run]
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
#   promote           Move the release already on one track to another (no rebuild —
#                     ships the exact binary you tested). Preferred over
#                     `publish.sh production` for promotion.
#   rollout           Change a staged rollout in place: raise the fraction (--set),
#                     halt it, or complete it to 100%.
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
MODE="publish"
case "${1:-}" in promote|rollout) MODE="$1"; shift ;; esac

TRACK="internal"
BUMP=0; NO_BUILD=0; DRY_RUN=0; UPLOAD_META=0; UPLOAD_IMAGES=0; ROLLOUT=""
FROM="internal"; TO="production"; SET=""; HALT=0; COMPLETE=0; VERSION_CODE=""
for arg in "$@"; do
  case "$MODE:$arg" in
    publish:internal|publish:alpha|publish:beta|publish:production) TRACK="$arg" ;;
    publish:--bump) BUMP=1 ;;
    publish:--no-build) NO_BUILD=1 ;;
    publish:--upload-metadata) UPLOAD_META=1 ;;
    publish:--upload-images) UPLOAD_IMAGES=1 ;;
    publish:--rollout=*|promote:--rollout=*) ROLLOUT="${arg#*=}" ;;
    promote:--from=*) FROM="${arg#*=}" ;;
    promote:--to=*) TO="${arg#*=}" ;;
    rollout:--set=*) SET="${arg#*=}" ;;
    rollout:--halt) HALT=1 ;;
    rollout:--complete) COMPLETE=1 ;;
    rollout:--version-code=*) VERSION_CODE="${arg#*=}" ;;
    *:--dry-run) DRY_RUN=1 ;;
    *) echo "Unknown arg for $MODE: $arg" >&2; exit 1 ;;
  esac
done

# ── Config ────────────────────────────────────────────────────────────────────
# .env.play resolution: $ENV_PLAY_PATH (explicit) > $KIT_DIR/.env.play (copy-in
# kit, legacy) > $PWD/.env.play (kit installed elsewhere, e.g. as a plugin).
ENV_PLAY="${ENV_PLAY_PATH:-}"
if [[ -z "$ENV_PLAY" ]]; then
  for c in "$KIT_DIR/.env.play" "$PWD/.env.play"; do
    [[ -f "$c" ]] && { ENV_PLAY="$c"; break; }
  done
fi
[[ -n "$ENV_PLAY" && -f "$ENV_PLAY" ]] || { echo "No .env.play found (checked \$ENV_PLAY_PATH, $KIT_DIR/.env.play, $PWD/.env.play) — copy .env.play.example and fill it in." >&2; exit 1; }
set -a; source "$ENV_PLAY"; set +a

PROJECT_DIR="${PROJECT_DIR:-$PWD}"
FLAVOR="${FLAVOR:-}"

# ── Preflight ─────────────────────────────────────────────────────────────────
fail() { echo "preflight: $1" >&2; exit 1; }
command -v bundle >/dev/null || fail "bundler not found (gem install bundler)"
for v in APP_PACKAGE PLAY_SERVICE_ACCOUNT_JSON; do
  [[ -n "${!v:-}" ]] || fail "$v unset in .env.play"
done
[[ -f "$PLAY_SERVICE_ACCOUNT_JSON" ]] || fail "service account json not found: $PLAY_SERVICE_ACCOUNT_JSON"
# Rollout fraction must be 0<f<=1 whenever set (e.g. 0.1, .5, 1). Rejects 0 / 0.0.
for f in "$ROLLOUT" "$SET"; do
  [[ -z "$f" ]] || [[ "$f" =~ ^(0?\.[0-9]*[1-9][0-9]*|1|1\.0+)$ ]] || fail "invalid rollout fraction: $f (use 0<f<=1, e.g. 0.1)"
done
export APP_PACKAGE PLAY_SERVICE_ACCOUNT_JSON

# ── promote / rollout: API-only, no build ─────────────────────────────────────
if [[ "$MODE" == "promote" ]]; then
  fl_args=("from:$FROM" "to:$TO")
  [[ -n "$ROLLOUT" ]] && fl_args+=("rollout:$ROLLOUT")
  [[ "$DRY_RUN" == 1 ]] && fl_args+=("dry_run:true")
  echo "==> (cd $KIT_DIR) fastlane promote ${fl_args[*]}"
  ( cd "$KIT_DIR" && bundle exec fastlane promote "${fl_args[@]}" )
  [[ "$DRY_RUN" == 1 ]] && echo "Done (dry-run, nothing committed)." || echo "Done. Promoted $FROM -> $TO."
  exit 0
fi
if [[ "$MODE" == "rollout" ]]; then
  n=$(( HALT + COMPLETE )); [[ -n "$SET" ]] && n=$(( n + 1 ))
  [[ "$n" == 1 ]] || fail "rollout needs exactly one of --set=, --halt, --complete"
  fl_args=()
  [[ -n "$SET" ]] && fl_args+=("set:$SET")
  [[ "$HALT" == 1 ]] && fl_args+=("halt:true")
  [[ "$COMPLETE" == 1 ]] && fl_args+=("complete:true")
  [[ -n "$VERSION_CODE" ]] && fl_args+=("version_code:$VERSION_CODE")
  [[ "$DRY_RUN" == 1 ]] && fl_args+=("dry_run:true")
  echo "==> (cd $KIT_DIR) fastlane rollout ${fl_args[*]}"
  ( cd "$KIT_DIR" && bundle exec fastlane rollout "${fl_args[@]}" )
  echo "Done."
  exit 0
fi

# ── Preflight (build + upload path only) ──────────────────────────────────────
command -v flutter >/dev/null || fail "flutter not on PATH"
[[ -f "$PROJECT_DIR/pubspec.yaml" ]] || fail "no pubspec.yaml in PROJECT_DIR=$PROJECT_DIR"
for v in KEYSTORE_PATH KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD; do
  [[ -n "${!v:-}" ]] || fail "$v unset in .env.play"
done
[[ -f "$KEYSTORE_PATH" ]] || fail "keystore not found: $KEYSTORE_PATH (run scripts/gen_upload_keystore.sh)"

export KEYSTORE_PATH KEYSTORE_PASSWORD KEY_ALIAS KEY_PASSWORD

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
# R8 mapping for deobfuscated crash/ANR reports (exists when minify is enabled).
if [[ -n "$FLAVOR" ]]; then
  MAPPING="$PROJECT_DIR/build/app/outputs/mapping/${FLAVOR}Release/mapping.txt"
else
  MAPPING="$PROJECT_DIR/build/app/outputs/mapping/release/mapping.txt"
fi

fl_args=("track:$TRACK" "aab:$AAB")
[[ -f "$MAPPING" ]] && fl_args+=("mapping:$MAPPING")
[[ -n "$ROLLOUT" ]] && fl_args+=("rollout:$ROLLOUT")
[[ "$DRY_RUN" == 1 ]] && fl_args+=("dry_run:true")
if [[ "$UPLOAD_META" == 1 ]]; then fl_args+=("skip_metadata:false"); else fl_args+=("skip_metadata:true"); fi
if [[ "$UPLOAD_IMAGES" == 1 ]]; then fl_args+=("skip_images:false"); else fl_args+=("skip_images:true"); fi
[[ -n "${METADATA_DIR:-}" ]] && fl_args+=("metadata_path:$METADATA_DIR")

echo "==> (cd $KIT_DIR) fastlane deploy ${fl_args[*]}"
( cd "$KIT_DIR" && bundle exec fastlane deploy "${fl_args[@]}" )

[[ "$DRY_RUN" == 1 ]] && echo "Done (dry-run, nothing committed). Track: $TRACK" || echo "Done. Uploaded to: $TRACK"
