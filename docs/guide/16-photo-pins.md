# Chapter 16: Photo pins

The app's copy of the web's photo pins (`travel-heatmap`, chapter 20 of its guide, up to 24f0c21). Press the pink 📷
on the map: the app finds where you are, and you take a photo **there**. No location, no pin; no gallery, no video for
new pins. Pins show as photo bubbles whatever the date filter says. Tap one to reopen it, take more, or flip
**Chia sẻ** on a photo: then every friend sees it on their map, and every share link with **Ảnh** on shows it too
(on the web page the link opens).

The server side is **Look Back**, the separate album app, reached on Find Me's own address under `/lb`. Look Back
being away just means no bubbles on the map, and 📷 ends in an error message.

## How the login works

The web browser keeps a cookie by itself. An app does not, so `PinsRepository` does it by hand:

1. `POST /media-ticket` with the normal Cognito token gives a ticket valid for 60 s.
2. `POST /lb/api/findme/session` with the ticket answers `Set-Cookie: fm_user=…`. The app keeps that value **in memory
   only**.
3. Every call to Look Back, every `Image.network` and the video player send it as a `Cookie` header.

The repository is rebuilt on every sign-in (`ref.watch(signedInProvider)`), so the next account starts with no cookie.
The cookie lives 12 hours; it is renewed after 6, or at once when Look Back answers 401.

If you know the web: this is what `credentials: 'same-origin'` was doing for you.

## Where you are

`pinFixProvider` → `currentFix(GeoApi)` in `pins_controller.dart` (the web's `geo.ts`) answers one of three:

| `Fix` | When | The sheet says |
|---|---|---|
| `FixOk(lat, lon)` | a fresh high-accuracy reading | the name, the note, **📷 Chụp ảnh**; a 📍 on the map at the spot |
| `FixDenied` | permission refused (asked once if never asked) | "Cần quyền vị trí để ghim ảnh ở đây…" |
| `FixFailed('off' / 'error' / 'silent')` | location service off, GPS error, nothing within 20 s | "Chưa lấy được vị trí, thử lại nhé (…)" + **Thử lại** |

The name starts from a named stop within 100 m (`nameNear`). With none (tracking off), `GET /place-name?lat&lon`
asks Find Me: its cache, else its naming queue, so the app asks again every 3 s, 4 times. Typing first wins.

## Shared photos

- **The switch:** `PUT /lb/api/findme/media/<id>/shared {shared}` on your own photos (not videos). It flips at once and
  goes back with "Chưa làm được…" if refused. A bubble with a shared photo gets a 💗.
- **Friends' photos:** `FriendPinsController` asks `POST /pin-grant` (Find Me, a 15-minute pass naming your friends),
  then `POST /lb/api/findme/shared/session {grant}` (Look Back) which answers the pins with only their shared photos
  and a second cookie, `fm_shared_friends`. Pictures send both cookies. It asks every 5 minutes and when the app comes
  back, a new pass only when under a minute is left. No friends: nothing is asked. Bubbles show only for friends shown
  on the map, ringed in their colour; tapping opens a look-only card ("Ảnh của <tên> · …").
- **Share links:** "Cho xem ảnh đã chia sẻ 🖼️" when making a link, 🖼️ on an existing one; both ask first. The link
  opens the **web** share page (not ported to the app, owner's call 2026-11-12).

## Code

| File | Role |
|---|---|
| `lib/features/pins/domain/pin.dart` | Models (`Pin.sub` = a friend's), `Fix` + `geoMessage`, `mergePins` (64 px grid, nothing merges at zoom 19), `nameNear`. |
| `lib/features/pins/data/pins_repository.dart` | The cookies, calls to Look Back, `setShared`, `placeName`, `pinGrant`, `loadSharedPins`, tus uploads in 8 MiB chunks. A new pin whose uploads all fail is deleted. |
| `presentation/pins_controller.dart` | Your list. Polls every 5 s while a file is processing. Location (`pinFixProvider`) and camera as replaceable providers. |
| `presentation/friend_pins_controller.dart` | Friends' shared pins, every 5 min; `visibleFriendPins`, `grantDue`. |
| `presentation/pin_layer.dart` | Bubbles (friend ring, 💗). Reads `MapCamera.of(context)`, so it re-merges as you zoom. |
| `presentation/add_pin_sheet.dart`, `pin_sheet.dart` | The two cards. Plain widgets in `MapScreen`'s `Stack`, not modal sheets: the map must stay draggable. |

**Why tus by hand?** It is three requests: `POST` to create, `PATCH` per chunk, `HEAD` to ask how far it got after a
dropped connection. A package would be more code to trust than the 40 lines it replaces.

**What the app does not have:** the public share page `/s/<id>`; a link opens in the browser. The per-pin link
(`/p/<code>`, `/lb/m/<code>`, "🔗 Gửi cho bạn") is gone from both apps.

## Packages

`flutter_image_compress` (the phone's own codecs make a photo's thumb and display as WebP; on iOS through a bundled
encoder that is slower than Android's), `image_picker` (the camera for pins, the gallery for the bag and avatar), `geolocator` (already there for the tracker) and `video_player` (HLS: ExoPlayer on Android, AVPlayer on iOS). iOS needs the three
`NS…UsageDescription` strings in `Info.plist`. Android needs no new permission: the camera opens through an intent.

## Photos made ready on the phone

Until now a photo was only a file to Look Back: it arrived, waited in a queue, and a worker made the small versions
people actually look at (a 400 px thumb, a 2048 px display picture, a tiny blur). Now the phone makes those three
itself **while the photo uploads**, and hands them in when the upload ends. Look Back checks them and the picture is
ready at once, with no queue.

The rule that keeps this safe: **it never delays or fails an upload**. Everything below is extra; whenever any of it
does not work out, the app tells Look Back "make them yourself" (`skip`) and you get exactly the old behaviour.

1. `uploadTus` starts the encoder beside the upload (`client_files.dart`, `encodeClientFiles`) and marks the upload
   `clientFiles=1`, so Look Back holds the photo for the phone instead of queueing it.
2. Upload done and the files are ready: `PUT …/media/<id>/client-files/thumb`, `…/display`, then
   `POST …/media/<id>/client-result` with the blur. Not ready yet, or anything failed: `POST …/client-result
   {"skip": true}`.
3. Two slow or failed photos in a row (more than 150 ms per megapixel) switch it off until the next sign-in: a phone
   that cannot keep up should not keep trying.
4. Look Back answers `quota` to a marked upload when the account has less than 4.3 MB left (it reserves room for
   the small files): the app asks again without the mark.

**Sizes are exact.** Look Back refuses a file that is more than a pixel off what it would have made (display = the
photo fitted into 2048 on its long edge, thumb = that fitted into 400, never enlarged). The package's `minWidth` /
`minHeight` do not mean "fit into": for a 4000×3000 photo, 2048/2048 gives 2731×2048. So `targetShort` computes the
*short* edge to ask for, and the encoder measures what it got (`rightSize`) before sending anything. A file of the
wrong size is never sent; the photo simply goes the old way.

Videos are untouched. Avatar and bag pictures go through the same `uploadTus`, so they get this too.

Check the real codecs (they decide the pixels, unit tests cannot):
`flutter test integration_test/client_files_test.dart --flavor dev --dart-define-from-file=config/example.json`
with an emulator or phone connected.

## Test on a phone

Needs Look Back (migrations 015–016) and Find Me (`/pin-grant`, `/place-name`, `pics`) deployed: neither is yet
(`travel-heatmap` HANDOFF).

1. Refuse location, tap 📷: the message, no camera, no pin. Allow it: a 📍 where you stand, **📷 Chụp ảnh**, a ⏳
   bubble, then the picture. With tracking off and no stop near, the name fills itself after a second or two.
2. Location service off: "Chưa lấy được vị trí… (off)", **Thử lại** after turning it on works.
3. Open the pin, flip **Chia sẻ** on: the bubble gets a 💗. On a friend's phone (you shown on their map): the bubble
   with your colour ring, look-only. Flip it off: gone for them within 5 minutes (on reopening the app at once).
4. Make a link with **Cho xem ảnh đã chia sẻ 🖼️**, open it in a browser: the shared photo. Turn 🖼️ off: gone within
   15 minutes.
5. Change the date filter: the bubbles stay. Zoom out: near ones merge and show a count; tap to zoom in.
6. Sign out and in as another account: none of the first account's bubbles, nor its friends'.

## Troubleshooting

| Symptom | Fix |
|---|---|
| No bubbles, no error | Look Back is away, the `/lb` route is not deployed, or the ticket secrets differ. Check `media-ticket` and `session` in the 🐞 console. |
| Bubbles stay ⏳ but the list loaded | The picture request failed; usually the `Cookie` did not reach `/lb/media`. |
| Video spins for ever on iPhone | AVPlayer did not send the header with the segments. Not tested yet. |
| A photo still shows ⏳ for a while after uploading | The phone's small files were not used. 🐞 console: `client-result` 204 = used; 202 = Look Back refused them and made its own; no `client-files` calls at all = the phone gave up (slow, or switched off after two strikes). All three end in a ready picture. |
| `client-files` answers 413 | Something between the phone and Look Back caps bodies under 4 MB (CloudFront or the outer nginx). |
