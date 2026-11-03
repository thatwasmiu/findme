# 09. Share links and friends

## 🔗 Share links

Files: `lib/features/shares/` (`data/shares_repository.dart`, `presentation/shares_sheet.dart`). Web twin:
`SharePanel.tsx` and the share functions in `api.ts`.

The sheet opens from **🔗 Chia sẻ**:

- **Create:** a name (1–40 characters), an expiry (1 giờ / 1 ngày / 7 ngày / Chọn ngày), and optionally "Cho xem cả
  đường đi 🐾" from a chosen day until today.
- **Each link:** remaining time ("còn 25 phút"), **Sao chép** (copies the link), **Gửi** (opens Android's / iOS's
  share sheet), **Sửa** (extend or change the route start day), **🐾** (route on/off), **Thu hồi** (asks first).
- **Expired links** show "đã hết hạn", lose Sao chép/Gửi, and offer **Gia hạn** and **Xoá**.

The link is `WEB_ORIGIN/s/<id>` and opens the **web** share page: the person you send it to does not need the app.
That is why `WEB_ORIGIN` is in the config ([chapter 02](02-running-the-app.md)).

## 👥 Friends

Files: `lib/features/friends/` (`data/friends_repository.dart`, `presentation/friends_controller.dart`,
`presentation/friends_sheet.dart`). Web twin: `useFriends.ts`, `FriendsPanel.tsx`, `friendsApi.ts`.

- Your **friend code** with Sao chép; type someone's code to send a request (if they already asked you, you become
  friends at once).
- **Lời mời đến:** Đồng ý / Từ chối. **Đang chờ:** Huỷ. **Bạn bè:** last seen ("thấy 3 giờ trước" or "chưa thấy hôm
  nay"), **Hiện trên bản đồ**, **Xoá bạn** (asks first).
- The 👥 button shows a badge with the number of incoming requests.

Refresh rhythm (same as the web): the list every 60 s. Shown friends' prints and positions come with your own trail in
the one `/track` request a minute (chapter 06), and right away when you switch a friend on; a friend the server leaves
out of the answer (no longer a friend) drops off. Paused while the app is in the background. Which friends are
shown is remembered on the phone (`shared_preferences`); a removed friend disappears from the map by itself.

Tests: `test/features/shares/` and `test/features/friends/`.

Next: [10. Testing](10-testing.md).
