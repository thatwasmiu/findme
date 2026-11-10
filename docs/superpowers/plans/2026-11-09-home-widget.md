# Home-Screen Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An Android home-screen widget showing the tracker's latest position and today's paw trail on a pastel map.

**Architecture:** The tracker hands each fix to a `TrailWidget`. Once a minute the live implementation (`WidgetUpdater`) draws a PNG in Dart from its own day file and cached OSM tiles, and `home_widget` passes it to a small Kotlin `AppWidgetProvider`, which also computes the age label.

**Tech Stack:** Flutter/Dart, Riverpod, `dart:ui` canvas, `home_widget`, Kotlin `RemoteViews`.

**Spec:** `docs/superpowers/specs/2026-11-09-home-widget-design.md`

## Global Constraints

- Work on branch `feat/home-widget`. Commit messages end with the session's attribution line.
- Commands use `C:\src\flutter\bin\flutter` if `flutter` is not on PATH. PowerShell.
- Android only: on iOS every widget call is skipped through `NoTrailWidget`.
- Never log tokens or coordinates. Log error `runtimeType` only.
- Tests never touch the network. Generated code is committed.
- Age label wording and rounding match `ago()` in `lib/core/time/format.dart`.
- Zoom 16, image 400x400 px, tiles 256 px, tile freshness 7 days, user agent as the app's map (`flutter_map (app.findme.mobile)`).
- Redraw at most once a minute. Label refresh about every 30 minutes (`updatePeriodMillis` 1800000) when Dart is not running.
- Widget files live in `<getApplicationSupportDirectory>/widget/`, excluded from Android backup.
- Empty-state text: `Chưa ghi hành trình`.
- A widget failure must never lose a fix or stop an upload.
- Deliberate shortcuts are marked `ponytail:` with their ceiling.

## Review Focus

1. Map server blocked (the owner's office network): a failed tile is not requested again for 5 minutes, and drawing still completes. Test in Task 4.
2. Offline with an expired cached tile: the old tile is used, not a blank square. Test in Task 4.
3. A fix still queued when sign-out clears the widget: it must not bring the location back. Test in Task 6.
4. A half-written last line in the day file after a crash: skipped, the rest still loads. Test in Task 3.
5. Rendering throws once: the next minute tries again, and the tracker's queue is untouched. Tests in Tasks 6 and 7.

---

### Task 1: Draft the guide chapter

**Files:**
- Create: `docs/guide/17-home-screen-widget.md`
- Modify: `docs/guide/README.md` (add row 16 after row 15)

No code in this task. Match the tone of `docs/guide/15-background-tracking.md`: the reader is a web developer new to mobile.

- [ ] **Step 1: Create the branch** with `git switch -c feat/home-widget`.

- [ ] **Step 2: Write the chapter's concept sections**

Sections: what a home-screen widget is, and why Flutter cannot draw one (the launcher process draws it); `AppWidgetProvider` as a broadcast receiver; `RemoteViews` as a description of a screen sent to another app; the path of a picture from Dart to the home screen; why widgets refresh rarely (30-minute minimum, battery) and why this app can do better while the tracker runs; OSM tile etiquette and the credit; what iPhone would need (WidgetKit, App Group, a Mac or hand-edited Xcode project). End with a section titled `Status: draft, finished after the code` listing what Task 9 adds.

- [ ] **Step 3: Add the README row**

`| 17 | [Home-screen widget](17-home-screen-widget.md): widgets, RemoteViews, drawing a map picture in Dart |`

- [ ] **Step 4: Commit** `docs(guide): draft the home-screen widget chapter`

---

### Task 2: Throwaway test of background drawing (gate)

**Files:** throwaway, on branch `spike/home-widget` from `feat/home-widget`. Never merged.

Purpose: prove that Dart can fetch a tile, decode `assets/images/hachiware.webp`, draw with `dart:ui` and write a PNG while the app's screen is gone.

- [ ] **Step 1: Add the throwaway code**

`flutter pub add home_widget`. Temporary code: call `turnOn()` at start-up, and from `_onFix` run one drawing pass that fetches one tile with `HttpClient`, decodes it and the Hachiware asset, draws them with `PictureRecorder`, calls `toImage(400, 400)`, and writes `widget-spike.png` to the application support directory. Log `widget-spike ok` or the error's `runtimeType`.

- [ ] **Step 2: Run it with the app swiped away**

```powershell
flutter run --flavor dev --dart-define-from-file=config/dev.json
adb shell pm grant app.findme.mobile.dev android.permission.ACCESS_FINE_LOCATION
adb shell pm grant app.findme.mobile.dev android.permission.ACCESS_BACKGROUND_LOCATION
```

Swipe the app out of Recents, leaving the tracker notification up. Send moves with `adb emu geo fix <lon> <lat>`, using a different position each time. Do this at least 3 times, 30 seconds apart.

- [ ] **Step 3: Check the result**

Run `adb logcat -d | Select-String widget-spike` and `adb shell run-as app.findme.mobile.dev ls -l files/widget-spike.png`, using the path the app logged if it differs.
Expected: `widget-spike ok` after the swipe, and the file's time changing with each move.

- [ ] **Step 4: Repeat after a reboot**

`adb reboot`, leave the app unopened, send moves. This exercises `trackerBoot`'s engine. Expected: same as Step 3.

- [ ] **Step 5: Decide**

If both pass: note what was learned for the guide, `git switch feat/home-widget`, delete the spike branch, continue.
If either fails: **stop and report to the owner.** The fallback (drawing in Kotlin) is a change of design, and Tasks 3-9 do not apply as written.

---

### Task 3: Tile maths and the day log

**Files:**
- Create: `lib/features/widget/domain/tile_math.dart`
- Create: `lib/features/widget/domain/day_log.dart`
- Create: `lib/features/widget/data/file_day_log.dart`
- Test: `test/features/widget/tile_math_test.dart`, `test/features/widget/file_day_log_test.dart`

**Interfaces:**
- Produces:
  - `const widgetZoom = 16; const widgetSizePx = 400; const tileSizePx = 256;`
  - `class TileKey { final int z, x, y; }` with value equality
  - `Set<TileKey> tilesFor(double lat, double lon, {int zoom = widgetZoom, int sizePx = widgetSizePx})`
  - `Offset toImage(double lat, double lon, {required double centreLat, required double centreLon})`, image pixels, with the centre at `(200, 200)`
  - `Rect tileRect(TileKey key, {required double centreLat, required double centreLon})`, where the tile lands in the image
  - `class DayTrail { final List<Fix> today; final Fix? last; }`
  - `abstract interface class DayLog { Future<void> append(Fix f); Future<DayTrail> read(DateTime now); Future<void> clear(); }`
  - `class FileDayLog implements DayLog { FileDayLog(Directory dir); }`, files `day.jsonl` and `last.json`, using `Fix.toJson`

- [ ] **Step 1: Write the failing tests**

```dart
test('tilesFor at 0,0 covers the four tiles around the centre', () {
  expect(tilesFor(0, 0).map((k) => k.x).toSet(), {32767, 32768});
  expect(tilesFor(0, 0).map((k) => k.y).toSet(), {32767, 32768});
  expect(tilesFor(0, 0).every((k) => k.z == 16), isTrue);
});
test('the centre lands in the middle of the image', () {
  expect(toImage(21.03, 105.85, centreLat: 21.03, centreLon: 105.85), const Offset(200, 200));
});
test('east is right and north is up', () {
  final p = toImage(21.04, 105.86, centreLat: 21.03, centreLon: 105.85);
  expect(p.dx, greaterThan(200));
  expect(p.dy, lessThan(200));
});
test('tileRect at 0,0 puts tile 32768,32768 from the image centre', () {
  expect(tileRect(const TileKey(16, 32768, 32768), centreLat: 0, centreLon: 0),
      const Rect.fromLTWH(200, 200, 256, 256));
});
```

For `FileDayLog`, using a temp directory and fixes built with explicit local `DateTime`s:

- `read returns today's fixes in order and the last one`
- `read the next day: today is empty, last is still yesterday's last fix`
- `append on a new day drops the old day's lines from the file`
- `a half-written last line is skipped` (write `{"t":"20` to the end of `day.jsonl`, then expect the complete lines)
- `clear removes everything: today empty, last null`

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/widget`
Expected: FAIL, the libraries do not exist.

- [ ] **Step 3: Implement**

Web Mercator: `worldX = (lon + 180) / 360 * 2^z * 256`, `worldY = (1 - asinh(tan(latRad)) / pi) / 2 * 2^z * 256`. `FileDayLog` serialises its operations the way `PointQueue._serial` does. Compare local calendar dates.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/widget`
Expected: PASS

- [ ] **Step 5: Commit** `feat(widget): tile maths and the day's points`

---

### Task 4: Tile cache

**Files:**
- Create: `lib/features/widget/data/tile_cache.dart`
- Test: `test/features/widget/tile_cache_test.dart`

**Interfaces:**
- Consumes: `TileKey`
- Produces:
  - `typedef TileFetch = Future<Uint8List?> Function(TileKey key);`
  - `abstract interface class WidgetTiles { Future<Uint8List?> get(TileKey key); }`
  - `class TileCache implements WidgetTiles { TileCache(Directory dir, TileFetch fetch, DateTime Function() now, {int maxFiles = 200}); }`
  - `Future<Uint8List?> fetchOsmTile(TileKey key)`, the real fetch: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, `User-Agent: flutter_map (app.findme.mobile)`, returns null on any failure

- [ ] **Step 1: Write the failing tests**

With a counting fake `TileFetch` and a settable clock:

- `a fresh cached tile is returned without fetching` (fetch count stays 1 over two gets)
- `a tile older than 7 days is fetched again and replaced`
- `an expired tile is returned when the fetch fails`
- `a missing tile whose fetch fails returns null`
- `a failed tile is not requested again for 5 minutes, then is` (count 1 at +4 min, count 2 at +6 min)
- `over maxFiles, the oldest files go` (maxFiles 2, three tiles, the first is gone from disk)

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/widget/tile_cache_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement**

Files are `tiles/{z}_{x}_{y}.png`, and age comes from the file's modified time compared against the injected clock. Tests set modified times with `File.setLastModifiedSync`. Failed tiles are remembered in memory only. Write through a temp file and rename. Mark the file-count limit `ponytail:`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/widget/tile_cache_test.dart`
Expected: PASS

- [ ] **Step 5: Commit** `feat(widget): tile cache that respects OpenStreetMap`

---

### Task 5: Draw the picture

**Files:**
- Create: `lib/features/trail/presentation/trail_painting.dart`
- Modify: `lib/features/trail/presentation/paw_layer.dart`, `lib/features/trail/presentation/map_view.dart` (use the shared code)
- Create: `lib/features/widget/data/render.dart`
- Test: `test/features/widget/render_test.dart`

**Interfaces:**
- Consumes: `TileKey`, `tileRect`, `toImage`, `pawSize`, `pawColor`, `bearing`, `Palette.page`
- Produces:
  - `void paintPaws(Canvas canvas, List<TrackPoint> points, {required Offset Function(TrackPoint) project, required Size area, required double size, Color? color})`
  - `const pastelMatrix = <double>[...]` (moved from `_pastel` in `map_view.dart`)
  - `class WidgetScene { final List<TrackPoint> trail; final TrackPoint here; }`
  - `Future<Uint8List> renderWidgetPng(WidgetScene scene, Map<TileKey, Uint8List> tiles, Uint8List hachiware)`

- [ ] **Step 1: Move the paw loop and `_drawPaw` into `paintPaws`, and `_pastel` into `pastelMatrix`, with no behaviour change**

- [ ] **Step 2: Run the existing map tests**

Run: `flutter test test/features/trail`
Expected: PASS

- [ ] **Step 3: Write the failing tests**

Use `testWidgets` with `tester.runAsync`, because image decoding needs real async. Decode the result with `instantiateImageCodec`, and read pixels with `toByteData`.

- `the picture is 400x400`
- `a missing tile leaves Palette.page` (corner pixel equals `Palette.page`, with an empty tile map)
- `a tile is drawn with the pastel tint` (a solid red PNG as every tile: corner pixel is neither pure red nor `Palette.page`)
- `an empty trail still draws Hachiware` (pixels around the centre differ from a corner)
- `a trail point far outside the image does not throw`

- [ ] **Step 4: Run to verify they fail**

Run: `flutter test test/features/widget/render_test.dart`
Expected: FAIL

- [ ] **Step 5: Implement `renderWidgetPng`**

Order: `Palette.page` fill, tiles through `ColorFilter.matrix(pastelMatrix)` at `tileRect`, `paintPaws` at `pawSize(widgetZoom)`, a blurred pink circle, Hachiware 56 px tall with feet on `here`, then `© OpenStreetMap` at 10 px bottom-right with a white half-transparent backing. Use `PictureRecorder`, `toImage(400, 400)`, `ImageByteFormat.png`. Corners stay square, since the widget layout rounds them.

- [ ] **Step 6: Run to verify they pass**

Run: `flutter test test/features/widget/render_test.dart test/features/trail`
Expected: PASS

- [ ] **Step 7: Commit** `feat(widget): draw the map picture in Dart`

---

### Task 6: The updater

**Files:**
- Create: `lib/features/widget/domain/trail_widget.dart`
- Create: `lib/features/widget/data/widget_updater.dart`
- Test: `test/features/widget/widget_updater_test.dart`

**Interfaces:**
- Consumes: `DayLog`, `DayTrail`, `WidgetTiles`, `tilesFor`, `WidgetScene`, `Fix`
- Produces:
  - `abstract interface class TrailWidget { void onFix(Fix f); void start(); void stop(); Future<void> refresh(); Future<void> clear(); }`
  - `class NoTrailWidget implements TrailWidget`, every method does nothing
  - `final trailWidgetProvider = Provider<TrailWidget>((_) => NoTrailWidget());`
  - `abstract interface class WidgetHost { Future<void> publish(Uint8List png, DateTime lastFix); Future<void> refreshLabel(); Future<void> clear(); }`
  - `typedef WidgetRender = Future<Uint8List> Function(WidgetScene scene, Map<TileKey, Uint8List> tiles);`
  - `class WidgetParts { final DayLog days; final WidgetTiles tiles; final WidgetHost host; final WidgetRender render; }`
  - `class WidgetUpdater implements TrailWidget { WidgetUpdater(Future<WidgetParts> parts, DateTime Function() now); @visibleForTesting Future<void> idle(); }`

- [ ] **Step 1: Write the failing tests**

Use in-memory fakes for `DayLog`, `WidgetTiles`, `WidgetHost`, a counting `WidgetRender`, and `fakeAsync`:

- `several fixes within a minute give one publish, at the minute's end` (3 fixes over 30 s, publishes == 0 before the tick and 1 after)
- `the last fix of a burst is drawn although no more follow`
- `a minute with no new fix refreshes the label only` (publishes unchanged, refreshLabel +1)
- `start publishes straight away when there is a last fix`
- `refresh with nothing recorded publishes nothing`
- `crossing local midnight redraws with an empty trail and here = last fix` (no new fix)
- `stop ends the timer`
- `clear clears the host`
- `a fix arriving after clear is ignored until start` (no append, no publish)
- `a draw running during clear does not publish` (render held on a `Completer`, clear, complete: publishes == 0, host cleared)
- `render throwing once: the next minute tries again and publishes`
- `a DayLog failure in onFix does not throw to the caller`

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/widget/widget_updater_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement**

Only the minute timer draws, apart from `start` and `refresh`, which is what makes the once-a-minute rule hold. Keep a `_dirty` flag, the local date of the last draw, a `_closed` flag (set by `clear`, unset by `start`) and an int generation bumped by `clear` and checked just before `publish`. One draw at a time, and a fix during a draw leaves `_dirty` set. Fetch only `tilesFor(here)`. Catch everything, and log `runtimeType` only. Convert fixes with `TrackPoint(f.lon, f.lat, f.at.millisecondsSinceEpoch ~/ 1000, f.acc)`.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/widget/widget_updater_test.dart`
Expected: PASS

- [ ] **Step 5: Commit** `feat(widget): redraw once a minute from the tracker's fixes`

---

### Task 7: Connect the tracker

**Files:**
- Modify: `lib/features/tracker/presentation/tracker_controller.dart`
- Test: `test/features/tracker/presentation/tracker_controller_test.dart`

**Interfaces:**
- Consumes: `trailWidgetProvider`, `TrailWidget`

- [ ] **Step 1: Write the failing tests**

Add a `FakeTrailWidget` recording calls and, optionally, throwing from `onFix`. Override `trailWidgetProvider` in `setUp`.

- `each fix goes to the widget after it is in the queue`
- `turnOn starts the widget and turnOff stops it`
- `resume refreshes the widget even with tracking off`
- `forget clears the widget before its upload wait` (ingest held on a `Completer`: `cleared` is true while the upload is pending)
- `a widget that throws on onFix does not stop the fix being queued or uploaded`

- [ ] **Step 2: Run to verify they fail**

Run: `flutter test test/features/tracker/presentation/tracker_controller_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement**

`_onFix`: after `append`, call `onFix` inside try/catch. `_start`: `start()`. `_stop`: `stop()`. `resume`: `unawaited(refresh())` first. `forget`: after `_stop()`, `await clear()` inside try/catch, before the upload wait.

- [ ] **Step 4: Run to verify they pass**

Run: `flutter test test/features/tracker`
Expected: PASS

- [ ] **Step 5: Commit** `feat(widget): the tracker feeds the widget`

---

### Task 8: The Android widget

**Files:**
- Create: `lib/features/widget/data/live_trail_widget.dart`, `lib/features/widget/data/home_widget_host.dart`
- Modify: `lib/main.dart`, `pubspec.yaml`
- Create: `android/app/src/main/kotlin/app/findme/findme/TrailWidgetProvider.kt`
- Create: `android/app/src/main/res/layout/trail_widget.xml`, `res/xml/trail_widget_info.xml`, `res/xml/backup_rules.xml`, `res/xml/data_extraction_rules.xml`, `res/drawable/trail_widget_bg.xml`, `res/drawable-nodpi/widget_hachiware.webp` (copy of the asset)
- Modify: `android/app/src/main/AndroidManifest.xml`
- Test: `test/features/widget/live_trail_widget_test.dart`

**Interfaces:**
- Consumes: `WidgetUpdater`, `WidgetParts`, `TileCache`, `fetchOsmTile`, `FileDayLog`, `renderWidgetPng`, `WidgetHost`, `trailWidgetProvider`
- Produces:
  - `TrailWidget liveTrailWidget(TargetPlatform platform)`, `NoTrailWidget` on anything but Android
  - Shared keys `findme.widget.png` (String path) and `findme.widget.lastFix` (epoch ms), both removed on clear

- [ ] **Step 1: Write the failing test**

```dart
test('iOS gets no widget', () {
  expect(liveTrailWidget(TargetPlatform.iOS), isA<NoTrailWidget>());
});
test('Android gets the updater', () {
  expect(liveTrailWidget(TargetPlatform.android), isA<WidgetUpdater>());
});
```

- [ ] **Step 2: Run to verify it fails**

Run: `flutter test test/features/widget/live_trail_widget_test.dart`
Expected: FAIL

- [ ] **Step 3: Add the package and the Dart side**

`flutter pub add home_widget`. `HomeWidgetHost` writes `widget.png` through a temp file and rename, saves the two keys with `HomeWidget.saveWidgetData`, then `HomeWidget.updateWidget(qualifiedAndroidName: 'app.findme.findme.TrailWidgetProvider')`. `WidgetParts` are built lazily in a `Future` from `getApplicationSupportDirectory()`. The Hachiware bytes come from `rootBundle`. Override `trailWidgetProvider` with `liveTrailWidget(defaultTargetPlatform)` in both `main()` and `trackerBoot()`.

- [ ] **Step 4: Add the Kotlin and the resources**

`TrailWidgetProvider : HomeWidgetProvider()`. In `onUpdate`: if the path or the file is missing, show the empty state with `Chưa ghi hành trình`, otherwise set the bitmap with `BitmapFactory.decodeFile` and the label from `agoLabel(nowMs, thenMs)`. `agoLabel` copies `ago()` exactly: `min = round(ms / 60000.0)`, `< 1` → `vừa xong`, `< 60` → `$min phút trước`, `h = round(min / 60.0)`, `< 24` → `$h giờ trước`, else `${round(h / 24.0)} ngày trước`. The tap uses `HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)`.

`trail_widget_info.xml`: `minWidth`/`minHeight` 110dp, `targetCellWidth`/`targetCellHeight` 2, `resizeMode="none"`, `updatePeriodMillis="1800000"`, `widgetCategory="home_screen"`, `previewLayout` = the widget layout. The layout's root uses `trail_widget_bg` with 24dp corners and `clipToOutline`.

Manifest: a `<receiver>` for `.TrailWidgetProvider` with `exported="false"`, the `APPWIDGET_UPDATE` filter and `android.appwidget.provider` meta-data. On `<application>`, add `android:fullBackupContent="@xml/backup_rules"` and `android:dataExtractionRules="@xml/data_extraction_rules"`. Both rule files exclude domain `file`, path `widget/` only.

- [ ] **Step 5: Verify**

Run: `flutter test` then `flutter analyze` then `flutter build apk --flavor dev --debug --dart-define-from-file=config/example.json`
Expected: all tests pass, no analyzer issues, APK built.

- [ ] **Step 6: Commit** `feat(widget): Android home-screen widget`

---

### Task 9: Try it on the emulator and finish the docs

**Files:**
- Modify: `docs/guide/17-home-screen-widget.md`, `docs/guide/cheatsheet.md`, `docs/HANDOFF.md`
- Fix anything the device run finds, with a test where one is possible.

- [ ] **Step 1: Run the device checks**

On the dev flavor with the widget on the home screen and the app swiped away:

| Check | Expected |
|---|---|
| Add the widget before recording | Empty state, tapping opens the app |
| Turn the tracker on, send moves with `adb emu geo fix` | Map, paws and Hachiware within about a minute, in the pastel tint |
| Stand still for 3 minutes | Label counts up, picture unchanged |
| `adb shell svc wifi disable; adb shell svc data disable`, then move | Trail still updates over the cached map |
| Sign out | Empty state straight away |
| `adb reboot` with the tracker on | Keeps updating without opening the app |
| Set the emulator's date just before midnight | Trail empties, Hachiware stays |

- [ ] **Step 2: Finish the guide chapter**

Replace the draft status section with: the real files, adding the widget on the emulator, the checks above, and what the Task 2 test taught. Add cheatsheet lines for the `adb emu geo fix` route and the widget's files.

- [ ] **Step 3: Update `docs/HANDOFF.md`**

Say what was verified on the emulator and what was not (no iPhone widget, no real device unless one was used).

- [ ] **Step 4: Verify**

Run: `dart format .`, `flutter analyze`, `flutter test`
Expected: clean, all pass.

- [ ] **Step 5: Commit** `docs(widget): finish the chapter and handoff`

- [ ] **Step 6: Run the iOS CI job**

After the owner agrees to push the branch: `gh workflow run` for the workflow described in `docs/guide/12-ci.md`, on `feat/home-widget`. Expected: the iOS job passes, or fails only for reasons also present on `main`.
