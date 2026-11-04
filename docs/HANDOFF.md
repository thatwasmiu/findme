# Handoff: Find Me mobile (Flutter)

Written 2026-11-03. Read `CLAUDE.md` first; this file is only the current state.

## Where things stand

- All features of the design are implemented for normal users: sign-in, map with paw prints / stops / Hachiware,
  date filter + live refresh with backoff, day diary / top places, replay alone and together, share links, friends.
  No admin screen (by design).
- Follows the web up to `travel-heatmap` e66386f (2026-11-03): one `/track` request a minute carries your trail
  (`have` → `unchanged`) and your shown friends (`friends=`); `/friends/live` and `/friends/{id}/today` are no longer
  called; "Hôm nay" is kept on the phone (`findme.today`) so reopening asks only for what is new. Also the web's
  build stamp (8c1254e): "Phiên bản <commit> <time UTC>" at the bottom of the 👥 sheet and printed at start-up, from
  `--dart-define=APP_VERSION=…` (CI sets it; chapter 02 has the command), "dev" without it.
- API on the app's own address (`travel-heatmap` b4929b0, live 2026-11-04): `API_URL` = `<WEB_ORIGIN>/api`. A
  relative `API_URL` (the web's `/api`) is refused with the config error screen. Update the `FINDME_DEV_CONFIG`
  secret if it still holds the `execute-api` address (that one keeps working until API Gateway is replaced).
- 143 unit + widget tests pass; `flutter analyze` is clean. Flutter 3.47.9 is installed at `C:\src\flutter`
  (not on PATH yet).
- **Runs on an Android emulator** (2026-11-04): SDK, NDK and emulator from zip files on `D:\Android` (no Android
  Studio, no admin; guide chapter 01 Step 3b). User env vars `ANDROID_HOME`, `ANDROID_AVD_HOME`,
  `GRADLE_USER_HOME` point there; virtual phone `findme` (API 35, WHPX acceleration). The dev debug APK built,
  installed and opened on the sign-in screen with `config/dev.json`. Not yet done: signing in and checking the map
  against the web, the integration test, any iPhone run.
- Pushed to https://github.com/thatwasmiu/findme (private) on 2026-11-03; first CI run not checked yet (Actions tab).

## Next steps

1. Owner: add `C:\src\flutter\bin` to PATH. Start the emulator (`D:\Android\Sdk\emulator\emulator.exe -avd findme`),
   then `flutter run --flavor dev --dart-define-from-file=config/dev.json` and sign in. Shortcut on the owner's PC:
   `dev.bat` in the repo root (gitignored, this PC's paths): `dev emu`, `dev run`, `dev build`, `dev install`,
   `dev check`, `dev test`, `dev gen`, `dev doctor`.
2. `config/dev.json` is filled in (from the web's `config.json`; `API_URL` = `WEB_ORIGIN` + `/api`).
3. Compare with the web on the same day: paw colours and sizes, stop sizes, tile tint, wording.
4. `flutter test integration_test --flavor dev --dart-define-from-file=config/example.json` on the emulator.
5. Check the first CI run on GitHub (Actions tab); the iOS job runs on pushes to main.
6. iPhone without a Mac: add the `FINDME_DEV_CONFIG` secret (chapter 12), run the iOS job, download
   `findme-unsigned-ipa`, install with Sideloadly using a second Apple ID (chapter 14 A2). The CI `.ipa` step
   (release build + packing) has never run yet; its first run is the test.

## Known gaps / decisions left open

- The `flutter` wrapper hung in this shell on 2026-11-03 (a `git log` behind it waited on a pager). Workaround that
  worked: `C:\src\flutter\bin\cache\dart-sdk\bin\dart.exe` with `FLUTTER_ROOT=C:\src\flutter` for `pub get`,
  `run build_runner`, `analyze`, and `… flutter_tools.snapshot test` for tests.
- Viewing a past range, shown friends are not refreshed (same as the web); pick Hôm nay to follow them.
- iOS has no dev/prod schemes (needs a Mac) and has never been built; CI's macOS job is the first check.
- System font instead of the web's Nunito (chapter 13 says how to add it).
- Taps on stops / prints / friends show a SnackBar, not a map popup.
- In a widget test, the share sheet's ✕ was not found by its screen-reader label "Đóng" (found by text instead);
  worth checking with TalkBack on a device.
