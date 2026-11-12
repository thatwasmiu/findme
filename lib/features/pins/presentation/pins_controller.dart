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

/// The few geolocator calls a pin needs; replaceable in tests.
class GeoApi {
  const GeoApi();

  Future<bool> serviceOn() => Geolocator.isLocationServiceEnabled();
  Future<LocationPermission> permissionNow() => Geolocator.checkPermission();
  Future<LocationPermission> askPermission() => Geolocator.requestPermission();
  Future<Spot> position() async {
    final g = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (lat: g.latitude, lon: g.longitude);
  }
}

/// One fresh, precise reading. Always settles: the permission prompt or a silent GPS cannot hold the sheet for
/// longer than [deadline].
Future<Fix> currentFix(
  GeoApi geo, {
  Duration deadline = const Duration(seconds: 20),
}) async {
  Future<Fix> ask() async {
    try {
      if (!await geo.serviceOn()) return const FixFailed('off');
      var p = await geo.permissionNow();
      if (p == LocationPermission.denied) p = await geo.askPermission();
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        return const FixDenied();
      }
      final at = await geo.position();
      return FixOk(at.lat, at.lon);
    } on Object {
      return const FixFailed('error');
    }
  }

  return await ask().timeout(
    deadline,
    onTimeout: () => const FixFailed('silent'),
  );
}

/// Where the phone is now; replaceable in tests.
final pinFixProvider = Provider<Future<Fix> Function()>(
  (_) =>
      () => currentFix(const GeoApi()),
);

/// A pin's photo from the camera, the bag's from the gallery; replaceable in tests.
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
