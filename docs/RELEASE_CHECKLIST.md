# Google Play release checklist

Generic checklist for any app shipped with this kit.

## Before the first upload (one-time, Play Console UI)

1. **Create app** — name, default language, app/game, free/paid.
2. **Privacy policy URL** — hosted on stable HTTPS; added under *Policy → App content*.
3. **Data Safety form** — [DATA_SAFETY.md](DATA_SAFETY.md); must match the app + policy.
4. **Content rating** — complete the questionnaire.
5. **Target audience & content** — declare age groups; comply with the rules they trigger.
6. **Ads** — declare whether the app shows ads (true if any ad SDK is present).
7. **Store listing** — title, short/full description, icon, feature graphic,
   phone screenshots (min 2). Text lives in `fastlane/metadata/android/en-US/`.
8. **App access** — if anything is behind a login, give Google test credentials.
9. **Signing** — enroll in Play App Signing; keep the upload key
   ([ANDROID_SIGNING.md](ANDROID_SIGNING.md)).
10. **First AAB** — build and upload by hand to *Internal testing* once.

## Per release (automated)

```bash
scripts/publish.sh internal --bump
```

- Build is signed and prod-configured via `DART_DEFINES`.
- Upload to *Internal testing* first; verify install + core flows on a device.

## Tracks (recommended order)

1. **Internal testing** — small allowlist; validates pipeline + signing.
2. **Closed testing (alpha)** — broader QA, onboarding feedback.
3. **Open testing (beta)** — scale + device diversity (optional).
4. **Production** — **staged rollout** (e.g. 5% → 20% → 100%).

## Pre-launch report

After uploading to a test track, open *Release → Testing → Pre-launch report*.
Resolve crashes, permission issues, and security warnings before promoting.

## Release notes

- User-facing *What's new* per locale: `metadata/android/<locale>/changelogs/<versionCode>.txt`.
- Keep an internal changelog (commits/PRs) mapped to store versions.

## Rollback

- Halt staged rollout at a lower % or roll back to the previous production
  release in the Console.
- Ship a fix with an incremented `versionCode` (`pubspec.yaml` `version: x.y.z+code`).

## Post-release

- Watch Play Console vitals (ANRs, crashes) and backend error rates.
- Revisit Data Safety and the privacy policy when adding features that touch new
  data types or third parties.
