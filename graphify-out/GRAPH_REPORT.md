# Graph Report - findme  (2026-11-25)

## Corpus Check
- 215 files · ~140,573 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 41 file(s) not represented in the graph (top: .xml 15, (none) 5, .plist 5)

## Summary
- 2971 nodes · 4499 edges · 172 communities (152 shown, 20 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9d883734`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- models.dart
- friend_models.dart
- debug_log.dart
- tracker_fakes.dart
- map_view.dart
- replay_controller.dart
- pins_repository.dart
- tracker_controller.dart
- pin.dart
- shares_sheet.dart
- app_errors.dart
- share.dart
- fakes.dart
- trail_math.dart
- bag_editor.dart
- with
- tracker_controller_test.dart
- AppDelegate
- ingest_client.dart
- avatar_crop.dart
- bag_widgets.dart
- dependencies
- pin_sheet.dart
- card_box.dart
- paw_layer.dart
- bag.dart
- pins_ui_test.dart
- date_range.dart
- tile_math.dart
- pins_repository_test.dart
- widget_updater_test.dart
- trail_controller.dart
- auth_controller.dart
- tracker_store.dart
- trail_widget.dart
- map_screen.dart
- render.dart
- friends_controller.dart
- friends_sheet.dart
- bag_repository.dart
- bag_sheet.dart
- add_pin_sheet.dart
- replay_bar.dart
- package:findme/features/auth/presentation/auth_controller.dart
- debug_console.dart
- hachiware.dart
- widget_updater.dart
- tile_cache.dart
- render.dart
- client_files.dart
- auth_repository_test.dart
- format.dart
- palette.dart
- welcome_screen.dart
- point_queue.dart
- BootReceiver.kt
- SpikeEntry
- session_store.dart
- List
- friendsControllerProvider
- trail_sheet.dart
- file_day_log.dart
- trail_controller_test.dart
- auth_repository_test.dart
- pins_controller.dart
- colors.dart
- tile_cache_test.dart
- shares_sheet_test.dart
- day_log.dart
- TrailWidgetProvider.kt
- fix.dart
- trip.dart
- authControllerProvider
- top_bar.dart
- ../../../helpers/fakes.dart
- TripBridge
- live_trail_widget.dart
- pill.dart
- prefs.dart
- package:findme/features/tracker/domain/fix.dart
- rules
- Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)
- geolocator_source_test.dart
- home_widget_host.dart
- package:findme/features/trail/domain/colors.dart
- fake_adapter.dart
- package:flutter/material.dart
- package:findme/core/config/app_config.dart
- bag_icons.dart
- tracker_sheet.dart
- package:flutter_test/flutter_test.dart
- package:findme/features/auth/data/session_store.dart
- upload_policy.dart
- TripTileService
- package:findme/core/theme/palette.dart
- Cheatsheet
- dart:convert
- Share
- _HachiwareState
- location_source.dart
- guide/README.md
- Review Focus
- freezed
- File Structure
- Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish
- Find Me mobile app (Flutter): design
- AppDelegate.swift
- friends_controller_test.dart
- Review Focus
- Find Me tracker (replaces Overland): design
- Review Focus
- Home-screen widget: where I am now
- version.dart
- package:findme/features/pins/domain/pin.dart
- Find Me tracker (replaces Overland): built, final-review fixes half done
- 04. Sign-in (Cognito) and secure storage
- MainActivity.kt
- 01. Install the tools on Windows
- hachiware_test.dart
- Review Focus
- 02. Running the app
- Chapter 16: Photo pins
- trip_channel.dart
- 14. Store accounts and app IDs (Apple and Google)
- date_filter.dart
- 15. Background tracking (Find Me replaces Overland)
- package:flutter/foundation.dart
- dart:ui
- Google Play: background location (drafts)
- trail_painting.dart
- 05. The map and paw prints
- 10. Testing
- 13. Later: iOS without a Mac, signing, App Store and Play Store
- 1. What and why
- 1. What and why
- 03. Project structure
- Chapter 18: The bag and your avatar
- CLAUDE.md
- 00. Flutter for web developers
- 11. Code generation, lints, formatting
- 12. CI with GitHub Actions
- 06. Date filter and live refresh
- 08. Replay
- 09. Share links and friends
- tracker_store_test.dart
- LaunchImage.imageset/README.md
- authControllerProvider
- Chapter 20: Live positions over MQTT
- Live positions over MQTT, phone side: design
- .onReceive
- ConsumerState
- Chapter 19: Trip mode
- live_sender_test.dart
- dart:math
- TrackerController
- wakeChannelProvider
- upload_policy_test.dart
- tracker_store_test.dart
- DebugEntry
- idle
- DebugLog
- DebugHttpLog

## God Nodes (most connected - your core abstractions)
1. `dependencies` - 21 edges
2. `authControllerProvider` - 20 edges
3. `Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)` - 20 edges
4. `Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish` - 19 edges
5. `TrackerController` - 18 edges
6. `signedInProvider` - 16 edges
7. `trackerControllerProvider` - 16 edges
8. `Cheatsheet` - 16 edges
9. `File Structure` - 16 edges
10. `friendsControllerProvider` - 15 edges

## Surprising Connections (you probably didn't know these)
- `The two Android pieces` --references--> `BootReceiver`  [INFERRED]
  docs/guide/17-home-screen-widget.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `How it gets made` --references--> `BootReceiver`  [INFERRED]
  docs/superpowers/specs/2026-11-09-home-widget-design.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `Where We're Going` --references--> `BootReceiver`  [INFERRED]
  plans/handoffs/HANDOFF_findme-tracker_device-fixes_2026-11-06.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `First native code: how Dart and Swift / Kotlin talk` --references--> `MainActivity`  [INFERRED]
  docs/guide/15-background-tracking.md → android/app/src/main/kotlin/app/findme/findme/MainActivity.kt
- `Where things stand` --references--> `FindMeWidget`  [INFERRED]
  docs/HANDOFF.md → ios/FindMeWidget/FindMeWidget.swift

## Import Cycles
- None detected.

## Communities (172 total, 20 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.06
Nodes (43): class, hash, identical, null, orElse, _self, _stops, _that (+35 more)

### Community 1 - "friend_models.dart"
Cohesion: 0.12
Nodes (30): _, avatar, class, friends, hash, id, identical, _incoming (+22 more)

### Community 2 - "debug_log.dart"
Cohesion: 0.05
Nodes (40): add, appDio, at, clear, _code, _cut, debugConsoleEnabled, error (+32 more)

### Community 3 - "tracker_fakes.dart"
Cohesion: 0.03
Nodes (78): accept, access, afterRequest, body, build, calls, connect, connects (+70 more)

### Community 4 - "map_view.dart"
Cohesion: 0.05
Nodes (39): avatar, build, clock, color, createState, didUpdateWidget, dispose, _fitted (+31 more)

### Community 5 - "replay_controller.dart"
Cohesion: 0.08
Nodes (21): build, clock, clockAt, copyWith, cycleSpeed, finish, own, playing (+13 more)

### Community 6 - "pins_repository.dart"
Cohesion: 0.04
Nodes (49): _api, _call, _cfg, _chunk, _clientOn, _clientStrike, _clientStrikes, _cookie (+41 more)

### Community 7 - "tracker_controller.dart"
Cohesion: 0.03
Nodes (56): _apply, _command, copyWith, endTrip, _expired, _failed, _failures, _fixes (+48 more)

### Community 8 - "pin.dart"
Cohesion: 0.05
Nodes (39): best, bestM, Bubble, _cellPx, cells, count, createdAt, d (+31 more)

### Community 9 - "shares_sheet.dart"
Cohesion: 0.05
Nodes (37): _bag, _bagOk, build, _busy, _create, createState, _custom, dispose (+29 more)

### Community 10 - "app_errors.dart"
Cohesion: 0.06
Nodes (38): AccountMissing, ApiStatus, AppError, AuthError, AuthExpired, body, code, detail (+30 more)

### Community 11 - "share.dart"
Cohesion: 0.13
Nodes (24): bag, class, hash, id, identical, null, operator, orElse (+16 more)

### Community 12 - "fakes.dart"
Cohesion: 0.06
Nodes (24): MockBag, a, baseOverrides, clear, clearToday, f, fakeAuth, MockAuth (+16 more)

### Community 13 - "trail_math.dart"
Cohesion: 0.05
Nodes (39): a, at, b, base, byName, cursor, end, f (+31 more)

### Community 14 - "bag_editor.dart"
Cohesion: 0.06
Nodes (32): _back, BagEditor, _BagEditorState, _busy, createState, _dirty, dispose, _draft (+24 more)

### Community 15 - "with"
Cohesion: 0.07
Nodes (31): env, name, runs-on, steps, CFG, TZ, if, name (+23 more)

### Community 16 - "tracker_controller_test.dart"
Cohesion: 0.06
Nodes (33): answer, base, c, clear, clears, ctl, dir, emit (+25 more)

### Community 17 - "AppDelegate"
Cohesion: 0.19
Nodes (4): 2. Code, First native code: how Dart and Swift / Kotlin talk, Task 10: iOS significant-location relaunch, AppDelegate

### Community 18 - "ingest_client.dart"
Cohesion: 0.09
Nodes (17): apiClientProvider, auth, answer, _api, deleteMe, FriendsRepository, me, _one (+9 more)

### Community 19 - "avatar_crop.dart"
Cohesion: 0.09
Nodes (22): bagRepositoryProvider, AvatarCrop, _AvatarCropState, _busy, c, _clear, createState, _CropPainter (+14 more)

### Community 20 - "bag_widgets.dart"
Cohesion: 0.07
Nodes (27): _avatarBg, _bagBody, bagCream, bagInk, _bagRim, _bagShape, border, borderWidth (+19 more)

### Community 21 - "dependencies"
Cohesion: 0.05
Nodes (41): dependencies, battery_plus, dio, flutter, flutter_image_compress, flutter_map, flutter_riverpod, flutter_secure_storage (+33 more)

### Community 22 - "pin_sheet.dart"
Cohesion: 0.06
Nodes (28): _act, by, _c, child, createState, dispose, _err, _failed (+20 more)

### Community 23 - "card_box.dart"
Cohesion: 0.14
Nodes (10): base, buildTheme, copyWith, build, CardBox, child, error, Notice (+2 more)

### Community 24 - "paw_layer.dart"
Cohesion: 0.13
Nodes (13): best, bestD, build, camera, color, maxPx, nearestPrint, paint (+5 more)

### Community 25 - "bag.dart"
Cohesion: 0.08
Nodes (25): avatarPath, canAdd, clamp, copyWith, cropSquare, fromJson, href, image (+17 more)

### Community 26 - "pins_ui_test.dart"
Cohesion: 0.07
Nodes (25): PinInput, FixDenied, FixFailed, FixOk, asked, askPermission, at, build (+17 more)

### Community 27 - "date_range.dart"
Cohesion: 0.08
Nodes (25): a, b, contains, customRange, f, from, hashCode, isLive (+17 more)

### Community 28 - "tile_math.dart"
Cohesion: 0.08
Nodes (24): cx, cy, half, hashCode, operator, sizePx, t, tileRect (+16 more)

### Community 29 - "pins_repository_test.dart"
Cohesion: 0.08
Nodes (24): api, bodies, calls, close, cookieOk, count, dio, down (+16 more)

### Community 30 - "widget_updater_test.dart"
Cohesion: 0.08
Nodes (22): append, base, clear, clears, days, failAppend, failPublish, failRender (+14 more)

### Community 31 - "trail_controller.dart"
Cohesion: 0.08
Nodes (23): copyWith, error, _friends, go, load, loading, _now, _paused (+15 more)

### Community 32 - "auth_controller.dart"
Cohesion: 0.17
Nodes (16): prefsProvider, authRepositoryProvider, AuthController, AuthPhase, build, expired, noAccount, signIn (+8 more)

### Community 33 - "tracker_store.dart"
Cohesion: 0.06
Nodes (32): _cached, enabled, forget, indicator, _indicatorKey, lastPreset, _onKey, owner (+24 more)

### Community 34 - "trail_widget.dart"
Cohesion: 0.09
Nodes (21): Fix, FriendPart, TrackAnswer, TrackPoint, TileKey, clear, days, here (+13 more)

### Community 35 - "map_screen.dart"
Cohesion: 0.15
Nodes (9): Spot, _adding, _closeSheets, createState, dispose, _life, _openPinId, showTiles (+1 more)

### Community 36 - "render.dart"
Cohesion: 0.11
Nodes (14): area, bytes, canvas, cat, _decode, _hachiwareHeight, here, image (+6 more)

### Community 37 - "friends_controller.dart"
Cohesion: 0.07
Nodes (29): build, _delete, authControllerProvider, _signedOut, friendsRepositoryProvider, answer, apply, ask (+21 more)

### Community 38 - "friends_sheet.dart"
Cohesion: 0.13
Nodes (13): actions, _busy, _code, _confirm, createState, dispose, _err, lead (+5 more)

### Community 39 - "bag_repository.dart"
Cohesion: 0.07
Nodes (24): _api, BagRepository, cardErrorText, delay, deleteCard, freshReceipts, friendBag, hashCode (+16 more)

### Community 40 - "bag_sheet.dart"
Cohesion: 0.11
Nodes (19): build, BagItem, Slots, BagSheet, _BagSheetState, color, createState, _failed (+11 more)

### Community 41 - "add_pin_sheet.dart"
Cohesion: 0.11
Nodes (18): AddPinSheet, _AddPinSheetState, build, createState, dispose, _err, _fix, initState (+10 more)

### Community 42 - "replay_bar.dart"
Cohesion: 0.13
Nodes (13): build, createState, didChangeDependencies, dispose, initState, _prev, ReplayBar, _ReplayBarState (+5 more)

### Community 43 - "package:findme/features/auth/presentation/auth_controller.dart"
Cohesion: 0.12
Nodes (13): bob, c, main, prefs, rel, repo, s, start (+5 more)

### Community 44 - "debug_console.dart"
Cohesion: 0.11
Nodes (16): _at, _block, build, child, createState, _Env, _errorRow, _hms (+8 more)

### Community 45 - "hachiware.dart"
Cohesion: 0.10
Nodes (19): a, b, build, createState, didChangeDependencies, dispose, f, Fade (+11 more)

### Community 46 - "widget_updater.dart"
Cohesion: 0.10
Nodes (19): clear, _closed, _dirty, _draw, _drawing, _drawnAt, _generation, _log (+11 more)

### Community 47 - "tile_cache.dart"
Cohesion: 0.11
Nodes (15): client, _dir, _failedAt, _fetch, fetchOsmTile, _file, _freshFor, maxFiles (+7 more)

### Community 48 - "render.dart"
Cohesion: 0.13
Nodes (14): codec, data, decode, fromARGB, here, image, main, o (+6 more)

### Community 49 - "client_files.dart"
Cohesion: 0.08
Nodes (24): blur, ClientEncoder, ClientFiles, d, display, displayEdge, _displayMaxBytes, displaySize (+16 more)

### Community 50 - "auth_repository_test.dart"
Cohesion: 0.11
Nodes (17): _api, AuthRepository, cfg, _cid, confirmSignUp, _fromResult, getAccessToken, login (+9 more)

### Community 51 - "format.dart"
Cohesion: 0.12
Nodes (16): ago, d, dayMonth, dm, duration, h, hhmm, hhmmIso (+8 more)

### Community 52 - "palette.dart"
Cohesion: 0.18
Nodes (10): card, error, ink, lavender, muted, page, Palette, pink (+2 more)

### Community 53 - "welcome_screen.dart"
Cohesion: 0.11
Nodes (18): _busy, _code, createState, dispose, _email, _err, _go, _invite (+10 more)

### Community 54 - "point_queue.dart"
Cohesion: 0.12
Nodes (16): append, clear, commit, count, create, dir, _drop, _endsMidLine (+8 more)

### Community 55 - "BootReceiver.kt"
Cohesion: 0.24
Nodes (5): BootReceiver, The two Android pieces, Task 11: Android reboot restart, How it gets made, Where We're Going

### Community 56 - "SpikeEntry"
Cohesion: 0.11
Nodes (11): describe(), FindMeWidget, .body, grantedGroups(), SpikeEntry, SpikeProvider, SpikeView, .body (+3 more)

### Community 57 - "session_store.dart"
Cohesion: 0.13
Nodes (14): access, expiresAt, fromJson, _key, load, refresh, save, SecureSessionStore (+6 more)

### Community 58 - "List"
Cohesion: 0.11
Nodes (20): build, signedInProvider, build, build, friendCountProvider, FriendPinsController, friendPinsRefresh, grantDue (+12 more)

### Community 59 - "friendsControllerProvider"
Cohesion: 0.12
Nodes (31): FindMeApp, _FindMeAppState, initState, AccountSheet, _AccountSheetState, build, build, friendsControllerProvider (+23 more)

### Community 60 - "trail_sheet.dart"
Cohesion: 0.07
Nodes (28): _Centered, BagGrid, BagHead, Initial, Pocket, PocketGrid, _Row, _Cell (+20 more)

### Community 61 - "file_day_log.dart"
Cohesion: 0.14
Nodes (10): append, clear, _day, _dir, _last, _parse, read, _readLast (+2 more)

### Community 62 - "trail_controller_test.dart"
Cohesion: 0.18
Nodes (10): asked, c, ctl, jwt, main, now, repo, start (+2 more)

### Community 63 - "auth_repository_test.dart"
Cohesion: 0.12
Nodes (15): adapter, answer, api, cfg, fail, load, main, ok (+7 more)

### Community 64 - "pins_controller.dart"
Cohesion: 0.10
Nodes (19): ask, askPermission, currentFix, deadline, _files, GeoApi, image, _paused (+11 more)

### Community 65 - "colors.dart"
Cohesion: 0.11
Nodes (14): atan2, bearing, distanceM, dLat, dLon, dx, dy, friendColor (+6 more)

### Community 66 - "tile_cache_test.dart"
Cohesion: 0.13
Nodes (13): a, answer, b, c, cache, dir, fetch, fetches (+5 more)

### Community 67 - "shares_sheet_test.dart"
Cohesion: 0.20
Nodes (7): clipboard, live, main, now, old, pump, repo

### Community 68 - "day_log.dart"
Cohesion: 0.15
Nodes (12): FileDayLog, append, clear, DayLog, DayTrail, last, read, sameLocalDay (+4 more)

### Community 70 - "fix.dart"
Cohesion: 0.15
Nodes (10): acc, at, deviceIdForPlatform, fromJson, hashCode, lat, lon, operator (+2 more)

### Community 71 - "trip.dart"
Cohesion: 0.12
Nodes (15): key, label, localEnd, m, null, presetOf, rest, s (+7 more)

### Community 72 - "authControllerProvider"
Cohesion: 0.06
Nodes (31): _c, connect, disconnect, _dropped, _first, _gap, _gen, _later (+23 more)

### Community 73 - "top_bar.dart"
Cohesion: 0.15
Nodes (10): _clock, createState, _disclosed, _disclosure, _disclosureKey, dispose, initState, open (+2 more)

### Community 74 - "../../../helpers/fakes.dart"
Cohesion: 0.11
Nodes (12): confirmWith, main, pump, repo, tracker, main, gps, main (+4 more)

### Community 76 - "live_trail_widget.dart"
Cohesion: 0.07
Nodes (18): main, main, picture, asset, create, dir, hachiware, _iosSpike (+10 more)

### Community 77 - "pill.dart"
Cohesion: 0.17
Nodes (9): badge, build, label, onTap, Pill, PillStyle, selected, semanticLabel (+1 more)

### Community 78 - "prefs.dart"
Cohesion: 0.12
Nodes (17): clear, clearToday, _last, _p, Prefs, readToday, rememberStart, round4 (+9 more)

### Community 79 - "package:findme/features/tracker/domain/fix.dart"
Cohesion: 0.25
Nodes (5): PointQueue, dir, fx, main, q

### Community 80 - "rules"
Cohesion: 0.18
Nodes (10): analyzer, exclude, include, linter, rules, avoid_catching_errors, cascade_invocations, lines_longer_than_80_chars (+2 more)

### Community 81 - "Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)"
Cohesion: 0.06
Nodes (31): CI failures (owner-pasted logs), Code Analysis, Commit log, Config / platform / CI, Dependencies (pubspec.yaml), Docs, Environment facts, Evidence & Data (+23 more)

### Community 82 - "geolocator_source_test.dart"
Cohesion: 0.11
Nodes (13): access, fixes, _map, openSettings, request, _settings, checkPermission, FakeGeolocator (+5 more)

### Community 83 - "home_widget_host.dart"
Cohesion: 0.14
Nodes (11): clear, HomeWidgetHost, _lastFixKey, _png, _pngKey, _provider, publish, refreshLabel (+3 more)

### Community 84 - "package:findme/features/trail/domain/colors.dart"
Cohesion: 0.29
Nodes (6): advance, _minMs, _msPerPrint, nextSpeed, replayMs, speeds

### Community 85 - "fake_adapter.dart"
Cohesion: 0.18
Nodes (10): calls, close, contentType, fakeDio, fetch, offline, Reply, requests (+2 more)

### Community 86 - "package:flutter/material.dart"
Cohesion: 0.17
Nodes (6): main, main, _scoped, settle, main, of

### Community 87 - "package:findme/core/config/app_config.dart"
Cohesion: 0.08
Nodes (21): AppConfig, ApiClient, _cfg, _dio, send, _token, TokenGetter, call (+13 more)

### Community 88 - "bag_icons.dart"
Cohesion: 0.13
Nodes (10): ItemType, BagIcon, build, _icons, _ink, _s, size, type (+2 more)

### Community 89 - "tracker_sheet.dart"
Cohesion: 0.20
Nodes (11): appConfigProvider, DebugSheet, WelcomeScreen, _form, BagFull, build, AvatarCircle, build (+3 more)

### Community 90 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.17
Nodes (7): _bubble, pins, _Waiting, host, main, pts, stop

### Community 92 - "upload_policy.dart"
Cohesion: 0.15
Nodes (11): backoff, every, m, maxAccuracyM, maxBatch, minMoveM, movingEvery, shouldUpload (+3 more)

### Community 94 - "package:findme/core/theme/palette.dart"
Cohesion: 0.09
Nodes (11): ConfigErrorApp, createState, message, _navigator, showTiles, main, app, main (+3 more)

### Community 95 - "Cheatsheet"
Cohesion: 0.11
Nodes (17): Bag and avatar (chapter 18), Cheatsheet, Config keys (`config/dev.json`, `config/prod.json`), Flavors, Git and CI, Home-screen widget (chapter 17), Live positions (chapter 20), Photo pins (chapter 16) (+9 more)

### Community 96 - "dart:convert"
Cohesion: 0.33
Nodes (4): friends, jwt, main, mine

### Community 97 - "Share"
Cohesion: 0.22
Nodes (7): _api, create, edit, list, revoke, _send, SharesRepository

### Community 98 - "_HachiwareState"
Cohesion: 0.33
Nodes (4): DebugOverlay, _DebugOverlayState, Hachiware, _HachiwareState

### Community 99 - "location_source.dart"
Cohesion: 0.22
Nodes (8): GeolocatorSource, access, fixes, LocationAccess, LocationSource, openSettings, request, FakeLocation

### Community 100 - "guide/README.md"
Cohesion: 0.18
Nodes (3): 07. Trail panel (day diary and top places), Find Me mobile: learning guide, Find Me (mobile)

### Community 101 - "Review Focus"
Cohesion: 0.20
Nodes (9): Global Constraints, Review Focus, Task 1: Trip domain + friend store cut, Task 2: API: sharing calls and ingest `trip: false`, Task 3: Tracker drives the trip, Task 4: Trip UI (tracker sheet, account sheet, app resume, picker), Task 5: Android: tile, widget button, alarm, headless entrypoint, Task 6: Docs (+1 more)

### Community 102 - "freezed"
Cohesion: 0.18
Nodes (13): FriendPatterns, MePatterns, LastPointPatterns, StopPatterns, Friend, Me, _Friend, _Me (+5 more)

### Community 103 - "File Structure"
Cohesion: 0.10
Nodes (20): Calls made in this plan (not in the spec), File Structure, Find Me Flutter App Implementation Plan, Global Constraints, Review Focus, Task 0: Toolchain and empty project that runs, Task 10: Top bar, date filter, trail sheet, Task 11: Replay (alone and together) (+12 more)

### Community 104 - "Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish"
Cohesion: 0.07
Nodes (28): Build timings, Code Analysis, Commits this session (all on main, pushed), Docs, Emulator permission evidence (before fix), Evidence & Data, Files Changed, Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish (+20 more)

### Community 105 - "Find Me mobile app (Flutter): design"
Cohesion: 0.13
Nodes (14): 1. Intent and why, 2. Goals, 3. Non-goals, 4. Anti-goals (would be a failure even if it runs), 5. Constraints and decided how, 6. Docs (deliverable), 7. Left to the builder, Architecture (+6 more)

### Community 106 - "AppDelegate.swift"
Cohesion: 0.20
Nodes (6): CoreLocation, Flutter, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 107 - "friends_controller_test.dart"
Cohesion: 0.50
Nodes (4): sharesRepositoryProvider, shareLauncherProvider, SharesSheet, _SharesSheetState

### Community 108 - "Review Focus"
Cohesion: 0.14
Nodes (13): Find Me Tracker Implementation Plan, Global Constraints, Review Focus, Task 12: Guide chapter 15, Play Store prep, handoff, Task 1: Fix model, Overland encoding, console masking, Task 2: Crash-safe file queue, Task 3: Ingest client, Task 4: Upload policy (pure) (+5 more)

### Community 109 - "Find Me tracker (replaces Overland): design"
Cohesion: 0.14
Nodes (13): 1. Intent and why, 2. Goals, 3. Non-goals, 4. Anti-goals (a failure even if it runs), 5. Constraints and decided how, 6. What the user sees, 7. Testing, 8. Left to the builder (+5 more)

### Community 110 - "Review Focus"
Cohesion: 0.15
Nodes (12): Global Constraints, Home-Screen Widget Implementation Plan, Review Focus, Task 1: Draft the guide chapter, Task 2: Throwaway test of background drawing (gate), Task 3: Tile maths and the day log, Task 4: Tile cache, Task 5: Draw the picture (+4 more)

### Community 111 - "Home-screen widget: where I am now"
Cohesion: 0.15
Nodes (12): Anti-goals, Biggest unknown: test this first, Goals, Guide chapter (for learning), Home-screen widget: where I am now, How it behaves, Left to the builder, Non-goals (+4 more)

### Community 117 - "package:findme/features/pins/domain/pin.dart"
Cohesion: 0.29
Nodes (5): a, b, item, main, pin

### Community 118 - "Find Me tracker (replaces Overland): built, final-review fixes half done"
Cohesion: 0.15
Nodes (12): Code map, Final review findings (fresh Opus reviewer). The fix pass is IN PROGRESS, Find Me tracker (replaces Overland): built, final-review fixes half done, Gotchas, Key Decisions (owner), Key Rulings (executor; full list in the ledger), Quick Start, Reference Documents (+4 more)

### Community 119 - "04. Sign-in (Cognito) and secure storage"
Cohesion: 0.25
Nodes (8): 04. Sign-in (Cognito) and secure storage, Account sheet and deleting your account, Error messages, How it works, Password managers, Sign-up, Tests, The four screens before the map

### Community 120 - "MainActivity.kt"
Cohesion: 0.19
Nodes (5): MainActivity, Handoff: Find Me mobile (Flutter), Known gaps / decisions left open, Next steps, Where things stand

### Community 121 - "01. Install the tools on Windows"
Cohesion: 0.17
Nodes (12): 01. Install the tools on Windows, Done? Tell Claude, Fixing common doctor errors, Step 1. Turn on Developer Mode and virtualization, Step 2. Install the Flutter SDK, Step 3. Install Android Studio, Step 3b. No Android Studio: SDK and emulator from zip files, Step 4. Accept the Android licences (+4 more)

### Community 122 - "hachiware_test.dart"
Cohesion: 0.29
Nodes (3): hopY, host, main

### Community 123 - "Review Focus"
Cohesion: 0.20
Nodes (9): Global Constraints, Pins taken where you are, shared per picture (mobile port) Implementation Plan, Review Focus, Task 1: Repository and model, Task 2: Taking a pin where you are, Task 3: The pin sheet — "Chia sẻ" switch, read-only for friends, Task 4: Friends' shared pins on the map, Task 5: Share links get "Ảnh" (+1 more)

### Community 125 - "02. Running the app"
Cohesion: 0.20
Nodes (10): 02. Running the app, Building an APK to install on a phone, Running from VS Code, Seeing logs, Step 1. Get the packages, Step 2. Create your config file, Step 3. Start the emulator, Step 4. Run (+2 more)

### Community 127 - "Chapter 16: Photo pins"
Cohesion: 0.18
Nodes (10): Chapter 16: Photo pins, Code, How the login works, Packages, Photos made ready on the phone, Pictures and videos through the image host, Shared photos, Test on a phone (+2 more)

### Community 129 - "trip_channel.dart"
Cohesion: 0.12
Nodes (14): _android, _ch, onCommand, sync, takePicker, TripChannel, _ch, _ios (+6 more)

### Community 130 - "14. Store accounts and app IDs (Apple and Google)"
Cohesion: 0.20
Nodes (10): 14. Store accounts and app IDs (Apple and Google), A2. Free, without a Mac: Sideloadly on Windows (third-party), A. Free: install on your own iPhone for 7 days, A. Free: install the APK directly, Android, B. Paid: Apple Developer Program (TestFlight and App Store), B. Paid: Google Play, iPhone (+2 more)

### Community 131 - "date_filter.dart"
Cohesion: 0.18
Nodes (10): DateRange, _active, build, createState, DateFilter, _DateFilterState, _now, onChange (+2 more)

### Community 132 - "15. Background tracking (Find Me replaces Overland)"
Cohesion: 0.22
Nodes (9): 15. Background tracking (Find Me replaces Overland), 3. Run, 4. Look, 5. Test, 6. Moving an account from Overland to Find Me, 7. Google Play, 8. Troubleshooting, Fake a walk on the emulator (+1 more)

### Community 133 - "package:flutter/foundation.dart"
Cohesion: 0.13
Nodes (11): WidgetUpdater, NoTrailWidget, TrailWidget, c, _headless, main, startTrackerHeadless, trackerBoot (+3 more)

### Community 134 - "dart:ui"
Cohesion: 0.17
Nodes (11): api, apiUrl, authority, bad, clientId, cognitoHost, fromEnvironment, fromMap (+3 more)

### Community 135 - "Google Play: background location (drafts)"
Cohesion: 0.25
Nodes (7): 1. In-app prominent disclosure (done in the app), 2. Background location declaration (Play Console → App content → Sensitive permissions), 3. Demo video (≤ 30 s, unlisted YouTube link), 4. Foreground service type (Play Console → App content → Foreground service permissions), 5. Privacy policy (done), 6. Data safety form (answers), Google Play: background location (drafts)

### Community 136 - "trail_painting.dart"
Cohesion: 0.14
Nodes (10): c, read, startTrackerHeadless, glow, paint, paintPaws, pastelMatrix, path (+2 more)

### Community 137 - "05. The map and paw prints"
Cohesion: 0.29
Nodes (7): 05. The map and paw prints, flutter_map in one picture, Flying, Paw prints: one painter, thousands of prints, Tapping things, Tests, Where the map opens

### Community 138 - "10. Testing"
Cohesion: 0.29
Nodes (7): 10. Testing, Rule: tests never touch the network, Running, Testing timers, When a test fails, Writing a unit test, Writing a widget test

### Community 139 - "13. Later: iOS without a Mac, signing, App Store and Play Store"
Cohesion: 0.22
Nodes (9): 13. Later: iOS without a Mac, signing, App Store and Play Store, App icon and name, Crash reporting, dev/prod on iOS, Google Play, iPhone without a Mac, Privacy manifest, Privacy policy page (+1 more)

### Community 140 - "1. What and why"
Cohesion: 0.29
Nodes (7): 1. What and why, Batteries and accuracy, How a phone records you while the app is closed, The blue indicator (iPhone), The queue: why "delete only after ok", The token, Why the OS kills apps, and how Find Me comes back

### Community 141 - "1. What and why"
Cohesion: 0.15
Nodes (12): 17. Home-screen widget (where am I now), 1. What and why, 2. The real files, 3. What the emulator taught us, 4. Run and test, Being polite to the map server, How a picture gets from Dart to the home screen, iPhone spike: does it work with a free Apple ID? (branch `spike/ios-widget`) (+4 more)

### Community 143 - "03. Project structure"
Cohesion: 0.33
Nodes (6): 03. Project structure, Folders, How state works: Riverpod in two minutes, Inside a feature: three layers, One request, end to end, Where errors are turned into words

### Community 145 - "Chapter 18: The bag and your avatar"
Cohesion: 0.33
Nodes (5): Chapter 18: The bag and your avatar, Code, How it works, Try it, Where to find it

### Community 146 - "CLAUDE.md"
Cohesion: 0.40
Nodes (3): Architecture, Commands (PowerShell), Conventions

### Community 147 - "00. Flutter for web developers"
Cohesion: 0.40
Nodes (5): 00. Flutter for web developers, Concept map: React → Flutter, How a mobile app differs from the PWA, What Flutter is, Words you will meet

### Community 148 - "11. Code generation, lints, formatting"
Cohesion: 0.40
Nodes (5): 11. Code generation, lints, formatting, Before every commit, Code generation (freezed + json_serializable), Formatting (`dart format`), Lints (`flutter analyze`)

### Community 149 - "12. CI with GitHub Actions"
Cohesion: 0.40
Nodes (5): 12. CI with GitHub Actions, Reading a failed run, Step 1. Put the project on GitHub, Step 2. Watch it run, Why iOS runs less often

### Community 151 - "06. Date filter and live refresh"
Cohesion: 0.50
Nodes (4): 06. Date filter and live refresh, Live refresh, exactly like the web, Testing time without waiting, The date filter

### Community 153 - "08. Replay"
Cohesion: 0.67
Nodes (3): 08. Replay, The clock, Two modes

### Community 154 - "09. Share links and friends"
Cohesion: 0.67
Nodes (3): 09. Share links and friends, 👥 Friends, 🔗 Share links

### Community 155 - "tracker_store_test.dart"
Cohesion: 0.10
Nodes (12): main, c, ctl, main, own, s, main, iso (+4 more)

### Community 158 - "authControllerProvider"
Cohesion: 0.10
Nodes (13): _askName, _busy, createState, _err, _mode, open, incomingCount, onAccount (+5 more)

### Community 159 - "Chapter 20: Live positions over MQTT"
Cohesion: 0.18
Nodes (10): 1. What MQTT is, in one minute, 2. Turning it on, 3. How the phone connects, 4. What gets published, 5. Stopping, 6. `/ingest` now waits longer, 7. In the background, 8. Check it (+2 more)

### Community 161 - "Live positions over MQTT, phone side: design"
Cohesion: 0.18
Nodes (10): Answered by the owner (2026-11-24), Background, Connection, Files, `/ingest` batching, Live positions over MQTT, phone side: design, Privacy, Stopping (+2 more)

### Community 163 - "ConsumerState"
Cohesion: 0.14
Nodes (15): _choose, _pickPicture, pinsRepositoryProvider, _pick, build, build, initState, _more (+7 more)

### Community 165 - "Chapter 19: Trip mode"
Cohesion: 0.33
Nodes (5): Android: the tile, the widget button, the alarm, Chapter 19: Trip mode, How it works, Try it, Where to find it

### Community 166 - "live_sender_test.dart"
Cohesion: 0.17
Nodes (9): LiveSender, IngestToken, lats, link, live, main, make, north (+1 more)

### Community 167 - "dart:math"
Cohesion: 0.14
Nodes (9): livePayload, liveTopic, m, _round, worthPublishing, fix, main, at (+1 more)

### Community 168 - "TrackerController"
Cohesion: 0.22
Nodes (10): ingestClientProvider, liveSenderProvider, pointQueueProvider, build, _issue, trackerClockProvider, TrackerController, TrackerState (+2 more)

### Community 177 - "wakeChannelProvider"
Cohesion: 0.40
Nodes (5): chargingProvider, wakeChannelProvider, forget, _start, turnOff

### Community 178 - "upload_policy_test.dart"
Cohesion: 0.40
Nodes (3): go, main, now

### Community 179 - "tracker_store_test.dart"
Cohesion: 0.13
Nodes (9): CardError, PinUploadFailed, StorageUnreadable, _LockedStorage, main, read, s, main (+1 more)

### Community 181 - "DebugEntry"
Cohesion: 0.50
Nodes (4): DebugEntry, ErrorEntry, HttpEntry, MqttEntry

## Knowledge Gaps
- **1589 isolated node(s):** `main`, `main`, `picture`, `SwiftUI`, `WidgetKit` (+1584 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2095 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FindMeWidget` connect `SpikeEntry` to `MainActivity.kt`?**
  _High betweenness centrality (0.235) - this node is a cross-community bridge._
- **What connects `main`, `main`, `picture` to the rest of the system?**
  _1589 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06376811594202898 - nodes in this community are weakly interconnected._
- **Why does `Where things stand` connect `MainActivity.kt` to `SpikeEntry`, `AppDelegate`?**
  _High betweenness centrality (0.213) - this node is a cross-community bridge._
- **Should `friend_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.11742424242424243 - nodes in this community are weakly interconnected._
- **Why does `MainActivity` connect `MainActivity.kt` to `AppDelegate`?**
  _High betweenness centrality (0.135) - this node is a cross-community bridge._
- **Should `debug_log.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.046511627906976744 - nodes in this community are weakly interconnected._