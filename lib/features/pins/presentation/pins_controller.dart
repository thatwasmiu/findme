import 'dart:async';

import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

/// While a photo or video is still being processed.
const pinPollMs = 5000;

/// All your pins, whatever the date filter says. A failed read leaves the bubbles where they are.
class PinsController extends Notifier<List<Pin>> {
  int _seq = 0; // a read from before a sign-out must not land after it
  Timer? _poll;
  bool _paused = false;

  @override
  List<Pin> build() {
    final signedIn = ref.watch(signedInProvider);
    ref.onDispose(() => _poll?.cancel());
    _seq++;
    if (signedIn) unawaited(Future.microtask(refresh));
    return const [];
  }

  Future<void> refresh() async {
    final mine = _seq;
    final got = await ref.read(pinsRepositoryProvider).openPins();
    if (mine != _seq || !ref.mounted) return;
    if (got != null) state = got;
    _poll?.cancel();
    if (state.any((p) => p.media.any((m) => m.status == 'processing'))) {
      _poll = Timer(const Duration(milliseconds: pinPollMs), () {
        if (!_paused && ref.mounted) unawaited(refresh());
      });
    }
  }

  /// The app went to the background: stop asking.
  void paused() => _paused = true;

  /// Back in the app: refresh right away.
  void resumed() {
    _paused = false;
    unawaited(refresh());
  }
}

final pinsControllerProvider = NotifierProvider<PinsController, List<Pin>>(
  PinsController.new,
);

/// Where the phone is now; null when refused or unavailable (the sheet still works). Replaceable in tests.
final pinGpsProvider = Provider<Future<Spot?> Function()>(
  (_) => () async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        return null;
      }
      final g = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (lat: g.latitude, lon: g.longitude);
    } on Object {
      return null;
    }
  },
);

/// Camera and gallery; replaceable in tests.
// ponytail: Android may kill the app behind the camera on low memory and that shot is lost; add
// ImagePicker.retrieveLostData if it happens.
class PinPicker {
  const PinPicker();

  static List<PinFile> _files(List<XFile> x) => [
    for (final f in x) PinFile(f.path, f.name),
  ];

  Future<List<PinFile>> photo() async {
    final f = await ImagePicker().pickImage(source: ImageSource.camera);
    return _files([?f]);
  }

  Future<List<PinFile>> video() async {
    final f = await ImagePicker().pickVideo(source: ImageSource.camera);
    return _files([?f]);
  }

  Future<List<PinFile>> gallery() async =>
      _files(await ImagePicker().pickMultipleMedia());

  /// One picture from the gallery (the bag and the avatar), at most [maxSide] pixels across.
  Future<PinFile?> image({double? maxSide}) async {
    final f = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
    );
    return f == null ? null : PinFile(f.path, f.name);
  }
}

final pinPickerProvider = Provider<PinPicker>((_) => const PinPicker());
