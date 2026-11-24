import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true when the phone is plugged in. Only while the app runs (no permission, no background wake).
final chargingProvider = Provider<Stream<bool>>(
  (_) => Battery().onBatteryStateChanged
      .map((s) => s != BatteryState.discharging && s != BatteryState.unknown)
      .distinct(),
);
