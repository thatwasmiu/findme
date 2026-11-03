import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/replay/presentation/replay_bar.dart';
import 'package:findme/features/replay/presentation/replay_controller.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/top_bar.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:findme/features/trail/presentation/trail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

final now = DateTime(2026, 10, 28, 15);
int sec(int h, [int m = 0]) =>
    DateTime(2026, 10, 28, h, m).millisecondsSinceEpoch ~/ 1000;
String iso(int h, [int m = 0]) => isoMs(DateTime(2026, 10, 28, h, m));

Widget sheet(
  Track track, {
  bool oneDay = true,
  bool replaying = false,
  VoidCallback? onReplay,
}) => MaterialApp(
  theme: buildTheme(),
  home: Scaffold(
    body: TrailSheet(
      track: track,
      oneDay: oneDay,
      replaying: replaying,
      onReplay: onReplay ?? () {},
      onSelect: (_, _) {},
    ),
  ),
);

void main() {
  setUpAll(() => registerFallbackValue(const DateRange(from: '', to: '')));

  group('trail sheet', () {
    testWidgets('empty range', (t) async {
      await t.pumpWidget(sheet(Track.empty));
      expect(
        find.text('Chưa có dấu chân nào trong khoảng này 🐾'),
        findsOneWidget,
      );
    });

    testWidgets('one day: diary with stays, moves (comma km) and replay', (
      t,
    ) async {
      final track = Track(
        points: [
          TrackPoint(105.78, 21.03, sec(9)),
          TrackPoint(105.78, 21.04, sec(9, 10)),
          TrackPoint(105.78, 21.05, sec(9, 20)),
          TrackPoint(105.78, 21.06, sec(9, 30)),
        ],
        stops: [
          Stop(
            lon: 105.78,
            lat: 21.06,
            start: iso(9, 30),
            end: iso(10, 30),
            seconds: 3600,
          ),
        ],
      );
      var replays = 0;
      await t.pumpWidget(sheet(track, onReplay: () => replays++));
      expect(find.text('📅 Nhật ký ngày'), findsOneWidget);
      expect(
        find.text('🐾 Một nơi xinh xinh'),
        findsOneWidget,
      ); // stop without a name
      expect(find.text('09:30 – 10:30'), findsOneWidget);
      expect(find.text('1 giờ'), findsOneWidget);
      expect(find.text('🛵 di chuyển · 2,2 km'), findsOneWidget);
      await t.tap(find.text('▶️ Phát lại'));
      expect(replays, 1);
      await t.pumpWidget(sheet(track, replaying: true));
      expect(find.text('⏹ Dừng'), findsOneWidget);
    });

    testWidgets('many days: top places with medals', (t) async {
      tallView(t);
      Stop s(String name, int secs) => Stop(
        lon: 1,
        lat: 1,
        start: iso(1),
        end: iso(2),
        seconds: secs,
        name: name,
      );
      await t.pumpWidget(
        sheet(
          Track(
            stops: [
              s('Nhà', 9000),
              s('Cafe', 3600),
              s('Chợ', 1800),
              s('Trường', 600),
            ],
          ),
          oneDay: false,
        ),
      );
      expect(find.text('⭐ Chỗ dừng nhiều nhất'), findsOneWidget);
      for (final m in ['🥇', '🥈', '🥉', '📍']) {
        expect(find.text(m), findsOneWidget);
      }
      await t.pumpWidget(
        sheet(Track(points: [TrackPoint(1, 1, sec(1))]), oneDay: false),
      );
      expect(find.text('Chưa dừng chỗ nào lâu hơn 5 phút'), findsOneWidget);
    });
  });

  group('top bar', () {
    late MockTrack track;
    Future<ProviderContainer> pump(
      WidgetTester t, {
      int incoming = 0,
      Future<Track> Function()? answer,
    }) async {
      track = MockTrack();
      when(() => track.fetch(any())).thenAnswer(
        (_) =>
            answer?.call() ??
            Future.value(
              Track(
                last: LastPoint(
                  lon: 1,
                  lat: 2,
                  ts: isoMs(now.subtract(const Duration(minutes: 12))),
                ),
              ),
            ),
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(auth: fakeAuth(), track: track),
            nowProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(
            theme: buildTheme(),
            home: Scaffold(
              body: TopBar(
                onShare: () {},
                onFriends: () {},
                incomingCount: incoming,
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump();
      return ProviderScope.containerOf(t.element(find.byType(TopBar)));
    }

    testWidgets('brand, last seen, share, friends badge, sign out, presets', (
      t,
    ) async {
      final c = await pump(t, incoming: 2);
      expect(find.text('📍 Find Me'), findsOneWidget);
      expect(find.text('👀 12 phút trước'), findsOneWidget);
      expect(find.text('🔗 Chia sẻ'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      for (final p in ['Hôm nay', 'Hôm qua', '7 ngày', '30 ngày']) {
        expect(find.text(p), findsOneWidget);
      }
      await t.tap(find.text('👀 12 phút trước'));
      expect(c.read(flyToProvider), (1.0, 2.0));
      await t.tap(find.text('7 ngày'));
      expect(
        c.read(trailControllerProvider).range,
        presetRange(Preset.d7, now),
      );
      await t.tap(find.bySemanticsLabel('Đăng xuất'));
      await t.pump();
      expect(c.read(authControllerProvider), AuthPhase.signedOut);
    });

    testWidgets('loading line and the 31-day error', (t) async {
      await pump(t, answer: () => Future.error(const FormatException()));
      expect(
        find.text('Chưa tải được dấu chân — thử lại sau chút nhé ✨'),
        findsOneWidget,
      );
    });
  });

  testWidgets('replay bar: clock, range, speed label, close', (t) async {
    final track = MockTrack();
    when(() => track.fetch(any())).thenAnswer((_) async => Track.empty);
    await t.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(auth: fakeAuth(), track: track),
        child: MaterialApp(
          theme: buildTheme(),
          home: const Scaffold(body: ReplayBar()),
        ),
      ),
    );
    final c = ProviderScope.containerOf(t.element(find.byType(ReplayBar)));
    c.read(replayControllerProvider.notifier).start([
      TrackPoint(1, 1, sec(8)),
      TrackPoint(1, 1, sec(9)),
    ]);
    c.read(replayControllerProvider.notifier).seek(0);
    await t.pump();
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('08:00 – 09:00'), findsOneWidget);
    expect(find.text('1×'), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await t.tap(find.bySemanticsLabel(RegExp('Tốc độ')));
      await t.pump();
    }
    expect(find.text('0,5×'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Đóng phát lại'));
    await t.pump();
    expect(c.read(replayControllerProvider), isNull);
  });
}
