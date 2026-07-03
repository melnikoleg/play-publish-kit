# Play Publish Kit

Generic, app-agnostic kit to ship **any** Flutter app to Google Play with one
command. Copy this folder into a Flutter project (or keep it standalone), fill in
`.env.play`, run `scripts/publish.sh`. No per-app code edits.

```
play-publish-kit/
├── README.md
├── .env.play.example        # copy → .env.play (gitignored), fill once per app
├── Gemfile                  # fastlane
├── .claude-plugin/          # plugin.json + marketplace.json (Claude Code plugin)
├── skills/                  # Claude Code skills: setup, release, listing, compliance
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
    ├── release.yml                 # optional GitHub Actions release workflow
    └── metadata/android/en-US/...  # store listing skeleton + changelogs/<versionCode>.txt
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

## Use as a Claude Code plugin

Instead of copying the folder, install the kit once as a
[Claude Code plugin](https://code.claude.com/docs/en/plugins):

```
/plugin marketplace add melnikoleg/play-publish-kit
/plugin install play-publish-kit@play-publish-kit
```

Then, from any Flutter project:

- `/play-publish-kit:setup` — bootstrap a new app or audit an existing setup
- `/play-publish-kit:release` — cut an internal build or promote to production (staged)
- `/play-publish-kit:listing` — draft + validate the store listing
- `/play-publish-kit:compliance` — Data Safety answers, target-SDK check

The skills also fire on plain language ("ship a new internal build"). Plugin
mode keeps all per-app state in **your** project and home dir, never in the
plugin: `.env.play` in the project root (gitignored), keystore + service
account under `~/.config/play/`, store metadata under `fastlane/metadata/` in
the project. The copy-the-folder workflow above still works unchanged, and a
project-local kit takes precedence over the installed plugin.

## Requirements

- Flutter on PATH, a JDK (for `keytool`), Ruby + Bundler (`gem install bundler`).
- A Google Play developer account; the app entry + first AAB upload are created
  manually once in Play Console (the API can't bootstrap a new app).
