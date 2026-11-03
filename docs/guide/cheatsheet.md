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

## Quality

| Command | Does |
|---|---|
| `flutter test` | All unit + widget tests |
| `flutter test test/features/trail` | One folder |
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
| `API_URL` | Find Me HTTP API URL | `config.json` → `apiUrl` |
| `AUTHORITY` | `https://cognito-idp.<region>.amazonaws.com/<pool id>` | `authority` |
| `CLIENT_ID` | Cognito app client id | `clientId` |
| `WEB_ORIGIN` | Web app address; share links are `WEB_ORIGIN/s/<id>` | the site you open |

## Flavors

| Flavor | App name | Android id |
|---|---|---|
| `dev` | Find Me Dev | `app.findme.mobile.dev` |
| `prod` | Find Me | `app.findme.mobile` |

iOS bundle id: `app.findme.mobile` (no flavors yet, chapter 13).

## Stored on the phone

| Key | Where | What |
|---|---|---|
| `findme.session` | secure storage (Keystore / Keychain) | access + refresh token |
| `findme:start` | shared_preferences | last point shown `[lon, lat]`, 4 decimals |
| `findme.shownFriends` | shared_preferences | ids of friends shown on the map |

Both `findme:start` and `findme.shownFriends` are cleared when you sign out or the session expires (the next login may be someone else).

## Timings

| What | Value |
|---|---|
| Trail refresh | 7 s, doubling to 60 s while nothing changes |
| Friends list / live positions | 7 s |
| A shown friend's prints today | 60 s |
| Access token renewal | when < 60 s left |
| Replay alone / together | 120 ms per print (min 10 s) / 60 s |

## Git and CI

| Command | Does |
|---|---|
| `git remote add origin https://github.com/YOUR-USER/findme.git` | Connects to GitHub (chapter 12) |
| `git push -u origin main` | First push; CI starts |
| GitHub → Actions → CI → Run workflow | Starts the iOS build by hand |
