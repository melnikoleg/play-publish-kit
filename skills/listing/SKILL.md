---
name: listing
description: >
  Draft and validate the Google Play store listing for a Flutter app with
  play-publish-kit. Use when the user wants store listing text, a Play Store
  description, app title, short description, or wants to update the listing
  metadata. Writes fastlane metadata files and validates Play's length limits.
---

# Draft the Play store listing

## Locate the kit and metadata dir (do this first)

1. `PROJECT_DIR` = the Flutter project root (the dir with `pubspec.yaml`).
2. **Copy-in mode** (wins when both exist): if the project contains a kit
   folder (one-level subdir with `scripts/publish.sh` + `fastlane/Fastfile`),
   the metadata dir is `<kit>/fastlane/metadata/android`.
3. **Plugin mode** otherwise: the metadata dir is
   `$PROJECT_DIR/fastlane/metadata/android`, seeded from
   `${CLAUDE_PLUGIN_ROOT}/templates/metadata/android/` if missing. Never
   write into `${CLAUDE_PLUGIN_ROOT}`.

## Write the listing

Draft from the app's README, features, and code — not from imagination:

- `<metadata>/en-US/title.txt` — max **30** characters
- `<metadata>/en-US/short_description.txt` — max **80** characters
- `<metadata>/en-US/full_description.txt` — max **4000** characters

Keep any privacy claims consistent with what the app actually does (check
its network/storage/analytics code). Don't promise features that don't exist;
don't use ALL-CAPS hype or keyword stuffing (Play policy).

## Validate lengths (always, after writing)

```bash
for f in title:30 short_description:80 full_description:4000; do
  name="${f%%:*}"; limit="${f##*:}"
  n=$(wc -m < "<metadata>/en-US/${name}.txt")
  echo "${name}: ${n}/${limit} $([ "$n" -le "$limit" ] && echo OK || echo TOO_LONG)"
done
```

Fix anything over the limit before finishing. Note: the changelog files under
`en-US/changelogs/<versionCode>.txt` have a **500**-character limit each.

To upload the listing without rebuilding:
`"$KIT_DIR/scripts/publish.sh" internal --upload-metadata --no-build`
(with `ENV_PLAY_PATH`/`METADATA_DIR` set in plugin mode) — but only when the
user asks to push it; drafting alone must not upload anything.
