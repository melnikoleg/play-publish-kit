fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android deploy

```sh
[bundle exec] fastlane android deploy
```

Upload a pre-built AAB to a Play track. Options: track, aab, rollout, skip_metadata, skip_images, dry_run.

### android promote

```sh
[bundle exec] fastlane android promote
```

Promote the release on one track to another without rebuilding. Options: from, to, rollout, dry_run.

### android rollout

```sh
[bundle exec] fastlane android rollout
```

Manage a staged rollout in place. Options: track (default production), set:<fraction>, halt, complete, version_code, dry_run.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
