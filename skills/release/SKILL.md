---
name: release
description: >
  Build and upload a Flutter app release to a Google Play track with
  play-publish-kit. Use when the user wants to ship, publish, or release a
  build, cut an internal/alpha/beta build, bump the build number, write a
  release changelog, or promote to production with a staged rollout. Requires
  a filled .env.play (otherwise point to the setup skill).
---

# Cut and publish a Play release

## Locate the kit and config (do this first)

1. `PROJECT_DIR` = the Flutter project root (the dir with `pubspec.yaml`).
2. **Copy-in mode** (wins when both exist): if the project contains a kit
   folder — a one-level subdir with `scripts/publish.sh` and
   `fastlane/Fastfile`, conventionally `play-publish-kit/` — then
   `KIT_DIR` = that dir, config is `$KIT_DIR/.env.play`, and metadata is
   `$KIT_DIR/fastlane/metadata/android`.
3. **Plugin mode** otherwise: `KIT_DIR="${CLAUDE_PLUGIN_ROOT}"`, config is
   `$PROJECT_DIR/.env.play`, metadata is
   `$PROJECT_DIR/fastlane/metadata/android` (seed from
   `${CLAUDE_PLUGIN_ROOT}/templates/metadata/` if missing). Always invoke the
   script with the paths made explicit:
   `ENV_PLAY_PATH="$PROJECT_DIR/.env.play" METADATA_DIR="$PROJECT_DIR/fastlane/metadata/android" "$KIT_DIR/scripts/publish.sh" ...`
4. If no `.env.play` exists anywhere, STOP and point the user at the `setup`
   skill (`/play-publish-kit:setup`). Never invent config values.
5. fastlane must be installed in `$KIT_DIR` (`bundle install`; re-run after a
   plugin update).

## Internal release (default)

1. Determine the new versionCode: the `+N` in the project `pubspec.yaml`
   `version:` line, plus one (the script's `--bump` does the increment).
2. Changelog: write one line for the NEW versionCode at
   `<metadata>/en-US/changelogs/<versionCode>.txt` summarizing the commits
   since the last release tag (`git describe --tags --abbrev=0`; if no tags,
   summarize recent commits).
3. Run: `"$KIT_DIR/scripts/publish.sh" internal --bump` (with `ENV_PLAY_PATH`/
   `METADATA_DIR` in plugin mode; add `--upload-metadata` if the changelog or
   listing should ship with it).
4. Report the new version and the upload result.

Other testing tracks work the same: `alpha` (closed), `beta` (open).

## Production promotion (staged)

Promote the build already tested on a testing track — do NOT rebuild for
production. Production is ALWAYS two steps:

1. Dry run first:
   `"$KIT_DIR/scripts/publish.sh" promote --from=<track> --to=production --rollout=<f> --dry-run`
   (`--from` defaults to `internal`; default `--rollout=0.1` unless the user
   specified one) and show the validation output.
2. Ask the user to confirm, and only after an explicit "yes" in this
   conversation run it without `--dry-run`.

Only build fresh for production (`publish.sh production --rollout=<f>`, same
two-step dry-run + confirm) when there is nothing on a testing track to
promote.

## Managing a staged rollout

- Raise: `"$KIT_DIR/scripts/publish.sh" rollout --set=<f>`
- Finish: `... rollout --complete`
- Halt on a regression: `... rollout --halt`

`--complete` and `--halt` also need explicit user confirmation. If supply
can't find the release, add `--version-code=<code>`.

## GUARDRAILS (non-negotiable)

- NEVER run the `production` track without the user's explicit confirmation
  in this conversation — even if the original request said "production", the
  dry-run output must be shown and confirmed first.
- Never bypass or edit the script's preflight checks to force an upload.
- Never write secrets into git-tracked files; `.env.play` must be gitignored.
- Never write anything into `${CLAUDE_PLUGIN_ROOT}` in plugin mode.
- If the upload fails, diagnose using the Troubleshooting section of
  `$KIT_DIR/docs/PUBLISHING.md` before retrying.
