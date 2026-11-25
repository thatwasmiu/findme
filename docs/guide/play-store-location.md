# Google Play: background location (drafts)

What Play Console asks for because Find Me reads location in the background (chapter 15). These are **drafts**:
read them, adjust to how you actually run the service, host the privacy policy yourself, and submit. Play's rules
change; check the current pages in Play Console before submitting.

## 1. In-app prominent disclosure (done in the app)

Shown once, before any location prompt, from the 🧭 sheet (`lib/features/tracker/presentation/tracker_sheet.dart`):

> Find Me sẽ ghi lại vị trí của bạn ở chế độ nền, kể cả khi bạn đóng ứng dụng. Vị trí được gửi về máy chủ Find Me
> để vẽ hành trình của bạn, và chỉ hiện cho bạn bè cùng những link chia sẻ mà bạn chọn. Bạn có thể tắt bất cứ lúc nào.

Buttons **Không** (nothing is asked, tracking stays off) and **Đồng ý** (then the system prompts follow).

## 2. Background location declaration (Play Console → App content → Sensitive permissions)

**Core feature that uses background location (draft):**

> Find Me records the user's position in the background, while the app is closed, to draw their travel trail on a
> map and to show their current position to the friends and share links they choose. Recording starts only when
> the user turns on "Ghi hành trình" in the app, after an in-app explanation, and stops when they turn it off or
> sign out. A notification is shown the whole time it runs.

**Why foreground use is not enough:** the trail is the user's day of movement; it must keep recording with the phone
in a pocket and the app closed.

## 3. Demo video (≤ 30 s, unlisted YouTube link)

Record on a phone or the emulator, in this order:

1. Open Find Me, tap **🧭**.
2. Turn **Ghi hành trình** on: the disclosure dialog appears; tap **Đồng ý**.
3. The system location prompt; then Settings → **Allow all the time**.
4. Back in the app: status **Đang ghi**; leave the app; the notification **Find Me đang ghi hành trình** is visible.
5. Reopen: **Điểm cuối** shows a recent time; the trail on the map.

## 4. Foreground service type (Play Console → App content → Foreground service permissions)

Type **location**. Draft: "Continuous location tracking that the user started (travel trail). The user sees a
notification the whole time and can stop it in the app."

## 5. Privacy policy (done)

Live page: `travel-heatmap/web/public/privacy.html`, served at `<WEB_ORIGIN>/privacy.html` with the web deploy
(Vietnamese, covers location, account, pins/photos, bag, friends, share links). Linked from the web sign-in form and
the app's welcome screen. Paste that URL into Play Console → App content → Privacy policy and into App Store Connect.
When the app starts sending a new kind of data, update the page, `ios/Runner/PrivacyInfo.xcprivacy` and §6.

## 6. Data safety form (answers)

| Question | Answer |
|---|---|
| Does the app collect or share user data? | Yes, collects |
| Data types | **Location → Precise location**; **Personal info → Email address, Name, User IDs**; **Photos and videos → Photos, Videos**; **App activity → Other user-generated content** (pin notes, bag items) |
| Shared with third parties? | No (AWS and Look Back are service providers, which Play does not count as sharing; friends and link holders the user picks are the app's function, not sharing) |
| Processed ephemerally? | No (stored) |
| Required or optional? | Email, name, user ID: required (account). Location, photos/videos, user content: optional (only when the user records, pins or fills the bag) |
| Purpose | App functionality (all); Account management (email, name, user ID) |
| Encrypted in transit? | Yes (HTTPS) |
| Can users request deletion? | Yes: in the app (👤 → 🗑️ Xoá tài khoản) or by email |
| Delete account URL (Data deletion section) | `<WEB_ORIGIN>/privacy.html` (its "Bạn có thể" list gives the in-app steps and the email) |

Keep this table, `ios/Runner/PrivacyInfo.xcprivacy` and the App Store Connect privacy answers saying the same thing.
