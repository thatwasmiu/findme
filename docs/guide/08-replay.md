# 08. Replay

Files: `lib/features/replay/presentation/replay_controller.dart`, `replay_bar.dart`,
`lib/features/replay/domain/replay_math.dart`. Web twin: `ReplayBar.tsx` (`useReplay`) and `replayAll` in `App.tsx`.

## Two modes

| Mode | When | How it plays |
|---|---|---|
| Alone | no friends shown, or a past range | Print by print, 120 ms per print at 1× (at least 10 s), so long days don't rush |
| Together | friends shown **and** the range reaches today | By the clock, from the earliest print of anyone to the latest, in about a minute at 1×; you and every shown friend stand where you were at that moment |

While replaying, the top bar is replaced by the **replay bar**: ⏸/▶️, the current time, the span (`dd/MM HH:mm` when
it spans days), the speed (0,5× → 1× → 2× → 4× → 8×), ✕, and a slider to scrub. Hachiware walks along the trail; the
map follows her when she nears the edge.

## The clock

The bar owns a **Ticker** (Flutter's per-frame callback, like `requestAnimationFrame`). Each frame it calls
`ReplayController.step(ms since last frame)`, which moves the position with `advance()`. If the phone's "remove
animations" accessibility setting is on, the replay jumps straight to the end (the web's `prefers-reduced-motion`).

Picking a new range or signing out stops the replay.

Tests: `test/features/replay/`.

Next: [09. Share links and friends](09-shares-and-friends.md).
