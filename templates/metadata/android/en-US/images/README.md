# Store graphics

Drop real assets here, then run `scripts/publish.sh <track> --upload-images`
to push them via the Play Developer API — no Console UI needed.

- `icon.png` — 512x512, PNG/JPEG, <1MB
- `featureGraphic.png` — 1024x500
- `phoneScreenshots/1.png`, `2.png`, ... — at least 2, actual app screenshots
  (real device, emulator, or `flutter build apk` installed via adb + `adb
  exec-out screencap -p`; a Flutter web build in a browser also works if
  no emulator/Xcode is available)

Google rejects placeholder/stock-photo screenshots on review — these must
show the actual app UI.
