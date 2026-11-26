import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/presentation/track_button.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/tracker_fakes.dart';

final now = DateTime.utc(2026, 11, 4, 12);

void main() {
  late FakeTracker tracker;

  // Disclosure already accepted: these tests are about the button, the sheet tests cover the dialog.
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'findme.trackerDisclosure': true,
    }),
  );

  Future<void> pump(WidgetTester t, TrackerState s) async {
    tallView(t);
    tracker = FakeTracker(s);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(
            auth: fakeAuth(),
            trackerStore: MemoryTrackerStore(),
            fakeTracker: false,
          ),
          trackerControllerProvider.overrideWith(() => tracker),
          locationSourceProvider.overrideWithValue(FakeLocation()),
          nowProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: Center(child: TrackButton())),
        ),
      ),
    );
    await t.pump();
  }

  testWidgets('always on, off: ▶ turns it on', (t) async {
    await pump(t, const TrackerState());
    expect(find.text('Ghi hành trình'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Bắt đầu ghi hành trình'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['turnOn']);
  });

  testWidgets('always on, on: ■ turns it off', (t) async {
    await pump(t, const TrackerState(on: true));
    expect(find.text('Đang ghi'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Dừng ghi hành trình'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['turnOff']);
  });

  testWidgets('trip mode, no trip: ▶ asks for a preset', (t) async {
    await pump(t, const TrackerState(sharing: 'trip'));
    await t.tap(find.bySemanticsLabel('Bắt đầu chuyến đi'));
    await t.pumpAndSettle();
    await t.tap(find.text('1 giờ'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['startTrip:1h']);
  });

  testWidgets('on a trip: time left, ■ ends it', (t) async {
    await pump(
      t,
      TrackerState(
        sharing: 'trip',
        on: true,
        tripUntil: now.add(const Duration(minutes: 42)),
      ),
    );
    expect(find.text('Đang đi · còn 42 phút'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Kết thúc chuyến đi'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['endTrip']);
  });

  testWidgets('a problem shows in red; the chip opens the sheet', (t) async {
    await pump(t, const TrackerState(problem: TrackerProblem.needAlways));
    await t.tap(find.text('Thiếu quyền vị trí "Luôn luôn"'));
    await t.pumpAndSettle();
    expect(find.text('📍 Ghi hành trình'), findsOneWidget);
  });
}
