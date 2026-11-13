# Trip mode, phone side (Android first) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trip-mode accounts record only during a timed trip started from the app, a Quick Settings tile or the home
widget; the trip ends by itself on its timer; friends' prints from before their trip are dropped.

**Architecture:** The tracker (`TrackerController`) stays the one recorder and gains the trip: it keeps the sharing
mode and the end time in `TrackerStore`, calls `PUT /me/sharing` around `turnOn`/`turnOff`, and checks the end time on
every fix, resume, wake, upload tick and alarm. A Dart `TripChannel` (`findme/trip`) tells Kotlin the end time; Kotlin
sets an AlarmManager alarm and refreshes the tile and the widget. Tile and widget send `toggle` to the running engine,
or start a screenless engine on the `tripCommand` entrypoint.

**Tech Stack:** Flutter 3.47, Riverpod 3, freezed, shared_preferences, Kotlin (TileService, AlarmManager, RemoteViews).

**Spec:** `travel-heatmap/docs/superpowers/specs/2026-11-13-trip-mode-design.md` (sections "Phone app", "Open screens
drop a finished trip"); server API: `travel-heatmap/docs/guide/22-trip-mode.md`.

## Global Constraints

- `GET /me` adds `sharing` (`'always'|'trip'`), `trip` (bool), `tripFrom`, `tripUntil` (ISO or null). Absent `sharing`
  (server not deployed) = no trip UI at all, tracker exactly as today.
- `PUT /me/sharing` bodies: `{mode: 'always'|'trip'}`, `{start: '15m'|'1h'|'tonight'|'open'}`, `{end: true}`; answers
  the same four fields.
- `/ingest` 200 `{result: 'ok', trip: false}` = stored, no trip on → tracker off.
- Preset labels: "15 phút", "1 giờ", "đến tối nay", "đến khi tắt"; first-time preset "1 giờ". "tonight" = 23:59:59
  Vietnam (UTC+7) today.
- Copy (from the spec / web): "Bắt đầu chuyến đi", "Kết thúc", "Đang đi · còn 42 phút", "Luôn bật", "Chỉ khi đi",
  "Không trong chuyến đi", "không trong chuyến đi" (friend row), "Chỉ ghi và chia sẻ khi bạn bắt đầu chuyến đi trong
  app Find Me.", "Luôn ghi và chia sẻ vị trí."
- No notification "Kết thúc" action (deferred). Always-on accounts: no tile/widget trip button behaviour change beyond
  "unavailable"/hidden.
- Never log coordinates or tokens; tests never touch the network.

## Review Focus

- Tile/widget tapped while the app's engine runs → command must reach that engine, never a second engine (two engines
  write one queue). Pinned in Task 5 by Kotlin structure (engine cache lookup first); device check.
- Trip ended on the web while the phone records → next upload's `trip: false` turns the tracker off (Task 2 test).
- Offline start → tracker runs with a local end time, `PUT {start}` retried before the next upload, uploads wait for it
  (Task 3 test "offline start retries the PUT before uploading").
- Fix arriving after the end time → dropped, tracker off (Task 3 test).
- Phone reopened after the trip ended elsewhere → `GET /me` with `trip: false` turns the tracker off (Task 3 test).

---

### Task 1: Trip domain + friend store cut

**Files:**
- Create: `lib/features/tracker/domain/trip.dart`, `test/features/tracker/domain/trip_test.dart`
- Modify: `lib/features/trail/domain/models.dart` (`FriendPart` + `trip`, `visibleFrom`),
  `lib/features/trail/domain/trail_math.dart` (`friendMerge`), `lib/features/friends/domain/friend_models.dart`
  (`Friend.trip`), `lib/features/friends/presentation/friends_sheet.dart` (subtitle)
- Test: `test/features/trail/domain/trail_math_test.dart`, `test/features/friends/presentation/friends_sheet_test.dart`

**Interfaces — Produces:**
- `enum TripPreset { m15, h1, tonight, open }` with `String get key` (`'15m'`…) and `String get label`;
  `TripPreset? presetOf(String? key)`.
- `typedef Sharing = ({bool tripMode, bool on, DateTime? until});` `Sharing? sharingFromJson(Map<String, dynamic> j)`
  (null when `sharing` is absent).
- `DateTime? localEnd(TripPreset p, DateTime now)` (offline start), `bool tripOver(DateTime? until, DateTime now)`,
  `String tripLeft(DateTime? until, DateTime now)` → `'còn 42 phút'`, `'còn 1 giờ 5 phút'`, `'đến khi tắt'`.
- `FriendPart.trip` (`bool?`), `FriendPart.visibleFrom` (`String?`); `Friend.trip` (`bool?`).

- [ ] Tests: `localEnd(tonight, 2026-11-13T10:00Z)` = `2026-11-13T16:59:59Z`; `localEnd(open)` null; `tripOver(null, …)`
  false; `tripLeft` wording; `sharingFromJson({})` null; `friendMerge` port of the web: `trip: false` → no points, no
  last; prints and `last` before `visibleFrom` dropped; `unchanged` keeps prev. Friend row with `trip: false` reads
  "không trong chuyến đi".
- [ ] Implement; `dart run build_runner build -d` for `Friend`.
- [ ] `flutter test test/features/tracker/domain test/features/trail test/features/friends` passes; commit.

### Task 2: API: sharing calls and ingest `trip: false`

**Files:**
- Modify: `lib/features/friends/data/friends_repository.dart`, `lib/features/tracker/data/ingest_client.dart`
- Test: `test/features/friends/data/friends_repository_test.dart`, `test/features/tracker/data/ingest_client_test.dart`

**Interfaces — Produces:**
- `FriendsRepository.sharing() → Future<Sharing?>` (`GET /me`), `setSharing(Map<String, Object> body) →
  Future<Sharing?>` (`PUT /me/sharing`).
- `IngestResult.tripOver`: 200 `result: 'ok'` with `trip == false` (stored; caller commits the batch, then stops).

- [ ] Tests for both calls (method, path, body, parse) and the new ingest result; implement; commit.

### Task 3: Tracker drives the trip

**Files:**
- Create: `lib/features/tracker/data/trip_channel.dart`
- Modify: `lib/features/tracker/data/tracker_store.dart`, `lib/features/tracker/presentation/tracker_controller.dart`,
  `test/helpers/tracker_fakes.dart`, `test/helpers/fakes.dart`
- Test: `test/features/tracker/presentation/tracker_controller_test.dart` (new `group('trip')`),
  `test/features/tracker/data/tracker_store_test.dart`

**Interfaces — Produces:**
- `TrackerStore`: `sharingMode()`/`setSharingMode(String?)` (prefs `findme.sharing`, read natively as
  `flutter.findme.sharing`), `tripUntil()`/`setTripUntil(DateTime?)` (`findme.tripUntil`, epoch ms),
  `lastPreset()`/`setLastPreset(TripPreset)` (`findme.tripPreset`, kept by `forget`), `tripPending()`/
  `setTripPending(String?)` (`findme.tripPending`: a preset key or `'end'`). `forget()` clears all but the preset.
- `TripChannel` (`findme/trip`, Android only): `sync(DateTime? until)` (Kotlin sets/cancels the alarm, refreshes tile
  and widget), `onCommand(void Function(String) f)` (`toggle`, `expire`, `picker`), `takePicker() → Future<bool>`.
  `tripChannelProvider`.
- `TrackerState`: `String? sharing` (`'always'|'trip'|null`), `DateTime? tripUntil`; `bool get tripMode`.
- `TrackerController`: `startTrip(TripPreset p)`, `endTrip()`, `setMode({required bool trip})`, `syncTrip()` (GET /me,
  run by `resume()` and on app resume), `toggleTrip()`; private `_expired()` check.

Rules:
- `startTrip`: GPS access first (`request()`; not always → `needAlways`, nothing sent); `sendNow()` best effort (10 s);
  `PUT {start}` → until from the answer, else `localEnd` + pending key; save until; `turnOn()`; `sync(until)`.
- `endTrip`: `turnOff()`; `sendNow()` best effort; `PUT {end}` else pending `'end'`.
- `turnOff` clears `tripUntil` and calls `sync(null)`.
- Every upload run first flushes a pending PUT; if that fails, it uploads nothing this run.
- `_onFix`, `resume`, `wake`, the upload tick and `expire`: past `tripUntil` → `turnOff()`, fix dropped.
- `IngestResult.tripOver` → commit, then `turnOff()` (only when `state.tripMode`).
- `syncTrip`: flush pending; `GET /me`; save mode; trip mode and no trip → `turnOff()` if on; trip on → keep the
  server's until (sync). Errors ignored (offline).
- `setMode(trip: true)` → `turnOff()` (server leaves no trip on); `setMode(trip: false)` → keep recording, clear until.

- [ ] Tests (fake channel, `MockFriends`): start sends `{start: '1h'}` and turns on with the answer's until; fix after
  until dropped + off; `IngestResult.tripOver` → off; offline start retries the PUT before uploading; resume with
  server `trip: false` turns off; end sends `{end: true}`; always-on account never stops on a fix.
- [ ] Implement; full `flutter test test/features/tracker` passes; commit.

### Task 4: Trip UI (tracker sheet, account sheet, app resume, picker)

**Files:**
- Modify: `lib/features/tracker/presentation/tracker_sheet.dart`, `lib/features/auth/presentation/account_sheet.dart`,
  `lib/features/trail/presentation/map_screen.dart` (resume → `syncTrip`; `TripChannel` `picker` → open sheet)
- Test: `test/features/tracker/presentation/tracker_sheet_test.dart`, `test/features/auth/presentation/account_sheet_test.dart`

- [ ] Trip-mode sheet: no switch; "Bắt đầu chuyến đi" + four preset pills (disclosure dialog first, as today); while on
  "Đang đi · còn …" + "Kết thúc". Account sheet: "Luôn bật"/"Chỉ khi đi" pills + the notice, only when `sharing` known.
- [ ] Widget tests for both; commit.

### Task 5: Android: tile, widget button, alarm, headless entrypoint

**Files:**
- Create: `android/.../TripBridge.kt` (channel, alarm, engine lookup / headless start, refresh tile + widget),
  `android/.../TripTileService.kt`, `android/.../TripReceiver.kt` (widget button + alarm), drawable `ic_trip.xml`
- Modify: `MainActivity.kt` (attach channel; tile long-press intent → picker), `BootReceiver.kt` (attach channel),
  `TrailWidgetProvider.kt` + `trail_widget.xml` (⏺/⏹ button, only in trip mode), `AndroidManifest.xml`,
  `lib/main.dart` (`tripCommand(List<String> args)` entrypoint)

- [ ] Kotlin: command goes to the cached app engine, else the boot engine, else a new engine on `tripCommand` with
  args `[cmd]` (cached under `BootReceiver.ENGINE`). Headless only when background location is granted and the
  disclosure was accepted; otherwise open the app on the picker. Alarm: `setAndAllowWhileIdle` (no exact-alarm
  permission). `ponytail:` inexact alarm, up to ~10 min late in doze; the server window is exact anyway.
- [ ] `flutter build apk --flavor dev --debug --dart-define-from-file=config/example.json` builds; on the emulator if
  available: tile tap starts/ends, widget button, alarm stops GPS.
- [ ] Commit.

### Task 6: Docs

- [ ] Guide chapter 19 (trip mode, phone), README index, cheatsheet lines, `docs/HANDOFF.md` entry; travel-heatmap
  HANDOFF trip-mode line. Commit.
