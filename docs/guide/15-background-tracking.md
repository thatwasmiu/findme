# 15. Background tracking (Find Me replaces Overland)

Until now every account needed a second app, **Overland**, to record GPS and send it to `/ingest`. Find Me now does
that itself, on Android and iPhone: open **🧭** on the map, switch **Ghi hành trình** on, allow location "always".

Design: `docs/superpowers/specs/2026-11-04-findme-tracker-design.md`. Server side (unchanged): `travel-heatmap`
`docs/guide/04-overland.md` and `lambdas/src/ingest.ts`.

## 1. What and why

### How a phone records you while the app is closed

A normal app stops running a few seconds after you leave it. Recording in the background is a special permission,
and the two systems grant it differently:

| | Android | iPhone |
|---|---|---|
| What keeps the app alive | A **foreground service**: a piece of the app the OS treats as "the user knows this is running". It must show a notification the whole time (**Find Me đang ghi hành trình**). | The **location background mode** (`UIBackgroundModes: location` in `Info.plist`): while location updates are on, iOS keeps the app running. A small blue/arrow indicator may show. |
| Permission | "While using the app", then separately **"Allow all the time"**. On Android 11+ the second step is only in Settings, never a pop-up. | "While using", then **"Always"** (iOS asks the second time on its own, sometimes days later, or you set it in Settings → Find Me → Location). |
| When it still stops | Some brands (Xiaomi, Oppo, Samsung's battery saver) kill apps anyway. Exempt Find Me from battery optimisation. | You **force-quit** it (swipe up in the app switcher). Low Power Mode. The 7-day sideload signature running out (chapter 14). |

### Why the OS kills apps, and how Find Me comes back

Phones free memory by terminating background apps. Two survival tricks:

- **iPhone: significant location change.** A cheap service built on cell towers and Wi-Fi (no GPS). While Find Me
  has it switched on, iOS **relaunches Find Me in the background** whenever you have moved about 500 m, even if iOS
  had terminated it. That is how Overland survives too. So after a system kill there is a gap of up to ~500 m, then
  recording resumes. A force-quit is the one case iOS respects: then nothing relaunches it.
- **Android: restart after reboot.** The foreground service is rarely killed, but a reboot ends everything. A
  **boot receiver** (Android calls it when the phone has started) checks "was tracking on?" and starts it again.

### The blue indicator (iPhone)

The 🧭 sheet on an iPhone has **Hiện chỉ báo vị trí** (Overland calls it "App using location"). On, iOS shows a
blue pill by the clock while Find Me records in the background; tapping it opens the app. It changes nothing about
accuracy, battery or how often fixes come: it is a visible "still recording" sign, handy while testing (no blue
pill = not recording). Off by default. Android has no such switch: its notification already plays that role.

### Batteries and accuracy

The settings are Overland's recommended ones, fixed in code (`lib/features/tracker/data/geolocator_source.dart`):
iPhone asks for ~100 m accuracy (GPS still answers, usually 5-30 m) and pauses when you stand still; Android asks for
high accuracy every 10 s, only when you moved 10 m. The server drops anything worse than 100 m and merges standing
still into one point a minute, so the phone does not need to be clever.

### The queue: why "delete only after ok"

Every fix (one GPS position) is appended to a file on the phone, `queue.jsonl`, one line each. Uploading reads the
oldest up to 500, sends them in Overland's exact format, and **only when the server answers `{"result":"ok"}`**
removes them. Offline for a day? The file grows, and everything is sent later. If the app dies between "server said
ok" and "file rewritten", the same fixes are sent again next time, and the server simply overwrites them (it keys
points by time + device). Duplicates are harmless; losses are not.

Removing lines means rewriting the file. Writing over `queue.jsonl` directly could leave half a file if the phone
died in the middle. So the new content goes to `queue.jsonl.tmp`, then a **rename** swaps it in. A rename is atomic:
afterwards there is either the old file or the new one, never a mix.

When does it upload? As soon as 50 fixes wait, or when the time picked under **Gửi mỗi** in the 🧭 sheet (5, 10 or 30
seconds, 1 or 2 minutes; default 1 minute, how often the map asks for new points) has passed since the last successful upload, or when you press
**Gửi ngay**. A longer wait means fewer requests and a little less battery, but friends see you later. A failure (no network, server error) waits 1, 2, 4, 8, 16, then 30 minutes before trying again.

| Server answer | What the app does |
|---|---|
| `200 {"result":"ok"}` | Removes that batch. |
| `401` | The token was replaced (another phone asked for one) or the account is switched off. Asks for a new token once and sends again. If the fresh token is refused too: keeps everything, shows **Token sai hoặc đã đổi**, tries again after the backoff. |
| `400` | The server says the batch is malformed: a bug in the app. Moves it to `rejected.jsonl` (kept, not retried) and shows **Điểm bị từ chối: N**, so one bad batch cannot block the rest. |
| anything else, or no answer | Keeps everything, tries again later. Not shown as a problem. |

### The token

The app gets the ingest token itself: when tracking is switched on with no token, or after `/ingest` says 401, it
calls `POST /me/ingest-token` with the sign-in token (like `/me`). The server makes a new token for the account
(the old one, e.g. Overland's, stops at once) and the app keeps it in the Keychain / Keystore like the sign-in
session (chapter 04), with the account's `sub`, never shown, never logged.

| `/me/ingest-token` answer | What the app does |
|---|---|
| `200 {"url", "token"}` | Saves the token, uploads. (`url` is `<API_URL>/ingest` and is not used.) |
| `401` | The usual signed-out screen; shows **Chưa có token** until you sign in again. Fixes are kept. |
| `403` | Admin login or a switched-off account: **Tài khoản này không ghi được hành trình**, not asked again until **Gửi ngay** or the switch. |
| `429`, other errors, no answer | **Chưa có token**, tries again after the backoff. |

It is only asked for while the account that owns the tracking is signed in, never for someone else's sign-in.

Only a deliberate **sign-out (👋)** ends tracking on this phone: one last upload attempt, then the queue and the
token are deleted. When the sign-in merely expires (30 days, or a 401 from the API), tracking carries on: the ingest
token does not depend on the sign-in. If **another account** signs in on the same phone, the previous account's
tracking is ended first, so nobody's points are ever sent with someone else's token.

## 2. Code

| File | Role |
|---|---|
| `lib/features/tracker/domain/fix.dart` | `Fix` (one position) and `overlandBatch` (the exact JSON `/ingest` reads). |
| `lib/features/tracker/domain/upload_policy.dart` | When to upload (50 / 5 min) and the backoff steps. Pure functions, easy to test. |
| `lib/features/tracker/data/point_queue.dart` | The queue file: append, peek, commit, reject, crash-safe rewrite. |
| `lib/features/tracker/data/ingest_client.dart` | One `POST /ingest`; maps the answer to ok / unauthorized / rejected / retry. Not `ApiClient` on purpose: that one would sign you out on a 401. |
| `lib/features/tracker/data/tracker_store.dart` | The token (secure storage) and the on/off flag (`shared_preferences`, read by Android's boot receiver). |
| `lib/features/tracker/data/geolocator_source.dart` | The real GPS through the `geolocator` package. Tests use a fake (`test/helpers/tracker_fakes.dart`). |
| `lib/features/tracker/presentation/tracker_controller.dart` | The brain: start/stop, each fix into the queue, one upload at a time. |
| `lib/features/tracker/presentation/tracker_sheet.dart` | The 🧭 sheet, including the disclosure dialog shown before the first location prompt. |
| `lib/features/tracker/data/wake_channel.dart` + `ios/Runner/AppDelegate.swift` | iPhone: significant-location monitoring and the background relaunch. |
| `android/.../BootReceiver.kt` + `trackerBoot` in `lib/main.dart` + `lib/features/tracker/boot.dart` | Android: restart after a reboot. |

### First native code: how Dart and Swift / Kotlin talk

Until now every line was Dart. Two small native files do what no Flutter package covered.

**A method channel** is a named pipe between Dart and the platform. `WakeChannel` (Dart) and `AppDelegate.swift`
both open `findme/tracker`:

```dart
static const _ch = MethodChannel('findme/tracker');
await _ch.invokeMethod<void>('startSignificant');   // Dart -> Swift
_ch.setMethodCallHandler((call) async { if (call.method == 'wake') f(); }); // Swift -> Dart
```

```swift
let ch = FlutterMethodChannel(name: "findme/tracker", binaryMessenger: messenger)
ch.setMethodCallHandler { call, result in ... startMonitoringSignificantLocationChanges() ... }
channel?.invokeMethod("wake", arguments: nil)   // on every significant change
```

**`AppDelegate.swift`, line by line, in words:**

1. `CLLocationManager` is Apple's location object. One is kept for significant changes only (geolocator has its
   own for GPS).
2. `didFinishLaunchingWithOptions` runs on every start. If `launchOptions` contains `.location`, iOS started us
   *because of a location event*: there is no window. Apple says to restart significant monitoring right away.
   With no window, Flutter's usual engine (created by the window's storyboard) never starts, so this code starts
   its own `FlutterEngine`, registers the plugins and runs the screenless Dart function `trackerBoot` (the same
   one Android uses after a reboot). It calls `resume()`: tracking is back.
3. `didInitializeImplicitFlutterEngine` runs when the normal, windowed engine starts (you opened the app). The
   background engine is stopped, so only one copy of Dart writes the queue.
4. `locationManager(_:didUpdateLocations:)` is each significant change: it sends `wake` to Dart, and Dart restarts
   the GPS stream (iOS may have paused it while you stood still).

**`BootReceiver.kt`, in words:** Android calls `onReceive` with `BOOT_COMPLETED` after a restart (the manifest
declares the receiver and the `RECEIVE_BOOT_COMPLETED` permission). It reads the on/off flag Dart saved
(`shared_preferences` keeps it in the `FlutterSharedPreferences` file with a `flutter.` prefix). If it was on, it
starts a Flutter engine without any screen and runs the Dart function `trackerBoot` (marked
`@pragma('vm:entry-point')` so the compiler keeps it). `trackerBoot` resumes the tracker; geolocator's foreground
service shows its notification again. When you then open the app, `MainActivity` stops that screenless engine before the
screen's own Dart starts, so only one copy ever writes the queue (the iPhone does the same in `AppDelegate`).

## 3. Run

```powershell
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

1. Sign in, tap **🧭**.
2. Turn **Ghi hành trình** on. Read the explanation, **Đồng ý**. Allow location; on Android 11+ the app shows
   **Thiếu quyền vị trí "Luôn luôn"**: tap **Mở cài đặt** → Permissions → Location → **Allow all the time**, come
   back, switch on again.

### Fake a walk on the emulator

The emulator has no GPS, but it can replay a route:

1. In the emulator window: **⋯ (Extended controls) → Location → Routes**.
2. Search two places a few hundred metres apart (or load a `.gpx` file), **Save route**, set speed, **Play route**.
3. Watch the 🧭 sheet: **Điểm cuối** says "vừa xong", **Điểm chờ gửi** grows.

## 4. Look

- 🧭 is pink while recording.
- The sheet: status, waiting count, last upload, last fix, **Gửi ngay**.
- The 🐞 console (dev builds): `POST /api/ingest 200`; tap it: the body shows `coordinates: •••` (never the real
  numbers).
- The map of that account (on the phone or the web) gets the new paw prints within a minute after an upload.
- `travel-heatmap` ingest log line: `{"received":N,"stored":N,...}` (ch04 **4. Look**).

## 5. Test

Unit and widget tests, no device:

```powershell
flutter test test/features/tracker
```

On devices (by hand; not done automatically):

| Check | How | Expected |
|---|---|---|
| Records in the background | Emulator route playing, press Home, wait 5 min, reopen | Points kept coming (Điểm cuối recent), uploads happened |
| Offline | Emulator: turn Wi-Fi + data off, walk the route, turn back on, **Gửi ngay** | Điểm chờ gửi back to 0, nothing missing on the map |
| Reboot (Android) | Tracking on, then `adb reboot`, wait for the home screen, play the route | The notification **Find Me đang ghi hành trình** is back without opening the app, Điểm cuối moves |
| iPhone relaunch | Sideloaded build (chapter 14), tracking on, leave it in the background for hours (iOS kills it eventually), walk > 1 km | Points from after the walk appear; a gap of ≤ ~500 m is normal |
| Sign-out | 👋, sign in again | Đã tắt, Điểm chờ gửi 0 |

`adb` lives in `D:\Android\Sdk\platform-tools` (chapter 01).

## 6. Moving an account from Overland to Find Me

Two apps sending for the same account at the same time would interleave their points (both iPhones say
`device_id: iphone`). So: try Find Me on a **different** account first. When you switch your own account, turn
Overland's tracking off (or uninstall it) *before* switching Find Me's on. Switching Find Me on asks the server for a
new token, which stops Overland's at once.

## 7. Google Play

Play reviews apps that read location in the background. What it needs, and where it lives:

- **Prominent disclosure** before any permission prompt: the dialog in `tracker_sheet.dart` (text says what, in the
  background even when closed, why, sent to the Find Me server; **Đồng ý** / **Không**).
- **Background location declaration** in Play Console (App content → Sensitive permissions), a **demo video**, a
  **privacy policy URL**, and the **Data safety** form. Drafts for all of these: [play-store-location.md](play-store-location.md).
- Play account and app IDs: chapter 14.

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| **Thiếu quyền vị trí "Luôn luôn"** | Settings → Apps → Find Me → Permissions → Location → Allow all the time (iPhone: Settings → Find Me → Location → Always, Precise on). |
| **Chưa có token** | Signed out (sign in again) or offline / server busy (it retries; **Gửi ngay** asks now). Fixes are kept meanwhile. |
| **Token sai hoặc đã đổi** | `/ingest` refused even a fresh token: the account is probably switched off. Check it on the admin page. |
| **Tài khoản này không ghi được hành trình** | `/me/ingest-token` said 403: an admin login or a switched-off account. |
| Notification missing on Android 13+ | Notifications for Find Me are off; tracking still runs. Allow notifications to see it. |
| Stops after a while (Android) | Battery optimisation: Settings → Apps → Find Me → Battery → Unrestricted. The 🧭 sheet has a shortcut. |
| **Chưa có token** on the iPhone after a while in the pocket (fixed 2026-11-06) | The Keychain was only readable while unlocked, so a locked phone "lost" the token. Now it is readable after the first unlock since power-on, and the app keeps the token in memory once read. Only right after a reboot, before the first unlock, nothing can be read: fixes wait and go after you unlock. |
| Stops after a while (iPhone) | You force-quit it, or Low Power Mode is on, or the sideload expired (reinstall). |
| **Điểm bị từ chối** above 0 | A bug in the app's batch format. Keep `rejected.jsonl` (in the app's files) for debugging; report it. |
| Points on the map late | Uploads wait for 50 fixes or 5 minutes. **Gửi ngay** sends at once. |

## Revision notes

**Key concepts**
- Background location: Android = foreground service + notification + "Allow all the time"; iPhone = location
  background mode + "Always".
- Survival: iPhone significant-location relaunch (~500 m); Android boot receiver. Neither survives a force-quit.
- Queue: append-only file, removed only after `{"result":"ok"}`, rewritten via temp file + rename.
- A method channel is a named pipe between Dart and Swift/Kotlin.

**Diagram**

```
GPS (geolocator) --> TrackerController --> queue.jsonl --(50 / 5 min / Gửi ngay)--> POST /ingest
       ^                     |                  ^                                        |
 wake (iOS significant)      |                  +------ kept unless {"result":"ok"} ------+
 boot receiver (Android) ----+
```

**Self-check**

<details>
<summary>1. Why can't Android just ask for "Allow all the time" in a pop-up?</summary>

Since Android 11 the system only offers that choice in Settings. The app can only send you there.
</details>

<details>
<summary>2. The phone dies right after the server said ok. What happens?</summary>

The queue was not rewritten yet, so the same fixes are sent again. The server overwrites points with the same time
and device, so nothing is duplicated and nothing is lost.
</details>

<details>
<summary>3. Why does a 401 from /ingest not sign you out?</summary>

The ingest token and the sign-in session are different things. A wrong ingest token only stops uploads; the
fixes stay queued until a new token works.
</details>

<details>
<summary>4. Why does AppDelegate start its own Flutter engine on a location relaunch?</summary>

A background relaunch opens no window, and the normal engine is created by the window. Without its own engine,
no Dart code would run, so tracking would not resume.
</details>

Next: back to [README](README.md).
