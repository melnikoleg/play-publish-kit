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
| R8 mapping.txt (deobfuscated crashes) | ✅ auto | uploaded with the AAB when present |
| Promote a tested build between tracks | ✅ `promote` | fastlane `promote` lane (no rebuild) |
| Staged rollout % | ✅ `--rollout=` | fastlane `supply` |
| Raise / halt / complete a staged rollout | ✅ `rollout` | fastlane `rollout` lane |
| Store listing text + changelog | ✅ `--upload-metadata` | `fastlane/metadata/android/` |
| Icon, feature graphic, screenshots | ✅ `--upload-images` | `fastlane/metadata/android/en-US/images/` |
| GCP project + service account + JSON key | ✅ one-time | `scripts/setup_gcp_service_account.sh` (gcloud) |
| **Create the app entry** in Play Console | ❌ one-time | Play Console UI (no API) |
| **Link service account / grant Play perms** | ❌ one-time | Play Console UI (no API) |
| Developer account verification (ID / D-U-N-S) | ❌ one-time | Play Console UI |
| Content rating questionnaire | ❌ one-time | Play Console UI |
| Data Safety form | ❌ one-time | Play Console UI ([DATA_SAFETY.md](DATA_SAFETY.md)) |
| Pricing, countries, target audience | ❌ one-time | Play Console UI |
| 12-tester closed test + production-access application | ❌ one-time | Play Console UI (new personal accounts, see below) |

**Rule of thumb:** everything on the **Google Cloud** side is CLI-scriptable
(gcloud). Everything on the **Play Console** side (create app, service-account
grant, content/policy forms) is browser-only — Google ships no API for it.

**Graphics are API-scriptable, despite looking browser-only.** Play Console's
icon/screenshot upload widgets are native OS file pickers with no accessible
DOM `<input type=file>` — browser automation (Claude in Chrome, Playwright,
etc.) cannot drive them. But `upload_to_play_store` (fastlane/supply) uploads
the same assets straight from `fastlane/metadata/android/en-US/images/` via
the API. Put files there and use `--upload-images` instead of fighting the
Console UI.

**The very first release upload to `internal` also works via the API**, even
while the app is still "Draft" in Console — confirmed by publishing straight
after creating the app + granting the service account, no manual AAB upload
needed. What's still manual: creating the app entry itself, and completing
the store listing (screenshots etc.) before the API will accept uploads to
*other* tracks (`alpha`/`beta`/`production` all reject non-draft releases on
a draft app with "Only releases with status draft may be created on draft
app" until the listing is complete).

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
   Also confirm `versionCode`/`versionName` in `defaultConfig` read
   `flutter.versionCode`/`flutter.versionName` — some older Flutter Android
   templates hardcode a literal number instead. If hardcoded, `--bump` edits
   `pubspec.yaml` but Gradle ignores it, and every upload after the first
   fails with `Version code N has already been used`.
5. **Play Console**: pay the $25 dev fee (once per developer account),
   complete account **verification** (personal: government ID + address doc;
   organization: business registry papers + D-U-N-S number — can take days,
   start early), then **Create app**. Play App Signing auto-enrolls on new
   apps — no manual step needed. The first AAB upload does **not** need to be
   manual; once the service account (next step) is granted,
   `scripts/publish.sh internal` works immediately, including for the very
   first release.

   **Production gate for new personal accounts** (created after Nov 13, 2023):
   Google requires a **closed test with ≥12 testers opted in for 14
   consecutive days** before you can *apply* for production access ("opted
   in" = accepted the invite and installed; invited-but-not-installed doesn't
   count). Organization accounts are exempt. Plan the alpha track phase
   around this — production simply won't exist as a target until Google
   approves the application. Details:
   https://support.google.com/googleplay/android-developer/answer/14151465
6. **Service account** (CLI): if this app shares a developer account with an
   earlier one, give it its **own** service account — set
   `PLAY_SERVICE_ACCOUNT_JSON` in `.env.play` to a new path *before* running
   the script below (it refuses to overwrite an existing key file, and reusing
   another app's key means reusing its GCP project/permissions boundary too).
   `scripts/setup_gcp_service_account.sh <project-id>` creates the GCP project,
   enables the Android Publisher API, makes the service account, and downloads
   the JSON key. Then do the one manual bit it prints: Play Console → *Users
   and permissions* → *Invite new users* → paste the SA email → grant
   *Release apps to testing tracks* (+ *Release to production* if needed) →
   *Send invite*. (Google has no API for the grant.) Permission usually
   applies within seconds — no propagation wait needed in practice.
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

# Push icon/feature graphic/screenshots from fastlane/metadata/.../images/
scripts/publish.sh internal --upload-images --no-build

# Promote the build already tested on internal to production at 10% —
# no rebuild, ships the exact tested binary (preferred)
scripts/publish.sh promote --from=internal --to=production --rollout=0.1

# Then manage the staged rollout entirely from the CLI
scripts/publish.sh rollout --set=0.5      # raise to 50%
scripts/publish.sh rollout --complete     # go to 100%
scripts/publish.sh rollout --halt         # stop it on a regression

# Build fresh and upload straight to production (only when there's nothing
# on a testing track to promote)
scripts/publish.sh production --rollout=0.1
```

- **Store listing**: edit files under `fastlane/metadata/android/en-US/` (start
  from [../templates/metadata](../templates/metadata)). Changelog filename = the
  `+build` number.
- **Dry run**: add `--dry-run` to validate the upload without committing.

## Track promotion order

internal → closed (alpha) → open (beta) → production. Use
`scripts/publish.sh promote` to move the tested build up (don't rebuild for
production), staged rollout for the production step, and
`scripts/publish.sh rollout --halt` on regressions (rolling back to a
*previous* release still needs the Console).
[RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) has the full sequence.

## Troubleshooting

- **"Package not found" / 404** → app or first AAB doesn't exist yet for
  `APP_PACKAGE`; do the one-time manual upload.
- **"signed with a different certificate"** → wrong upload keystore; the AAB must
  be signed with the upload key enrolled in Play App Signing.
- **Service account 403 / "The caller does not have permission"** →
  permissions not granted, or propagation delay. Most common cause on a
  fresh project: the service account exists in GCP but was never actually
  invited in Play Console (see `setup_gcp_service_account.sh`'s manual step
  above) — check *Users and permissions* for its email before assuming
  propagation delay.
- **"Could not find folder ./fastlane/metadata/android"** → fastlane's
  `upload_to_play_store` validates `metadata_path` exists even when
  `skip_upload_metadata: true`. Fixed in the Fastfile by only passing
  `metadata_path` when metadata upload is actually requested; if you're on
  an older copy of this kit, apply the same fix or pass
  `metadata_path:nil` explicitly.
- **`--upload-images` commits with "The caller does not have permission"
  even though image uploads themselves succeed** → the individual
  `edits.images.upload` calls only need "Manage store presence", but
  **committing** an edit containing image changes needs **Admin (all
  permissions)** on that app — "Release apps to testing tracks" +
  "Manage store presence" together are not enough. This is undocumented by
  Google; confirmed by testing directly against the Play Developer API.
  Grant Admin on the one app if `--upload-images` fails at the commit step
  with everything else already granted.
- **"Image type invalid"** on `--upload-images` → usually the icon has an
  alpha channel; Play's app icon must be fully opaque. Flatten it:
  `magick icon.png -background white -alpha remove -alpha off icon.png`.
- **AAB missing after build** → flavor mismatch; check `FLAVOR` in `.env.play` or
  set `AAB_PATH` explicitly.
- **Gradle ignores the keystore** → build.gradle not reading env vars; re-check
  the signing snippet.
- **"Version code N has already been used"** → either `versionCode` is
  hardcoded in `build.gradle`/`build.gradle.kts` instead of reading
  `flutter.versionCode` (fix once, see step 4 above), or you uploaded to a
  second track without `--bump` — every track shares one versionCode
  sequence, so each new upload anywhere needs a higher number.
- **"Only releases with status draft may be created on draft app"** → the
  store listing isn't complete yet (graphics especially). `internal` accepts
  uploads on a draft app; other tracks don't. Finish the listing (or use
  `--upload-images`, see above) first.
- **Upload/promote to `production` fails but testing tracks work** → on a
  personal account created after Nov 13, 2023, production doesn't exist as a
  target until the 12-tester/14-day closed test is done and Google approves
  the production-access application (see one-time setup above).
- **`rollout --halt`/`--set` can't find the release** → some fastlane/supply
  versions need the release pinned explicitly; retry with
  `--version-code=<versionCode of the rolling release>`.
- **`bundle install` fails on a fresh machine with a Bundler version error**
  → an old `Gemfile.lock` pinned to a Bundler version incompatible with a
  newer Ruby. `rm Gemfile.lock && bundle install` to regenerate it.

## CI/CD

[../templates/release-manual.yml](../templates/release-manual.yml) — GitHub
Actions workflow that calls `scripts/publish.sh` directly (same behavior as
running it locally). Signing key and service account travel as base64
repo secrets. [../templates/release.yml](../templates/release.yml) is an
alternative using a third-party upload action and tag-push triggers instead.

## Reusing for the next app

Copy the kit folder, replace `.env.play`, regenerate (or reuse) the upload key,
swap the `fastlane/metadata` text, redo the one-time Console steps. Scripts and
fastlane stay untouched.
