# Live positions over MQTT, phone side: design

Date: 2026-11-24. Status: **approved** (owner, 2026-11-24: questions answered below). Server, broker and web: travel-heatmap
`docs/superpowers/specs/2026-11-23-live-mqtt-design.md` (section "Phone") and guide chapter 23. This file only adds what
the phone needs; the broker contract there is fixed.

## What the phone does

While the tracker records (a trip, or always for an always-on account), each GPS fix that says something new is
published to the owner's broker as the account's live position; `/ingest` keeps uploading the trail, now in bigger
batches. MQTT is a side channel: nothing it does can block, delay or drop an `/ingest` upload.

## Connection

- `MQTT_URL` in `config/*.json` (optional, like the web's `mqttUrl`): e.g. `wss://mqtt.daste.io.vn`. Absent = no live
  channel, everything else as today. Must start with `wss://` or `ws://`.
- `mqtt_client` (`MqttServerClient`, `useWebSocket`, port 443, MQTT 3.1.1, keepalive 60 s, no logging).
- Username `findme`, password = the ingest token, client id `<account id>/phone-<8 random hex>`.
- **Account id = the `sub` already stored with the ingest token** (`TrackerStore.token()` returns `{token, sub}`;
  `postConfirmation` creates the account with `id: sub`). No `GET /me` call is needed.
- Connected while the tracker is on and a token exists. Dropped or refused: reconnect after 2 s, doubling to 60 s (the
  web's numbers); the wait goes back to 2 s only after a connection that lasted 60 s, so a broker that kicks us at
  once (trip not open on the server yet) is asked at most once a minute.
- On (re)connect: publish the newest accepted fix, if any.

## What gets published

Pure rule (`lib/features/tracker/domain/live_policy.dart`), tested on its own:

- Skip a fix with `acc > 100` (`MAX_ACCURACY_M`, the server's value).
- Publish when it is ≥ `max(5 m, acc / 2)` from the last **published** fix (the first fix always goes).
- At most one a second: a fix inside that second waits in a one-slot "newest" box and goes when the second is up
  (the next fix replaces it).
- Standing still: nothing.
- Payload: `{"lat":..,"lon":..,"ts":<epoch s>,"acc":..}`, 6 decimals, topic `live/<id>`, QoS 0, retained.

## Stopping

Every stop goes through `TrackerController.turnOff` (switch off, trip end by hand / timer / web / `/ingest`'s
`trip: false`, mode switched to "Chỉ khi đi") or `forget` (sign-out, another account): publish an **empty retained**
message to `live/<id>`, then disconnect. Not connected at that moment: one connect just to clear (10 s timeout), best
effort. Always allowed by the broker, even after the trip ended.

## `/ingest` batching

- **Moving** (a fix ≥ `MIN_MOVE_M` = 5 m from the one before it, in the last minute): upload when 60 s have passed
  since the last good upload. **Still:** 5 min. The 50-fixes threshold and the backoff stay.
- The tick runs every 60 s and decides with that rule (today it runs every "Gửi mỗi").
- **Flush at once** (everything queued, backoff still respected): app goes to the background (`AppLifecycleListener`
  `onHide`, next to the existing `paused()` calls), a trip ends (any of the stops above), and on charge (see Q2).

## Background

- **Android:** the tracker already runs geolocator's foreground service, which keeps the process and the Dart engine
  alive, so the socket stays open and publishing continues with the screen off. No new permission.
- **iPhone:** the app runs in the background only while iOS delivers locations (`UIBackgroundModes: location`,
  already there). Publishing continues while moving; when iOS pauses updates (standing still) the app is suspended and
  the socket dies, friends keep the retained position. On the next wake (significant change) it reconnects. Accepted
  by design; no new background mode.

## Privacy

Never log the token, the account id, the topic or a payload. Debug lines: connection state and counts only.

## Files

- `lib/core/config/app_config.dart`: optional `mqttUrl`.
- `lib/features/tracker/domain/live_policy.dart`: `worthPublishing` (accuracy / distance), `livePayload`, `liveTopic`; the 1 s rule is in `LiveSender`.
- `lib/features/tracker/domain/upload_policy.dart`: moving / still wait.
- `lib/features/tracker/data/live_sender.dart`: `LiveLink` (connect / publish / disconnect; `MqttLiveLink` on
  `mqtt_client`, `FakeLink` in tests) and `LiveSender` (newest box, 1 s rule, reconnect, clear).
- `lib/features/tracker/data/charging.dart`: plugged-in stream (`battery_plus`).
- `TrackerController`: feeds fixes to `LiveSender`, starts / stops it, adaptive tick, `flush()`.
- `MapScreen`: `onHide` → `flush()`.
- Guide chapter 20, cheatsheet lines, HANDOFF. No separate plan file: this spec's file list is the plan.

## Answered by the owner (2026-11-24)

1. **"Gửi mỗi" (5 s … 2 min) in the 🧭 sheet.** Adaptive batching replaces it. **Removed.**
2. **Flush on charge.** Needs a plugged-in signal: `battery_plus` (new dependency, works while the app runs, no
   permission) or skip it (background and trip-end flushes already cover most of it). **`battery_plus`.**
3. **GPS rate.** Today Android asks a fix every 10 s and both platforms only after 10 m (Overland's settings), so live
   updates arrive about every 10 s / 10 m, not every second. **Keep.**
