# Play Publish Kit

Generic, app-agnostic kit to ship **any** Flutter app to Google Play with one
command. Copy this folder into a Flutter project (or keep it standalone), fill in
`.env.play`, run `scripts/publish.sh`. No per-app code edits.

```
play-publish-kit/
├── README.md
├── .env.play.example        # copy → .env.play (gitignored), fill once per app
├── Gemfile                  # fastlane
├── scripts/
│   ├── publish.sh           # build signed AAB → upload to a track
│   └── gen_upload_keystore.sh
├── fastlane/
│   ├── Appfile              # reads package + service account from env
│   └── Fastfile             # upload-only `deploy` lane (app-agnostic)
├── docs/
│   ├── PUBLISHING.md        # the playbook (start here)
│   ├── ANDROID_SIGNING.md
│   ├── DATA_SAFETY.md
│   ├── RELEASE_CHECKLIST.md
│   └── PROMPTS.md           # copy-paste Claude Code prompts
└── templates/
    ├── build.gradle.kts.signing-snippet
    └── metadata/android/en-US/...   # store listing skeleton
```

## Quickstart (per app)

```bash
cp .env.play.example .env.play        # then edit it
scripts/gen_upload_keystore.sh        # one-time, if no upload key yet
# wire signing into the app's android/app/build.gradle.kts
#   (see templates/build.gradle.kts.signing-snippet)
scripts/publish.sh internal --bump    # build + upload
```

Full walkthrough: [docs/PUBLISHING.md](docs/PUBLISHING.md).

## Requirements

- Flutter on PATH, a JDK (for `keytool`), Ruby + Bundler (`gem install bundler`).
- A Google Play developer account; the app entry + first AAB upload are created
  manually once in Play Console (the API can't bootstrap a new app).
