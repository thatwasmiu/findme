# Chapter 20: Live positions over MQTT

The phone side of live positions (`travel-heatmap` guide chapter 23 has the broker, the server checks and the web).
While the tracker records, each GPS fix that says something new reaches friends within a second or two, instead of
at the next `/track` poll. `/ingest` still stores the trail; it now uploads less often. Design:
`docs/superpowers/specs/2026-11-24-live-mqtt-phone-design.md`.

## 1. What MQTT is, in one minute

MQTT is a small publish/subscribe protocol. A **broker** (a server) keeps connections open; a client **publishes** a
message on a **topic** (a name like `live/abc`), and every client **subscribed** to that topic gets it. A
**retained** message is kept by the broker and handed to anyone who subscribes later: a friend opening the map gets
your last position at once. An empty retained message deletes it. **QoS 0** means "send once, no receipt": fine for
positions, the next one replaces it anyway.

Our broker lives on the owner's VPS at `wss://mqtt.daste.io.vn` (MQTT over WebSockets, behind nginx's TLS).

## 2. Turning it on

Add the broker to `config/dev.json` / `config/prod.json`:

```json
"MQTT_URL": "wss://mqtt.daste.io.vn"
```

Empty or missing: no live channel, the app works as before. Anything not starting with `wss://` or `ws://` shows the
config error screen. The CI secret `FINDME_DEV_CONFIG` needs the key too if CI builds should publish.

## 3. How the phone connects

| MQTT field | Value | Why |
|---|---|---|
| client id | `<account id>/phone-<8 hex>` | the broker refuses an id that does not start with your account id |
| username | `findme` | ignored, but MQTT 3.1.1 refuses a password without a username |
| password | the **ingest token** | the same token `/ingest` takes; no Cognito token goes to the VPS |
| topic | `live/<account id>` | the only topic you may write |

The account id is the Cognito `sub`. The tracker already stores it next to the ingest token
(`TrackerStore.token()` → `{token, sub}`), so no extra request is needed.

The connection is open only while the tracker records. If it drops or is refused, the phone tries again after 2 s,
4, 8 … up to 60 s. A connection that lasted a minute resets the wait to 2 s; one the broker closes at once (a
trip-mode account whose trip the server does not know about yet) keeps the long wait.

## 4. What gets published

`lib/features/tracker/domain/live_policy.dart`, one rule:

- A fix rougher than 100 m (the server's `MAX_ACCURACY_M`) never goes.
- Otherwise it goes when it is at least **max(5 m, accuracy / 2)** from the last one sent. GPS wanders by about half
  its accuracy while you stand still; this keeps that wandering off your friends' maps.
- At most **one a second**. A fix inside that second waits; a newer one replaces it.
- After every (re)connect, the newest fix goes again.

The message: `{"lat":10.123457,"lon":106.987654,"ts":1795000000,"acc":12.3}` (6 decimals, `ts` in whole seconds),
retained, QoS 0. The broker disconnects a client that sends anything else.

How often a fix arrives is still up to the GPS settings of chapter 15 (Android: every 10 s if moved 10 m; iPhone:
after 10 m), so live updates come about that often, not every second. Kept on purpose: no extra battery.

## 5. Stopping

Every stop goes through `TrackerController.turnOff` or `forget`: the switch, a trip ending (by hand, its timer, the
web, `/ingest`'s `trip: false`), switching to "Chỉ khi đi", signing out. `LiveSender.stop()` publishes an **empty
retained** message (the broker always allows that on your own topic, even after the trip ended), waits a second for
it to leave, then disconnects. If the connection was down, it connects once just for that.

## 6. `/ingest` now waits longer

`lib/features/tracker/domain/upload_policy.dart` `uploadWait`:

| | Upload when |
|---|---|
| moving (a fix moved 5 m from the one before, in the last minute) | 1 minute after the last good upload |
| still | 5 minutes |
| always | 50 fixes waiting, or **Gửi ngay** |

Plus a **flush** (everything queued, unless a failure's backoff is running) when the app goes to the background
(`MapScreen`'s `onHide`), when tracking stops, and when the phone is plugged in (`battery_plus`, only while the app
runs). The "Gửi mỗi" choice is gone: the app decides.

MQTT is a side channel. A fix goes to `LiveSender` and to the queue side by side; a broker that is down, slow or
refusing never delays or drops an upload.

## 7. In the background

- **Android:** geolocator's foreground service keeps the app alive, so the connection stays open with the screen off.
- **iPhone:** the app runs in the background only while iOS hands it locations. Standing still, iOS pauses them and
  suspends the app; the socket dies and friends keep your last (retained) position with its time. The next wake
  reconnects. No new background mode or permission was added.

## 8. Check it

- Unit tests: `flutter test test/features/tracker` (a fake broker, `FakeLink`, in `test/helpers/tracker_fakes.dart`).
- On a device, with a friend's browser on the map: walk; their marker should follow within a couple of seconds.
- From a computer (travel-heatmap chapter 23 §6): `npx mqtt sub … -t "live/<your id>" -v` shows each message; ending
  the trip shows an empty one.
- The phone never logs the token, the account id, the topic or a position.

## 9. Files

`lib/core/config/app_config.dart` (`mqttUrl`), `lib/features/tracker/domain/{live_policy,upload_policy}.dart`,
`lib/features/tracker/data/live_sender.dart` (`LiveLink`, `MqttLiveLink`, `LiveSender`),
`lib/features/tracker/data/charging.dart`, `lib/features/tracker/presentation/tracker_controller.dart`,
`lib/features/trail/presentation/map_screen.dart`.
