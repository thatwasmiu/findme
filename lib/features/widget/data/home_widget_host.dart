import 'dart:io';
import 'dart:typed_data';

import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:home_widget/home_widget.dart';

/// Read by `TrailWidgetProvider.kt`.
const _pngKey = 'findme.widget.png';
const _lastFixKey = 'findme.widget.lastFix';
const _provider = 'app.findme.findme.TrailWidgetProvider';

class HomeWidgetHost implements WidgetHost {
  HomeWidgetHost(Directory dir)
    : _png = File('${dir.path}/widget.png'),
      _tmp = File('${dir.path}/widget.png.tmp');

  final File _png;
  final File _tmp;

  @override
  Future<void> publish(Uint8List png, DateTime lastFix) async {
    await _tmp.writeAsBytes(png, flush: true);
    await _tmp.rename(_png.path); // the widget never reads half a picture
    await HomeWidget.saveWidgetData<String>(_pngKey, _png.path);
    await HomeWidget.saveWidgetData<int>(
      _lastFixKey,
      lastFix.millisecondsSinceEpoch,
    );
    await refreshLabel();
  }

  @override
  Future<void> refreshLabel() =>
      HomeWidget.updateWidget(qualifiedAndroidName: _provider);

  @override
  Future<void> clear() async {
    await HomeWidget.saveWidgetData<String>(_pngKey, null);
    await HomeWidget.saveWidgetData<int>(_lastFixKey, null);
    await refreshLabel(); // no key left: the empty state, even if the file below cannot go
    for (final f in [_png, _tmp]) {
      if (f.existsSync()) await f.delete();
    }
  }
}
