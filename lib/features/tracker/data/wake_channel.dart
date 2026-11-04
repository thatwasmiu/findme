import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// iPhone only: "significant location change" monitoring in `ios/Runner/AppDelegate.swift`. While it runs, iOS
/// relaunches a terminated Find Me in the background after ~500 m of movement, and every such event calls back
/// [onWake] so GPS recording (which iOS may have paused) starts again. On Android every call is a no-op.
class WakeChannel {
  static const _ch = MethodChannel('findme/tracker');

  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> start() async {
    if (_ios) await _ch.invokeMethod<void>('startSignificant');
  }

  Future<void> stop() async {
    if (_ios) await _ch.invokeMethod<void>('stopSignificant');
  }

  void onWake(void Function() f) {
    if (!_ios) return;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'wake') f();
    });
  }
}

final wakeChannelProvider = Provider<WakeChannel>((_) => WakeChannel());
