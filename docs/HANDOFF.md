# Handoff: Find Me mobile (Flutter)

Written 2026-11-03, tracker added 2026-11-04. Read `CLAUDE.md` first; this file is only the current state.

## Where things stand

- **Tracker (Find Me replaces Overland)** on branch `feat/tracker` (2026-11-04, not merged): 🧭 on the map →
  "Ghi hành trình". Background GPS (geolocator), crash-safe queue file, uploads to `/ingest` in Overland's format,
  iOS significant-location relaunch (Swift in `AppDelegate`), Android reboot restart (`BootReceiver.kt`), Play
  disclosure dialog. Token is **pasted** for now (`ponytail:`, until the server API hands it out). Guide chapter 15,
  Play drafts in `docs/guide/play-store-location.md`. Spec/plan: `docs/superpowers/{specs,plans}/2026-11-04-*`.
  **Unit/widget tested only.** Not yet seen on a device: recording with the emulator route, the reboot restart,
  anything on iPhone. The Swift has never compiled (iOS CI runs only on main / by hand).
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
- **Sign-in fixed on devices** (2026-11-04): Cognito speaks `application/x-amz-json-1.1`, which dio neither encodes
  (it sent the body form-encoded → `SerializationException`) nor decodes (every error read as "HTTP 400", and a
  right password failed too). `cognito_api.dart` now sends and reads JSON text itself; the auth tests use Cognito's
  real content type and check the bytes on the wire. A wrong login on the emulator says "Sai email hoặc mật khẩu.";
  a real account has not been tried yet.
- **🐞 debug console** in dev builds (`lib/core/debug/`, guide chapter 02): HTTP calls (masked paths, status, ms,
  error code; a tap shows the URL and both bodies, secrets as •••), Flutter / uncaught / map tile errors,
  environment. A second 🐞 tap closes it. In memory only, last 200; compiled out of prod.
- **Map tiles on the owner's office network:** TLS to every `openstreetmap.org` host is reset (curl on the PC too;
  other tile hosts and the API work), so the map stays mostly grey there. Not an app bug; works elsewhere. Open
  question: a dev-only tile server override if the office network is where testing happens.
- 151 unit + widget tests pass; `flutter analyze` is clean. Flutter 3.47.9 is installed at `C:\src\flutter`
  (not on PATH yet).
- **Runs on an Android emulator** (2026-11-04): SDK, NDK and emulator from zip files on `D:\Android` (no Android
  Studio, no admin; guide chapter 01 Step 3b). User env vars `ANDROID_HOME`, `ANDROID_AVD_HOME`,
  `GRADLE_USER_HOME` point there; virtual phone `findme` (API 35, WHPX acceleration). The dev debug APK built,
  installed and opened on the sign-in screen with `config/dev.json`. Not yet done: signing in and checking the map
  against the web, the integration test, any iPhone run.
- Pushed to https://github.com/thatwasmiu/findme (private) on 2026-11-03; first CI run not checked yet (Actions tab).

## Next steps

0. Tracker on devices (chapter 15 §5): emulator route + background, offline, `adb reboot`; then iOS CI (Actions →
   Run workflow on `feat/tracker`) to compile the Swift; then the iPhone relaunch test on a test account.
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
