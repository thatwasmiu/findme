# 06. Date filter and live refresh

Files: `lib/features/trail/presentation/trail_controller.dart`, `date_filter.dart`, `top_bar.dart`,
`lib/features/trail/domain/date_range.dart`. Web twin: the polling in `App.tsx`, `DateFilter.tsx`, `dateRange.ts`.

## The date filter

Presets **Hôm nay / Hôm qua / 7 ngày** (the web also has 30 ngày; the app leaves it out), and 📅 opens a range
picker. Ranges are in the phone's local time,
sent to the API as JS-style ISO strings (`2026-10-26T17:00:00.000Z`, always with milliseconds: `isoMs()`). The API
serves at most ~31 days; more → "Chọn tối đa 31 ngày một lần nhé 📅".

## Live refresh, exactly like the web

`TrailController` keeps the trail fresh:

1. **First load:** the whole range.
2. **Every refresh after that:** only the newest part (`tailFrom`): from the start of the stop you are still at, or
   15 minutes before your last print. The result is merged in (`mergeTail`). Much less data on a 30-day range.
3. **One request a minute** (`pollMs`, 60 s) for you *and* your shown friends (`GET /track?…&have=…&friends=…`).
   `have` is your newest point time: if it is still the newest, the server answers `unchanged` after one tiny read
   and only the 👀 point moves. Each shown friend rides along as `<id>~<since>~<have>` (`friendAsk`); their answers
   are merged like your own trail (`friendMerge`, `FriendsController.apply`). Switching a friend on (or the friend
   list arriving) asks at once instead of waiting for the next minute.
4. **Past ranges** (yesterday, an old custom range) cannot change: no fetch, but the screen still re-renders so
   "👀 12 phút trước" keeps moving.
5. **Background:** when the app is hidden (`AppLifecycleListener.onHide`) it stops asking; when it comes back
   (`onShow`) it refreshes at once.
6. **Only the latest load wins:** if you switch range while a load is in flight, the old answer is thrown away
   (a sequence number, like the web's `seq`).
7. **Today kept on the phone** (web: `todayCache.ts`): with **Hôm nay** picked, each load saves today's trail (yours
   and shown friends') in `shared_preferences` (`findme.today`), tagged with the account (the `sub` inside the access
   token, `subOf`) and the day. Reopening the app the same day draws it at once, and the first request is already the
   short one (`from` = the newest part, `have` = the newest time). Another account or another day: ignored. Signing
   out, an expired session or a login without a map deletes it.

Errors: a failed background refresh stays silent and keeps what is on screen (the next tick retries). A failed full
load shows "Chưa tải được dấu chân — thử lại sau chút nhé ✨". 401 signs you out, 403 shows the "no account" screen.

## Testing time without waiting

`test/features/trail/presentation/trail_controller_test.dart` uses `fake_async`: the test moves a fake clock
(`f.elapse(Duration(seconds: 60))`) and timers fire instantly. The clock the controller reads (`nowProvider`) is
overridden too, so "today" is always 28 Oct 2026 15:00 in the test.

Next: [07. Trail panel](07-trail-panel.md).
