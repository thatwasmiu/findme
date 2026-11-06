# Find Me tracker (replaces Overland): built, final-review fixes half done

**Date:** 2026-11-04
**Status:** IN PROGRESS
**Bead(s):** none
**Chain:** `standalone-tracker` seq `1`
**Parent:** none, first in this chain (sibling: `HANDOFF_findme-flutter-app_2026-11-03.md`, the app build, a separate work stream)

## The Goal
Find Me (Flutter, `C:\Users\DatNT4\Desktop\works\findme`) records GPS in the background on Android and iPhone and
uploads it to `travel-heatmap`'s `POST /ingest` in Overland's exact format, so new users don't have to set up
Overland. The owner wants one app, Google Play distribution for Android, a learning chapter (owner is new to mobile),
and room to extend later. The token is pasted for now; the owner will build a server API that hands it out after sign-in.

## Reference Documents
- Spec: `docs/superpowers/specs/2026-11-04-findme-tracker-design.md` (approved by the owner)
- Plan: `docs/superpowers/plans/2026-11-04-findme-tracker.md` (12 tasks; the owner chose Native, i.e. inline execution)
- Ledger with every Ruling: `.superpowers/sdd/2026-11-04-findme-tracker/progress.md` (git-ignored)
- Review diff: `.superpowers/sdd/2026-11-04-findme-tracker/review-1804bf2..029e401.diff`
- Guide: `docs/guide/15-background-tracking.md`, `docs/guide/play-store-location.md`
- `CLAUDE.md`, `docs/HANDOFF.md` (both updated for the tracker)

## Where We Are
- Branch `feat/tracker`, 11 commits on top of main (`1804bf2`). Nothing is pushed or merged.
- Tasks 1-12 are all committed. The suite had 212 passing tests at `81e9e73`, `flutter analyze` was clean, and Task 12 is docs only.
- The dev debug APK builds (`√ Built build\app\outputs\flutter-apk\app-dev-debug.apk`, 1563 s Gradle; it includes the Kotlin up to Task 8).
  The APK has **not** been rebuilt since `BootReceiver.kt` was added in Task 11. Rebuild it to compile the Kotlin.
- The Swift (`ios/Runner/AppDelegate.swift`) has never been compiled. The iOS CI job runs only on main or `workflow_dispatch`.
- Nothing has run on a device: no emulator route, no reboot test, no iPhone.
- **Uncommitted, in progress:** failing tests written for the final-review fix pass, in
  `test/features/tracker/presentation/tracker_controller_test.dart`, `test/features/auth/presentation/auth_controller_test.dart`,
  `test/features/tracker/data/tracker_store_test.dart` and `test/helpers/tracker_fakes.dart`.
  - **Bug to fix first:** in `tracker_store_test.dart` the new test name `'owner: the token's account…'` has an apostrophe
    inside single quotes, so the file doesn't parse. Use double quotes.
  - The other new tests fail as expected (RED): the forget-waits-for-upload test, the turnOn-records-owner test,
    the auth test for an account switch with no token, and the auth test for a forget that fails.

## Final review findings (fresh Opus reviewer). The fix pass is IN PROGRESS
| # | Severity | Finding | Fix to make |
|---|---|---|---|
| C1 | Critical | Android: after a reboot the boot engine (`BootReceiver.kt`, cached as `findme.tracker`) keeps running when the user opens the app. Two isolates then write the same `queue.jsonl`, which loses fixes on rename. | In `MainActivity.configureFlutterEngine`: `FlutterEngineCache.getInstance().get("findme.tracker")?.destroy()` and remove it from the cache (mirrors iOS) |
| I1 | Important | `forget()` skips the forced upload while one is running | `await _running` first, then `_upload(force:true)`, all inside the 10 s timeout |
| I2 | Important | A fix chained on `_work` can be appended after `clear()` | `await _work` before `clear()` in `forget()` |
| I3 | Important | Account switch with no token pasted keeps the previous account's queue | Add `TrackerStore.owner()` (token's sub, else prefs owner) and `setOwner(sub)`. `turnOn` sets the owner from the current access token's `subOf`. `forget` clears it. `AuthController.signIn` compares `owner()` instead of `token()?.sub`. The fakes already have `owned`/`owner()`/`setOwner` |
| I4 | Important | `signOut` throws before `logout()` if `forget()` fails | Wrap `forget()` in try/catch in `auth_controller.dart` signOut. `FakeTracker.failForget` already exists |
| I5 | Important | iOS background engine runs `main()`/runApp with no view | `engine.run(withEntrypoint: "trackerBoot")` in AppDelegate (the `trackerBoot` entrypoint already exists in `lib/main.dart`) |
Minors (defer, list for the owner): `_start()` resets badToken on every wake; onError leaves the subscription, timer and
flag on; the upload loop reads the token once; every fix parses the whole queue file about 3 times (cache the count);
state is written after dispose; there's no explicit crash-between-ok-and-commit test; there's no `goAsync()` in BootReceiver.

## Key Decisions (owner)
- Both Android and iPhone. iPhone stays on Sideloadly for now (7-day expiry accepted).
- Temporary token paste (`ponytail:`); the owner's API replaces it later ("so more secure").
- The survival layer is in v1: iOS significant-location relaunch and Android reboot restart.
- The owner tests on a **different account** while Overland keeps running on theirs, so `device_id` `iphone`/`android` is fine.
- Android ships on **Google Play**, which means a disclosure dialog, background-location declaration, video, privacy policy and data safety. Drafts are in `play-store-location.md`.
- Wants a learning chapter (ch15 is done).
- Rejected `flutter_background_geolocation`: Android release builds need a paid licence.

## Key Rulings (executor; full list in the ledger)
- `IngestClient` is separate from `ApiClient`, because a 401 there would sign the user out.
- Debug console masks `coordinates`. Added the `ingest` route word.
- A 1-min Timer re-checks uploads while tracking is on. `@visibleForTesting idle({uploads})` makes the tests deterministic.
- After an ok, the loop re-checks `shouldUpload` (sends at once if 50 or more wait). `saveToken` uploads immediately.
- `baseOverrides` fakes the tracker by default (`fakeTracker: false` for the controller/sheet tests).
- The entry button is 🧭 in the TopBar (📍 is the brand). The disclosure is remembered in prefs `findme.trackerDisclosure`.
- iOS: a headless FlutterEngine starts on a location relaunch because UIScene opens no window. It is destroyed when the window engine starts.
- Android: the spike was skipped. geolocator_android 5.2.1 binds its service in `onAttachedToEngine`, so headless should work.
- POST_NOTIFICATIONS is not requested at runtime (`ponytail:`).

## Code map
- `lib/features/tracker/domain/{fix,upload_policy,location_source}.dart`: `Fix`, `overlandBatch`, `deviceIdForPlatform`,
  `shouldUpload`/`backoff` (50 fixes / 5 min / up to 500 per batch; backoff 1,2,4,8,16,30 min), `LocationSource`/`LocationAccess`.
- `lib/features/tracker/data/`: `point_queue.dart` (queue.jsonl + rejected.jsonl, `_serial` chain, tmp+rename),
  `ingest_client.dart` (`IngestResult` ok/unauthorized/rejected/retry), `tracker_store.dart` (secure `findme.ingest`,
  prefs `findme.tracking`), `geolocator_source.dart`, `wake_channel.dart` (channel `findme/tracker`).
- `lib/features/tracker/presentation/tracker_controller.dart` (`TrackerState`, `TrackerProblem`, resume/turnOn/turnOff/
  sendNow/saveToken/forget/wake), `tracker_sheet.dart`. `lib/features/tracker/boot.dart` (`startTrackerHeadless`).
- Wiring: `lib/main.dart` (GeolocatorSource override, `trackerBoot` entrypoint), `lib/app.dart` (resume in initState),
  `auth_controller.dart` (signOut→forget; signIn with a different sub→forget), `top_bar.dart` (🧭), `map_screen.dart`.
- Native: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist` (location keys, UIBackgroundModes),
  `android/app/src/main/AndroidManifest.xml` (permissions, BootReceiver), `android/.../BootReceiver.kt`.
- Tests: `test/features/tracker/**`, `test/helpers/tracker_fakes.dart` (MockIngest, jwt(), MemoryTrackerStore, FakeLocation, FakeTracker, FakeWake).

## Gotchas
- Use `C:/src/flutter/bin/flutter` and `dart`. The full test run takes about 30 s. A cold APK build takes about 26 min: run it in the background.
- Bash heredocs with `'` inside python broke once. Use the Write tool for big files. Python `"\a"` became a bell char in the cheatsheet once.
- Riverpod: overriding the same provider twice throws, so use the `baseOverrides` flags.

## Where We're Going
1. Fix the parse error in `tracker_store_test.dart`, then implement I1-I4 until all new tests pass. Then C1 (Kotlin MainActivity) and I5 (Swift). Run the full suite and analyze, commit, and add `Final: fixed …` lines to the ledger.
2. Rebuild the APK in the background to compile the Kotlin.
3. Tell the owner the remaining device checks (ch15 §5), the iOS CI run on `feat/tracker` (needs a push, which is the owner's call), the deferred minors and the rulings list.
4. Then `superpowers:finishing-a-development-branch` (merge/PR is the owner's call). Delete the `.superpowers/sdd/2026-11-04-findme-tracker` workspace after a clean review.

## User Feedback & Preferences
- Caveman + ponytail modes active: terse, minimal code.
- "continue" means go with the recommendation. Approved spec → "Approve, plan it". Chose "Native" execution.
- "remember to add a chapter so I can learn".
- Setting up Overland is tedious for new users, which is the whole motivation.

## Quick Start
```
cd C:\Users\DatNT4\Desktop\works\findme ; git status ; git log --oneline -12
C:/src/flutter/bin/flutter test test/features/tracker test/features/auth
```
Next action: fix the quote in `tracker_store_test.dart`, then make the review-fix tests pass.
