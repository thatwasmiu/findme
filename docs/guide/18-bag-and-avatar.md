# Chapter 18: The bag and your avatar

The app's copy of the web's bag and avatar (`travel-heatmap`, chapter 21 of its guide). Every account has a **bag**:
8 pockets you fill with ways to reach you (phone, Zalo, email, YouTube, Spotify, TikTok, Instagram, links, QR codes,
photos, secret notes). Friends open it by tapping you on the map or "🎒 Túi" in the friends list. You can also choose
an **avatar**: a round picture that replaces Hachiware on your map and your initial on your friends' maps.

## Where to find it

| You want | Tap |
|---|---|
| Edit your bag | 👥 → "🎒 Túi của tôi & ảnh đại diện" → a pocket. Then "Lưu túi". |
| Change your avatar | The round picture at the top of your bag. Drag to move, slider to zoom, "Lưu ảnh". |
| Open a friend's bag | Their marker on the map, or "🎒 Túi" on their row in 👥 |
| Let a share link open your bag | 🔗 → "Cho mở túi đồ 🎒" on a new link, or 🎒 on an existing one. A warning comes first: anyone holding the link sees everything. |

## How it works

- The bag is one document on the Find Me API: `GET/PUT /me/bag`, `GET /friends/{id}/bag`, `PUT /me/avatar`.
  The server checks every item (a phone must look like one, a YouTube link must point at YouTube…). When it says no,
  the editor shows why (`whyBag`).
- **Pictures** (QR, photo, avatar) go to **Look Back** like pin photos (chapter 16), same cookie, same tus upload, but
  into the account's album without a pin (`POST /lb/api/findme/card-album`, tus metadata `albumId` + `role`).
  Look Back then gives a **receipt** (`GET …/card-media/{id}/receipt`, 409 while it is still processing). Find Me only
  keeps a picture whose receipt checks out.
- A receipt lasts 10 minutes, so new pictures get a fresh one when you press "Lưu túi" (`freshReceipts`). Old
  pictures are deleted from Look Back only after the save worked.
- The avatar is cropped on the phone: `cropSquare` picks the square, `dart:ui` draws it at 800 × 800 and saves a PNG
  (the web saves a JPEG; Flutter has no JPEG encoder built in).
- Friends' pictures and QR codes are plain public addresses (signed, short-lived for the bag), so `Image.network`
  needs no cookie. A marker keeps the initial / Hachiware until the picture has loaded, and if it never does.
- Phone, email and links open with `url_launcher` (`tel:`, `mailto:`, the browser or the app).

## Code

| File | Role |
|---|---|
| `lib/features/bag/domain/bag.dart` | Item types, `itemAction`, `canAdd`, `cropSquare`, JSON in and out. Port of `bag.ts`. |
| `lib/features/bag/data/bag_repository.dart` | The API calls, `uploadCard`, `waitForReceipt`, `freshReceipts`, `cardErrorText`. Port of `bagApi.ts` + `cardUpload.ts`. |
| `presentation/bag_icons.dart` | The 11 pocket icons, the web's SVG drawn with `flutter_svg`. |
| `presentation/bag_widgets.dart` | The backpack (`BagGrid`), pockets, `AvatarCircle`, the cream sheet. |
| `presentation/bag_sheet.dart` | A friend's bag, read-only; full-screen picture / note (white behind a QR). |
| `presentation/bag_editor.dart` | Your bag: add, edit, move ◀ ▶, remove, save. Asks before closing unsaved. |
| `presentation/avatar_crop.dart` | Pick, drag, zoom, upload; "Bỏ ảnh, dùng lại Hachiware" clears it. |

## Try it

The bag needs the Find Me API with the bag routes deployed (`travel-heatmap` HANDOFF says whether it is). Until then
opening a bag says "Chưa mở được túi…". With it live: fill two pockets on one account, add the other as a friend,
tap the first one's marker. A QR should scan from another phone off the white screen.
