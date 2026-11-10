# 17. Home-screen widget (where am I now)

A small square on the Android home screen shows the last spot the tracker recorded, today's paw trail and Hachiware,
on the same pastel map as the app, without opening it.

Design: `docs/superpowers/specs/2026-11-09-home-widget-design.md`. Chapter 15 explains the tracker that feeds it.

## 1. What and why

### What a home-screen widget really is

Coming from the web, you might picture a widget as a tiny always-open page of your app. It isn't. The home screen is
**another app** (the launcher), and your code doesn't run inside it. Your app only sends the launcher a description
of what to show, and the launcher draws it. Most of the time none of your code is running at all.

That explains the rest of this chapter:

- **Flutter can't draw a widget.** Flutter paints its own pixels on a surface inside your app, and the launcher has
  no way to host that. A widget has to be described in Android's native terms.
- **There is no animation or hot state.** Hachiware hops in the app, but on the home screen she stands still. You
  send a finished description and it stays there until you send another.
- **Scrolling a map is impossible.** A widget can't host a real interactive map, so Find Me sends a **picture** of one.

### The two Android pieces

| Piece | Think of it as | What it does |
|---|---|---|
| **`AppWidgetProvider`** | A webhook handler | A class Android calls when something happens to the widget, such as "it was added" or "time to update". It's a kind of **broadcast receiver**, like `BootReceiver` from chapter 15: it wakes up, does a little work, and ends. |
| **`RemoteViews`** | A serialised view tree, like sending HTML to another process | A description of the layout plus values to fill in: "this image here, this text there". Only a short list of simple views is allowed: `ImageView` and `TextView` yes, custom drawing no. |

The layout is an XML file (`res/layout/`), and another XML file (`res/xml/`) tells the launcher the widget's size and
how often to refresh. The manifest registers the provider, the same way it registers `BootReceiver`.

### How a picture gets from Dart to the home screen

```
GPS fix -> TrackerController -> widget code saves the point
                                       |  (once a minute)
                                       v
                    Dart draws a PNG: map tiles + paws + Hachiware
                                       |
                                       v
                    PNG file + "last seen" time saved on the phone
                                       |  home_widget package: "please update"
                                       v
                    Kotlin provider reads them, builds RemoteViews
                                       |
                                       v
                    Launcher shows it on the home screen
```

Drawing happens in Dart because the app already knows how to paint paws and tint a map, and because Dart code can be
tested with `flutter test`. The [`home_widget`](https://pub.dev/packages/home_widget) package is the bridge. Kotlin
only shows the result.

One thing can't live in the picture: the **"12 phút trước" label**. It has to keep counting when Dart isn't running,
so Kotlin works it out each time the widget updates, from the saved time.

### Why widgets refresh so rarely, and how Find Me gets around it

A widget on its own can ask Android for an update at most **every 30 minutes**. This is deliberate: a phone with 20
widgets waking up constantly would have a dead battery by lunchtime.

Find Me has an advantage. While the tracker is on, its foreground service (chapter 15) is already running, so it can
push a new picture to the widget whenever it likes. It redraws **once a minute at most**, which is frequent enough to
feel current. When the tracker is off, only the 30-minute refresh is left, and that just updates the label. The
picture stays as it was, which is why the age is always visible: an old location must never look current.

Locket feels instant for a different reason: **push messages** from its server wake the widget. Find Me doesn't need
them here, because the location comes from the phone itself.

### Being polite to the map server

OpenStreetMap's tile servers are free and run on donations, and their usage policy says so plainly. A widget that
redraws all day could be a real nuisance, so Find Me:

- keeps downloaded tiles on the phone for at least 7 days,
- only asks for a tile it doesn't already have,
- waits 5 minutes before retrying a tile that failed (your office network blocks these servers, for example),
- identifies itself, and shows the required **© OpenStreetMap** credit on the picture.

### What iPhone would need

The idea carries over, but the pieces differ: **WidgetKit** with a SwiftUI view instead of `RemoteViews`, and a
separate **widget extension** target in the Xcode project. The app and the extension can only share files through an
**App Group**. iOS also controls when widgets refresh much more strictly. Adding an extension target is awkward
without a Mac, so iPhone is left for later. On iPhone the widget code simply does nothing for now.

## 2. The real files

| File | What it does |
|---|---|
| `lib/features/widget/domain/tile_math.dart` | Web Mercator maths: which map tiles cover the picture, and where a point lands in it |
| `lib/features/widget/domain/trail_widget.dart` | `TrailWidget`, what the tracker calls. `NoTrailWidget` does nothing (tests, iPhone) |
| `lib/features/widget/data/file_day_log.dart` | Today's points in `day.jsonl`, the latest point in `last.json`. Needed because the tracker's queue deletes points once uploaded |
| `lib/features/widget/data/tile_cache.dart` | Map tiles on the phone, and the polite fetching described above |
| `lib/features/widget/data/render.dart` | Draws the 400x400 PNG with `dart:ui` |
| `lib/features/widget/data/widget_updater.dart` | The once-a-minute rule, and clearing without a late draw bringing the location back |
| `lib/features/widget/data/home_widget_host.dart` | Saves the PNG, hands its path and the time to Kotlin through the `home_widget` package |
| `android/.../TrailWidgetProvider.kt` | Reads those two values, builds `RemoteViews`, works out the age label |
| `android/app/src/main/res/layout/trail_widget.xml` | The layout: picture, age chip, credit, empty state |
| `android/app/src/main/res/xml/trail_widget_info.xml` | Size (2x2) and the 30-minute refresh |
| `android/app/src/main/res/xml/backup_rules.xml`, `data_extraction_rules.xml` | Keep `files/widget/` (today's locations) out of backups |

The widget's files live in `files/widget/`, which `getApplicationSupportDirectory()` points to on Android.

## 3. What the emulator taught us

The plan's biggest worry was whether Dart can draw a picture with no screen. It can: `dart:ui`'s `Picture.toImage`
worked with the app swiped away and after a reboot, when no activity exists at all.

The surprise was elsewhere. **Swiping the app out of Recents stopped the tracker itself**, widget or no widget. A
`FlutterActivity` normally creates its own Flutter engine and destroys it when the activity goes. No engine means no
Dart, and geolocator stops its foreground service when its engine detaches. The fix is in `MainActivity.kt`: it hands
Flutter one engine kept in `FlutterEngineCache` for the life of the process, so the engine outlives the screen, and
the next screen attaches to it. Think of it as moving a long-running job out of a page and into a server process.

The second finding: a "2x2" widget isn't square on every launcher. On the emulator it is much taller than wide, and
`centerCrop` cut off the edges of the picture. Anything that must stay visible, like the **© OpenStreetMap** credit,
has to be a real view in the layout rather than pixels in the image.

## 4. Run and test

**Testing with a signed-in real account?** Moving the emulator records fake points and uploads them. Build with a
copy of `config/dev.json` whose `API_URL` and `WEB_ORIGIN` point at `https://blocked.invalid`, and afterwards turn
the tracker off and delete `app_flutter/tracker/queue.jsonl`, or the fake points go up with the next real upload.

Add the widget: long-press the home screen → **Widgets** → **Find Me Dev** → drag it out. Then turn on 🧭 **Ghi hành
trình** and send moves, a different spot each time, at least 10 m apart:

```powershell
adb emu geo fix 105.8522 21.0285
adb emu geo fix 105.8526 21.0289
```

| Check | Expected |
|---|---|
| Add the widget before recording | Hachiware and "Chưa ghi hành trình" |
| Send moves | Map, paws and Hachiware within about a minute |
| Stand still for 3 minutes | Label counts up, picture unchanged |
| Swipe the app out of Recents, send moves | Tracker notification stays, picture still changes |
| `adb shell svc wifi disable`, `adb shell svc data disable`, then move | Trail updates over the map tiles already on the phone; where there are none, plain pastel |
| `adb reboot` with the tracker on, don't open the app | Keeps updating |
| Clock just before midnight (emulator only: `adb root`, `adb shell settings put global auto_time 0`, `adb shell date MMDDhhmmYYYY.ss`, and set `auto_time` back to 1) | Paws gone, Hachiware stays |
| Sign out | Empty state straight away |

## Troubleshooting

| Symptom | Fix |
|---|---|
| Stays on "Chưa ghi hành trình" | No fix yet, or the first minute hasn't passed. Check the tracker sheet's "Điểm cuối". |
| Label moves but the picture doesn't | You're standing still (the tracker ignores moves under 10 m), or the app's process is gone. |
| Plain pastel behind the paws | Those map tiles aren't on the phone and the server can't be reached. A failed tile is retried after 5 minutes, at the next redraw. |
| Age only changes every 30 minutes | The tracker is off, so only Android's own refresh is left. |
