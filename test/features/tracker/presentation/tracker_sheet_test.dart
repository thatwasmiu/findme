import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/tracker/domain/location_source.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/tracker/presentation/tracker_sheet.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/tracker_fakes.dart';

final now = DateTime.utc(2026, 11, 4, 12);

void main() {
  late FakeTracker tracker;
  late FakeLocation gps;
  late MemoryTrackerStore store;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester t, TrackerState s) async {
    tallView(t);
    tracker = FakeTracker(s);
    gps = FakeLocation();
    store = MemoryTrackerStore();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(
            auth: fakeAuth(),
            trackerStore: store,
            fakeTracker: false,
          ),
          trackerControllerProvider.overrideWith(() => tracker),
          locationSourceProvider.overrideWithValue(gps),
          nowProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: TrackerSheet()),
        ),
      ),
    );
    await t.pump();
  }

  for (final (state, text) in [
    (const TrackerState(on: true), 'Đang ghi'),
    (const TrackerState(), 'Đã tắt'),
    (
      const TrackerState(problem: TrackerProblem.needAlways),
      'Thiếu quyền vị trí "Luôn luôn"',
    ),
    (
      const TrackerState(on: true, problem: TrackerProblem.badToken),
      'Token sai hoặc đã đổi',
    ),
    (
      const TrackerState(on: true, problem: TrackerProblem.noToken),
      'Chưa có token',
    ),
    (
      const TrackerState(on: true, problem: TrackerProblem.noAccount),
      'Tài khoản này không ghi được hành trình',
    ),
  ]) {
    testWidgets('status: $text', (t) async {
      await pump(t, state);
      expect(find.text(text), findsOneWidget);
    });
  }

  testWidgets('needAlways offers the settings screen', (t) async {
    await pump(t, const TrackerState(problem: TrackerProblem.needAlways));
    await t.tap(find.text('Mở cài đặt').first);
    expect(gps.settingsOpened, 1);
  });

  testWidgets('counts and times', (t) async {
    await pump(
      t,
      TrackerState(
        on: true,
        queued: 12,
        lastOk: now.subtract(const Duration(minutes: 5)),
        lastFix: now.subtract(const Duration(minutes: 2)),
      ),
    );
    expect(find.text('Điểm chờ gửi: 12'), findsOneWidget);
    expect(find.text('Gửi lần cuối: 5 phút trước'), findsOneWidget);
    expect(find.text('Điểm cuối: 2 phút trước'), findsOneWidget);
    expect(find.textContaining('Điểm bị từ chối'), findsNothing);
  });

  testWidgets('rejected shown when there are some', (t) async {
    await pump(t, const TrackerState(rejected: 3));
    expect(find.text('Điểm bị từ chối: 3'), findsOneWidget);
    expect(find.text('Gửi lần cuối: chưa'), findsOneWidget);
  });

  testWidgets('Gửi ngay calls sendNow', (t) async {
    await pump(t, const TrackerState(on: true, queued: 3));
    await t.tap(find.text('Gửi ngay'));
    expect(tracker.calls, ['sendNow']);
  });

  testWidgets('first switch-on: Không keeps it off', (t) async {
    await pump(t, const TrackerState());
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.textContaining('kể cả khi bạn đóng ứng dụng'), findsOneWidget);
    await t.tap(find.text('Không'));
    await t.pumpAndSettle();
    expect(tracker.calls, isEmpty);
  });

  testWidgets('Đồng ý turns it on, and is not asked again', (t) async {
    await pump(t, const TrackerState());
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    await t.tap(find.text('Đồng ý'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['turnOn']);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(find.text('Đồng ý'), findsNothing);
    expect(tracker.calls, ['turnOn', 'turnOn']);
  });

  testWidgets('switch off calls turnOff', (t) async {
    await pump(t, const TrackerState(on: true));
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(tracker.calls, ['turnOff']);
  });

  testWidgets('iPhone: indicator switch calls setIndicator', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pump(t, const TrackerState(on: true));
    expect(find.text('Hiện chỉ báo vị trí'), findsOneWidget);
    await t.tap(find.byKey(const Key('indicator')));
    await t.pump();
    expect(tracker.calls, ['setIndicator:true']);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Android: no indicator switch', (t) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await pump(t, const TrackerState(on: true));
    expect(find.text('Hiện chỉ báo vị trí'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'upload interval: current one selected, tap calls setUploadEvery',
    (t) async {
      await pump(t, const TrackerState(on: true));
      for (final l in ['5 giây', '10 giây', '30 giây', '1 phút', '2 phút']) {
        expect(find.text(l), findsOneWidget);
      }
      await t.tap(find.text('10 giây'));
      await t.pump();
      expect(tracker.calls, ['setUploadEvery:10s']);
    },
  );

  testWidgets('trip mode, no trip: no switch, presets after the disclosure', (
    t,
  ) async {
    await pump(t, const TrackerState(sharing: 'trip'));
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Không trong chuyến đi'), findsOneWidget);
    expect(find.text('Bắt đầu chuyến đi'), findsOneWidget);
    expect(find.text('Kết thúc'), findsNothing);
    await t.tap(find.text('1 giờ'));
    await t.pumpAndSettle();
    await t.tap(find.text('Đồng ý'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['startTrip:1h']);
    await t.tap(find.text('đến khi tắt'));
    await t.pumpAndSettle();
    expect(tracker.calls, ['startTrip:1h', 'startTrip:open']);
  });

  testWidgets('on a trip: time left and Kết thúc', (t) async {
    await pump(
      t,
      TrackerState(
        sharing: 'trip',
        on: true,
        tripUntil: now.add(const Duration(minutes: 42)),
      ),
    );
    expect(find.text('Đang đi · còn 42 phút'), findsOneWidget);
    await t.tap(find.text('Kết thúc'));
    await t.pump();
    expect(tracker.calls, ['endTrip']);
  });

  testWidgets('an open trip says until switched off', (t) async {
    await pump(t, const TrackerState(sharing: 'trip', on: true));
    expect(find.text('Đang đi · đến khi tắt'), findsOneWidget);
  });
}
