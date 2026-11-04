import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import '../../../helpers/fakes.dart';

Widget host(Widget map, MemoryPrefs prefs) => ProviderScope(
  overrides: baseOverrides(auth: fakeAuth(), prefs: prefs),
  child: MaterialApp(home: Scaffold(body: map)),
);

void main() {
  const pts = [
    TrackPoint(105.78, 21.03, 1000),
    TrackPoint(105.781, 21.031, 1060),
  ];
  const stop = Stop(
    lon: 105.78,
    lat: 21.03,
    start: '2026-10-27T01:00:00Z',
    end: '2026-10-27T02:00:00Z',
    seconds: 3600,
  );

  testWidgets('draws stops and Hachiware on the last point, remembers it', (
    t,
  ) async {
    final prefs = MemoryPrefs();
    await t.pumpWidget(
      host(
        const MapView(
          points: pts,
          stops: [stop],
          last: LastPoint(
            lon: 105.781,
            lat: 21.031,
            ts: '2026-10-27T02:00:00Z',
          ),
          showTiles: false,
        ),
        prefs,
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('🐾'), findsOneWidget);
    expect(find.bySemanticsLabel('Lần cuối thấy ở đây'), findsOneWidget);
    expect(prefs.start, (105.781, 21.031));
  });

  testWidgets('tapping a stop tells its name, or "Một nơi xinh xinh"', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const MapView(points: pts, stops: [stop], showTiles: false),
        MemoryPrefs(),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('🐾'));
    await t.pump();
    expect(find.textContaining('Một nơi xinh xinh'), findsOneWidget);
    expect(find.textContaining('1 giờ'), findsOneWidget);
  });

  testWidgets(
    'a friend pin shows their initial; replay hides "me" and shows the walker',
    (t) async {
      const friend = MapFriend(
        id: 'b',
        name: 'bình',
        color: Colors.teal,
        points: pts,
        last: LastPoint(lon: 105.78, lat: 21.03, ts: 'T'),
      );
      await t.pumpWidget(
        host(
          const MapView(
            points: pts,
            stops: [],
            last: LastPoint(lon: 105.781, lat: 21.031, ts: 'T'),
            friends: [friend],
            replay: ReplayView(track: pts, pos: 0.5),
            showTiles: false,
          ),
          MemoryPrefs(),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('B'), findsOneWidget);
      expect(find.bySemanticsLabel('Lần cuối thấy ở đây'), findsNothing);
      expect(find.bySemanticsLabel('Phát lại'), findsOneWidget);
    },
  );

  testWidgets('cannot zoom past the last tile level (19): no gray map', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const MapView(points: pts, stops: [stop], showTiles: false),
        MemoryPrefs(),
      ),
    );
    await t.pumpAndSettle();
    final map = t.widget<FlutterMap>(find.byType(FlutterMap)).mapController!
      ..move(const LatLng(21.03, 105.78), 22);
    await t.pump();
    expect(map.camera.zoom, 19);
  });
}
