# Android release signing

Two keys are involved with Google Play:

- **App signing key** — the key Play uses to sign what users download. With
  **Play App Signing** (recommended, default for new apps) Google generates and
  guards this key. You never hold it.
- **Upload key** — the key *you* sign AABs with before uploading. Play verifies
  it, strips your signature, and re-signs with the app signing key. This is the
  key this kit creates and uses.

## Create the upload key

```bash
scripts/gen_upload_keystore.sh        # writes to KEYSTORE_PATH from .env.play
```

Back up the `.jks` and its password somewhere safe and **out of the repo**. If
you lose the upload key you can ask Google to reset it (only possible because the
real app key lives with Play); if you opted out of Play App Signing and lose the
app key, you can never update the app.

## How the build picks it up

`scripts/publish.sh` exports `KEYSTORE_PATH`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`,
`KEY_PASSWORD` from `.env.play`. The app's `android/app/build.gradle.kts` must
read them (see [../templates/build.gradle.kts.signing-snippet](../templates/build.gradle.kts.signing-snippet)).
No passwords are stored in the repo.

## CI

Inject the same four variables as protected secrets, and store the keystore as a
base64 secret decoded to a temp file at job start. Never commit the keystore or
its password.

## Security

- Keystore, `.env.play`, and the service-account JSON must be gitignored.
- Rotate any secret that ever lands in a tracked file, then scrub or re-key.
