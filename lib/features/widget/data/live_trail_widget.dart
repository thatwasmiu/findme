import 'dart:async';
import 'dart:io';

import 'package:findme/features/widget/data/file_day_log.dart';
import 'package:findme/features/widget/data/home_widget_host.dart';
import 'package:findme/features/widget/data/render.dart';
import 'package:findme/features/widget/data/tile_cache.dart';
import 'package:findme/features/widget/data/widget_updater.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';

/// The real widget on Android. iPhone needs a WidgetKit extension first (guide chapter 17), so nothing happens there.
TrailWidget liveTrailWidget(TargetPlatform platform) {
  if (platform == TargetPlatform.android) {
    return WidgetUpdater(_load, DateTime.now);
  }
  if (platform == TargetPlatform.iOS) unawaited(_iosSpike());
  return NoTrailWidget();
}

/// ponytail: iPhone widget parked (docs/HANDOFF.md). The test widget `ios/FindMeWidget` stays as a check: this writes
/// the time to the App Group so it can show whether the signing gives one. Replace with the real widget once it does.
Future<void> _iosSpike() async {
  try {
    await HomeWidget.setAppGroupId('group.app.findme.mobile');
    final now = DateTime.now();
    final hm =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await HomeWidget.saveWidgetData<String>('spike', hm);
    await HomeWidget.updateWidget(iOSName: 'FindMeWidget');
  } on Object catch (_) {} // a widget problem must never stop the app
}

Future<WidgetParts> _load() async {
  final root = await getApplicationSupportDirectory();
  // This folder is excluded from Android backup (res/xml/backup_rules.xml): it holds locations.
  final dir = Directory('${root.path}/widget');
  await dir.create(recursive: true);
  final asset = await rootBundle.load('assets/images/hachiware.webp');
  final hachiware = asset.buffer.asUint8List(
    asset.offsetInBytes,
    asset.lengthInBytes,
  );
  return WidgetParts(
    days: FileDayLog(dir),
    tiles: TileCache(
      Directory('${dir.path}/tiles'),
      fetchOsmTile,
      DateTime.now,
    ),
    host: HomeWidgetHost(dir),
    render: (scene, tiles) => renderWidgetPng(scene, tiles, hachiware),
  );
}
