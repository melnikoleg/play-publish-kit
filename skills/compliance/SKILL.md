---
name: compliance
description: >
  Google Play compliance checks for a Flutter app with play-publish-kit. Use
  for filling the Play Console Data Safety form answers (what data is
  collected/shared, encryption, deletion) from the app's actual code and
  privacy policy, or for checking the app's targetSdk against Google Play's
  current minimum requirement before a release.
---

# Play compliance: Data Safety and target SDK

## Locate the kit (do this first)

1. `PROJECT_DIR` = the Flutter project root (the dir with `pubspec.yaml`).
2. **Copy-in mode** (wins when both exist): a one-level subdir with
   `scripts/publish.sh` + `fastlane/Fastfile` is the kit; work in its
   `docs/DATA_SAFETY.md`.
3. **Plugin mode** otherwise: `KIT_DIR="${CLAUDE_PLUGIN_ROOT}"`. Copy
   `${CLAUDE_PLUGIN_ROOT}/docs/DATA_SAFETY.md` to
   `$PROJECT_DIR/docs/DATA_SAFETY.md` first and fill the PROJECT copy — never
   edit files inside the plugin directory.

## Data Safety answers

1. Read the app's actual behavior, not its marketing: network calls and SDKs
   (analytics, crash reporting, ads, auth), local storage, permissions in
   `AndroidManifest.xml`, third-party packages in `pubspec.yaml`.
2. Read the privacy policy (URL or file) if one exists.
3. Fill the table in the Data Safety doc: per data type — collected? shared?
   purpose; plus encryption-in-transit and a deletion mechanism.
4. FLAG every disagreement between code and policy explicitly (e.g. policy
   says "no data collected" but the app bundles an analytics SDK). Do not
   paper over conflicts — the user must resolve them before submitting the
   form in Play Console (the form itself is browser-only, no API).

## Target-SDK check

1. Read `targetSdk` from `android/app/build.gradle.kts` (or the Flutter
   default it inherits).
2. Compare against Google Play's CURRENT minimum target API level for app
   updates — look it up (it rises roughly yearly; hardcoded knowledge goes
   stale) at
   https://support.google.com/googleplay/android-developer/answer/11926878.
3. If below the requirement: report the gap and the minimal change needed.
   Do NOT upgrade speculatively or bump other dependencies "while at it".

## Guardrails

- Report findings; change build files only when the user asks.
- Never invent Data Safety answers a code read can't support — mark unknowns
  as "verify manually".
