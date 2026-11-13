# Chapter 19: Trip mode

The phone side of trip mode (`travel-heatmap`, chapter 22 of its guide, has the server). An account is either
**Luôn bật** (always on: the tracker works exactly as in chapter 15) or **Chỉ khi đi** (trip mode: nothing is
recorded or shown until you start a trip, and the trip ends by itself). New accounts start in trip mode; existing
ones stay always on. Until the server has trip mode deployed, `GET /me` has no `sharing` field and none of this shows.

## Where to find it

| You want | Do |
|---|---|
| Start a trip | 🧭 → "Bắt đầu chuyến đi" → 15 phút · 1 giờ · đến tối nay · đến khi tắt. Or the "Chuyến đi" Quick Settings tile, or ⏺ on the home widget (both use the last preset; "1 giờ" the first time). |
| End it early | 🧭 → "Kết thúc", or tap the tile / ⏹ again. |
| Pick another length from outside the app | Long-press the tile: the app opens on the presets. |
| Switch the mode | 👤 → "Luôn bật" / "Chỉ khi đi". |

Add the tile once: pull down Quick Settings → ✏️ → drag "Chuyến đi" up.

## How it works

- The tracker is still the only recorder (`TrackerController`). In trip mode it is driven by the trip:
  `startTrip(preset)` uploads what is queued (it belongs to the earlier trip's window), calls
  `PUT /me/sharing {start}`, then `turnOn()`; `endTrip()` calls `turnOff()`, uploads, then `PUT {end: true}`.
- The end time is kept in `TrackerStore` (`findme.tripUntil`). GPS stops at it from four places: an Android alarm,
  every fix (a fix after the end is dropped), every upload tick, and `resume()` / `wake()`.
- **The server is the judge.** On app open and every time the app comes back, `GET /me` says whether a trip is on;
  no trip → tracker off. `/ingest` answers `trip: false` when no trip is on (ended on the web, or by its timer) → the
  uploader turns the tracker off. A friend or a link never sees a point outside the window even if the phone is late.
- **Offline start:** GPS starts with the end worked out on the phone (`localEnd`), and the start is kept as
  "pending"; the next upload sends it first and waits for it (until the server has the window it drops every point).
  An offline end is retried at the next app open.
- **Friends:** `/track` says where viewing starts (`visibleFrom`) or `trip: false`; `friendMerge` drops prints from
  before it, and everything on `trip: false`. A friend not on a trip reads "không trong chuyến đi" in 👥.

## Android: the tile, the widget button, the alarm

All three live in Kotlin and only pass messages; Dart decides (`findme/trip` channel, `trip_channel.dart` ⇄
`TripBridge.kt`):

- Dart → Kotlin `sync(until)`: set (or cancel) the alarm, redraw the tile and the widget from Dart's prefs
  (`flutter.findme.sharing`, `flutter.findme.tracking`, `flutter.findme.tripUntil`).
- Kotlin → Dart `toggle` (tile / widget tap), `expire` (alarm), `picker` (tile long-press while the app runs).
- A command goes to the engine that already runs (the app's, or the screenless one). Two engines would both write
  the queue file, so a new one is started only when none runs: the `tripCommand` entrypoint in `main.dart`.
- Without "Luôn luôn" location or the disclosure, a tap opens the app on the presets instead (a screenless engine
  cannot ask for permission).
- The alarm is inexact (`setAndAllowWhileIdle`, no special permission): in deep sleep it may ring several minutes
  late. The server's window is exact, so nothing after the end is ever stored.

Not built yet: "Kết thúc" and "còn 42 phút" on the tracking notification (needs our own foreground service), iPhone
controls (there the check on each fix is what stops it).

## Try it

```powershell
flutter test test/features/tracker
# on a device, with the server deployed and a trip-mode account:
adb shell cmd statusbar click-tile app.findme.mobile.dev/app.findme.findme.TripTileService
```
