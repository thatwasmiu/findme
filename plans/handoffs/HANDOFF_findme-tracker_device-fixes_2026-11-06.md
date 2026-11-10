# Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish

**Date:** 2026-11-06
**Status:** COMPLETED for this session (all committed and pushed); IN PROGRESS for the feature overall (on-device verification on iPhone pending)
**Bead(s):** none (no `bd` on this machine)
**Epic:** Find Me replaces Overland (background tracking in the Flutter app)
**Chain:** `standalone-tracker` seq `2`
**Parent:** `HANDOFF_findme-tracker_review-fixes_2026-11-04.md`
**Prior chain:** `HANDOFF_findme-tracker_review-fixes_2026-11-04.md` > this

---

## Related Handoffs

- `HANDOFF_findme-flutter-app_2026-11-03.md` — the original Flutter app build (separate work stream, before the tracker).

## Since Last Handoff

The parent (seq 1) stopped mid fix-pass: failing tests written for the final-review findings, a parse error in
`tracker_store_test.dart`, C1/I5 not started, Kotlin never compiled, Swift never compiled, nothing on a device.

- **Parent's "Where We're Going" step 1 (fix pass) — done.** I1–I4 implemented RED→GREEN, C1 (Android two engines)
  fixed in `MainActivity.configureFlutterEngine`, I5 (iOS background engine runs `trackerBoot`) done. Commit
  `2736469`. Suite 219/219 then.
- **Step 2 (rebuild APK to compile Kotlin) — done.** `√ Built build\app\outputs\flutter-apk\app-dev-debug.apk`
  (164.6 s Gradle, warm). Kotlin `BootReceiver.kt` + `MainActivity.kt` compile.
- **Step 3/4 (tell owner, finishing-a-development-branch) — done.** Owner chose "merge main": fast-forward of
  `feat/tracker` into `main` (main had not moved), branch deleted, pushed.
- **Risk that materialised:** "nothing on a device" hid two real bugs — the tracking switch never turned on on the
  emulator (geolocator permission quirk) and the iPhone showed "Chưa có token" after sitting locked (Keychain
  accessibility). Both found by the owner on devices and fixed this session.
- **Open question from parent answered:** the token API. The owner (in another session, commit `eaa2c21` in this
  repo and `0931bb4` in travel-heatmap) built `POST /me/ingest-token`; the paste field is gone. Server is
  **deployed** (travel-heatmap `docs/HANDOFF.md` row says `**yes** (2026-11-04)`).
- **Trajectory shifted** from "finish the review" to "polish on real devices": owner asked for Overland-like
  options (location indicator, send interval), map polish (zoom cap, Hachiware animation), removing "30 ngày".
- **Still unverified:** the iOS Swift compile and the iPhone background relaunch were not confirmed in this session
  (CI runs on every push to main now; owner sideloads with Sideloadly). The owner did install on iPhone (iOS 15)
  and reported the locked-phone token bug, which implies the iOS build compiled at least once (`.ipa` from CI).

## Reference Documents

- `CLAUDE.md` — project conventions (Vietnamese UI copy, tokens only in secure storage, never log tokens/coordinates,
  `ponytail:` markers, a feature gets a guide chapter + cheatsheet lines, `docs/HANDOFF.md` = current state).
- `docs/superpowers/specs/2026-11-04-findme-tracker-design.md` — tracker design (approved by owner).
- `docs/superpowers/plans/2026-11-04-findme-tracker.md` — 12-task plan (executed Native/inline).
- `docs/guide/15-background-tracking.md` — learning chapter for the owner (new to mobile).
- `docs/guide/play-store-location.md` — Play Store drafts (disclosure, declaration, video, privacy policy, data safety).
- `docs/guide/14-store-accounts-and-app-ids.md` §A2 — Sideloadly install for the iPhone.
- `C:\Users\DatNT4\Desktop\works\travel-heatmap\lambdas\src\friends.ts` (`POST /me/ingest-token`),
  `lambdas/src/ingest.ts`, `lambdas/src/overland.ts` — server contract.

## The Goal

Find Me (Flutter, Android + iPhone) records GPS in the background and uploads it to the travel-heatmap `/ingest`
endpoint in Overland's exact format, so new users no longer set up the Overland app (tedious: token typed by hand,
Vietnamese keyboard mangles it, six settings). The app must survive the OS killing it (iOS significant-location
relaunch, Android reboot restart), never lose points (queue cleared only after `{"result":"ok"}`), get its upload
token from the server after sign-in (`POST /me/ingest-token`), ship on Google Play (disclosure dialog), and stay
learnable for the owner (guide chapter 15). This session took it from "unit-tested only" to "works on the emulator
and mostly on the owner's iPhone".

## Where We Are

- **Branch:** `main`, clean except the untracked parent handoff
  `plans/handoffs/HANDOFF_findme-tracker_review-fixes_2026-11-04.md` (never committed — commit it with this one).
- **HEAD:** `c885746`, pushed (`origin/main` = `c885746`). CI (GitHub Actions `ci.yml`) builds Android on every
  push and the unsigned iOS `.ipa` on main (job "Build iOS (unsigned .ipa)", artifact `findme-unsigned-ipa`).
- **Tests:** last full-suite run in this session = **243/243** (after the permission fix, before the last three
  commits). After that the owner asked for "small change → no full suite, no build": the last changes were
  verified with the affected folders only — `test/core/storage test/features/tracker test/features/auth` →
  **116/116**, `test/features/trail test/features/replay test/app_test.dart` → **83/83**. `flutter analyze` clean.
  A full `flutter test` has NOT been run on `c885746`; run it first next session.
- **Tracker controller** `lib/features/tracker/presentation/tracker_controller.dart`:
  - `resume()`, `turnOn()`, `turnOff()`, `sendNow()`, `forget()`, `wake()`, `setIndicator({on})`,
    `setUploadEvery(Duration)`; private `_start()`, `_stop()`, `_onFix()`, `_upload({force})`, `_uploadRun()`,
    `_issue()` (fetches token), `_readToken()` + `bool _locked` (new: unreadable Keychain ≠ no token),
    `@visibleForTesting idle({uploads})`.
  - `TrackerState` fields: `on, problem, queued, rejected, lastOk, lastFix, sending, indicator, uploadEvery`.
  - `TrackerProblem { none, noToken, badToken, noAccount, needAlways }` (`noAccount` added by `eaa2c21` for 403).
  - Upload timer `_tick = Timer.periodic(state.uploadEvery, …)`; restarted in `setUploadEvery` when running.
- **Token flow (eaa2c21, owner's other session):** no paste field. `_uploadRun` reads the stored token; if none or
  `badToken`, `_issue()` → `IngestClient.newToken()` (`POST /me/ingest-token` via `ApiClient`, reads `['token']`),
  saved with the Cognito `sub`. 401 from `/ingest` → one more `_issue()`; a fresh token refused → `badToken`.
  403 → `noAccount` ("Tài khoản này không ghi được hành trình"). Owner check: `_store.owner()` must equal current
  `sub`, else no token is fetched.
- **Store** `lib/features/tracker/data/tracker_store.dart`: `SecureTrackerStore` uses `backgroundSafeStorage`,
  caches the token in memory (`_cached`), throws `StorageUnreadable` on `PlatformException`, returns `null` only
  when nothing is stored or JSON is garbled. Keys: secure `findme.ingest`; prefs `findme.tracking`,
  `findme.trackerOwner`, `findme.trackerIndicator`, `findme.trackerUploadSeconds`.
- **Secure storage** `lib/core/storage/secure.dart`: `backgroundSafeStorage = FlutterSecureStorage(iOptions:
  IOSOptions(accessibility: KeychainAccessibility.first_unlock))`, used by `SecureSessionStore` (Cognito session)
  and `SecureTrackerStore`.
- **GPS** `lib/features/tracker/data/geolocator_source.dart`: `request()` returns `always` at once if
  `checkPermission()` already says always; otherwise asks (twice if whileInUse) and returns `checkPermission()`.
  `fixes({indicator})` → iOS `AppleSettings(accuracy: medium, distanceFilter: 10,
  pauseLocationUpdatesAutomatically: true, showBackgroundLocationIndicator: indicator)`; Android
  `AndroidSettings(high, distanceFilter 10, interval 10 s, ForegroundNotificationConfig('Find Me đang ghi hành
  trình', …))`.
- **Upload policy** `lib/features/tracker/domain/upload_policy.dart`: `uploadAt = 50`, `uploadEvery = 1 min`
  (default), `uploadChoices = [5 s, 10 s, 30 s, 1 min, 2 min]`, `maxBatch = 500`, `backoff` 1,2,4,8,16,30 min,
  `shouldUpload(…, every:)`.
- **Sheet** `lib/features/tracker/presentation/tracker_sheet.dart`: switch + disclosure (once, prefs
  `findme.trackerDisclosure`), status line, iPhone-only "Hiện chỉ báo vị trí" switch (`Key('indicator')`), counts,
  "Gửi mỗi" pills (`5 giây … 2 phút`), "Gửi ngay", Android battery hint. Opened by 🧭 in `top_bar.dart`.
- **Map** `lib/features/trail/presentation/map_view.dart`: `MapOptions(maxZoom: 19)`; marker `_hachiware()` now
  `Hachiware(label:)` from `lib/features/trail/presentation/hachiware.dart` (animated).
- **Date filter** `lib/features/trail/domain/date_range.dart`: `Preset { today, yesterday, d7 }` ("30 ngày" removed).
- **Native:** `ios/Runner/AppDelegate.swift` (significant-location + background engine `run(withEntrypoint:
  "trackerBoot")`), `android/.../MainActivity.kt` (destroys cached boot engine `findme.tracker`),
  `android/.../BootReceiver.kt`.
- **Docs updated:** ch15 (indicator, Gửi mỗi, locked-iPhone troubleshooting row), ch06 (no 30 ngày), cheatsheet
  keys/timings, `docs/HANDOFF.md` (review fixes; not yet updated for this session's last commits — see Where We're
  Going).

## What We Tried (Chronological)

1. **Resume from parent: fix pass.** Parse error in `tracker_store_test.dart` (apostrophe in single-quoted test
   name) → switched to double quotes. Implemented I1 (`forget` awaits `_work` and `_running` then forced upload,
   10 s cap), I2 (`await _work` before `clear()`), I3 (`TrackerStore.owner()/setOwner`, `turnOn` records owner,
   `signIn` compares owner), I4 (try/catch around `forget()` in `signOut`). All RED→GREEN except I2 whose test
   passed before the fix (race not deterministic) — fixed by reading. C1: `MainActivity.configureFlutterEngine`
   destroys `FlutterEngineCache` `findme.tracker`. I5: Swift `engine.run(withEntrypoint: "trackerBoot")`.
   Result: 219/219, analyze clean, APK built (Kotlin compiles). Commit `2736469`.
2. **Finishing branch.** Menu → owner "try to merge main" → fast-forward (`main` was still `1804bf2`), 219/219 on
   merged main, branch deleted, owner "Yes, push main" → `1804bf2..2736469`.
3. **Sideloadly Q&A (iOS 15).** Explained: Developer Mode step not needed on iOS 15 (only 16+); app deployment
   target is 15.0 (`IPHONEOS_DEPLOYMENT_TARGET = 15.0`) so it runs; second Apple ID = a fresh account made only for
   Sideloadly (email becomes the Apple ID); "10 App IDs remain" = free-account limit of 10 new bundle IDs per 7 days,
   cannot be deleted, reinstalling the same bundle ID reuses one; 3 sideloaded apps max on device.
4. **Gray map when zoomed in (bug).** Root cause: `MapOptions` had no `maxZoom` (flutter_map unbounded) while OSM
   tiles stop at 19; Leaflet on the web caps automatically. Test `cannot zoom past the last tile level (19)`:
   RED (zoom 22.0) → `maxZoom: 19` → GREEN. Committed `b1f8266` — the commit landed on `feat/ingest-token` because
   the checkout had been switched outside this conversation; later main was fast-forwarded to include it.
5. **Token API contract discussion.** Proposed `POST /me/ingest-token` (POST mints new; server keeps only SHA-256
   hash so it cannot return an existing token), answers `200 {url, token}`, `401`, `403`, optional `429`. Flagged
   "one phone per account": minting on a second phone kills the first phone's token. Owner implemented it in
   another session (`eaa2c21` app, `0931bb4` server). I verified the contract matches: app reads `token`, builds
   `<API_URL>/ingest` itself (same as `url` because `API_URL = WEB_ORIGIN/api`).
6. **Overland "App using location" switch.** Explained iOS `showsBackgroundLocationIndicator` (blue pill, visual
   only; with When-In-Use it is forced on). Owner chose a sheet switch → `TrackerStore.indicator/setIndicator`,
   `LocationSource.fixes({indicator})`, `TrackerController.setIndicator` (re-subscribes GPS when running), iOS-only
   switch. Also fixed double-subscribe race in `_start()` (await before `_fixes ??=`). Commit `a0d2c60` (with item 7).
7. **Upload interval ("Gửi mỗi").** First version 1/5/15/30 min/1 h, default 5 min (key `findme.trackerUploadMinutes`).
   Then owner: "5s/10s/30s/1m/2m" → changed to seconds (`findme.trackerUploadSeconds`, old key ignored), default
   1 min (my call: matches the map's `/track` poll), timer period follows the interval. Commit `c885746`.
8. **Old UI after `dev.bat install`.** Owner saw the paste-token field: `dev install` only installs the last built
   APK (20:25, before `eaa2c21`). Told owner to `dev build` first.
9. **Switch won't turn on (emulator).** Evidence: `adb shell dumpsys package app.findme.mobile.dev` → FINE,
   COARSE, BACKGROUND all `granted=true`, POST_NOTIFICATIONS false. Logcat: each tap opened
   `GrantPermissionsActivity` twice and closed. Root cause in `geolocator_android-5.2.1`
   `PermissionManager.requestPermission`: when status is already `always`, it requests only FINE/COARSE; the result
   lacks BACKGROUND so `hasBackgroundAccess` is false → returns `whileInUse` → our `turnOn` set `needAlways`.
   Fix: `request()` checks first and trusts `checkPermission()`. Tests `geolocator_source_test.dart` with a
   `FakeGeolocator extends GeolocatorPlatform` (RED 2/3 → GREEN). Built with `flutter build apk … config/dev.json`
   + `adb install -r` + monkey launch (first attempt via `cmd //c dev.bat` failed: "'dev.bat' is not recognized"
   — run from wrong cwd). Owner confirmed "Bật được rồi". Commit `9621a54`.
10. **Remove "30 ngày".** `Preset.d30` deleted; tests updated (`trail_ui_test`, `date_range_test`); ch06 note.
    Commit `aa290d1`.
11. **Hachiware lost glow/jump vs web.** Web `styles.css` `.me`: 56×66, img 48×48 white circle, 3 px pink border,
    pink box-shadow, `hop` 1.6 s, `ripple`, `shadow`, reduced-motion off. Ported to `hachiware.dart` with pure
    keyframe functions `hopAt/shadowAt/rippleAt` (CSS-like per-segment easing). Two `map_view_test` tests then hung
    in `pumpAndSettle` (infinite animation) → their `host()` sets `MediaQuery.disableAnimations: true`.
    Commit `10368c0`.
12. **"Chưa có token" on iPhone after background (bug).** Server ruled out (deployed). Asked owner which device →
    iPhone. Root cause: `flutter_secure_storage` default iOS accessibility `unlocked` → Keychain reads fail while
    locked; `token()` swallowed the error as `null` → app thought "no token" → `_issue()` → session also unreadable
    → `noToken`. Fix (owner also asked "make /ingest always work when locked"): `first_unlock` accessibility for
    session + token, in-memory token cache, `StorageUnreadable` distinct from "none", controller `_locked` path
    skips `_issue()` and keeps queuing. The darwin plugin (`flutter_secure_storage_darwin-0.4.3`) searches all
    accessibility levels on read and delete-then-add on write mismatch, so old items migrate. Commit `c885746`.

## Key Decisions

- **Merge to main by fast-forward** (owner choice) and delete `feat/tracker`; later owner works directly on `main`
  and pushes after each change (owner said "commit and push" repeatedly).
- **Upload interval default = 1 min** (my call when 5 min left the list). Rejected: 5 s default (≈12 requests/min
  while moving, battery).
- **Timer period = chosen interval** (not a fixed 5 s tick). Rejected a 5 s tick: parses the queue file ~3× every
  5 s even when idle.
- **Indicator and interval are phone settings** — kept on sign-out (not cleared by `forget()`).
- **Locked Keychain: `first_unlock` + memory cache + `StorageUnreadable`.** Rejected `first_unlock_this_device`
  (would not survive a backup restore to a new phone — not needed, but `first_unlock` is the common choice for
  background-location apps). Rejected "just retry" without distinguishing unreadable from absent (would still mint
  tokens and kill other devices' tokens).
- **Permission fix in our `GeolocatorSource`**, not patching the plugin.
- **Hachiware tests**: map tests run with reduced motion rather than replacing `pumpAndSettle` everywhere.
- **"30 ngày" removed only in the app** — owner's choice; the web removed it too (travel-heatmap `20400e2`).
- **Small changes → no full suite / no build** (owner instruction) — only affected test folders.

## Evidence & Data

### Commits this session (all on main, pushed)

| Hash | Message |
|---|---|
| `2736469` | fix(tracker): final review — one engine per queue, safe forget, account switch |
| `eaa2c21` | feat(tracker): fetch the ingest token from POST /me/ingest-token (owner's other session) |
| `b1f8266` | fix(map): stop zooming at 19, where OSM tiles end |
| `a0d2c60` | feat(tracker): upload interval choice and iPhone location indicator |
| `9621a54` | fix(tracker): switch stayed off when "Allow all the time" was granted |
| `aa290d1` | feat(trail): drop the 30 ngày preset |
| `10368c0` | feat(map): Hachiware hops and glows like on the web |
| `c885746` | fix(tracker): keep the token on a locked iPhone; Gửi mỗi 5 s–2 min |

Pushes: `1804bf2..2736469`, `2736469..b1f8266`, `b1f8266..a0d2c60`, `a0d2c60..9621a54`, `9621a54..c885746`.

### Test counts over the session

| Point | Command | Result |
|---|---|---|
| After I1–I4 | `flutter test test/features/tracker test/features/auth` | 85/85 |
| After C1/I5 | `flutter test` | 219/219 |
| After zoom cap | `flutter test` | 220/220 |
| After indicator | `flutter test` | 234/234 |
| After interval v1 | `flutter test` | 240/240 |
| After permission fix | `flutter test` | 243/243 |
| Interval v2 (5 s–2 min) background run | `flutter test` | 242 pass, 1 fail (`few queued wait 5 min…` — stale default) → fixed; tracker 83/83 |
| 30 ngày | `flutter test test/features/trail test/features/replay` | 73/73 |
| Hachiware | `hachiware_test.dart` 7/7; trail+replay+app 83/83 (after reduced-motion host) |
| Locked Keychain | `test/core/storage test/features/tracker test/features/auth` | 116/116 |

### Emulator permission evidence (before fix)

```
android.permission.POST_NOTIFICATIONS: granted=false
android.permission.ACCESS_FINE_LOCATION: granted=true
android.permission.ACCESS_COARSE_LOCATION: granted=true
android.permission.ACCESS_BACKGROUND_LOCATION: granted=true
logcat per tap: 2× Transition OPEN … topActivity=com.android.permissioncontroller/…GrantPermissionsActivity
```

### Other log evidence

- `Find Me a0d2c60 2026-11-04 14:42` (build stamp printed at start-up), FlutterGeolocator "Geolocator foreground
  service connected", "Flutter engine connected. Connected engine count 1".
- **Unfixed:** older process logged every minute:
  `Unhandled Exception: type '(AsyncError, AsyncError)' is not a subtype of type '(AsyncError<Object?>?,
  AsyncError<Object?>?)' in type cast … #0 FriendsController.refresh (…/friends_controller.dart:102:29)` —
  `AsyncError` from dart:async vs riverpod's `AsyncError` name clash. Not investigated yet.

### Build timings

| Build | Time |
|---|---|
| First Gradle build with geolocator (seq 1) | 1563.6 s |
| Warm rebuild with Kotlin | 164.6 s |

### Web Hachiware spec (source of the port)

```
.me 56x66; img 48x48 left 4 bottom 10; border 3px pink; box-shadow 0 4px 12px rgba(236,72,153,.45)
hop 1.6s ease-in-out: 0/100% translateY(0) scale(1.06,.94); 15% scale(1);
  45% translateY(-12px) scale(.97,1.04) rotate(-4deg); 60% … rotate(4deg); 85% translateY(0) scale(1)
shadow: 0,15,85,100% scale 1 op 1; 45,60% scale .6 op .5   ripple (ease-out): 0-80% scale .6 op 0; 85% .8/.9; 100% 2.4/0
```

## Code Analysis

- `geolocator_android 5.2.1 PermissionManager.requestPermission` adds `ACCESS_BACKGROUND_LOCATION` to the request
  only when current status is `whileInUse`; `onRequestPermissionsResult` returns `always` only if the BACKGROUND
  result is in the answer (`hasBackgroundAccess`). So a repeat request when already `always` reports `whileInUse`.
- `geolocator_android` binds its foreground service in `onAttachedToEngine` (no activity needed) — why the headless
  boot engine can start GPS.
- `flutter_secure_storage 11.2.0`: `IOSOptions(accessibility: …)` default `unlocked`; darwin 0.4.3 `write` =
  update-if-exists else delete+add; reads search all accessibility levels (`crossAccessibilityQueries`).
- `flutter_map 8`: `MapOptions.maxZoom` null = unbounded; `TileLayer.maxZoom: 19` alone leaves gray beyond 19.
- `travel-heatmap friends.ts` `POST /me/ingest-token`: `randomBytes(32).toString('hex')`, `setToken(self.id,
  sha256hex(token), self.tokenHash)`, returns `{url: WEB_ORIGIN/api/ingest, token}`; 403 for no account / disabled.
- Controller `_uploadRun` order: noAccount (unless force) → `_readToken()` → if `_locked` return → issue if none or
  badToken (respecting `_notBefore` unless force) → loop `shouldUpload` with `every: state.uploadEvery`.

## Files Changed

### Source code
- `lib/core/storage/secure.dart` — new `backgroundSafeStorage`.
- `lib/features/auth/data/session_store.dart` — uses `backgroundSafeStorage`; `@visibleForTesting storage`.
- `lib/features/auth/presentation/auth_controller.dart` — signIn compares `owner()`; signOut try/catch forget.
- `lib/features/tracker/data/tracker_store.dart` — owner, indicator, uploadEvery (seconds), `StorageUnreadable`,
  cache, `backgroundSafeStorage`.
- `lib/features/tracker/data/geolocator_source.dart` — permission fix, `fixes({indicator})`.
- `lib/features/tracker/domain/location_source.dart` — `fixes({bool indicator})`.
- `lib/features/tracker/domain/upload_policy.dart` — choices 5 s–2 min, default 1 min, `every:` param.
- `lib/features/tracker/presentation/tracker_controller.dart` — I1–I3, indicator, interval, timer, `_readToken`.
- `lib/features/tracker/presentation/tracker_sheet.dart` — indicator switch, Gửi mỗi pills.
- `lib/features/trail/presentation/hachiware.dart` — new animated marker.
- `lib/features/trail/presentation/map_view.dart` — `maxZoom: 19`, uses `Hachiware`.
- `lib/features/trail/domain/date_range.dart` — no `d30`.
- `android/app/src/main/kotlin/app/findme/findme/MainActivity.kt` — destroy boot engine.
- `ios/Runner/AppDelegate.swift` — `run(withEntrypoint: "trackerBoot")`.

### Tests
- `test/core/storage/secure_test.dart` (new), `test/features/tracker/data/geolocator_source_test.dart` (new),
  `test/features/trail/presentation/hachiware_test.dart` (new).
- Updated: `tracker_store_test`, `upload_policy_test`, `tracker_controller_test`, `tracker_sheet_test`,
  `auth_controller_test`, `map_view_test`, `trail_ui_test`, `date_range_test`, `test/helpers/tracker_fakes.dart`
  (`MemoryTrackerStore.locked/indicatorOn/every`, `FakeLocation.lastIndicator`, `FakeTracker.calls/failForget`).

### Docs
- `docs/guide/15-background-tracking.md`, `docs/guide/06-date-filter-and-live-refresh.md`, `docs/guide/cheatsheet.md`,
  `docs/HANDOFF.md` (partly), `CLAUDE.md` (tracker exception — by earlier commit).

### Scratch (not in repo)
- `C:\Users\DatNT4\AppData\Local\Temp\claude\…\scratchpad\build-switch.log`, `switch.log` — build/log captures.

## User Feedback & Preferences

- "try to merge main" → merge locally; "Yes, push main"; repeatedly "Commit and push" — owner wants main pushed
  after each finished change.
- "small change so no need to run full test suite and build" — for small changes run only affected tests, no build.
- Writes in Vietnamese and English mixed; answers in Vietnamese were fine when they wrote Vietnamese.
- Uses iPhone on **iOS 15**, sideloads with **Sideloadly** and a second Apple ID; also tests on the Android emulator
  via `dev.bat` (`dev build`, `dev install`).
- Wants Overland parity features: "App using location" indicator switch → "công tắc trong sheet"; send interval
  "5s/10s/30s/1m/2m".
- "bỏ 30 ngày" — drop the 30-day preset.
- "character in app losing glowing/jumping effect compare to web" — parity with web visuals matters.
- "is there a way to make sure the /ingest always work even when locked" — reliability in the pocket is the priority.
- Earlier (seq 1): wants a learning chapter for every feature; caveman + ponytail modes active (terse, minimal code).

## Gotchas & Discoveries

- **The checkout can change under you.** Mid-session the working tree switched to `feat/ingest-token` (owner's
  other session) and back to `main`; a commit meant for main landed on the branch. Always run `git status -sb`
  before committing; report the real branch.
- **`dev.bat install` installs the last built APK** — it does not build. After pulling new code: `dev build` first.
- **`cmd //c "dev.bat …"` from Git Bash fails** ("not recognized") — call `C:/src/flutter/bin/flutter build apk
  --flavor dev --debug --dart-define-from-file=config/dev.json` and `D:/Android/Sdk/platform-tools/adb.exe install
  -r build/app/outputs/flutter-apk/app-dev-debug.apk` directly, launch with `adb shell monkey -p
  app.findme.mobile.dev -c android.intent.category.LAUNCHER 1`.
- **Git Bash path conversion** mangles `/sdcard/...` for adb (`cat: C:/…/Git/sdcard/ui.xml`): `export
  MSYS_NO_PATHCONV=1`.
- **`adb logcat` without `-d` blocks**; with the emulator off, `adb devices` starts the daemon and logcat waits
  forever — use a timeout or check `adb devices` first.
- **Python `"\a"` in heredocs** becomes a bell char (broke `adb.exe` path in cheatsheet once); use `chr(92)`.
- **Endless animations break `pumpAndSettle`** — any widget test that shows the map with a last point must set
  `MediaQuery.disableAnimations`.
- **Riverpod overriding the same provider twice throws** — `baseOverrides(fakeTracker: false)` when a test brings
  its own tracker.
- **iOS 15:** no Developer Mode toggle; "VPN & Device Management" may be "Profiles & Device Management";
  location settings at Settings → Privacy → Location Services → Find Me → Always + Precise Location.
- **Android "Allow all the time"** lives in App info → Permissions → Location; appears only after the app asked once.
- **Free Apple ID limits:** 10 new App IDs / 7 days (cannot delete, expire after 7 days), 3 sideloaded apps.

## Owner Q&A given this session (so the next session doesn't repeat or contradict)

| Question | Answer given |
|---|---|
| How to install with Sideloadly | ch14 A2: iTunes+iCloud from apple.com, Trust, drag `findme.ipa`, second Apple ID, Trust developer profile; 7-day re-sign |
| "I have iOS 15" | works (target 15.0); skip Developer Mode |
| What is my second Apple ID / email becomes Apple ID | new Apple account just for Sideloadly; its email is the Apple ID; don't sign the phone into it |
| "10 App IDs remain" / can I delete one | free-account weekly limit; can't delete; same bundle ID reuses one |
| Does `eaa2c21` change UI | removed Token field/"Lưu"/"Đã lưu token"; added status "Tài khoản này không ghi được hành trình" |
| What does Overland's "App using location" do | iOS blue indicator; visual only; forced with When-In-Use |
| Why call `/me/ingest-token` when a token is stored | only when the stored token can't be read or `/ingest` says 401 |

## Where We're Going

1. **Run the full suite on `c885746`** (`C:/src/flutter/bin/flutter test`) — last full run was 243/243 before the
   final three commits. Fix anything red.
2. **Owner verifies on iPhone** with the new CI `.ipa` (Sideloadly): turn tracking on, lock, pocket ≥30 min, unlock
   → status must be "Đang ghi", "Gửi lần cuối" recent. Expect one re-login on first launch is possible.
3. **Fix `FriendsController.refresh` cast crash** (`friends_controller.dart:102`, dart:async `AsyncError` vs
   riverpod `AsyncError`) — logged every minute; use systematic debugging, write a failing test first.
4. **Update `docs/HANDOFF.md`** for this session (token API live, permission fix, locked-Keychain fix, interval
   5 s–2 min, indicator, Hachiware, no 30 ngày, zoom cap).
5. **Deferred minors from the final review** (seq 1 list): `_start()` resets badToken per wake; stream `onError`
   leaves timer/flag on; ~3 whole-file parses per fix (worse with a 5 s interval — consider cached counts); no
   explicit crash-between-ok-and-commit test; no `goAsync()` in `BootReceiver`.
6. **One phone per account**: decide whether the server should keep one token per device (owner's call); today
   a second phone minting a token kills the first.

## Risks & Blockers

- Swift/iOS behaviour (significant-location relaunch, background engine) still not observed on a device.
- 5 s interval + whole-file queue parsing per fix/tick may cost battery on long offline queues.
- Two devices on one account rotate each other's token (401 ping-pong).
- First launch after the Keychain change may require signing in again.

## Open Questions

- Does the iPhone now keep "Đang ghi" while locked for hours? (owner to report)
- Should the server allow several tokens per account (per device)?
- Is the `FriendsController.refresh` crash still present in the current build (seen in an older process)?

## Quick Start for Next Session

```bash
# Repo
cd C:\Users\DatNT4\Desktop\works\findme
git status -s ; git log --oneline -10

# Reference docs
docs/superpowers/specs/2026-11-04-findme-tracker-design.md
docs/guide/15-background-tracking.md
docs/HANDOFF.md

# Key files to read first
lib/features/tracker/presentation/tracker_controller.dart
lib/features/tracker/data/tracker_store.dart
lib/features/tracker/data/geolocator_source.dart
lib/features/friends/presentation/friends_controller.dart   # line 102 crash

# Verify current state
C:/src/flutter/bin/flutter test
C:/src/flutter/bin/flutter analyze

# Emulator tools
D:/Android/Sdk/platform-tools/adb.exe devices
.\dev.bat build ; .\dev.bat install      # from the repo root in PowerShell

# Next action
Run the full suite on c885746, then debug FriendsController.refresh (friends_controller.dart:102).
```

## Session Closed
**Closed at:** 2026-11-06
**Commit:** the `session: findme-tracker-device-fixes` commit that includes this note
**Session status:** Handed off to next session
