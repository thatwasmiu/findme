import 'package:findme/features/trail/presentation/hachiware.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('keyframes (the web styles.css hop / shadow / ripple)', () {
    test('hop: squashed on landing, 12 px up and tilted at the top', () {
      final land = hopAt(0);
      expect(land.dy, 0);
      expect(land.sx, closeTo(1.06, 1e-9));
      expect(land.sy, closeTo(0.94, 1e-9));
      final up = hopAt(0.45);
      expect(up.dy, -12);
      expect(up.turnDeg, -4);
      expect(hopAt(0.60).turnDeg, 4);
      expect(hopAt(0.85).dy, 0);
      expect(hopAt(0.30).dy, inExclusiveRange(-12, 0));
    });

    test('shadow shrinks while she is up', () {
      expect(shadowAt(0).scale, 1);
      expect(shadowAt(0.5).scale, closeTo(0.6, 1e-9));
      expect(shadowAt(0.5).opacity, closeTo(0.5, 1e-9));
    });

    test('ripple only shows after she lands', () {
      expect(rippleAt(0.5).opacity, 0);
      expect(rippleAt(0.85).opacity, closeTo(0.9, 1e-9));
      expect(rippleAt(1).scale, closeTo(2.4, 1e-9));
    });
  });

  Widget host(Widget w, {bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(child: w),
    ),
  );

  double hopY(WidgetTester t) => t
      .widget<Transform>(find.byKey(const Key('hachiware-hop')))
      .transform
      .getTranslation()
      .y;

  testWidgets('she hops: up at 45% of the 1.6 s loop, down at 85%', (t) async {
    await t.pumpWidget(host(const Hachiware(label: 'x')));
    expect(hopY(t), 0);
    await t.pump(const Duration(milliseconds: 720)); // 45%
    expect(hopY(t), lessThan(-11));
    await t.pump(const Duration(milliseconds: 640)); // 85%
    expect(hopY(t), closeTo(0, 0.5));
  });

  testWidgets('pink ring and glow around her', (t) async {
    await t.pumpWidget(host(const Hachiware(label: 'x')));
    final d =
        t.widget<Container>(find.byKey(const Key('hachiware-face'))).decoration!
            as BoxDecoration;
    expect(d.shape, BoxShape.circle);
    expect(d.border!.top.width, 3);
    expect(d.boxShadow, isNotEmpty);
  });

  testWidgets('reduced motion: she stands still', (t) async {
    await t.pumpWidget(host(const Hachiware(label: 'x'), reduceMotion: true));
    await t.pump(const Duration(milliseconds: 720));
    expect(hopY(t), 0);
  });

  testWidgets('keeps her screen-reader label', (t) async {
    await t.pumpWidget(host(const Hachiware(label: 'Lần cuối thấy ở đây')));
    expect(find.bySemanticsLabel('Lần cuối thấy ở đây'), findsOneWidget);
  });
}
