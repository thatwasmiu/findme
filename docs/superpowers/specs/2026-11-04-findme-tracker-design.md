# Find Me tracker (replaces Overland): design

Written 2026-11-04. Builds on `2026-11-02-findme-flutter-app-design.md`. Upload contract and server behaviour:
`travel-heatmap/docs/guide/04-overland.md`, `03-ingest-api.md`, `lambdas/src/ingest.ts`, `lambdas/src/overland.ts`.

## 1. Intent and why

Today every account needs a second app, Overland, to record GPS. Setting it up for a new person is tedious and
fragile: the admin makes a token, sends a 64-character token and the address through some chat, the person installs
Overland, types both in (a Vietnamese keyboard rewrites the token), and must get six tracking settings right.
Overland is also iPhone only.

Find Me becomes the one app: it records your position in the background and uploads it to the same `/ingest`
endpoint, on Android and iPhone. Signing in and turning on one switch is all a new person should do.

The owner plans to extend tracking later and will add a server API that hands a signed-in user their own ingest
address and token, so the token never travels by chat (the secure path). Until then the token is pasted once.

## 2. Goals

- Background recording on Android and iPhone, with the app closed (in the background, not force-quit).
- Points queued on the phone; uploaded in batches to `<API_URL>/ingest` in Overland's exact format, so the
  server needs no change.
- No data loss: a queued point is removed only after the server answers `{"result":"ok"}` for its batch. Offline
  for days = keep queuing, send later.
- Survives the OS killing the app:
  - iPhone: significant-location-change monitoring relaunches the app in the background after it was terminated
    by the system; the app then resumes GPS recording.
  - Android: a foreground service while tracking; after a reboot, tracking restarts if it was on.
- Visible status, so a silent stop is noticed: on/off, permission problem, queued count, last upload, last point.
- Tracking settings baked in (Overland's recommended ones): continuous GPS, ~100 m desired accuracy, pause
  updates when still. Not user-tunable in v1.
- Token: temporary paste field, stored in `flutter_secure_storage`. The source of the token is one small piece
  that the owner's future API replaces (fetch after sign-in, no screen).
- **A learning chapter for the owner** (new to mobile): `docs/guide/15-background-tracking.md` (next free number),
  same layout as the other chapters, plus cheatsheet lines and a README index entry. It teaches, not just lists:
  - how background location differs on Android and iOS (foreground service + notification vs background mode;
    why the OS kills apps; what "significant location change" is and why it relaunches the app);
  - the permission ladder (while-in-use → always) and why Play demands the disclosure screen;
  - the first native code in the project: what `AppDelegate.swift` and the Kotlin boot receiver do, line by line,
    and how Dart and native talk (method channel or plugin, whichever is used);
  - the queue: why "delete only after ok", why temp-file-then-rename;
  - how to test: emulator GPX route, reboot test, reading the 🐞 console, checking points arrived (the web map or
    the ingest log line from `travel-heatmap` ch04);
  - the Play Store steps (declaration, video, privacy policy, data safety) and the platform limits in section 5;
  - revision notes and a self-check, like the other chapters.
- `docs/HANDOFF.md` updated.

## 3. Non-goals

- The server API for fetching the ingest address/token (owner builds it later in `travel-heatmap`).
- Any server change. `/ingest` already filters accuracy (>100 m dropped or "held"), merges still points, handles
  late days.
- User-tunable tracking settings, tracking modes, battery profiles.
- On-phone trail from unsent points (the map keeps showing server data as today).
- Surviving a user force-quit (Overland does not either), or brand battery killers (Xiaomi, Oppo…) beyond a hint.
- Signed iPhone distribution (still the 7-day sideload; see the app design and guide chapter 14).

## 4. Anti-goals (a failure even if it runs)

- Dropping points: deleting from the queue before `ok`, or a crash that corrupts the queue file and loses it all.
- Tracking that stops silently with nothing on screen saying so.
- Logging or showing the token, coordinates, or the ingest address with the token (debug console included:
  mask like existing secrets).
- Points from one account uploaded with another account's token after sign-out / sign-in as someone else.
- A battery drain clearly worse than Overland with its recommended settings.

## 5. Constraints and decided how

### Upload contract (fixed by the server)

- `POST <API_URL>/ingest`, header `Authorization: Bearer <token>`, JSON body:
  `{"locations":[{"type":"Feature","geometry":{"type":"Point","coordinates":[lon,lat]},
  "properties":{"timestamp":"<ISO-8601 UTC>","horizontal_accuracy":<m>,"device_id":"<id>"}}]}`.
- `200 {"result":"ok"}` = batch stored, remove it from the queue. `401` = token wrong/rotated/account disabled:
  keep the queue, stop retrying until the token changes, show it. `400` = malformed batch: this is our bug; keep
  it (do not delete data), log status only. `5xx`/network = keep, retry later with backoff.
- Same timestamp + device overwrite on the server, so re-sending a batch is safe.
- `device_id`: `iphone` on iOS (the id Overland used), `android` on Android. Builder's call, stated to the owner.
  The owner tries Find Me on a **different account** while Overland keeps running on theirs, so the two never
  share a points partition and the same id is safe.

### Decided with the owner

- Both platforms; iPhone stays on sideload for now.
- Token by temporary paste now; owner's API later. Paste is marked `ponytail:` with the plan to delete it.
- Survival layer (iOS relaunch + Android reboot restart) is in v1.
- Status UI as described in section 6.
- **Android ships on Google Play.** Play's background-location policy shapes the permission flow:
  - Prominent in-app disclosure screen *before* any location prompt: what is collected (position, in the
    background, even when the app is closed), why (your trail and the friends you share with), and that it is
    sent to the Find Me server. Explicit "Đồng ý" / "Không" buttons; "Không" leaves tracking off.
  - Ask foreground location first, then "Allow all the time" as a separate step (Android 11+ sends the user to
    settings for it); explain the second step on screen.
  - Foreground service type `location` declared in the manifest.
  - Store-side work, done by the owner, prepared by the builder in the guide: Play Console background-location
    declaration, a short demo video of the disclosure + tracking, a privacy policy URL covering location, data
    safety form answers. The builder writes a draft privacy policy text and the form answers in the guide; the
    owner hosts and submits them.
  - The submission and review themselves are not part of this work.

### Builder's defaults (stated to the owner, changeable)

- Location stream: `geolocator` (free, both platforms; Android foreground-service notification support, iOS
  `allowBackgroundLocationUpdates` / `pauseLocationUpdatesAutomatically`). Rejected
  `flutter_background_geolocation`: Android release builds need a paid licence.
- Survival layer is small native code, not a plugin:
  - iOS (`AppDelegate.swift`): start `startMonitoringSignificantLocationChanges` while tracking is on; on a
    background launch with the location key, Flutter's `main()` runs and the Dart side resumes recording because
    the "tracking on" flag is set. Needs Always permission and `UIBackgroundModes: location`.
  - Android: `RECEIVE_BOOT_COMPLETED` receiver that restarts the location foreground service if the flag is on.
    Must be verified on a real Android 14+ device (foreground-service-from-boot rules).
- Queue: append-only JSON-lines file in the app's documents directory, written with `dart:io`. Upload reads the
  oldest N lines, and rewrites the file without them only after `ok`. Write to a temp file and rename, so a crash
  mid-write cannot lose the queue. `ponytail:` file queue; move to sqlite if it measurably struggles.
- Batching: upload when ≥ 50 points are queued or ≥ 5 minutes since the last upload, and on "Gửi ngay"; at most
  500 points per request. Backoff on failures (e.g. 1 → 2 → 4 … → 30 min cap).
- The queue survives sign-out? **Only a deliberate sign-out ends tracking** (builder's call after review). The
  app also signs itself out when a session lapses (`AuthController.expired()` on a 401, or the 30-day refresh
  token refused); that must **not** touch tracking, the queue or the ingest token: the ingest token is independent
  of Cognito, and someone who never opens the map must keep recording. So the tracker listens to the explicit
  `signOut()`, not to `signedInProvider` / `sessionEpochProvider`.
  - Deliberate sign-out: stop tracking, upload what is possible with the current token (best effort, short
    timeout), then delete the queue and the token.
  - The stored token remembers which account (Cognito `sub`) pasted it. A later sign-in as a **different**
    account does the same as a deliberate sign-out for the old one before anything else, so one person's points
    never go out under another's token.
- A batch answered `400` is moved to a side file (`rejected`), not retried, not deleted, and the rest of the queue
  carries on. Status shows `Điểm bị từ chối: N` as a problem (it is our bug). Builder's call after review.
- Accepted risk while the token is pasted: the app cannot check that the token belongs to the signed-in account
  (no endpoint links them), so a wrong paste fills someone else's trail. Goes away with the owner's API.
- Permissions: Android `ACCESS_FINE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` ("Allow all the time"),
  `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`; iOS
  `NSLocationAlwaysAndWhenInUseUsageDescription`, `NSLocationWhenInUseUsageDescription`, background mode
  `location`. Asked when the switch is turned on, not at app start.
- Architecture: new feature folder `lib/features/tracker/{data,domain,presentation}`. Upload goes through the
  existing `ApiClient` only if it can send a different bearer (the ingest token, not the Cognito token); otherwise a
  small separate dio for `/ingest`. Builder's call after reading `api_client.dart`.

### Platform limits to state in the guide

- iOS: significant-location relaunch needs ~500 m of movement, so a gap after a system kill is normal.
  User force-quit stops tracking until the app is opened.
- Android: the notification "Find Me đang ghi hành trình" is required by the OS while tracking.
  Some brands kill apps anyway: show a hint to exempt Find Me from battery optimisation.
- iPhone sideload expiry (7 days) stops the app entirely; nothing to do in code beyond the "last point" status.

## 6. What the user sees

A "Ghi hành trình" section (in the 👥 sheet or its own sheet: builder's call, keep it reachable in one tap from the
map). Vietnamese copy is new (no web file to copy), written in the web's tone:

- Switch: on/off. First turn-on shows the disclosure screen (section 5), then asks for permissions step by step;
  refusal shows why it is needed. Same flow on iOS (harmless there, one code path).
- Status line: `Đang ghi` / `Đã tắt` / `Thiếu quyền vị trí "Luôn luôn"` (tap opens system settings) /
  `Token sai hoặc đã đổi` (after a 401).
- `Điểm chờ gửi: N`, `Gửi lần cuối: <relative time>`, `Điểm cuối: <relative time>`, button `Gửi ngay`.
- Token field (temporary): masked, paste only, "Lưu". Without a token the switch can still record (queue grows);
  status says the token is missing.
- Android: battery-optimisation hint with a button to the system screen.
- Network errors are not alarming: the queue just grows; only 401 and permission problems are shown as problems.

## 7. Testing

- Unit tests (no network, no device): Overland JSON encoding, queue append / take / commit-after-ok / crash-safe
  rewrite, batching and backoff rules, response handling (ok / 401 / 400 / 5xx / timeout), sign-out clears queue
  and token.
- Widget tests: status states and copy, token field never shows the token in clear.
- Manual on devices (listed in the guide chapter): Android emulator with a GPX route; real Android reboot test;
  iPhone relaunch after a system kill (hard to force: walking with the app suspended for a long time, or
  simulating memory pressure in Xcode is not available without a Mac — note as unverified until seen on the
  owner's iPhone).

## 8. Left to the builder

- Exact thresholds (50 points / 5 min / backoff steps) within the spirit above.
- Where the section lives in the UI; wording details.
- Whether upload reuses `ApiClient` or a small separate client.
- Plugin versions, Kotlin/Swift details, how Dart learns about an iOS background relaunch.
- Guide chapter number and layout (next free number in `docs/guide/`).
