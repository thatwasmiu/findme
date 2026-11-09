# 16. Home-screen widget (where am I now)

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

## Status: draft, finished after the code

Written before the code, so you can read the concepts first. These sections come once it's built:

- the real files and what each one does,
- how to add the widget on the emulator,
- how to test it with a fake route, offline, after a reboot, and across midnight,
- what the first test of drawing in the background taught us.
