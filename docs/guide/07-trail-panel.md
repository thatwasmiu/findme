# 07. Trail panel (day diary and top places)

File: `lib/features/trail/presentation/trail_sheet.dart`. Web twin: `TrailPanel.tsx`; logic in
`lib/features/trail/domain/trail_math.dart` (`timeline`, `topStops`).

The panel is a **DraggableScrollableSheet**: it peeks at the bottom (22% of the screen) and you drag it up to 60%.

| Range | Shows |
|---|---|
| Empty | "Chưa có dấu chân nào trong khoảng này 🐾" |
| One day | **📅 Nhật ký ngày**: stays (`09:30 – 10:30 · 🐾 Nhà · 1 giờ`) and the moves between them (`🛵 di chuyển · 2,2 km`, comma decimal like Vietnamese writing). Moves under 100 m are GPS wobble and hidden. ▶️ Phát lại when there are at least 2 prints |
| Several days | **⭐ Chỗ dừng nhiều nhất**: top 10 places by total time, 🥇🥈🥉 then 📍 |

A stop without a name shows "Một nơi xinh xinh" (names come from Nominatim on the server and can be missing).
Tapping a row flies the map there.

Tests: the "trail sheet" group in `test/features/trail/presentation/trail_ui_test.dart`.

Next: [08. Replay](08-replay.md).
