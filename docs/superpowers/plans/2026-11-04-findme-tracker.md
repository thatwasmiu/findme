# Find Me Tracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Find Me records your position in the background on Android and iPhone and uploads it to `/ingest` in
Overland's format, so Overland is no longer needed.

**Architecture:** New feature `lib/features/tracker/{data,domain,presentation}`. A `LocationSource` (geolocator)
feeds fixes to a `TrackerController` (Riverpod), which appends them to a crash-safe file queue and uploads batches
through a small `IngestClient`. Native code is only the survival layer: iOS significant-location-change (Swift in
`AppDelegate`) and an Android boot receiver that starts a headless Dart entrypoint.

**Tech Stack:** Flutter 3.47 / Dart 3, `geolocator` (new), `path_provider` (new direct dep, already in the lock
file), dio, flutter_riverpod 3, flutter_secure_storage, shared_preferences, mocktail, fake_async.

**Spec:** `docs/superpowers/specs/2026-11-04-findme-tracker-design.md` (read it first; this plan argues from it).
Server contract: `C:\Users\DatNT4\Desktop\works\travel-heatmap\lambdas\src\ingest.ts` and `overland.ts`.

## Global Constraints

- No server change. Body exactly `{"locations":[{"type":"Feature","geometry":{"type":"Point","coordinates":[lon,lat]},"properties":{"timestamp":"<ISO-8601 UTC>","horizontal_accuracy":<m>,"device_id":"<id>"}}]}`, header `Authorization: Bearer <ingest token>`, `POST <AppConfig.api>/ingest`.
- A queued fix is removed only after `200` with body `{"result":"ok"}`.
- `device_id`: `iphone` on iOS, `android` on Android.
- Thresholds: upload when queued ≥ 50 or ≥ 5 min since last successful upload (and queue non-empty), or on "Gửi ngay"; ≤ 500 fixes per request; backoff 1, 2, 4, 8, 16, 30 min (cap 30) after `5xx`/network.
- Ingest token + its account `sub` only in `flutter_secure_storage`. Never log/show the token, coordinates, or the URL with a token. The 🐞 console must not show coordinates.
- Only a deliberate `signOut()` (or a sign-in as a different `sub`) ends tracking and deletes queue + token. `expired()` and `noAccount()` must not touch the tracker.
- UI copy Vietnamese (new copy, web tone). Copy fixed by the spec: `Ghi hành trình`, `Đang ghi`, `Đã tắt`, `Thiếu quyền vị trí "Luôn luôn"`, `Token sai hoặc đã đổi`, `Điểm chờ gửi: N`, `Gửi lần cuối: …`, `Điểm cuối: …`, `Gửi ngay`, `Điểm bị từ chối: N`, `Find Me đang ghi hành trình`, `Đồng ý`, `Không`.
- Permissions asked only when the switch is turned on, after the disclosure screen.
- Temporary token paste marked `// ponytail: pasted ingest token until the server hands it out after sign-in; delete TokenField + saveToken then.`
- Tests never touch the network or real files outside a temp dir. `flutter analyze` and `dart format --set-exit-if-changed .` clean before every commit. Generated code committed.
- If the `flutter` wrapper hangs in the shell, use the workaround in `docs/HANDOFF.md` (Known gaps).

## Review Focus

1. **Crash between "upload ok" and "queue rewritten"** → fixes re-sent next time (server overwrites by time+device), never lost. Test in Task 2 (`commit after reopen`).
2. **Token pasted with spaces/newline** (the ch04 keyboard problem) → trimmed before saving; empty after trim = refused. Test in Task 5.
3. **Fixes arriving while an upload is in flight** → appended, not lost, not double-sent; only one upload at a time. Test in Task 6 (`no overlapping uploads`).
4. **Switch on with no token** → records and queues, status says the token is missing, no request sent. Test in Task 6.
5. **Garbage or partial last line in the queue file** (killed mid-append) → that line skipped, rest kept. Test in Task 2.

---

### Task 1: Fix model, Overland encoding, console masking

**Files:**
- Create: `lib/features/tracker/domain/fix.dart`
- Modify: `lib/core/debug/debug_log.dart` (`_secret` regex)
- Test: `test/features/tracker/domain/fix_test.dart`, `test/core/debug/debug_log_test.dart`

**Interfaces:**
- Produces:
  - `class Fix { const Fix({required DateTime at, required double lat, required double lon, required double acc}); }` with `Map<String, dynamic> toJson()` / `factory Fix.fromJson(Map<String, dynamic>)` (queue line format: `{"t":"<iso utc>","lat":…,"lon":…,"acc":…}`), `==`/`hashCode` by value. Plain class, no freezed.
  - `Map<String, dynamic> overlandBatch(List<Fix> fixes, String deviceId)` — the exact body in Global Constraints; timestamp `at.toUtc().toIso8601String()`.
  - `String get deviceIdForPlatform` — `iphone` when `defaultTargetPlatform == TargetPlatform.iOS`, else `android`.

- [ ] **Step 1: Write failing tests**
  - `overlandBatch encodes lon,lat order and UTC timestamp`: one `Fix(at: DateTime.utc(2026,11,4,3,15,42), lat: 10.77, lon: 106.70, acc: 12)` with `'android'` → `locations[0].geometry.coordinates == [106.70, 10.77]`, `properties.timestamp == '2026-11-04T03:15:42.000Z'`, `horizontal_accuracy == 12`, `device_id == 'android'`, `type == 'Feature'`.
  - `Fix json round-trip`.
  - In `debug_log_test.dart`: `showBody masks coordinates` — `showBody({'locations':[{'geometry':{'coordinates':[106.7,10.77]}}]})` contains `'•••'` and does not contain `'106.7'`.
- [ ] **Step 2: Run** `flutter test test/features/tracker test/core/debug` → FAIL (missing file / unmasked).
- [ ] **Step 3: Implement** `fix.dart`; change `_secret` to `RegExp('password|token|secret|coordinates', caseSensitive: false)`.
- [ ] **Step 4: Run** same command → PASS.
- [ ] **Step 5: Commit** `feat(tracker): fix model and Overland batch encoding`.

### Task 2: Crash-safe file queue

**Files:**
- Create: `lib/features/tracker/data/point_queue.dart`
- Test: `test/features/tracker/data/point_queue_test.dart`

**Interfaces:**
- Consumes: `Fix` (Task 1).
- Produces: `class PointQueue { PointQueue(Directory dir); Future<void> append(Fix f); Future<List<Fix>> peek(int max); Future<void> commit(int n); Future<void> reject(int n); Future<int> count(); Future<int> rejectedCount(); Future<void> clear(); }` and `final pointQueueProvider = FutureProvider<PointQueue>` (dir = `getApplicationDocumentsDirectory()/tracker`).
  - Files: `queue.jsonl`, `rejected.jsonl` in `dir`. `append` = `writeAsString(line + '\n', mode: FileMode.append, flush: true)`.
  - `commit(n)` drops the first n lines; `reject(n)` appends the first n lines to `rejected.jsonl` then drops them. Both rewrite via `queue.jsonl.tmp` + `rename` (atomic on both platforms).
  - Unparseable lines are skipped by `peek`/`count` and dropped on the next rewrite.
  - All methods serialised through one internal `Future` chain (no two writes at once).

- [ ] **Step 1: Write failing tests** (each with `Directory.systemTemp.createTempSync()`):
  - `append then peek returns in order`; `peek(2)` of 3 returns first 2.
  - `commit removes only the first n`; `count` after = 1.
  - `reject moves n to rejected` — `rejectedCount() == n`, `count()` reduced.
  - `commit after reopen`: new `PointQueue` on same dir sees remaining lines (survives restart).
  - `partial last line skipped`: write two good lines + `'{"t":"2026'` raw → `count() == 2`, `peek(10).length == 2`.
  - `leftover tmp file ignored`: a stale `queue.jsonl.tmp` present → queue reads `queue.jsonl` only.
  - `clear empties both files`.
- [ ] **Step 2: Run** `flutter test test/features/tracker/data/point_queue_test.dart` → FAIL.
- [ ] **Step 3: Implement.** `// ponytail: JSON-lines file, whole-file rewrite on commit; sqlite if queues of 100k+ points get slow.`
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(tracker): crash-safe point queue`.

### Task 3: Ingest client

**Files:**
- Create: `lib/features/tracker/data/ingest_client.dart`
- Test: `test/features/tracker/data/ingest_client_test.dart` (dio with `test/helpers/fake_adapter.dart`)

**Interfaces:**
- Consumes: `overlandBatch`, `Fix`, `AppConfig`, `appDio()`.
- Produces: `enum IngestResult { ok, unauthorized, rejected, retry }`; `class IngestClient { IngestClient(AppConfig cfg, {Dio? dio}); Future<IngestResult> send(String token, List<Fix> fixes, String deviceId); }`; `final ingestClientProvider = Provider<IngestClient>`.
  - Separate from `ApiClient` (that one injects the Cognito token and throws `AuthExpired` on 401, which would sign the user out). Uses `appDio()` so the 🐞 console still sees it (coordinates masked by Task 1, Authorization never read).
  - `200` + `{"result":"ok"}` → ok; `200` other body → retry; `401` → unauthorized; `400` → rejected; other status or `DioException` → retry. `connectTimeout`/`receiveTimeout` 20 s.

- [ ] **Step 1: Write failing tests** — one per mapping above, plus `sends bearer and body to <api>/ingest` (assert request path ends `/ingest`, header `Authorization == 'Bearer tok'`, body `locations.length == fixes.length`).
- [ ] **Step 2: Run** `flutter test test/features/tracker/data/ingest_client_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(tracker): ingest client`.

### Task 4: Upload policy (pure)

**Files:**
- Create: `lib/features/tracker/domain/upload_policy.dart`
- Test: `test/features/tracker/domain/upload_policy_test.dart`

**Interfaces:**
- Produces: `bool shouldUpload({required int queued, required DateTime? lastOk, required DateTime now, required DateTime? notBefore})` and `Duration backoff(int failures)`; constants `uploadAt = 50`, `uploadEvery = Duration(minutes: 5)`, `maxBatch = 500`.
  - `shouldUpload`: false if `queued == 0` or `now < notBefore`; true if `queued >= 50`, or `lastOk == null`, or `now - lastOk >= 5 min`.

- [ ] **Step 1: Write failing tests**: `backoff(1..7) == [1,2,4,8,16,30,30] min`; `shouldUpload` cases: empty → false; 50 queued → true; 3 queued, last ok 4 min ago → false; 6 min ago → true; never uploaded → true; inside backoff window → false even with 500 queued.
- [ ] **Step 2–4:** run `flutter test test/features/tracker/domain` FAIL → implement → PASS.
- [ ] **Step 5: Commit** `feat(tracker): upload thresholds and backoff`.

### Task 5: Tracker settings store

**Files:**
- Create: `lib/features/tracker/data/tracker_store.dart`
- Test: `test/features/tracker/data/tracker_store_test.dart`

**Interfaces:**
- Produces: `typedef IngestToken = ({String token, String sub});` `abstract interface class TrackerStore { Future<IngestToken?> token(); Future<void> saveToken(String raw, String sub); Future<bool> enabled(); Future<void> setEnabled(bool on); Future<void> forget(); }`; `class SecureTrackerStore implements TrackerStore` (`FlutterSecureStorage` key `findme.ingest` → JSON `{token, sub}`; `SharedPreferences` key `findme.tracking` bool); `final trackerStoreProvider = Provider<TrackerStore>`.
  - `saveToken` trims; throws `ArgumentError` if empty after trim.
  - `findme.tracking` must stay a plain legacy `SharedPreferences` bool: Android native reads it as `flutter.findme.tracking` in the `FlutterSharedPreferences` file (Task 11).
  - `forget` deletes both.

- [ ] **Step 1: Write failing tests** (`FlutterSecureStorage.setMockInitialValues({})`, `SharedPreferences.setMockInitialValues({})`): `saveToken trims spaces and newlines`; `empty token refused`; `token round-trip with sub`; `enabled defaults false`; `forget clears token and flag`.
- [ ] **Step 2–4:** run `flutter test test/features/tracker/data/tracker_store_test.dart` FAIL → implement → PASS.
- [ ] **Step 5: Commit** `feat(tracker): token and on/off store`.

### Task 6: Tracker controller

**Files:**
- Create: `lib/features/tracker/domain/location_source.dart`, `lib/features/tracker/presentation/tracker_controller.dart`
- Test: `test/features/tracker/presentation/tracker_controller_test.dart`

**Interfaces:**
- Consumes: Tasks 1–5.
- Produces:
  - `enum LocationAccess { denied, whileInUse, always }`; `abstract interface class LocationSource { Future<LocationAccess> access(); Future<LocationAccess> request(); Stream<Fix> fixes(); Future<void> openSettings(); }`; `final locationSourceProvider = Provider<LocationSource>` (real impl in Task 8; tests override).
  - `enum TrackerProblem { none, noToken, badToken, needAlways }`
  - `class TrackerState { final bool on; final TrackerProblem problem; final int queued; final int rejected; final DateTime? lastOk; final DateTime? lastFix; final bool sending; }` (+ `copyWith`).
  - `class TrackerController extends Notifier<TrackerState>` with `Future<void> resume()` (called on app start: if store enabled and access == always → listen), `Future<void> turnOn()` (assumes disclosure accepted; `request()`; not always → `problem = needAlways`, stays off), `Future<void> turnOff()`, `Future<void> sendNow()`, `Future<void> saveToken(String raw)` (sub = `subOf` of the current Cognito access token from `authRepositoryProvider`; clears `badToken`), `Future<void> wake()` (iOS relaunch/significant change: re-subscribe if on), `Future<void> forget()` (stop, best-effort upload with 10 s cap, `queue.clear()`, `store.forget()`).
  - `final trackerControllerProvider = NotifierProvider<TrackerController, TrackerState>`. **Does not watch `signedInProvider` / `sessionEpochProvider`.**
  - On each fix: `queue.append`, update `lastFix`/`queued`, then `_maybeUpload()`: if no token → `problem = noToken`, return; if `badToken` → return until `saveToken`; if `sending` → return; if `shouldUpload` → loop `peek(maxBatch)` / `send`: ok → `commit`, `lastOk = now`, failures = 0; rejected → `reject`; unauthorized → `problem = badToken`, stop; retry → `failures++`, `notBefore = now + backoff(failures)`, stop. `sendNow` ignores `notBefore`.

- [ ] **Step 1: Write failing tests** (fake `LocationSource` with a `StreamController<Fix>`, mocktail `IngestClient`, in-memory `TrackerStore`, `PointQueue` on temp dir, `fake_async` for time):
  - `turnOn without always → needAlways, not listening`.
  - `fix is queued and 50th fix triggers one upload; ok commits`.
  - `no token → queues, problem noToken, send never called`.
  - `401 → badToken, further fixes queue without sending; saveToken clears and next fix uploads`.
  - `400 → batch rejected, rest still sent` (queue of 600: first 500 rejected, next 100 ok in the same run).
  - `retry → backoff: no send for 1 min, then send`.
  - `no overlapping uploads`: `send` held on a `Completer`; 60 more fixes arrive; `send` called once until completed; afterwards queued count == 60 and next upload sends them.
  - `resume with flag on and always → listening`; `flag off → not`.
  - `forget clears queue and token, stops stream`.
- [ ] **Step 2: Run** `flutter test test/features/tracker/presentation/tracker_controller_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(tracker): controller (record, queue, upload)`.

### Task 7: Auth wiring

**Files:**
- Modify: `lib/features/auth/presentation/auth_controller.dart` (`signIn`, `signOut`)
- Test: `test/features/auth/presentation/auth_controller_test.dart`

**Interfaces:**
- Consumes: `trackerControllerProvider.notifier.forget()`, `trackerStoreProvider.token()`, `subOf`.
- `signOut()`: call `forget()` **before** `logout()` (needs nothing from Cognito, but keep order obvious). `signIn()`: after `login`, if stored ingest token's `sub` != `subOf(new access token)` → `forget()`. `expired()` / `noAccount()` unchanged.

- [ ] **Step 1: Write failing tests** (override `trackerControllerProvider` with a fake notifier recording `forget` calls): `signOut forgets tracker`; `expired does not`; `sign-in as same sub keeps`; `sign-in as other sub forgets`.
- [ ] **Step 2–4:** run `flutter test test/features/auth` FAIL → implement → PASS (existing auth tests still pass).
- [ ] **Step 5: Commit** `feat(tracker): only a deliberate sign-out ends tracking`.

### Task 8: Real location source, permissions, platform config

**Files:**
- Modify: `pubspec.yaml` (`flutter pub add geolocator path_provider`), `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `lib/app.dart` (call `resume()` once on start)
- Create: `lib/features/tracker/data/geolocator_source.dart`

**Interfaces:**
- Consumes: `LocationSource` (Task 6).
- Produces: `class GeolocatorSource implements LocationSource`, registered as the default of `locationSourceProvider`.
  - Android: `AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 10, intervalDuration: Duration(seconds: 10), foregroundNotificationConfig: ForegroundNotificationConfig(notificationTitle: 'Find Me đang ghi hành trình', notificationText: 'Chạm để mở', setOngoing: true))`.
  - iOS: `AppleSettings(accuracy: LocationAccuracy.medium /* ~100 m */, distanceFilter: 10, pauseLocationUpdatesAutomatically: true, allowBackgroundLocationUpdates: true, showBackgroundLocationIndicator: false, activityType: ActivityType.other)`.
  - `request()`: `requestPermission()`; if result is whileInUse, call it again (Android 10 / iOS escalate to Always; Android 11+ returns whileInUse → caller shows "open settings").
  - Drop fixes with `accuracy < 0` or lat/lon both 0 (server would drop them anyway; saves queue space).
- Android manifest: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`; geolocator's service with `android:foregroundServiceType="location"` (follow the geolocator README for the exact `<service>` override).
- iOS `Info.plist`: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription` (Vietnamese: why Find Me needs it), `UIBackgroundModes` = `[location]`.
- `POST_NOTIFICATIONS` is not requested at runtime: `// ponytail: Android 13+ hides the tracking notification until the user allows notifications; the service still runs. Request it if users miss the notification.`

- [ ] **Step 1:** `flutter pub add geolocator path_provider`; edit manifest + plist.
- [ ] **Step 2: Verify build:** `flutter build apk --flavor dev --debug --dart-define-from-file=config/example.json` → `✓ Built build\app\outputs\flutter-apk\app-dev-debug.apk`.
- [ ] **Step 3: Verify tests/analyze:** `flutter test`, `flutter analyze` → all pass, no issues.
- [ ] **Step 4: Commit** `feat(tracker): geolocator source and platform permissions`.

### Task 9: Tracker sheet (UI)

**Files:**
- Create: `lib/features/tracker/presentation/tracker_sheet.dart`
- Modify: `lib/features/trail/presentation/map_screen.dart` (a 📍 button next to the 👥 button at line ~96, opening `TrackerSheet.open(context)`; same pill style)
- Test: `test/features/tracker/presentation/tracker_sheet_test.dart`

**Interfaces:**
- Consumes: `trackerControllerProvider`, `formatRelative`-style helper from `lib/core/time/format.dart` (reuse what the trail panel uses for "x phút trước"; add one only if none exists).
- Produces: `class TrackerSheet extends ConsumerStatefulWidget { static Future<void> open(BuildContext) }` (bottom sheet like `FriendsSheet.open`).
  - Switch `Ghi hành trình`. First turn-on: disclosure dialog (`showDialog`), shown once (remember acceptance in `SharedPreferences` key `findme.trackerDisclosure`). Text must say: position is collected **in the background, even when the app is closed**; used to draw your trail and show it to friends/links you share; sent to the Find Me server. Buttons `Không` (stays off) / `Đồng ý` (→ `turnOn()`).
  - Status line per `TrackerProblem`: none+on → `Đang ghi`; off → `Đã tắt`; needAlways → `Thiếu quyền vị trí "Luôn luôn"` + button `Mở cài đặt` (`openSettings()`); badToken → `Token sai hoặc đã đổi`; noToken → `Chưa có token`.
  - Lines `Điểm chờ gửi: N`, `Gửi lần cuối: …` (`chưa` if null), `Điểm cuối: …`, `Điểm bị từ chối: N` (only if > 0, error colour), button `Gửi ngay` (disabled while `sending`).
  - Token field: `obscureText: true`, `autocorrect: false`, `enableSuggestions: false`, button `Lưu`; never pre-filled with the stored token (show `Đã lưu token` when one exists). Marked with the ponytail comment from Global Constraints.
  - Android only: hint `Nếu máy hay tắt ứng dụng, hãy tắt tối ưu pin cho Find Me.` + `Mở cài đặt`.

- [ ] **Step 1: Write failing widget tests** (override `trackerControllerProvider` with fixed states): each status line text; `Không` in disclosure keeps off and does not call `turnOn`; `Đồng ý` calls `turnOn`; `token field obscures input and is empty with a saved token`; `Gửi ngay calls sendNow`; rejected line hidden at 0.
- [ ] **Step 2–4:** run `flutter test test/features/tracker/presentation` FAIL → implement → PASS.
- [ ] **Step 5: Manual check on emulator:** `flutter run --flavor dev --dart-define-from-file=config/dev.json`; Extended controls → Location → load a GPX route; paste a test account's token; switch on; watch `Điểm chờ gửi` grow, `Gửi ngay` → 0, the 🐞 console shows `POST /ingest 200` with coordinates masked; points appear on the map of that account.
- [ ] **Step 6: Commit** `feat(tracker): tracker sheet`.

### Task 10: iOS significant-location relaunch

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`, `lib/features/tracker/presentation/tracker_controller.dart` (call the channel)
- Create: `lib/features/tracker/data/wake_channel.dart`
- Test: `test/features/tracker/data/wake_channel_test.dart`

**Interfaces:**
- Produces: method channel `findme/tracker`.
  - Dart → Swift: `startSignificant`, `stopSignificant` (called by `TrackerController` when turning on/off and in `resume()`; no-op on Android: guard with `defaultTargetPlatform == TargetPlatform.iOS`).
  - Swift → Dart: `wake` on every significant-change location → `TrackerController.wake()`.
  - `class WakeChannel { Future<void> start(); Future<void> stop(); void onWake(void Function() f); }` + `wakeChannelProvider`; tests mock it.
- Swift: a `CLLocationManager` held by `AppDelegate`, delegate forwards `didUpdateLocations` as `wake`. Register the channel in `didInitializeImplicitFlutterEngine` (the engine's binary messenger from `engineBridge`). If launched with `launchOptions[.location]`, call `startMonitoringSignificantLocationChanges()` right away (Apple requires restarting it on relaunch).
- Before writing Swift, read: Apple "Handling location updates in the background" and the `FlutterImplicitEngineBridge` API in the Flutter version installed (`C:\src\flutter`).

- [ ] **Step 1: Write failing test**: `TrackerController` calls `WakeChannel.start` on `turnOn` success and `stop` on `turnOff`; a `wake` callback re-subscribes to `fixes()` when on. (Add to the Task 6 test file or this one.)
- [ ] **Step 2–4:** run `flutter test test/features/tracker` FAIL → implement Dart + Swift → PASS.
- [ ] **Step 5: Verify iOS build in CI:** push the branch; the macOS job (`.github/workflows`, guide chapter 12) builds `Runner` → green. Unverified on device until the owner's iPhone test (guide chapter 15 lists the steps).
- [ ] **Step 6: Commit** `feat(tracker): iOS significant-location relaunch`.

### Task 11: Android reboot restart

**Files:**
- Create: `android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt`
- Modify: `android/app/src/main/AndroidManifest.xml` (receiver for `BOOT_COMPLETED`, `exported="false"`), `lib/main.dart` (add `@pragma('vm:entry-point') Future<void> trackerBoot()`)

**Interfaces:**
- `BootReceiver.onReceive`: read `getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE).getBoolean("flutter.findme.tracking", false)`; if true, create a `FlutterEngine(context)` and run Dart entrypoint `trackerBoot` (`DartExecutor.DartEntrypoint(FlutterInjector.instance().flutterLoader().findAppBundlePath(), "trackerBoot")`), keep it in `FlutterEngineCache` under `"tracker"` so it is not collected.
- `trackerBoot()`: `WidgetsFlutterBinding.ensureInitialized()`, build `ProviderContainer(overrides: [appConfigProvider.overrideWithValue(AppConfig.fromEnvironment())])`, `await container.read(trackerControllerProvider.notifier).resume()`. No `runApp`.
- **Spike first (≤ 1 h):** check that geolocator's foreground service starts from this headless engine after a reboot on the emulator (API 35). If it does not, fallback instead: the receiver posts a notification `Chạm để tiếp tục ghi hành trình` that opens the app (whose start calls `resume()`). Record which one shipped in the guide and HANDOFF.

- [ ] **Step 1: Spike** on emulator: switch on, `adb reboot`, wait, check the tracking notification is back and `Điểm chờ gửi` grows (or the fallback notification appears).
- [ ] **Step 2: Implement** the variant that worked.
- [ ] **Step 3: Verify:** `flutter build apk --flavor dev --debug --dart-define-from-file=config/example.json` succeeds; reboot test passes on the emulator; `flutter test` and `flutter analyze` clean.
- [ ] **Step 4: Commit** `feat(tracker): restart tracking after Android reboot`.

### Task 12: Guide chapter 15, Play Store prep, handoff

**Files:**
- Create: `docs/guide/15-background-tracking.md`, `docs/guide/play-store-location.md` (draft privacy policy text + Data safety answers + background-location declaration text + what the demo video shows)
- Modify: `docs/guide/README.md` (row 15), `docs/guide/cheatsheet.md`, `docs/HANDOFF.md`, `CLAUDE.md` (feature list: add `tracker`)

**Interfaces:** none (docs). Chapter layout = existing chapters (`What and why`, `Code`, `Run`, `Look`, `Test`, `Troubleshooting`, `Revision notes` with self-check). Must teach every point listed in spec §2 "A learning chapter". Include: emulator GPX route steps, `adb reboot` test, iPhone test steps (sideload build, switch on, walk, leave app in background for hours, check points), Android battery-optimisation steps, platform limits from spec §5, how to switch an account from Overland to Find Me (same account later: uninstall Overland first).

- [ ] **Step 1:** Write the docs.
- [ ] **Step 2: Verify:** every command in the chapter runs as written in PowerShell (run the non-device ones); links resolve.
- [ ] **Step 3: Commit** `docs(ch15): background tracking, Play Store location prep`.
