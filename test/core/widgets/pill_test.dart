import 'package:findme/core/widgets/pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('on pill has white text and taps', (t) async {
    var taps = 0;
    await t.pumpWidget(
      host(
        Pill(label: 'Đăng nhập 💖', style: PillStyle.on, onTap: () => taps++),
      ),
    );
    final text = t.widget<Text>(find.text('Đăng nhập 💖'));
    expect(text.style?.color, Colors.white);
    await t.tap(find.byType(Pill));
    expect(taps, 1);
  });

  testWidgets('semanticLabel is what screen readers hear', (t) async {
    await t.pumpWidget(
      host(const Pill(label: '👋', semanticLabel: 'Đăng xuất')),
    );
    expect(find.bySemanticsLabel('Đăng xuất'), findsOneWidget);
  });

  testWidgets('badge shows the count only when > 0', (t) async {
    await t.pumpWidget(host(const Pill(label: '👥', badge: 2)));
    expect(find.text('2'), findsOneWidget);
    await t.pumpWidget(host(const Pill(label: '👥', badge: 0)));
    expect(find.text('0'), findsNothing);
  });
}
