# Publishing prompts (for Claude Code)

Generic copy-paste prompts to drive any app's Play release with this kit. Run
them from the Flutter project that has the kit configured (`.env.play` filled).

> **Installed the kit as a Claude Code plugin?** These prompts exist as
> skills — no copy-paste needed: `/play-publish-kit:setup` (prompts 1, 6),
> `/play-publish-kit:release` (2, 5), `/play-publish-kit:listing` (3),
> `/play-publish-kit:compliance` (4, 7). See the README for install steps.

---

## 1. Setup audit

> Audit this app for Google Play publishing with play-publish-kit. Check:
> `.env.play` exists and every var is set, the keystore at `KEYSTORE_PATH`
> exists, the service-account JSON exists, `android/app/build.gradle.kts` reads
> the keystore from env vars, and `cd play-publish-kit && bundle exec fastlane
> lanes` lists `deploy`. Report pass/fail with the exact fix for each fail. Don't
> upload anything.

## 2. Cut an internal release

> Ship a new internal-testing build. Bump the build number, write a one-line
> changelog for the new versionCode under
> `play-publish-kit/fastlane/metadata/android/en-US/changelogs/` summarizing
> commits since the last release tag, then run
> `play-publish-kit/scripts/publish.sh internal --bump`. Show the new version and
> the upload result. Stop and ask before touching production.

## 3. Generate the store listing

> Draft the Play store listing for this app from its README and features. Write
> `title.txt` (≤30 chars), `short_description.txt` (≤80), and
> `full_description.txt` (≤4000) under
> `play-publish-kit/fastlane/metadata/android/en-US/`. Keep the privacy section
> consistent with the app's actual data handling. Then validate the lengths.

## 4. Fill the Data Safety answers

> Read this app's network/storage/auth code and the privacy policy, then fill the
> table in `play-publish-kit/docs/DATA_SAFETY.md` with the correct Data Safety
> answers (collected/shared/purpose per data type, encryption-in-transit,
> deletion). Flag anything where code and policy disagree.

## 5. Promote to production (staged)

> Promote the build tested on internal to production at 10% staged rollout —
> don't rebuild. First run `play-publish-kit/scripts/publish.sh promote
> --from=internal --to=production --rollout=0.1 --dry-run` and show the
> validation output; only run it for real after I confirm. Later I'll say
> "raise to 50%" / "complete" / "halt" — use
> `play-publish-kit/scripts/publish.sh rollout --set=0.5 | --complete | --halt`,
> confirming before --complete or --halt.

## 6. New-app bootstrap

> I'm publishing a brand-new app with play-publish-kit. Walk me through the
> one-time setup from docs/PUBLISHING.md: generate `.env.play`, create the upload
> keystore, wire the signing snippet into `android/app/build.gradle.kts`, and
> produce the first AAB for me to upload manually. List the manual Play Console
> steps I must do that can't be scripted.

## 7. Target-SDK / compliance check

> Before this release, check whether the app meets Google Play's current minimum
> `targetSdk` requirement (`android/app/build.gradle.kts`). If it's below the
> required level, tell me the gap and the minimal change. Don't upgrade
> speculatively.
