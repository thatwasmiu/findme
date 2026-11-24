# Graph Report - findme  (2026-11-24)

## Corpus Check
- 208 files · ~135,129 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 41 file(s) not represented in the graph (top: .xml 15, (none) 5, .plist 5)

## Summary
- 2866 nodes · 4354 edges · 166 communities (146 shown, 20 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 15 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f0566119`
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
- tracker_sheet.dart
- package:flutter_test/flutter_test.dart
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
- friends_repository.dart
- package:findme/core/config/app_config.dart
- bag_icons.dart
- package:findme/core/config/app_config.dart
- map_view_test.dart
- package:findme/features/auth/data/session_store.dart
- upload_policy.dart
- TripTileService
- bag_repository_test.dart
- Cheatsheet
- dart:convert
- _HachiwareState
- package:findme/features/trail/domain/models.dart
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
- Handoff: Find Me mobile (Flutter)
- 02. Running the app
- Chapter 16: Photo pins
- friend_pins_controller.dart
- trip_channel.dart
- 14. Store accounts and app IDs (Apple and Google)
- date_filter.dart
- 15. Background tracking (Find Me replaces Overland)
- main.dart
- dart:ui
- Google Play: background location (drafts)
- trail_painting.dart
- 05. The map and paw prints
- 10. Testing
- 13. Later: iOS without a Mac, signing, App Store and Play Store
- 1. What and why
- 1. What and why
- Evidence & Data
- 03. Project structure
- 17. Home-screen widget (where am I now)
- Chapter 18: The bag and your avatar
- CLAUDE.md
- 00. Flutter for web developers
- 11. Code generation, lints, formatting
- 12. CI with GitHub Actions
- Files Changed
- 06. Date filter and live refresh
- 08. Replay
- 09. Share links and friends
- tracker_store_test.dart
- LaunchImage.imageset/README.md
- account_sheet.dart
- .onReceive
- ConsumerState
- Chapter 19: Trip mode

## God Nodes (most connected - your core abstractions)
1. `authControllerProvider` - 20 edges
2. `Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)` - 20 edges
3. `dependencies` - 19 edges
4. `Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish` - 19 edges
5. `signedInProvider` - 16 edges
6. `TrackerController` - 16 edges
7. `trackerControllerProvider` - 16 edges
8. `File Structure` - 16 edges
9. `friendsControllerProvider` - 15 edges
10. `Cheatsheet` - 15 edges

## Surprising Connections (you probably didn't know these)
- `The two Android pieces` --references--> `BootReceiver`  [INFERRED]
  docs/guide/17-home-screen-widget.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `How it gets made` --references--> `BootReceiver`  [INFERRED]
  docs/superpowers/specs/2026-11-09-home-widget-design.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `Where We're Going` --references--> `BootReceiver`  [INFERRED]
  plans/handoffs/HANDOFF_findme-tracker_device-fixes_2026-11-06.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `First native code: how Dart and Swift / Kotlin talk` --references--> `MainActivity`  [INFERRED]
  docs/guide/15-background-tracking.md → android/app/src/main/kotlin/app/findme/findme/MainActivity.kt
- `Where things stand` --references--> `MainActivity`  [INFERRED]
  docs/HANDOFF.md → android/app/src/main/kotlin/app/findme/findme/MainActivity.kt

## Import Cycles
- None detected.

## Communities (166 total, 20 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.06
Nodes (43): class, hash, identical, null, orElse, _self, _stops, _that (+35 more)

### Community 1 - "friend_models.dart"
Cohesion: 0.11
Nodes (30): _, avatar, class, friends, hash, id, identical, _incoming (+22 more)

### Community 2 - "debug_log.dart"
Cohesion: 0.04
Nodes (43): add, appDio, at, clear, _code, _cut, debugConsoleEnabled, DebugEntry (+35 more)

### Community 3 - "tracker_fakes.dart"
Cohesion: 0.03
Nodes (70): access, afterRequest, body, build, calls, ctl, emit, enabled (+62 more)

### Community 4 - "map_view.dart"
Cohesion: 0.05
Nodes (36): avatar, build, clock, color, createState, didUpdateWidget, dispose, _fitted (+28 more)

### Community 5 - "replay_controller.dart"
Cohesion: 0.08
Nodes (21): build, clock, clockAt, copyWith, cycleSpeed, finish, own, playing (+13 more)

### Community 6 - "pins_repository.dart"
Cohesion: 0.04
Nodes (49): _api, _call, _cfg, _chunk, _clientOn, _clientStrike, _clientStrikes, _cookie (+41 more)

### Community 7 - "tracker_controller.dart"
Cohesion: 0.03
Nodes (58): wakeChannelProvider, _apply, _command, copyWith, endTrip, _expired, _failed, _failures (+50 more)

### Community 8 - "pin.dart"
Cohesion: 0.05
Nodes (39): best, bestM, Bubble, _cellPx, cells, count, createdAt, d (+31 more)

### Community 9 - "shares_sheet.dart"
Cohesion: 0.05
Nodes (37): _bag, _bagOk, build, _busy, _create, createState, _custom, dispose (+29 more)

### Community 10 - "app_errors.dart"
Cohesion: 0.07
Nodes (32): AccountMissing, ApiStatus, AppError, AuthError, AuthExpired, body, code, detail (+24 more)

### Community 11 - "share.dart"
Cohesion: 0.14
Nodes (24): bag, class, hash, id, identical, null, operator, orElse (+16 more)

### Community 12 - "fakes.dart"
Cohesion: 0.06
Nodes (25): MockBag, a, baseOverrides, clear, clearToday, f, fakeAuth, MockAuth (+17 more)

### Community 13 - "trail_math.dart"
Cohesion: 0.05
Nodes (39): a, at, b, base, byName, cursor, end, f (+31 more)

### Community 14 - "bag_editor.dart"
Cohesion: 0.06
Nodes (30): _back, _busy, createState, _dirty, dispose, _draft, _edit, _err (+22 more)

### Community 15 - "with"
Cohesion: 0.07
Nodes (31): env, name, runs-on, steps, CFG, TZ, if, name (+23 more)

### Community 16 - "tracker_controller_test.dart"
Cohesion: 0.06
Nodes (31): answer, c, clear, clears, ctl, dir, emit, friends (+23 more)

### Community 17 - "AppDelegate"
Cohesion: 0.19
Nodes (4): 2. Code, First native code: how Dart and Swift / Kotlin talk, Task 10: iOS significant-location relaunch, AppDelegate

### Community 18 - "ingest_client.dart"
Cohesion: 0.08
Nodes (21): ApiClient, apiClientProvider, auth, _api, create, edit, list, revoke (+13 more)

### Community 19 - "avatar_crop.dart"
Cohesion: 0.09
Nodes (22): bagRepositoryProvider, AvatarCrop, _AvatarCropState, _busy, c, _clear, createState, _CropPainter (+14 more)

### Community 20 - "bag_widgets.dart"
Cohesion: 0.05
Nodes (38): _Centered, _avatarBg, _bagBody, bagCream, BagGrid, BagHead, bagInk, _bagRim (+30 more)

### Community 21 - "dependencies"
Cohesion: 0.05
Nodes (39): dependencies, dio, flutter, flutter_image_compress, flutter_map, flutter_riverpod, flutter_secure_storage, flutter_svg (+31 more)

### Community 22 - "pin_sheet.dart"
Cohesion: 0.05
Nodes (38): pinsRepositoryProvider, _load, build, _act, build, by, _c, child (+30 more)

### Community 23 - "card_box.dart"
Cohesion: 0.12
Nodes (13): base, buildTheme, copyWith, build, CardBox, child, error, Notice (+5 more)

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
Nodes (36): _cached, enabled, _everyKey, forget, indicator, _indicatorKey, IngestToken, lastPreset (+28 more)

### Community 34 - "trail_widget.dart"
Cohesion: 0.09
Nodes (22): Fix, FriendPart, TrackAnswer, TrackPoint, DayTrail, TileKey, clear, days (+14 more)

### Community 35 - "map_screen.dart"
Cohesion: 0.08
Nodes (16): Spot, _adding, _closeSheets, createState, dispose, _life, _openPinId, showTiles (+8 more)

### Community 36 - "render.dart"
Cohesion: 0.13
Nodes (13): area, bytes, canvas, cat, _decode, _hachiwareHeight, here, image (+5 more)

### Community 37 - "friends_controller.dart"
Cohesion: 0.09
Nodes (22): answer, apply, ask, copyWith, FriendsController, friendsPollMs, FriendsState, _list (+14 more)

### Community 38 - "friends_sheet.dart"
Cohesion: 0.11
Nodes (15): actions, _busy, _code, _confirm, createState, dispose, _err, lead (+7 more)

### Community 39 - "bag_repository.dart"
Cohesion: 0.09
Nodes (21): _api, BagRepository, cardErrorText, delay, deleteCard, freshReceipts, friendBag, hashCode (+13 more)

### Community 40 - "bag_sheet.dart"
Cohesion: 0.11
Nodes (15): FindMeWidget, BagItem, Slots, color, createState, _failed, initState, item (+7 more)

### Community 41 - "add_pin_sheet.dart"
Cohesion: 0.09
Nodes (23): _choose, _pickPicture, AddPinSheet, _AddPinSheetState, build, createState, dispose, _err (+15 more)

### Community 42 - "replay_bar.dart"
Cohesion: 0.19
Nodes (10): build, createState, didChangeDependencies, dispose, initState, _prev, ReplayBar, _ReplayBarState (+2 more)

### Community 43 - "package:findme/features/auth/presentation/auth_controller.dart"
Cohesion: 0.12
Nodes (11): ConfigErrorApp, createState, message, _navigator, showTiles, app, main, main (+3 more)

### Community 44 - "debug_console.dart"
Cohesion: 0.12
Nodes (14): _at, _block, child, createState, DebugOverlay, _DebugOverlayState, _errorRow, _hms (+6 more)

### Community 45 - "hachiware.dart"
Cohesion: 0.10
Nodes (19): a, b, build, createState, didChangeDependencies, dispose, f, Fade (+11 more)

### Community 46 - "widget_updater.dart"
Cohesion: 0.07
Nodes (24): clear, _closed, _dirty, _draw, _drawing, _drawnAt, _generation, _log (+16 more)

### Community 47 - "tile_cache.dart"
Cohesion: 0.14
Nodes (12): client, _dir, _failedAt, _fetch, fetchOsmTile, _file, _freshFor, maxFiles (+4 more)

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
Cohesion: 0.13
Nodes (10): describe(), .body, grantedGroups(), SpikeEntry, SpikeProvider, SpikeView, .body, View (+2 more)

### Community 57 - "session_store.dart"
Cohesion: 0.13
Nodes (14): access, expiresAt, fromJson, _key, load, refresh, save, SecureSessionStore (+6 more)

### Community 58 - "List"
Cohesion: 0.12
Nodes (20): build, signedInProvider, build, build, friendCountProvider, FriendPinsController, build, PinsController (+12 more)

### Community 59 - "friendsControllerProvider"
Cohesion: 0.17
Nodes (24): initState, build, build, build, friendsControllerProvider, friendsOnMapProvider, build, friendPinsControllerProvider (+16 more)

### Community 60 - "trail_sheet.dart"
Cohesion: 0.06
Nodes (24): incomingCount, onAccount, onFriends, onShare, onTrack, build, lead, _medals (+16 more)

### Community 61 - "file_day_log.dart"
Cohesion: 0.15
Nodes (10): append, clear, _day, _dir, _last, _parse, read, _readLast (+2 more)

### Community 62 - "trail_controller_test.dart"
Cohesion: 0.10
Nodes (16): c, ctl, main, own, s, main, asked, c (+8 more)

### Community 63 - "auth_repository_test.dart"
Cohesion: 0.12
Nodes (15): adapter, answer, api, cfg, fail, load, main, ok (+7 more)

### Community 64 - "pins_controller.dart"
Cohesion: 0.10
Nodes (19): ask, askPermission, currentFix, deadline, _files, GeoApi, image, _paused (+11 more)

### Community 65 - "colors.dart"
Cohesion: 0.15
Nodes (12): atan2, bearing, distanceM, dLat, dLon, dx, dy, friendColor (+4 more)

### Community 66 - "tile_cache_test.dart"
Cohesion: 0.07
Nodes (19): main, main, picture, TileCache, WidgetTiles, a, answer, b (+11 more)

### Community 67 - "shares_sheet_test.dart"
Cohesion: 0.20
Nodes (7): clipboard, live, main, now, old, pump, repo

### Community 68 - "day_log.dart"
Cohesion: 0.17
Nodes (11): FileDayLog, append, clear, DayLog, last, read, sameLocalDay, today (+3 more)

### Community 70 - "fix.dart"
Cohesion: 0.15
Nodes (10): acc, at, deviceIdForPlatform, fromJson, hashCode, lat, lon, operator (+2 more)

### Community 71 - "trip.dart"
Cohesion: 0.12
Nodes (15): key, label, localEnd, m, null, presetOf, rest, s (+7 more)

### Community 72 - "authControllerProvider"
Cohesion: 0.13
Nodes (21): appConfigProvider, build, DebugSheet, _Env, _sessionExpiry, authControllerProvider, build, WelcomeScreen (+13 more)

### Community 73 - "tracker_sheet.dart"
Cohesion: 0.12
Nodes (14): _clock, createState, _disclosed, _disclosure, _disclosureKey, dispose, initState, open (+6 more)

### Community 74 - "package:flutter_test/flutter_test.dart"
Cohesion: 0.10
Nodes (14): main, confirmWith, main, pump, repo, tracker, main, _scoped (+6 more)

### Community 76 - "live_trail_widget.dart"
Cohesion: 0.15
Nodes (8): asset, create, dir, hachiware, _iosSpike, liveTrailWidget, _load, root

### Community 77 - "pill.dart"
Cohesion: 0.18
Nodes (9): badge, build, label, onTap, Pill, PillStyle, selected, semanticLabel (+1 more)

### Community 78 - "prefs.dart"
Cohesion: 0.11
Nodes (17): clear, clearToday, _last, _p, Prefs, readToday, rememberStart, round4 (+9 more)

### Community 79 - "package:findme/features/tracker/domain/fix.dart"
Cohesion: 0.10
Nodes (14): PointQueue, dir, fx, main, q, fix, main, dir (+6 more)

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
Cohesion: 0.25
Nodes (6): advance, _minMs, _msPerPrint, nextSpeed, replayMs, speeds

### Community 85 - "fake_adapter.dart"
Cohesion: 0.18
Nodes (10): calls, close, contentType, fakeDio, fetch, offline, Reply, requests (+2 more)

### Community 86 - "friends_repository.dart"
Cohesion: 0.17
Nodes (11): answer, _api, deleteMe, FriendsRepository, me, _one, relations, remove (+3 more)

### Community 87 - "package:findme/core/config/app_config.dart"
Cohesion: 0.08
Nodes (21): api, apiUrl, AppConfig, authority, bad, clientId, cognitoHost, fromEnvironment (+13 more)

### Community 88 - "bag_icons.dart"
Cohesion: 0.13
Nodes (10): ItemType, BagIcon, build, _icons, _ink, _s, size, type (+2 more)

### Community 89 - "package:findme/core/config/app_config.dart"
Cohesion: 0.14
Nodes (8): ShareInvalid, full, main, adapter, cfg, main, repo, shareJson

### Community 90 - "map_view_test.dart"
Cohesion: 0.22
Nodes (4): host, main, pts, stop

### Community 92 - "upload_policy.dart"
Cohesion: 0.20
Nodes (8): backoff, every, m, maxBatch, shouldUpload, uploadAt, uploadChoices, uploadEvery

### Community 94 - "bag_repository_test.dart"
Cohesion: 0.17
Nodes (4): main, calls, main, res

### Community 95 - "Cheatsheet"
Cohesion: 0.12
Nodes (16): Bag and avatar (chapter 18), Cheatsheet, Config keys (`config/dev.json`, `config/prod.json`), Flavors, Git and CI, Home-screen widget (chapter 17), Photo pins (chapter 16), Photos made on the phone (+8 more)

### Community 96 - "dart:convert"
Cohesion: 0.33
Nodes (4): friends, jwt, main, mine

### Community 97 - "_HachiwareState"
Cohesion: 0.33
Nodes (4): DateFilter, _DateFilterState, Hachiware, _HachiwareState

### Community 98 - "package:findme/features/trail/domain/models.dart"
Cohesion: 0.17
Nodes (5): main, iso, main, stopAt, main

### Community 99 - "location_source.dart"
Cohesion: 0.12
Nodes (14): GeolocatorSource, access, fixes, LocationAccess, LocationSource, openSettings, request, gps (+6 more)

### Community 100 - "guide/README.md"
Cohesion: 0.18
Nodes (3): 07. Trail panel (day diary and top places), Find Me mobile: learning guide, Find Me (mobile)

### Community 101 - "Review Focus"
Cohesion: 0.20
Nodes (9): Global Constraints, Review Focus, Task 1: Trip domain + friend store cut, Task 2: API: sharing calls and ingest `trip: false`, Task 3: Tracker drives the trip, Task 4: Trip UI (tracker sheet, account sheet, app resume, picker), Task 5: Android: tile, widget button, alarm, headless entrypoint, Task 6: Docs (+1 more)

### Community 102 - "freezed"
Cohesion: 0.18
Nodes (13): FriendPatterns, PendingPatterns, LastPointPatterns, StopPatterns, Friend, Pending, _Friend, _Pending (+5 more)

### Community 103 - "File Structure"
Cohesion: 0.10
Nodes (20): Calls made in this plan (not in the spec), File Structure, Find Me Flutter App Implementation Plan, Global Constraints, Review Focus, Task 0: Toolchain and empty project that runs, Task 10: Top bar, date filter, trail sheet, Task 11: Replay (alone and together) (+12 more)

### Community 104 - "Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish"
Cohesion: 0.12
Nodes (16): Code Analysis, Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish, Gotchas & Discoveries, Key Decisions, Open Questions, Owner Q&A given this session (so the next session doesn't repeat or contradict), Quick Start for Next Session, Reference Documents (+8 more)

### Community 105 - "Find Me mobile app (Flutter): design"
Cohesion: 0.13
Nodes (14): 1. Intent and why, 2. Goals, 3. Non-goals, 4. Anti-goals (would be a failure even if it runs), 5. Constraints and decided how, 6. Docs (deliverable), 7. Left to the builder, Architecture (+6 more)

### Community 106 - "AppDelegate.swift"
Cohesion: 0.20
Nodes (6): CoreLocation, Flutter, SceneDelegate, RunnerTests, UIKit, XCTest

### Community 107 - "friends_controller_test.dart"
Cohesion: 0.20
Nodes (8): bob, c, main, prefs, rel, repo, s, start

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

### Community 121 - "01. Install the tools on Windows"
Cohesion: 0.17
Nodes (12): 01. Install the tools on Windows, Done? Tell Claude, Fixing common doctor errors, Step 1. Turn on Developer Mode and virtualization, Step 2. Install the Flutter SDK, Step 3. Install Android Studio, Step 3b. No Android Studio: SDK and emulator from zip files, Step 4. Accept the Android licences (+4 more)

### Community 122 - "hachiware_test.dart"
Cohesion: 0.29
Nodes (3): hopY, host, main

### Community 123 - "Review Focus"
Cohesion: 0.20
Nodes (9): Global Constraints, Pins taken where you are, shared per picture (mobile port) Implementation Plan, Review Focus, Task 1: Repository and model, Task 2: Taking a pin where you are, Task 3: The pin sheet — "Chia sẻ" switch, read-only for friends, Task 4: Friends' shared pins on the map, Task 5: Share links get "Ảnh" (+1 more)

### Community 124 - "Handoff: Find Me mobile (Flutter)"
Cohesion: 0.40
Nodes (4): Handoff: Find Me mobile (Flutter), Known gaps / decisions left open, Next steps, Where things stand

### Community 125 - "02. Running the app"
Cohesion: 0.20
Nodes (10): 02. Running the app, Building an APK to install on a phone, Running from VS Code, Seeing logs, Step 1. Get the packages, Step 2. Create your config file, Step 3. Start the emulator, Step 4. Run (+2 more)

### Community 127 - "Chapter 16: Photo pins"
Cohesion: 0.20
Nodes (9): Chapter 16: Photo pins, Code, How the login works, Packages, Photos made ready on the phone, Shared photos, Test on a phone, Troubleshooting (+1 more)

### Community 128 - "friend_pins_controller.dart"
Cohesion: 0.20
Nodes (8): friendPinsRefresh, grantDue, _grantMarginS, _paused, resumed, _seq, _timer, visibleFriendPins

### Community 129 - "trip_channel.dart"
Cohesion: 0.12
Nodes (14): _android, _ch, onCommand, sync, takePicker, TripChannel, _ch, _ios (+6 more)

### Community 130 - "14. Store accounts and app IDs (Apple and Google)"
Cohesion: 0.20
Nodes (10): 14. Store accounts and app IDs (Apple and Google), A2. Free, without a Mac: Sideloadly on Windows (third-party), A. Free: install on your own iPhone for 7 days, A. Free: install the APK directly, Android, B. Paid: Apple Developer Program (TestFlight and App Store), B. Paid: Google Play, iPhone (+2 more)

### Community 131 - "date_filter.dart"
Cohesion: 0.20
Nodes (8): DateRange, _active, build, createState, _now, onChange, _pick, value

### Community 132 - "15. Background tracking (Find Me replaces Overland)"
Cohesion: 0.22
Nodes (9): 15. Background tracking (Find Me replaces Overland), 3. Run, 4. Look, 5. Test, 6. Moving an account from Overland to Find Me, 7. Google Play, 8. Troubleshooting, Fake a walk on the emulator (+1 more)

### Community 133 - "main.dart"
Cohesion: 0.14
Nodes (9): c, read, startTrackerHeadless, c, _headless, main, startTrackerHeadless, trackerBoot (+1 more)

### Community 135 - "Google Play: background location (drafts)"
Cohesion: 0.25
Nodes (7): 1. In-app prominent disclosure (done in the app), 2. Background location declaration (Play Console → App content → Sensitive permissions), 3. Demo video (≤ 30 s, unlisted YouTube link), 4. Foreground service type (Play Console → App content → Foreground service permissions), 5. Privacy policy (done), 6. Data safety form (answers), Google Play: background location (drafts)

### Community 136 - "trail_painting.dart"
Cohesion: 0.22
Nodes (7): glow, paint, paintPaws, pastelMatrix, path, paw, _pawPath

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
Cohesion: 0.29
Nodes (7): 1. What and why, Being polite to the map server, How a picture gets from Dart to the home screen, iPhone spike: does it work with a free Apple ID? (branch `spike/ios-widget`), What a home-screen widget really is, What iPhone would need, Why widgets refresh so rarely, and how Find Me gets around it

### Community 142 - "Evidence & Data"
Cohesion: 0.29
Nodes (7): Build timings, Commits this session (all on main, pushed), Emulator permission evidence (before fix), Evidence & Data, Other log evidence, Test counts over the session, Web Hachiware spec (source of the port)

### Community 143 - "03. Project structure"
Cohesion: 0.33
Nodes (6): 03. Project structure, Folders, How state works: Riverpod in two minutes, Inside a feature: three layers, One request, end to end, Where errors are turned into words

### Community 144 - "17. Home-screen widget (where am I now)"
Cohesion: 0.33
Nodes (5): 17. Home-screen widget (where am I now), 2. The real files, 3. What the emulator taught us, 4. Run and test, Troubleshooting

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

### Community 150 - "Files Changed"
Cohesion: 0.40
Nodes (5): Docs, Files Changed, Scratch (not in repo), Source code, Tests

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
Cohesion: 0.13
Nodes (9): CardError, PinUploadFailed, StorageUnreadable, _LockedStorage, main, read, s, main (+1 more)

### Community 158 - "account_sheet.dart"
Cohesion: 0.18
Nodes (10): AccountSheet, _AccountSheetState, _askName, _busy, createState, _delete, _err, _mode (+2 more)

### Community 163 - "ConsumerState"
Cohesion: 0.14
Nodes (15): FindMeApp, _FindMeAppState, BagEditor, _BagEditorState, BagSheet, _BagSheetState, FriendsSheet, _FriendsSheetState (+7 more)

### Community 165 - "Chapter 19: Trip mode"
Cohesion: 0.33
Nodes (5): Android: the tile, the widget button, the alarm, Chapter 19: Trip mode, How it works, Try it, Where to find it

## Knowledge Gaps
- **1530 isolated node(s):** `main`, `main`, `picture`, `SwiftUI`, `WidgetKit` (+1525 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 2010 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **20 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `FindMeWidget` connect `bag_sheet.dart` to `SpikeEntry`, `Handoff: Find Me mobile (Flutter)`?**
  _High betweenness centrality (0.258) - this node is a cross-community bridge._
- **What connects `main`, `main`, `picture` to the rest of the system?**
  _1530 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06376811594202898 - nodes in this community are weakly interconnected._
- **Why does `Where things stand` connect `Handoff: Find Me mobile (Flutter)` to `MainActivity.kt`, `AppDelegate`, `bag_sheet.dart`?**
  _High betweenness centrality (0.229) - this node is a cross-community bridge._
- **Should `friend_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.11229946524064172 - nodes in this community are weakly interconnected._
- **Why does `MainActivity` connect `MainActivity.kt` to `AppDelegate`, `Handoff: Find Me mobile (Flutter)`?**
  _High betweenness centrality (0.146) - this node is a cross-community bridge._
- **Should `debug_log.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04343971631205674 - nodes in this community are weakly interconnected._