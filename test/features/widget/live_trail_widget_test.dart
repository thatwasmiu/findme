import 'package:findme/features/widget/data/live_trail_widget.dart';
import 'package:findme/features/widget/data/widget_updater.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS gets no widget', () {
    expect(liveTrailWidget(TargetPlatform.iOS), isA<NoTrailWidget>());
  });

  test('Android gets the updater', () {
    expect(liveTrailWidget(TargetPlatform.android), isA<WidgetUpdater>());
  });
}
