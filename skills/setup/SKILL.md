---
name: setup
description: >
  Set up or audit Google Play publishing for a Flutter app with
  play-publish-kit. Use for new-app bootstrap (create .env.play, generate an
  upload keystore, wire Gradle signing, create the GCP service account, list
  the manual Play Console steps) or to audit an existing setup and report
  pass/fail with exact fixes. Read-only unless the user asks to bootstrap;
  never uploads anything.
---

# Set up or audit Play publishing

## Locate the kit and config (do this first, every skill in this plugin)

1. `PROJECT_DIR` = the Flutter project root (the dir with `pubspec.yaml`).
2. **Copy-in mode** (wins when both exist): if the project contains a kit
   folder — a one-level subdir with `scripts/publish.sh` and
   `fastlane/Fastfile`, conventionally `play-publish-kit/` — then
   `KIT_DIR` = that dir and config is `$KIT_DIR/.env.play`.
3. **Plugin mode** otherwise: `KIT_DIR="${CLAUDE_PLUGIN_ROOT}"` and config is
   `$PROJECT_DIR/.env.play`. Per-app state must NEVER be written inside the
   plugin directory (it is shared across projects and replaced on update):
   - `.env.play` → `$PROJECT_DIR/.env.play`
   - keystore + service-account JSON → `~/.config/play/` (the example's defaults)
   - store metadata → `$PROJECT_DIR/fastlane/metadata/android/`
4. Invoke kit scripts explicitly with the resolved paths, e.g.
   `ENV_PLAY_PATH="$PROJECT_DIR/.env.play" "$KIT_DIR/scripts/publish.sh" ...`

## Mode: audit (default when .env.play exists)

Check each item and report a pass/fail table with the exact fix per failure.
Do NOT upload or change anything.

1. `.env.play` exists (at the mode's location) and every required var is
   non-empty: `APP_PACKAGE`, `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`,
   `KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`. Never print secret values —
   report only set/unset.
2. The keystore file at `KEYSTORE_PATH` exists.
3. The service-account JSON at `PLAY_SERVICE_ACCOUNT_JSON` exists.
4. `android/app/build.gradle.kts` reads the keystore from env vars
   (`KEYSTORE_PATH`/`KEYSTORE_PASSWORD`/`KEY_ALIAS`/`KEY_PASSWORD` — compare
   with `$KIT_DIR/templates/build.gradle.kts.signing-snippet`).
5. `(cd "$KIT_DIR" && bundle exec fastlane lanes)` lists `deploy`
   (run `bundle install` in `$KIT_DIR` first if fastlane is missing; after a
   plugin update, `bundle install` must be re-run).
6. `.env.play` is gitignored in the repo that contains it
   (`git check-ignore` it).

## Mode: bootstrap (new app, or user asks for setup)

Walk through the one-time setup from `$KIT_DIR/docs/PUBLISHING.md` (steps 1–8):

1. Create `.env.play` at the mode's location from
   `$KIT_DIR/.env.play.example` and fill it in with the user. BEFORE writing
   it, ensure the containing repo's `.gitignore` covers `.env.play`; add the
   entry if missing. Same for `*.jks` and service-account JSON if the user
   points them inside the repo (prefer `~/.config/play/`).
2. Upload keystore: `"$KIT_DIR/scripts/gen_upload_keystore.sh"` (interactive —
   the user types the password; never generate or echo passwords yourself).
3. Wire signing into `android/app/build.gradle.kts` using
   `$KIT_DIR/templates/build.gradle.kts.signing-snippet`.
4. GCP service account: `"$KIT_DIR/scripts/setup_gcp_service_account.sh"`
   (needs authenticated gcloud).
5. `bundle install` in `$KIT_DIR`.
6. Build the first AAB (`flutter build appbundle --release`) for the manual
   first upload.

Then list explicitly the browser-only Play Console steps no API can do:
pay the $25 dev fee and **Create app**; upload the **first AAB by hand**
(Testing → Internal testing) and enroll in Play App Signing; link the service
account (Users and permissions → invite the SA email → grant "Release apps to
testing tracks", plus production if needed); content rating questionnaire;
Data Safety form; pricing/countries/target audience.

## Guardrails

- Never upload, never touch Play tracks from this skill.
- Never print or store secret values; never write secrets into git-tracked
  files — verify with `git check-ignore` before creating `.env.play`.
- Never write anything into `${CLAUDE_PLUGIN_ROOT}` in plugin mode.
