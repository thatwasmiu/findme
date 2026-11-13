# Cheatsheet

All commands run in PowerShell in the project folder. Flutter lives in `C:\src\flutter\bin` (add it to PATH, chapter 01).

## Setup

| Command | Does |
|---|---|
| `flutter doctor -v` | Checks the tools (chapter 01) |
| `flutter doctor --android-licenses` | Accepts Android licences |
| `flutter emulators` / `flutter emulators --launch Pixel_7_API_35` | Lists / starts emulators |
| `flutter devices` | Lists connected phones and emulators |
| `flutter pub get` | Downloads packages (like `npm install`) |
| `Copy-Item config\example.json config\dev.json` | Creates your config (then fill it in) |

## Run and build

| Command | Does |
|---|---|
| `flutter run --flavor dev --dart-define-from-file=config/dev.json` | Runs the dev app; `r` hot reload, `R` restart, `q` quit |
| `flutter run --flavor prod --dart-define-from-file=config/prod.json` | Runs the prod app |
| `flutter logs` | Device log |
| `flutter build apk --flavor dev --debug --dart-define-from-file=config/dev.json` | APK in `build\app\outputs\flutter-apk\` |
| `flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json` | Play Store bundle (chapter 13) |
| `flutter clean` | Deletes build output (when a build is stuck) |
| `… --dart-define="APP_VERSION=$(git rev-parse --short HEAD) $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm'))"` | Add to any build: commit + time shown as "Phiên bản …" in the 👥 sheet (else "dev") |

Dev builds: the 🐞 button opens the debug console (HTTP calls with status and error code, errors, environment).

## Quality

| Command | Does |
|---|---|
| `flutter test` | All unit + widget tests |
| `flutter test test/features/trail` | One folder |
| `flutter test test/features/auth` | Sign-in and sign-up (Đăng ký → mã 6 số → vào luôn) |
| `flutter test --name "stale load"` | Tests whose name matches |
| `flutter test --coverage` | Coverage in `coverage\lcov.info` |
| `flutter test integration_test --flavor dev --dart-define-from-file=config/example.json` | Full app on the emulator |
| `flutter analyze` | Lints (must be "No issues found!") |
| `dart fix --apply` | Auto-fixes lint issues |
| `dart format .` | Formats all code |
| `dart run build_runner build -d` | Regenerates `*.g.dart` / `*.freezed.dart` |

## Config keys (`config/dev.json`, `config/prod.json`)

| Key | Value | Web equivalent |
|---|---|---|
| `API_URL` | Find Me HTTP API URL | `WEB_ORIGIN` + `/api` (full address, not the web's bare `/api`) |
| `AUTHORITY` | `https://cognito-idp.<region>.amazonaws.com/<pool id>` | `authority` |
| `CLIENT_ID` | Cognito app client id | `clientId` |
| `WEB_ORIGIN` | Web app address; share links are `WEB_ORIGIN/s/<id>` | the site you open |

## Flavors

| Flavor | App name | Android id |
|---|---|---|
| `dev` | Find Me Dev | `app.findme.mobile.dev` |
| `prod` | Find Me | `app.findme.mobile` |

iOS bundle id: `app.findme.mobile` (no flavors yet, chapter 13).
Privacy manifest: `ios/Runner/PrivacyInfo.xcprivacy`; new data sent to the API = new entry there + App Privacy in App Store Connect + `travel-heatmap/web/public/privacy.html`.
Privacy policy URL: `<WEB_ORIGIN>/privacy.html` (welcome card link).

## Stored on the phone

| Key | Where | What |
|---|---|---|
| `findme.session` | secure storage (Keystore / Keychain) | access + refresh token |
| `findme:start` | shared_preferences | last point shown `[lon, lat]`, 4 decimals |
| `findme.shownFriends` | shared_preferences | ids of friends shown on the map |
| `findme.today` | shared_preferences | today's trail (yours + shown friends'), for one account (`sub`) and one day |
| `findme.ingest` | secure storage | the ingest token from `POST /me/ingest-token` + the account (`sub`) it belongs to (chapter 15) |
| `findme.tracking` | shared_preferences | tracking on/off (Android's boot receiver reads it as `flutter.findme.tracking`) |
| `findme.trackerDisclosure` | shared_preferences | the location explanation was accepted once |
| `findme.trackerOwner` | shared_preferences | the account (`sub`) that switched tracking on, before any token was fetched |
| `findme.trackerIndicator` | shared_preferences | iPhone: show the blue location indicator while tracking (a phone setting, kept on sign-out) |
| `findme.trackerUploadSeconds` | shared_preferences | "Gửi mỗi": seconds between uploads (5, 10, 30, 60, 120; default 60; kept on sign-out) |
| `tracker/queue.jsonl`, `tracker/rejected.jsonl` | app documents folder | fixes waiting for `/ingest`; batches the server refused |

All three are cleared when you sign out or the session expires (the next login may be someone else); `findme.today`
also on a login without a map. The tracker's keys and files are cleared only by a deliberate sign-out (👤 → 👋) or account delete or when
another account signs in, never by an expired session.

## Timings

| What | Value |
|---|---|
| Trail + shown friends (one `/track`) | 60 s, and at once when a friend is switched on |
| Friends list | 60 s |
| Access token renewal | when < 60 s left |
| Replay alone / together | 120 ms per print (min 10 s) / 60 s |
| Tracker upload | at 50 waiting fixes, or "Gửi mỗi" (default 1 min) after the last ok, or Gửi ngay; ≤ 500 per request |
| Tracker backoff after a failure | 1, 2, 4, 8, 16, 30 min |
| GPS | Android: every 10 s if moved 10 m; iPhone: ~100 m accuracy, pauses when still |

## Tracker (chapter 15)

| Command | Does |
|---|---|
| `flutter test test/features/tracker` | Tracker unit + widget tests |
| `D:\Android\Sdk\platform-tools\adb.exe reboot` | Reboots the emulator or phone (tracking should come back on its own) |
| Emulator ⋯ → Location → Routes → Play route | Fakes a walk |

## Photo pins (chapter 16)

- Look Back: `<WEB_ORIGIN>/lb/api/findme/…`, media `<WEB_ORIGIN>/lb/media/<key>`.
- Login: `POST /media-ticket` → `POST /lb/api/findme/session` → cookie `fm_user`, memory only, renewed after 6 h.
- New pin: fresh fix (15 s, given up at 20 s) or no pin; name from a stop ≤ 100 m, else `GET /place-name?lat&lon`
  (`{name, pending}`, 4 tries 3 s apart). Camera photos only.
- Switch: `PUT /lb/api/findme/media/<id>/shared {"shared": true|false}` (images only).
- Friends: `POST /pin-grant` → `{grant, exp}` (null with no friends) → `POST /lb/api/findme/shared/session {grant}` →
  pins with `sub` + cookie `fm_shared_friends`. Every 5 min, new pass under 60 s left.
- Links: `pics: true` on `POST /shares` / `PATCH /shares/<id>` ("Ảnh", 🖼️).
- Uploads: tus 1.0.0, 8 MiB chunks. Limits on Look Back: 500 MiB a file, 5 GiB an account.
- Polling: every 5 s only while a file is `processing`.
- App icon: `assets/images/logo.png` and the launcher files all come from the web's `web/public/icon-512.png`.

## Home-screen widget (chapter 17)

| Command / item | Does |
|---|---|
| `adb emu geo fix <lon> <lat>` | One fake position on the emulator (lon first; move 10 m or more each time) |
| `adb shell run-as app.findme.mobile.dev ls -l files/widget` | The widget's files: `widget.png`, `day.jsonl`, `last.json`, `tiles/` |
| `flutter test test/features/widget` | Widget unit tests |

- Redraw at most once a minute while the tracker runs; label alone about every 30 min when it doesn't.
- Zoom 16, picture 400x400 px, tiles kept 7 days, failed tile retried after 5 min.

## Bag and avatar (chapter 18)

- 👤 → 🗑️ Xoá tài khoản: type your name → `DELETE /me` → signed out (owner account: no button). Server side: `travel-heatmap` f17b5ea.
- 👤 → "🎒 Túi của tôi & ảnh đại diện": edit your bag; the round picture on top changes your avatar.
- A friend's bag: tap their marker, or "🎒 Túi" in 👥. A share link opens it only with 🎒 on.
- 8 pockets; phone, Zalo, email, YouTube, Spotify, TikTok, Instagram once each; links, QR, photos, notes repeat.
- Pictures: Look Back upload → receipt (10 min) → `PUT /me/bag`; old pictures deleted only after a save.
- `flutter test test/features/bag` runs its tests.

## Git and CI

| Command | Does |
|---|---|
| `git remote add origin https://github.com/YOUR-USER/findme.git` | Connects to GitHub (chapter 12) |
| `git push -u origin main` | First push; CI starts |
| GitHub → Actions → CI → Run workflow | Starts the iOS build by hand |

## Store release (chapter 14)

| Command / item | Does |
|---|---|
| `keytool -genkey -v -keystore $env:USERPROFILE\findme-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` | Creates the Android upload key (once; back it up) |
| `flutter build apk --flavor prod --release --dart-define-from-file=config/prod.json` | APK to install directly |
| `flutter build appbundle --flavor prod --release --dart-define-from-file=config/prod.json` | `.aab` for Google Play |
| `flutter build ipa --release --dart-define-from-file=config/prod.json` | iOS archive (Mac only) |
| `version: 1.0.0+N` in `pubspec.yaml` | Raise `N` before every store upload |
| Apple Developer Program | 99 USD/year; free Apple ID = own iPhone only, 7-day installs |
| Apple ID | free at account.apple.com: email + phone for SMS, no Apple device needed |
| iPhone without a Mac | Sideloadly (Windows, free, third-party) + `findme-unsigned-ipa` from CI, second Apple ID; chapter 14 A2 |
| `FINDME_DEV_CONFIG` | GitHub Actions secret = content of `config/dev.json`; CI's APK / `.ipa` use it (else placeholders) |
| Google Play Console | 25 USD once; new personal accounts: 12 testers × 14 days before production |
