import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Android's side of trip mode (`TripBridge.kt`): the alarm that stops GPS at the trip's end, the Quick Settings
/// tile and the home widget's ⏺/⏹ button. On iPhone every call is a no-op (the check on each fix is what counts
/// there).
class TripChannel {
  static const _ch = MethodChannel('findme/trip');

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  /// The trip's end changed (null: no end, or no trip): Kotlin sets or cancels the alarm and redraws the tile and
  /// the widget from the saved prefs. Never fails the caller: the fix check and the server window still hold.
  Future<void> sync(DateTime? until) async {
    if (!_android) return;
    try {
      await _ch.invokeMethod<void>('sync', until?.millisecondsSinceEpoch);
    } on Object catch (e) {
      debugPrint('trip sync failed: ${e.runtimeType}');
    }
  }

  /// Commands from Kotlin: `toggle` (tile / widget tap), `expire` (the alarm), `picker` (the tile's long-press while
  /// the app runs).
  void onCommand(void Function(String) f) {
    if (!_android) return;
    _ch.setMethodCallHandler((call) async => f(call.method));
  }

  /// The app was opened by the tile's long-press (or a tap that could not run without a screen): show the presets.
  /// Asked once at start; true only once.
  Future<bool> takePicker() async {
    if (!_android) return false;
    try {
      return await _ch.invokeMethod<bool>('takePicker') ?? false;
    } on Object {
      return false;
    }
  }
}

final tripChannelProvider = Provider<TripChannel>((_) => TripChannel());
