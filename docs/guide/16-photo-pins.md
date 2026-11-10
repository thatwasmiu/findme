# Chapter 16: Photo pins

The app's copy of the web's photo pins (`travel-heatmap`, chapter 20 of its guide). Press the pink 📷 on the map, take a
photo, record a video or pick from the phone, and pin it to a place. Pins show as photo bubbles whatever the date
filter says. Tap one to reopen it, add more, or send it to a friend as a link.

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

## Code

| File | Role |
|---|---|
| `lib/features/pins/domain/pin.dart` | Models, `mergePins` (64 px grid, nothing merges at zoom 19), `nameNear`, `startPosition`. |
| `lib/features/pins/data/pins_repository.dart` | The cookie, calls to Look Back, tus uploads in 8 MiB chunks. A new pin whose uploads all fail is deleted. |
| `presentation/pins_controller.dart` | The list. Polls every 5 s while a file is processing. GPS and camera as replaceable providers. |
| `presentation/pin_layer.dart` | Bubbles. Reads `MapCamera.of(context)`, so it re-merges as you zoom. |
| `presentation/add_pin_sheet.dart`, `pin_sheet.dart` | The two cards. Plain widgets in `MapScreen`'s `Stack`, not modal sheets: the map must stay draggable. |

**Why tus by hand?** It is three requests: `POST` to create, `PATCH` per chunk, `HEAD` to ask how far it got after a
dropped connection. A package would be more code to trust than the 40 lines it replaces.

**What the app does not have:** the friend's page `/p/<code>`. A link opens in the browser on the web, same as `/s/<id>`.

## Packages

`image_picker` (camera, gallery) and `video_player` (HLS: ExoPlayer on Android, AVPlayer on iOS). iOS needs the three
`NS…UsageDescription` strings in `Info.plist`. Android needs no new permission: the camera opens through an intent.

## Test on a phone

1. 📷 → **Chụp ảnh**. A ⏳ bubble appears, then the picture.
2. **Quay video**, wait for it to process, tap, ▶. Then **Chọn từ máy** with several files.
3. Change the date filter: the bubbles stay. Zoom out: near ones merge and show a count; tap to zoom in.
4. **🔗 Gửi cho bạn**, **Sao chép link**, open it in a private browser window. **Tắt link**, reload: expired.
5. Sign out and in as another account: none of the first account's bubbles.

On iPhone also pick a HEIC photo. Look Back refuses HEIC, so if `image_picker` does not convert it you will see
"Không hỗ trợ loại file này."; on Android a HEIC from the gallery is refused the same way.

## Troubleshooting

| Symptom | Fix |
|---|---|
| No bubbles, no error | Look Back is away, the `/lb` route is not deployed, or the ticket secrets differ. Check `media-ticket` and `session` in the 🐞 console. |
| Bubbles stay ⏳ but the list loaded | The picture request failed; usually the `Cookie` did not reach `/lb/media`. |
| Video spins for ever on iPhone | AVPlayer did not send the header with the segments. Not tested yet. |
