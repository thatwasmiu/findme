import 'dart:io';

import 'package:findme/features/widget/data/file_day_log.dart';
import 'package:findme/features/widget/data/home_widget_host.dart';
import 'package:findme/features/widget/data/render.dart';
import 'package:findme/features/widget/data/tile_cache.dart';
import 'package:findme/features/widget/data/widget_updater.dart';
import 'package:findme/features/widget/domain/trail_widget.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// The real widget on Android. iPhone needs a WidgetKit extension first (guide chapter 17), so nothing happens there.
TrailWidget liveTrailWidget(TargetPlatform platform) =>
    platform == TargetPlatform.android
    ? WidgetUpdater(_load, DateTime.now)
    : NoTrailWidget();

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
