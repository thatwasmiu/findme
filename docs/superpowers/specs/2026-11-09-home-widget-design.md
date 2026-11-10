# Home-screen widget: where I am now

Date: 2026-11-09. Status: built on branch `feat/home-widget`; see `docs/HANDOFF.md`.

## Why

The owner wants to glance at the phone's home screen and see where they are now and the paw trail of their day,
without opening the app. It is a small personal touch inspired by Locket, not a social feature.

## What the owner decided

- It shows **their own trail**, with **their current location**: the last spot the tracker recorded on this phone.
- Look **A from the mockups: a real map** with the paw trail, Hachiware on the latest spot, and a "2 phút trước" label.
- **A guide chapter is part of the work, for learning.** Either order was fine with the owner.

## Goals

- Shows the latest tracker position and today's trail on a pastel map, like the app's map.
- Keeps updating while the app is closed, as long as the tracker is on.
- Android first. Nothing in this work may stop the iOS build.

## Non-goals

- iPhone widget. It needs a WidgetKit extension and an App Group, and the owner has no Mac. Later, separately.
- Friends, photos, push messages, any backend change.
- Live updates to the second.
- Several sizes or settings. One widget, no configuration screen.

## Anti-goals

- A widget that drains the battery or hammers the OpenStreetMap servers.
- An old location that looks current. The age must always be visible.
- A location left on the screen after signing out.
- Tokens or coordinates in logs (project rule).
- Disturbing the tracker: a widget failure must never lose a fix or stop an upload.

## How it behaves

The calls below are Claude's, played back to the owner, who raised no objection. They can still be changed.

| Situation | Behaviour |
|---|---|
| Layout | About 2x2 cells, square, rounded. Pastel map centred on the latest spot, fixed zoom 16. Trail parts outside the square are cut off. Hachiware on the latest spot with its pink glow. |
| Label | Bottom-left chip: "vừa xong", "12 phút trước", "3 giờ trước", "2 ngày trước", same words as `ago()` in `lib/core/time/format.dart`. |
| Credit | A tiny "© OpenStreetMap" in a corner. The mockup left it out, but the map's licence requires it. |
| Tap | Opens the app. |
| Tracker on, moving | Redraws at most once a minute. The last fix of a burst is drawn too, even if no more fixes follow. |
| Tracker on, standing still | No fixes arrive (10 m distance filter), so no redraw. The label is refreshed once a minute. |
| Tracker off, or app process gone | Keeps the last picture. The label is refreshed about every 30 minutes (Android's minimum). |
| No internet, or map server blocked | Uses map tiles already on the phone. The trail is still drawn on top. A missing tile is plain page colour (`Palette.page`). |
| Midnight (phone's local time) | The trail starts empty. Hachiware stays on the last spot. If the tracker is off, nothing can redraw at midnight, so the old picture stays until the app or tracker next runs. Its label still shows its age. |
| Deliberate sign-out, or another account signs in | Widget clears at once and shows the empty state. A lapsed session does not clear it, matching the tracker. |
| Nothing recorded yet | Empty state: pastel background, Hachiware, "Chưa ghi hành trình". This wording is new, the web has no widget. |

The trail contains only what the tracker recorded on this phone today. It does not ask the server, so a day when the
tracker started at noon shows the trail from noon.

## How it gets made

Claude's calls, based on what the app already has:

- **Drawing stays in Dart.** Kotlin only shows a finished picture. This reuses the paw painting and the pastel colour
  matrix from `lib/features/trail/presentation/`, keeps the logic testable with `flutter test`, and suits an owner who
  is new to native code.
- **`home_widget` package** connects Dart and the Android widget. It works on both the app's engine and the headless
  engine that `BootReceiver` starts, because plugins register per engine.
- **A new feature folder** `lib/features/widget/{data,domain}`. Pure logic (tile maths, which tiles are needed, the
  once-a-minute rule, the day's points) goes in `domain`.
- **The tracker's queue cannot be the source.** `PointQueue` deletes points once uploaded, so the widget keeps its own
  file of today's points. `TrackerController._onFix` hands each fix to the widget code after the queue write, without
  awaiting it and with errors swallowed. The file goes in a folder excluded from Android cloud backup.
- **Map tiles** are fetched by Dart with the same user agent as the app's map, cached on disk, kept at least 7 days,
  and fetched only when the set of tiles needed changes. This follows OpenStreetMap's tile usage policy.
- **The picture** is a PNG of about 400x400 px written to app-private storage. Kotlin loads it into the widget. Keep
  it small enough for Android's limit on widget updates (about 1 MB).
- **The age label is computed in Kotlin**, from a stored timestamp, every time the widget updates. It has to work
  when Dart is not running. It copies the wording and rounding of `ago()`.
- **A one-minute timer** runs while the tracker is on: it redraws if new points arrived, otherwise only updates the
  label.
- **Clearing** happens at the start of `TrackerController.forget()`, before its upload wait of up to 10 seconds. A
  draw already running when the clear happens must not publish its picture afterwards.
- On iOS all widget calls are skipped.

## Biggest unknown: test this first

Drawing a picture and fetching tiles from Dart while the app's screen is gone has not been tried here. The tracker's
background running is itself listed in `docs/HANDOFF.md` as not yet seen on a device. So the first code step is a
throwaway test on the emulator: swipe the app away with the tracker on, and check that a picture is still drawn and
reaches the widget.

If it fails, the fallback is to draw in Kotlin instead (tiles, tint and a simplified paw), with Dart only saving the
points. That is more native code and more work, so it comes back to the owner before going ahead.

## Guide chapter (for learning)

The owner is new to mobile and wants a chapter for this feature: `docs/guide/17-home-screen-widget.md`, plus
cheatsheet lines and an entry in the guide's `README.md`.

1. **Drafted before any widget code**, as the first step of the plan: what a home-screen widget is, why Flutter
   cannot draw one directly, what `AppWidgetProvider` and `RemoteViews` are, how a picture travels from Dart to the
   home screen, why widgets refresh so rarely, and what iPhone would need.
2. **Finished after the code**, with the real files, how to add the widget on the emulator, how to test it, and
   anything the first-step test taught.

## Testing

- Unit tests with no network, using a fake tile fetcher: tile maths, once-a-minute rule including the last fix of a
  burst, day rollover, clearing while a draw is running, and a widget failure leaving the tracker's queue untouched.
- `flutter analyze` and the existing tests stay clean.
- By hand on the emulator, for both the dev flavor and a tracker route: add the widget, app swiped away, offline,
  reboot, sign-out, midnight.
- The Kotlin label has no automated test, since the project has no Android unit tests. Keep it very small.

## Left to the builder

File and class names, image size within the limit, the widget's preview image in the launcher, how the one-minute
timer is wired into the tracker's start and stop, and the tile cache's size limit.

## When done

Update `docs/HANDOFF.md` in the same change, mark deliberate shortcuts with `ponytail:`, and run the iOS CI job to
confirm the new package does not break the iOS build.
