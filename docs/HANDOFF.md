# Handoff: Find Me mobile (Flutter)

Written 2026-11-03. Read `CLAUDE.md` first; this file is only the current state.

## Where things stand

- All features of the design are implemented for normal users: sign-in, map with paw prints / stops / Hachiware,
  date filter + live refresh with backoff, day diary / top places, replay alone and together, share links, friends.
  No admin screen (by design).
- 119 unit + widget tests pass; `flutter analyze` is clean. Flutter 3.47.9 is installed at `C:\src\flutter`
  (not on PATH yet).
- **Never run on a device.** The Android SDK / Android Studio / emulator are not installed yet (owner, guide
  chapter 01). Not yet done because of that: an APK build, the integration test on the emulator, a visual check
  against the web.
- No GitHub remote yet: CI (`.github/workflows/ci.yml`) has never run (guide chapter 12).

## Next steps

1. Owner: finish guide chapter 01 (Android Studio, SDK, emulator), add `C:\src\flutter\bin` to PATH.
2. `config/dev.json` from the web's `config.json` + `WEB_ORIGIN` (chapter 02); `flutter run --flavor dev …`.
3. Compare with the web on the same day: paw colours and sizes, stop sizes, tile tint, wording.
4. `flutter test integration_test --flavor dev --dart-define-from-file=config/example.json` on the emulator.
5. Create the private GitHub repo and push; check both CI jobs (run the iOS one by hand).

## Known gaps / decisions left open

- iOS has no dev/prod schemes (needs a Mac) and has never been built; CI's macOS job is the first check.
- System font instead of the web's Nunito (chapter 13 says how to add it).
- Taps on stops / prints / friends show a SnackBar, not a map popup.
- In a widget test, the share sheet's ✕ was not found by its screen-reader label "Đóng" (found by text instead);
  worth checking with TalkBack on a device.
