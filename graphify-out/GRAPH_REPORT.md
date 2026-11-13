# Graph Report - findme  (2026-11-13)

## Corpus Check
- 195 files · ~122,270 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 37 file(s) not represented in the graph (top: .xml 14, (none) 5, .plist 4)

## Summary
- 2622 nodes · 3985 edges · 154 communities (141 shown, 13 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 13 edges (avg confidence: 0.94)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c04a36fc`
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
- friends_repository.dart
- avatar_crop.dart
- bag_widgets.dart
- dependencies
- pin_sheet.dart
- StatelessWidget
- dart:async
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
- package:findme/features/tracker/domain/fix.dart
- friends_controller.dart
- package:flutter/material.dart
- bag_repository.dart
- bag_sheet.dart
- add_pin_sheet.dart
- package:findme/core/config/app_config.dart
- package:flutter_riverpod/flutter_riverpod.dart
- debug_console.dart
- hachiware.dart
- widget_updater.dart
- tile_cache.dart
- render.dart
- prefs.dart
- auth_repository_test.dart
- format.dart
- palette.dart
- welcome_screen.dart
- point_queue.dart
- BootReceiver.kt
- paw_layer.dart
- session_store.dart
- ConsumerState
- friendsControllerProvider
- trail_sheet.dart
- file_day_log.dart
- friends_controller_test.dart
- trail_controller_test.dart
- pins_controller.dart
- render_test.dart
- tile_cache_test.dart
- hachiware_test.dart
- appConfigProvider
- TrailWidgetProvider.kt
- fix.dart
- app_config.dart
- authControllerProvider
- date_filter.dart
- wake_channel.dart
- _HachiwareState
- package:flutter/foundation.dart
- pill.dart
- List
- Exception
- rules
- Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)
- geolocator_source_test.dart
- home_widget_host.dart
- Mock
- _MapViewState
- bag_icons.dart
- ingest_client.dart
- fake_adapter.dart
- package:findme/core/theme/palette.dart
- map_view_test.dart
- dart:convert
- upload_policy.dart
- day_log.dart
- package:findme/core/errors/app_errors.dart
- Cheatsheet
- Prefs
- TrackerController
- shares_sheet_test.dart
- tracker_sheet.dart
- guide/README.md
- freezed
- File Structure
- Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish
- Find Me mobile app (Flutter): design
- AppDelegate.swift
- integration_test/app_test.dart
- Review Focus
- Find Me tracker (replaces Overland): design
- Review Focus
- Home-screen widget: where I am now
- version.dart
- friend_pins_controller.dart
- Find Me tracker (replaces Overland): built, final-review fixes half done
- 04. Sign-in (Cognito) and secure storage
- MainActivity.kt
- 01. Install the tools on Windows
- shares_repository.dart
- Review Focus
- Handoff: Find Me mobile (Flutter)
- 02. Running the app
- Chapter 16: Photo pins
- trail_painting.dart
- 14. Store accounts and app IDs (Apple and Google)
- upload_policy_test.dart
- 15. Background tracking (Find Me replaces Overland)
- Fix
- package:findme/core/storage/prefs.dart
- Google Play: background location (drafts)
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
- idle
- LaunchImage.imageset/README.md
- _SharesSheetState

## God Nodes (most connected - your core abstractions)
1. `authControllerProvider` - 20 edges
2. `Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)` - 20 edges
3. `Find Me tracker on real devices: review fixes, token API wiring, emulator/iPhone bugs, map polish` - 19 edges
4. `dependencies` - 18 edges
5. `File Structure` - 16 edges
6. `signedInProvider` - 16 edges
7. `friendsControllerProvider` - 15 edges
8. `Cheatsheet` - 14 edges
9. `AppDelegate` - 14 edges
10. `pinsRepositoryProvider` - 14 edges

## Surprising Connections (you probably didn't know these)
- `The two Android pieces` --references--> `BootReceiver`  [INFERRED]
  docs/guide/17-home-screen-widget.md → android/app/src/main/kotlin/app/findme/findme/BootReceiver.kt
- `Where things stand` --references--> `MainActivity`  [INFERRED]
  docs/HANDOFF.md → android/app/src/main/kotlin/app/findme/findme/MainActivity.kt
- `Where things stand` --references--> `AppDelegate`  [INFERRED]
  docs/HANDOFF.md → ios/Runner/AppDelegate.swift
- `First native code: how Dart and Swift / Kotlin talk` --references--> `MainActivity`  [INFERRED]
  docs/guide/15-background-tracking.md → android/app/src/main/kotlin/app/findme/findme/MainActivity.kt
- `Find Me Tracker Implementation Plan` --references--> `AppDelegate`  [INFERRED]
  docs/superpowers/plans/2026-11-04-findme-tracker.md → ios/Runner/AppDelegate.swift

## Import Cycles
- None detected.

## Communities (154 total, 13 thin omitted)

### Community 0 - "models.dart"
Cohesion: 0.07
Nodes (41): class, hash, identical, null, orElse, _self, _stops, _that (+33 more)

### Community 1 - "friend_models.dart"
Cohesion: 0.12
Nodes (29): _, avatar, class, friends, hash, id, identical, _incoming (+21 more)

### Community 2 - "debug_log.dart"
Cohesion: 0.04
Nodes (43): add, appDio, at, clear, _code, _cut, debugConsoleEnabled, DebugEntry (+35 more)

### Community 3 - "tracker_fakes.dart"
Cohesion: 0.04
Nodes (47): access, afterRequest, body, build, calls, ctl, emit, enabled (+39 more)

### Community 4 - "map_view.dart"
Cohesion: 0.05
Nodes (36): avatar, build, clock, color, createState, didUpdateWidget, dispose, _fitted (+28 more)

### Community 5 - "replay_controller.dart"
Cohesion: 0.05
Nodes (34): build, createState, didChangeDependencies, dispose, initState, _prev, ReplayBar, _ReplayBarState (+26 more)

### Community 6 - "pins_repository.dart"
Cohesion: 0.05
Nodes (43): _api, _call, _cfg, _chunk, _cookie, _cookieFrom, _cookieName, createPin (+35 more)

### Community 7 - "tracker_controller.dart"
Cohesion: 0.05
Nodes (36): copyWith, _failed, _failures, _fixes, _gps, indicator, lastFix, lastOk (+28 more)

### Community 8 - "pin.dart"
Cohesion: 0.05
Nodes (39): best, bestM, Bubble, _cellPx, cells, count, createdAt, d (+31 more)

### Community 9 - "shares_sheet.dart"
Cohesion: 0.05
Nodes (37): _bag, _bagOk, build, _busy, _create, createState, _custom, dispose (+29 more)

### Community 10 - "app_errors.dart"
Cohesion: 0.06
Nodes (36): AccountMissing, ApiStatus, AppError, AuthError, AuthExpired, body, code, detail (+28 more)

### Community 11 - "share.dart"
Cohesion: 0.14
Nodes (24): bag, class, hash, id, identical, null, operator, orElse (+16 more)

### Community 12 - "fakes.dart"
Cohesion: 0.10
Nodes (18): a, baseOverrides, clear, clearToday, f, fakeAuth, p, quietFriends (+10 more)

### Community 13 - "trail_math.dart"
Cohesion: 0.06
Nodes (37): a, at, b, base, byName, cursor, end, f (+29 more)

### Community 14 - "bag_editor.dart"
Cohesion: 0.06
Nodes (30): _back, _busy, createState, _dirty, dispose, _draft, _edit, _err (+22 more)

### Community 15 - "with"
Cohesion: 0.07
Nodes (30): env, name, runs-on, steps, CFG, TZ, if, name (+22 more)

### Community 16 - "tracker_controller_test.dart"
Cohesion: 0.06
Nodes (29): answer, c, clear, clears, ctl, dir, emit, fx (+21 more)

### Community 17 - "AppDelegate"
Cohesion: 0.15
Nodes (4): 2. Code, First native code: how Dart and Swift / Kotlin talk, Task 10: iOS significant-location relaunch, AppDelegate

### Community 18 - "friends_repository.dart"
Cohesion: 0.12
Nodes (12): ApiClient, apiClientProvider, auth, answer, _api, deleteMe, FriendsRepository, me (+4 more)

### Community 19 - "avatar_crop.dart"
Cohesion: 0.09
Nodes (22): bagRepositoryProvider, AvatarCrop, _AvatarCropState, _busy, c, _clear, createState, _CropPainter (+14 more)

### Community 20 - "bag_widgets.dart"
Cohesion: 0.07
Nodes (27): _avatarBg, _bagBody, bagCream, bagInk, _bagRim, _bagShape, border, borderWidth (+19 more)

### Community 21 - "dependencies"
Cohesion: 0.05
Nodes (38): dependencies, dio, flutter, flutter_map, flutter_riverpod, flutter_secure_storage, flutter_svg, freezed_annotation (+30 more)

### Community 22 - "pin_sheet.dart"
Cohesion: 0.06
Nodes (28): _act, by, _c, child, createState, dispose, _err, _failed (+20 more)

### Community 23 - "StatelessWidget"
Cohesion: 0.15
Nodes (12): _Centered, BagGrid, BagHead, Initial, Pocket, PocketGrid, _Row, _Cell (+4 more)

### Community 24 - "dart:async"
Cohesion: 0.13
Nodes (9): ConfigErrorApp, createState, FindMeApp, _FindMeAppState, message, _navigator, showTiles, main (+1 more)

### Community 25 - "bag.dart"
Cohesion: 0.08
Nodes (25): avatarPath, canAdd, clamp, copyWith, cropSquare, fromJson, href, image (+17 more)

### Community 26 - "pins_ui_test.dart"
Cohesion: 0.07
Nodes (23): PinInput, Spot, asked, askPermission, at, build, error, host (+15 more)

### Community 27 - "date_range.dart"
Cohesion: 0.08
Nodes (25): a, b, contains, customRange, f, from, hashCode, isLive (+17 more)

### Community 28 - "tile_math.dart"
Cohesion: 0.04
Nodes (42): advance, _minMs, _msPerPrint, nextSpeed, replayMs, speeds, atan2, bearing (+34 more)

### Community 29 - "pins_repository_test.dart"
Cohesion: 0.08
Nodes (24): api, bodies, calls, close, cookieOk, count, dio, down (+16 more)

### Community 30 - "widget_updater_test.dart"
Cohesion: 0.08
Nodes (22): append, base, clear, clears, days, failAppend, failPublish, failRender (+14 more)

### Community 31 - "trail_controller.dart"
Cohesion: 0.08
Nodes (21): copyWith, error, _friends, go, load, loading, _now, _paused (+13 more)

### Community 32 - "auth_controller.dart"
Cohesion: 0.16
Nodes (19): initState, prefsProvider, authRepositoryProvider, AuthController, AuthPhase, build, expired, noAccount (+11 more)

### Community 33 - "tracker_store.dart"
Cohesion: 0.09
Nodes (23): _cached, enabled, _everyKey, forget, indicator, _indicatorKey, IngestToken, _onKey (+15 more)

### Community 34 - "trail_widget.dart"
Cohesion: 0.08
Nodes (26): Fix, FriendPart, TrackAnswer, TrackPoint, WidgetUpdater, DayTrail, TileKey, clear (+18 more)

### Community 35 - "map_screen.dart"
Cohesion: 0.08
Nodes (19): _adding, _closeSheets, createState, dispose, _life, _openPinId, showTiles, _spot (+11 more)

### Community 36 - "package:findme/features/tracker/domain/fix.dart"
Cohesion: 0.10
Nodes (14): PointQueue, dir, fx, main, q, fix, main, dir (+6 more)

### Community 37 - "friends_controller.dart"
Cohesion: 0.09
Nodes (20): answer, apply, ask, copyWith, friendsPollMs, _list, me, _paused (+12 more)

### Community 38 - "package:flutter/material.dart"
Cohesion: 0.08
Nodes (20): _askName, _busy, createState, _err, open, actions, _busy, _code (+12 more)

### Community 39 - "bag_repository.dart"
Cohesion: 0.09
Nodes (21): _api, BagRepository, cardErrorText, delay, deleteCard, freshReceipts, friendBag, hashCode (+13 more)

### Community 40 - "bag_sheet.dart"
Cohesion: 0.12
Nodes (14): BagItem, Slots, color, createState, _failed, initState, item, lead (+6 more)

### Community 41 - "add_pin_sheet.dart"
Cohesion: 0.11
Nodes (16): build, createState, dispose, _err, _fix, initState, _locate, _name (+8 more)

### Community 42 - "package:findme/core/config/app_config.dart"
Cohesion: 0.17
Nodes (7): full, main, adapter, cfg, main, repo, shareJson

### Community 43 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.09
Nodes (18): _api, fetch, TrackRepository, trackRepositoryProvider, confirmWith, main, pump, repo (+10 more)

### Community 44 - "debug_console.dart"
Cohesion: 0.12
Nodes (12): _at, _block, child, createState, _errorRow, _hms, _httpRow, _list (+4 more)

### Community 45 - "hachiware.dart"
Cohesion: 0.10
Nodes (19): a, b, build, createState, didChangeDependencies, dispose, f, Fade (+11 more)

### Community 46 - "widget_updater.dart"
Cohesion: 0.10
Nodes (19): clear, _closed, _dirty, _draw, _drawing, _drawnAt, _generation, _log (+11 more)

### Community 47 - "tile_cache.dart"
Cohesion: 0.14
Nodes (12): client, _dir, _failedAt, _fetch, fetchOsmTile, _file, _freshFor, maxFiles (+4 more)

### Community 48 - "render.dart"
Cohesion: 0.13
Nodes (13): area, bytes, canvas, cat, _decode, _hachiwareHeight, here, image (+5 more)

### Community 49 - "prefs.dart"
Cohesion: 0.12
Nodes (14): clear, clearToday, _last, _p, readToday, rememberStart, round4, saveShownFriends (+6 more)

### Community 50 - "auth_repository_test.dart"
Cohesion: 0.06
Nodes (35): _api, AuthRepository, cfg, _cid, confirmSignUp, _fromResult, getAccessToken, login (+27 more)

### Community 51 - "format.dart"
Cohesion: 0.12
Nodes (16): ago, d, dayMonth, dm, duration, h, hhmm, hhmmIso (+8 more)

### Community 52 - "palette.dart"
Cohesion: 0.18
Nodes (10): card, error, ink, lavender, muted, page, Palette, pink (+2 more)

### Community 53 - "welcome_screen.dart"
Cohesion: 0.12
Nodes (16): _busy, _code, createState, dispose, _email, _err, _go, _invite (+8 more)

### Community 54 - "point_queue.dart"
Cohesion: 0.12
Nodes (16): append, clear, commit, count, create, dir, _drop, _endsMidLine (+8 more)

### Community 55 - "BootReceiver.kt"
Cohesion: 0.21
Nodes (4): BootReceiver, Task 11: Android reboot restart, How it gets made, Where We're Going

### Community 56 - "paw_layer.dart"
Cohesion: 0.12
Nodes (13): best, bestD, build, camera, color, maxPx, nearestPrint, paint (+5 more)

### Community 57 - "session_store.dart"
Cohesion: 0.13
Nodes (12): access, expiresAt, fromJson, _key, load, refresh, save, Session (+4 more)

### Community 58 - "ConsumerState"
Cohesion: 0.11
Nodes (24): AccountSheet, _AccountSheetState, SignInForm, _SignInFormState, _choose, BagEditor, _BagEditorState, _pickPicture (+16 more)

### Community 59 - "friendsControllerProvider"
Cohesion: 0.17
Nodes (21): build, build, build, friendsControllerProvider, friendsOnMapProvider, build, FriendsSheet, _FriendsSheetState (+13 more)

### Community 60 - "trail_sheet.dart"
Cohesion: 0.12
Nodes (16): build, lead, _medals, muted, name, oneDay, onReplay, onTap (+8 more)

### Community 61 - "file_day_log.dart"
Cohesion: 0.15
Nodes (10): append, clear, _day, _dir, _last, _parse, read, _readLast (+2 more)

### Community 62 - "friends_controller_test.dart"
Cohesion: 0.20
Nodes (8): bob, c, main, prefs, rel, repo, s, start

### Community 63 - "trail_controller_test.dart"
Cohesion: 0.18
Nodes (10): asked, c, ctl, jwt, main, now, repo, start (+2 more)

### Community 64 - "pins_controller.dart"
Cohesion: 0.10
Nodes (19): ask, askPermission, currentFix, deadline, _files, GeoApi, image, _paused (+11 more)

### Community 65 - "render_test.dart"
Cohesion: 0.11
Nodes (15): codec, data, decode, fromARGB, here, image, main, o (+7 more)

### Community 66 - "tile_cache_test.dart"
Cohesion: 0.11
Nodes (16): TileCache, WidgetTiles, a, answer, b, c, cache, dir (+8 more)

### Community 67 - "hachiware_test.dart"
Cohesion: 0.29
Nodes (3): hopY, host, main

### Community 68 - "appConfigProvider"
Cohesion: 0.18
Nodes (13): appConfigProvider, build, DebugSheet, _Env, _sessionExpiry, _form, BagFull, build (+5 more)

### Community 70 - "fix.dart"
Cohesion: 0.15
Nodes (10): acc, at, deviceIdForPlatform, fromJson, hashCode, lat, lon, operator (+2 more)

### Community 71 - "app_config.dart"
Cohesion: 0.17
Nodes (10): api, apiUrl, authority, bad, clientId, cognitoHost, fromEnvironment, fromMap (+2 more)

### Community 72 - "authControllerProvider"
Cohesion: 0.20
Nodes (12): _delete, authControllerProvider, build, WelcomeScreen, _signedOut, linkOpenerProvider, _tap, friendsRepositoryProvider (+4 more)

### Community 73 - "date_filter.dart"
Cohesion: 0.20
Nodes (8): DateRange, _active, build, createState, _now, onChange, _pick, value

### Community 74 - "wake_channel.dart"
Cohesion: 0.20
Nodes (7): _ch, _ios, onWake, start, stop, WakeChannel, FakeWake

### Community 75 - "_HachiwareState"
Cohesion: 0.28
Nodes (6): DebugOverlay, _DebugOverlayState, DateFilter, _DateFilterState, Hachiware, _HachiwareState

### Community 76 - "package:flutter/foundation.dart"
Cohesion: 0.09
Nodes (11): asset, create, dir, hachiware, liveTrailWidget, _load, root, main (+3 more)

### Community 77 - "pill.dart"
Cohesion: 0.17
Nodes (9): badge, build, label, onTap, Pill, PillStyle, selected, semanticLabel (+1 more)

### Community 78 - "List"
Cohesion: 0.18
Nodes (13): build, signedInProvider, build, friendCountProvider, FriendPinsController, build, PinsController, build (+5 more)

### Community 79 - "Exception"
Cohesion: 0.50
Nodes (3): CardError, PinUploadFailed, StorageUnreadable

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

### Community 84 - "Mock"
Cohesion: 0.15
Nodes (6): MockBag, MockAuth, MockPins, MockShares, MockTrack, MockIngest

### Community 86 - "bag_icons.dart"
Cohesion: 0.13
Nodes (10): ItemType, BagIcon, build, _icons, _ink, _s, size, type (+2 more)

### Community 87 - "ingest_client.dart"
Cohesion: 0.08
Nodes (19): AppConfig, _cfg, _dio, send, _token, TokenGetter, call, _cfg (+11 more)

### Community 88 - "fake_adapter.dart"
Cohesion: 0.18
Nodes (10): calls, close, contentType, fakeDio, fetch, offline, Reply, requests (+2 more)

### Community 89 - "package:findme/core/theme/palette.dart"
Cohesion: 0.13
Nodes (10): base, buildTheme, copyWith, build, CardBox, child, error, Notice (+2 more)

### Community 90 - "map_view_test.dart"
Cohesion: 0.17
Nodes (7): _bubble, pins, _Waiting, host, main, pts, stop

### Community 91 - "dart:convert"
Cohesion: 0.12
Nodes (9): backgroundSafeStorage, friends, jwt, main, mine, main, main, read (+1 more)

### Community 92 - "upload_policy.dart"
Cohesion: 0.20
Nodes (8): backoff, every, m, maxBatch, shouldUpload, uploadAt, uploadChoices, uploadEvery

### Community 93 - "day_log.dart"
Cohesion: 0.17
Nodes (11): FileDayLog, append, clear, DayLog, last, read, sameLocalDay, today (+3 more)

### Community 94 - "package:findme/core/errors/app_errors.dart"
Cohesion: 0.08
Nodes (15): c, read, startTrackerHeadless, main, main, main, _scoped, settle (+7 more)

### Community 95 - "Cheatsheet"
Cohesion: 0.13
Nodes (14): Bag and avatar (chapter 18), Cheatsheet, Config keys (`config/dev.json`, `config/prod.json`), Flavors, Git and CI, Home-screen widget (chapter 17), Photo pins (chapter 16), Quality (+6 more)

### Community 96 - "Prefs"
Cohesion: 0.67
Nodes (3): Prefs, SharedPrefs, MemoryPrefs

### Community 97 - "TrackerController"
Cohesion: 0.15
Nodes (13): ingestClientProvider, pointQueueProvider, wakeChannelProvider, build, forget, _issue, _start, trackerClockProvider (+5 more)

### Community 98 - "shares_sheet_test.dart"
Cohesion: 0.18
Nodes (7): clipboard, live, main, now, old, pump, repo

### Community 99 - "tracker_sheet.dart"
Cohesion: 0.09
Nodes (19): access, fixes, LocationAccess, locationSourceProvider, openSettings, request, build, createState (+11 more)

### Community 100 - "guide/README.md"
Cohesion: 0.18
Nodes (3): 07. Trail panel (day diary and top places), Find Me mobile: learning guide, Find Me (mobile)

### Community 102 - "freezed"
Cohesion: 0.18
Nodes (13): FriendPatterns, RelationsPatterns, LastPointPatterns, StopPatterns, Friend, Relations, _Friend, _Relations (+5 more)

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

### Community 117 - "friend_pins_controller.dart"
Cohesion: 0.12
Nodes (13): friendPinsRefresh, grantDue, _grantMarginS, _paused, resumed, _seq, _timer, visibleFriendPins (+5 more)

### Community 118 - "Find Me tracker (replaces Overland): built, final-review fixes half done"
Cohesion: 0.15
Nodes (12): Code map, Final review findings (fresh Opus reviewer). The fix pass is IN PROGRESS, Find Me tracker (replaces Overland): built, final-review fixes half done, Gotchas, Key Decisions (owner), Key Rulings (executor; full list in the ledger), Quick Start, Reference Documents (+4 more)

### Community 119 - "04. Sign-in (Cognito) and secure storage"
Cohesion: 0.25
Nodes (8): 04. Sign-in (Cognito) and secure storage, Account sheet and deleting your account, Error messages, How it works, Password managers, Sign-up, Tests, The four screens before the map

### Community 121 - "01. Install the tools on Windows"
Cohesion: 0.17
Nodes (12): 01. Install the tools on Windows, Done? Tell Claude, Fixing common doctor errors, Step 1. Turn on Developer Mode and virtualization, Step 2. Install the Flutter SDK, Step 3. Install Android Studio, Step 3b. No Android Studio: SDK and emulator from zip files, Step 4. Accept the Android licences (+4 more)

### Community 122 - "shares_repository.dart"
Cohesion: 0.22
Nodes (7): _api, create, edit, list, revoke, _send, SharesRepository

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
Cohesion: 0.22
Nodes (8): Chapter 16: Photo pins, Code, How the login works, Packages, Shared photos, Test on a phone, Troubleshooting, Where you are

### Community 129 - "trail_painting.dart"
Cohesion: 0.17
Nodes (8): _drawPaw, glow, paint, paintPaws, pastelMatrix, path, main, main

### Community 130 - "14. Store accounts and app IDs (Apple and Google)"
Cohesion: 0.20
Nodes (10): 14. Store accounts and app IDs (Apple and Google), A2. Free, without a Mac: Sideloadly on Windows (third-party), A. Free: install on your own iPhone for 7 days, A. Free: install the APK directly, Android, B. Paid: Apple Developer Program (TestFlight and App Store), B. Paid: Google Play, iPhone (+2 more)

### Community 131 - "upload_policy_test.dart"
Cohesion: 0.40
Nodes (3): go, main, now

### Community 132 - "15. Background tracking (Find Me replaces Overland)"
Cohesion: 0.22
Nodes (9): 15. Background tracking (Find Me replaces Overland), 3. Run, 4. Look, 5. Test, 6. Moving an account from Overland to Find Me, 7. Google Play, 8. Troubleshooting, Fake a walk on the emulator (+1 more)

### Community 133 - "Fix"
Cohesion: 0.29
Nodes (6): FixDenied, FixFailed, FixOk, GeolocatorSource, LocationSource, FakeLocation

### Community 135 - "Google Play: background location (drafts)"
Cohesion: 0.25
Nodes (7): 1. In-app prominent disclosure (done in the app), 2. Background location declaration (Play Console → App content → Sensitive permissions), 3. Demo video (≤ 30 s, unlisted YouTube link), 4. Foreground service type (Play Console → App content → Foreground service permissions), 5. Privacy policy (done), 6. Data safety form (answers), Google Play: background location (drafts)

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
Nodes (7): 1. What and why, Being polite to the map server, How a picture gets from Dart to the home screen, The two Android pieces, What a home-screen widget really is, What iPhone would need, Why widgets refresh so rarely, and how Find Me gets around it

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

### Community 158 - "_SharesSheetState"
Cohesion: 0.50
Nodes (4): sharesRepositoryProvider, shareLauncherProvider, SharesSheet, _SharesSheetState

## Knowledge Gaps
- **1405 isolated node(s):** `_busy`, `_err`, `open`, `createState`, `_askName` (+1400 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1851 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `freezed` connect `freezed` to `models.dart`, `friend_models.dart`, `share.dart`, `dependencies`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `_busy`, `_err`, `open` to the rest of the system?**
  _1405 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.06765327695560254 - nodes in this community are weakly interconnected._
- **Why does `dev_dependencies` connect `dependencies` to `freezed`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Should `friend_models.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.11553030303030302 - nodes in this community are weakly interconnected._
- **Why does `AppDelegate` connect `AppDelegate` to `Review Focus`, `AppDelegate.swift`, `Handoff: Find Me mobile (Flutter)`, `.locationManager`?**
  _High betweenness centrality (0.006) - this node is a cross-community bridge._
- **Should `debug_log.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04343971631205674 - nodes in this community are weakly interconnected._