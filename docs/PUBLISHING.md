# Publishing a Flutter app to Google Play

Generic playbook for this kit. Works for any Flutter app — all app-specific
values live in `.env.play`, not in code or scripts.

**Goal: after one-time setup, every release is one command** —
`scripts/publish.sh internal --bump`.

---

## What is automated vs. manual

| Step | Automated | Where |
|------|-----------|-------|
| Build signed release AAB | ✅ | `scripts/publish.sh` |
| Version bump (`+build`) | ✅ `--bump` | project `pubspec.yaml` |
| Upload to a track | ✅ | fastlane `deploy` lane |
| Staged rollout % | ✅ `--rollout=` | fastlane `supply` |
| Store listing text + changelog | ✅ `--upload-metadata` | `fastlane/metadata/android/` |
| GCP project + service account + JSON key | ✅ one-time | `scripts/setup_gcp_service_account.sh` (gcloud) |
| **Create the app entry** in Play Console | ❌ one-time | Play Console UI (no API) |
| **First-ever AAB upload** + App Signing enroll | ❌ one-time | Play Console UI (API can't bootstrap) |
| **Link service account / grant Play perms** | ❌ one-time | Play Console UI (no API) |
| Content rating questionnaire | ❌ one-time | Play Console UI |
| Data Safety form | ❌ one-time | Play Console UI ([DATA_SAFETY.md](DATA_SAFETY.md)) |
| Pricing, countries, target audience | ❌ one-time | Play Console UI |

**Rule of thumb:** everything on the **Google Cloud** side is CLI-scriptable
(gcloud). Everything on the **Play Console** side (create app, first upload,
service-account grant, content forms) is browser-only — Google ships no API for it.

---

## One-time setup (per app)

1. **Copy the kit** into the app (or keep it beside it). Set `PROJECT_DIR` in
   `.env.play` if the kit is not run from the Flutter project root.
2. **Config**: `cp .env.play.example .env.play` and fill in package, flavor,
   keystore, service-account path, and any `DART_DEFINES`.
3. **Upload key**: `scripts/gen_upload_keystore.sh` → keep the `.jks` out of the
   repo, back it up. ([ANDROID_SIGNING.md](ANDROID_SIGNING.md))
4. **Wire signing** into `android/app/build.gradle.kts` using
   [../templates/build.gradle.kts.signing-snippet](../templates/build.gradle.kts.signing-snippet).
   The build must read keystore values from env vars (the script sets them).
5. **Play Console**: pay the $25 dev fee, **Create app**, then build once and
   **upload the first AAB by hand** in *Testing → Internal testing*. Enroll in
   **Play App Signing** when prompted. (The Developer API cannot create the app
   or its first release.)
6. **Service account** (CLI): `scripts/setup_gcp_service_account.sh` creates the
   GCP project, enables the Android Publisher API, makes the service account, and
   downloads the JSON key to `PLAY_SERVICE_ACCOUNT_JSON`. Then do the one manual
   bit it prints: Play Console → *Users and permissions* → *Invite new users* →
   paste the SA email → grant *Release apps to testing tracks* (+ *Release to
   production* if needed) → *Send invite*. (Google has no API for the grant.)
7. **App content** (Policy → App content): privacy policy URL, Data Safety,
   content rating, target audience, ads declaration. See
   [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md).
8. **Tooling**: `bundle install` (in the kit dir) to install fastlane.

After step 6, the API path works and everything below is one command.

---

## Routine release

```bash
# Internal track, auto-bump build number
scripts/publish.sh internal --bump

# Push updated store listing + changelog (no rebuild)
scripts/publish.sh internal --upload-metadata --no-build

# Promote to production at 10% staged rollout
scripts/publish.sh production --rollout=0.1
```

- **Store listing**: edit files under `fastlane/metadata/android/en-US/` (start
  from [../templates/metadata](../templates/metadata)). Changelog filename = the
  `+build` number.
- **Dry run**: add `--dry-run` to validate the upload without committing.

## Track promotion order

internal → closed (alpha) → open (beta) → production. Use staged rollout for
production; halt/roll back in the Console on regressions.
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) has the full sequence.

## Troubleshooting

- **"Package not found" / 404** → app or first AAB doesn't exist yet for
  `APP_PACKAGE`; do the one-time manual upload.
- **"signed with a different certificate"** → wrong upload keystore; the AAB must
  be signed with the upload key enrolled in Play App Signing.
- **Service account 403** → permissions not granted, or propagation delay.
- **AAB missing after build** → flavor mismatch; check `FLAVOR` in `.env.play` or
  set `AAB_PATH` explicitly.
- **Gradle ignores the keystore** → build.gradle not reading env vars; re-check
  the signing snippet.

## Reusing for the next app

Copy the kit folder, replace `.env.play`, regenerate (or reuse) the upload key,
swap the `fastlane/metadata` text, redo the one-time Console steps. Scripts and
fastlane stay untouched.
