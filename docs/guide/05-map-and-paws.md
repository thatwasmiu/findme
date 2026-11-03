# 05. The map and paw prints

Files: `lib/features/trail/presentation/map_view.dart`, `paw_layer.dart`, `lib/core/storage/prefs.dart`. Web twin:
`MapView.tsx`, `paws.ts`, `startView.ts`.

## flutter_map in one picture

`FlutterMap` is a stack of **layers** drawn on top of each other, bottom first:

```
FlutterMap
 ├─ TileLayer          OpenStreetMap tiles (pastel tint via ColorFiltered, like the web's CSS filter)
 ├─ PawLayer           your paw prints
 ├─ PawLayer × N       each shown friend's prints, in their colour
 ├─ MarkerLayer        stops 🐾, friends' initials, Hachiware
 └─ RichAttributionWidget  "© OpenStreetMap contributors" (required by OSM's rules)
```

Tiles need `userAgentPackageName: 'app.findme.mobile'` so OSM can identify the app (their usage policy).

## Paw prints: one painter, thousands of prints

A widget per print would be slow with thousands of prints. `PawLayer` uses a **CustomPainter**, Flutter's canvas
(the web's `<canvas>` in `paws.ts`):

- `MapCamera.of(context)` gives the current camera; `camera.latLngToScreenOffset()` turns lat/lon into pixels.
- Each print is rotated toward the next one (`bearing`) and shifted left/right alternately, like footsteps.
- Colour by local hour (`pawColor`): peach morning, pink afternoon, coral evening, lavender night. Friends: one colour each (`friendColor`, same hash as the web).
- Size by zoom (`pawSize`): 14 / 11 / 8 / 6 px.
- Prints more than 20 px off-screen are skipped.
- `shouldRepaint` skips redraws when a poll hands back the same trail (`samePoints`), saving battery.

## Where the map opens

- First time on this phone: Hà Nội (Hoàn Kiếm), zoom 13.
- When data arrives with a last point: there, zoom 16, and that point is remembered (`Prefs.rememberStart`, 4
  decimals) so next time the map opens there at zoom 15.
- No last point but some prints: the map fits all prints.

## Tapping things

- A stop 🐾 → its name (or "Một nơi xinh xinh"), times and duration.
- Near a paw print → its time and accuracy, "🐾 14:05 · ±8 m".
- A friend's pin → their name.

These show as a small bar at the bottom of the screen (a SnackBar) instead of Leaflet's popups.

## Flying

Tapping 👀 or a row in the diary sets `flyToProvider`; `MapView` animates there (zoom 17, 0.8 s).

## Tests

`test/features/trail/presentation/paw_layer_test.dart` (sizes, same-trail check, nearest print) and
`map_view_test.dart` (markers, Hachiware, replay walker; tiles switched off with `showTiles: false` so tests never
touch the network).

Next: [06. Date filter and live refresh](06-date-filter-and-live-refresh.md).
