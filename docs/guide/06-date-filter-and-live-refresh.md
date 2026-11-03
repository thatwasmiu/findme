# 06. Date filter and live refresh

Files: `lib/features/trail/presentation/trail_controller.dart`, `date_filter.dart`, `top_bar.dart`,
`lib/features/trail/domain/date_range.dart`. Web twin: the polling in `App.tsx`, `DateFilter.tsx`, `dateRange.ts`.

## The date filter

Presets **Hôm nay / Hôm qua / 7 ngày / 30 ngày**, and 📅 opens a range picker. Ranges are in the phone's local time,
sent to the API as JS-style ISO strings (`2026-10-26T17:00:00.000Z`, always with milliseconds: `isoMs()`). The API
serves at most ~31 days; more → "Chọn tối đa 31 ngày một lần nhé 📅".

## Live refresh, exactly like the web

`TrailController` keeps the trail fresh:

1. **First load:** the whole range.
2. **Every refresh after that:** only the newest part (`tailFrom`): from the start of the stop you are still at, or
   15 minutes before your last print. The result is merged in (`mergeTail`). Much less data on a 30-day range.
3. **Backoff:** 7 s after a load; if nothing new arrived (same last point), wait twice as long: 14 s, 28 s, 56 s,
   then 60 s at most. New prints → back to 7 s.
4. **Past ranges** (yesterday, an old custom range) cannot change: no fetch, but the screen still re-renders so
   "👀 12 phút trước" keeps moving.
5. **Background:** when the app is hidden (`AppLifecycleListener.onHide`) it stops asking; when it comes back
   (`onShow`) it refreshes at once.
6. **Only the latest load wins:** if you switch range while a load is in flight, the old answer is thrown away
   (a sequence number, like the web's `seq`).

Errors: a failed background refresh stays silent and keeps what is on screen (the next tick retries). A failed full
load shows "Chưa tải được dấu chân — thử lại sau chút nhé ✨". 401 signs you out, 403 shows the "no account" screen.

## Testing time without waiting

`test/features/trail/presentation/trail_controller_test.dart` uses `fake_async`: the test moves a fake clock
(`f.elapse(Duration(seconds: 7))`) and timers fire instantly. The clock the controller reads (`nowProvider`) is
overridden too, so "today" is always 28 Oct 2026 15:00 in the test.

Next: [07. Trail panel](07-trail-panel.md).
