import 'dart:async';

import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/add_pin_sheet.dart';
import 'package:findme/features/pins/presentation/pin_sheet.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/map_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' show LocationPermission;
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

const ready = PinMedia(
  id: 'm1',
  kind: 'image',
  status: 'ready',
  thumb: 't.webp',
  display: 'd.webp',
);
const waiting = PinMedia(id: 'm2', kind: 'video', status: 'processing');

Pin pin({String id = 'a', String? sub, List<PinMedia>? media}) => Pin(
  id: id,
  lat: 21.0285, // where the map opens
  lon: 105.8542,
  name: 'Hồ Gươm',
  createdAt: '2026-11-10T05:00:00.000Z',
  sub: sub,
  media: media ?? const [ready],
);

class FakePicker implements PinPicker {
  List<PinFile> next = const [PinFile('p', 'a.jpg')];
  final used = <String>[];
  @override
  Future<List<PinFile>> photo() async {
    used.add('photo');
    return next;
  }

  @override
  Future<PinFile?> image({double? maxSide}) async => next.firstOrNull;
}

class FakeGeo implements GeoApi {
  FakeGeo({
    this.service = true,
    this.permission = LocationPermission.whileInUse,
    this.at,
    this.error = false,
  });

  final bool service;
  final LocationPermission permission;

  /// null and no error: never answers.
  final Spot? at;
  final bool error;
  int asked = 0;

  @override
  Future<bool> serviceOn() async => service;
  @override
  Future<LocationPermission> permissionNow() async => permission;
  @override
  Future<LocationPermission> askPermission() async {
    asked++;
    return permission;
  }

  @override
  Future<Spot> position() {
    if (error) return Future.error(Exception('gps'));
    return at == null ? Completer<Spot>().future : Future.value(at);
  }
}

class FakeSignedIn extends AuthController {
  @override
  AuthPhase build() => AuthPhase.signedIn;
  void leave() => state = AuthPhase.signedOut;
}

const PinInput _input = (lat: 0.0, lon: 0.0, name: null, note: null);

Widget host(Widget child, MockPins pins, {List<Override> more = const []}) =>
    ProviderScope(
      overrides: [
        ...baseOverrides(auth: fakeAuth(), pins: pins),
        ...more,
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_input);
    registerFallbackValue(const <PinFile>[]);
  });

  group('PinsController', () {
    ProviderContainer container(MockPins pins) {
      final c = ProviderContainer(
        overrides: [
          ...baseOverrides(auth: fakeAuth(), pins: pins),
          authControllerProvider.overrideWith(FakeSignedIn.new),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('a failed read keeps the bubbles', () async {
      final pins = quietPins();
      when(pins.openPins).thenAnswer((_) async => [pin()]);
      final c = container(pins);
      c.read(pinsControllerProvider);
      await c.read(pinsControllerProvider.notifier).refresh();
      expect(c.read(pinsControllerProvider), hasLength(1));
      when(pins.openPins).thenAnswer((_) async => null);
      await c.read(pinsControllerProvider.notifier).refresh();
      expect(c.read(pinsControllerProvider), hasLength(1));
    });

    test('signing out empties them, and a late read cannot refill', () async {
      final pins = quietPins();
      final gate = Completer<List<Pin>?>();
      when(pins.openPins).thenAnswer((_) => gate.future);
      final c = container(pins);
      final sub = c.listen(pinsControllerProvider, (_, _) {});
      addTearDown(sub.close);
      await Future<void>.delayed(Duration.zero);
      (c.read(authControllerProvider.notifier) as FakeSignedIn).leave();
      await Future<void>.delayed(Duration.zero);
      gate.complete([pin()]);
      await Future<void>.delayed(Duration.zero);
      expect(c.read(pinsControllerProvider), isEmpty);
    });
  });

  group('bubbles on the map', () {
    testWidgets('one pin opens; two together show the count', (t) async {
      Pin? opened;
      await t.pumpWidget(
        host(
          MapView(
            points: const [],
            stops: const [],
            showTiles: false,
            pins: [pin()],
            onPin: (p) => opened = p,
          ),
          quietPins(),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.bySemanticsLabel('Xem ảnh'));
      expect(opened?.id, 'a');

      await t.pumpWidget(
        host(
          MapView(
            points: const [],
            stops: const [],
            showTiles: false,
            pins: [
              pin(),
              pin(id: 'b'),
            ],
          ),
          quietPins(),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });
  });

  group('AddPinSheet', () {
    late FakePicker picker;
    const stop = Stop(
      name: 'Hồ Gươm',
      lat: 21.03,
      lon: 105.78,
      start: 'S',
      end: 'E',
      seconds: 60,
    );
    const atStop = FixOk(21.03, 105.78);
    const farAway = FixOk(10.77, 106.70);

    setUp(() => picker = FakePicker());

    Widget sheet(
      MockPins pins, {
      required List<Fix> fixes,
      VoidCallback? onAdded,
      void Function(double, double)? onSpot,
    }) => host(
      AddPinSheet(
        stops: const [stop],
        onSpot: onSpot ?? (_, _) {},
        onAdded: onAdded ?? () {},
        onClose: () {},
      ),
      pins,
      more: [
        pinPickerProvider.overrideWithValue(picker),
        pinFixProvider.overrideWithValue(() async => fixes.removeAt(0)),
      ],
    );

    String nameText(WidgetTester t) =>
        t.widget<TextField>(find.byKey(const Key('pinName'))).controller!.text;

    testWidgets('denied: says why, no camera, no pin', (t) async {
      tallView(t);
      final pins = quietPins();
      await t.pumpWidget(sheet(pins, fixes: [const FixDenied()]));
      await t.pump();
      expect(find.textContaining('Cần quyền vị trí'), findsOneWidget);
      expect(find.text('📷 Chụp ảnh'), findsNothing);
      verifyNever(() => pins.addFiles(any(), any(), any()));
    });

    testWidgets('failed: retry asks again', (t) async {
      tallView(t);
      final spots = <(double, double)>[];
      await t.pumpWidget(
        sheet(
          quietPins(),
          fixes: [const FixFailed('silent'), atStop],
          onSpot: (lat, lon) => spots.add((lat, lon)),
        ),
      );
      await t.pump();
      expect(
        find.text('Chưa lấy được vị trí, thử lại nhé (silent)'),
        findsOneWidget,
      );
      expect(find.text('📷 Chụp ảnh'), findsNothing);
      await t.tap(find.text('Thử lại'));
      await t.pump();
      expect(spots, [(21.03, 105.78)]);
      expect(find.text('📷 Chụp ảnh'), findsOneWidget);
    });

    testWidgets('near a stop: named from it, no /place-name', (t) async {
      tallView(t);
      final pins = quietPins();
      await t.pumpWidget(sheet(pins, fixes: [atStop]));
      await t.pump();
      expect(nameText(t), 'Hồ Gươm');
      verifyNever(() => pins.placeName(any(), any()));
    });

    testWidgets('no stop near: named from /place-name', (t) async {
      tallView(t);
      final pins = quietPins();
      when(() => pins.placeName(10.77, 106.70))
          .thenAnswer((_) async => 'Chợ Bến Thành');
      await t.pumpWidget(sheet(pins, fixes: [farAway]));
      await t.pump();
      await t.pump();
      expect(nameText(t), 'Chợ Bến Thành');
    });

    testWidgets('a typed name beats a late place name and is sent', (t) async {
      tallView(t);
      final pins = quietPins();
      final late = Completer<String>();
      when(() => pins.placeName(any(), any())).thenAnswer((_) => late.future);
      when(() => pins.addFiles(any(), any(), any()))
          .thenAnswer((_) async => (pin: pin(), failed: 0, message: ''));
      await t.pumpWidget(sheet(pins, fixes: [farAway]));
      await t.pump();
      await t.enterText(find.byKey(const Key('pinName')), 'Nhà');
      late.complete('Chợ Bến Thành');
      await t.pump();
      expect(nameText(t), 'Nhà');
      await t.tap(find.text('📷 Chụp ảnh'));
      await t.pump();
      final sent =
          verify(() => pins.addFiles(captureAny(), any(), any()))
                  .captured
                  .single
              as PinInput;
      expect((sent.name, sent.lat, sent.lon), ('Nhà', 10.77, 106.70));
    });

    testWidgets('camera only: no video, no gallery', (t) async {
      tallView(t);
      await t.pumpWidget(sheet(quietPins(), fixes: [atStop]));
      await t.pump();
      expect(find.text('Chụp ảnh ở đây'), findsOneWidget);
      expect(find.text('🎥 Quay video'), findsNothing);
      expect(find.text('🖼️ Chọn từ máy'), findsNothing);
    });

    testWidgets('picking nothing uploads nothing', (t) async {
      tallView(t);
      final pins = quietPins();
      picker.next = const [];
      await t.pumpWidget(sheet(pins, fixes: [atStop]));
      await t.pump();
      await t.tap(find.text('📷 Chụp ảnh'));
      await t.pump();
      verifyNever(() => pins.addFiles(any(), any(), any()));
    });

    testWidgets('all failed: tells why and stays open', (t) async {
      tallView(t);
      final pins = quietPins();
      when(() => pins.addFiles(any(), any(), any()))
          .thenAnswer((_) async => (pin: null, failed: 1, message: 'Đầy rồi'));
      var added = 0;
      await t.pumpWidget(sheet(pins, fixes: [atStop], onAdded: () => added++));
      await t.pump();
      await t.tap(find.text('📷 Chụp ảnh'));
      await t.pump();
      await t.pump();
      expect(find.text('Đầy rồi'), findsOneWidget);
      expect(added, 0);
    });
  });

  group('where you are', () {
    test('geoMessage says why', () {
      expect(
        geoMessage(const FixDenied()),
        'Cần quyền vị trí để ghim ảnh ở đây. Bật trong Cài đặt › Find Me › Vị trí nhé.',
      );
      expect(
        geoMessage(const FixFailed('off')),
        'Chưa lấy được vị trí, thử lại nhé (off)',
      );
      expect(geoMessage(const FixOk(1, 2)), isNull);
    });

    test('location service off is a failure, not a denial', () async {
      final f = await currentFix(FakeGeo(service: false));
      expect(f, isA<FixFailed>().having((f) => f.reason, 'reason', 'off'));
    });

    test('refused after asking is denied', () async {
      final geo = FakeGeo(permission: LocationPermission.denied);
      expect(await currentFix(geo), isA<FixDenied>());
      expect(geo.asked, 1);
      expect(
        await currentFix(FakeGeo(permission: LocationPermission.deniedForever)),
        isA<FixDenied>(),
      );
    });

    test('a position is ok; an error or silence fails', () async {
      final ok = await currentFix(FakeGeo(at: (lat: 1, lon: 2)));
      expect(ok, isA<FixOk>().having((f) => (f.lat, f.lon), 'at', (1.0, 2.0)));
      expect(
        await currentFix(FakeGeo(error: true)),
        isA<FixFailed>().having((f) => f.reason, 'reason', 'error'),
      );
      expect(
        await currentFix(FakeGeo(), deadline: Duration.zero),
        isA<FixFailed>().having((f) => f.reason, 'reason', 'silent'),
      );
    });
  });

  group('PinSheet', () {
    Widget sheet(
      Pin p,
      MockPins pins, {
      String? by,
      VoidCallback? onClose,
      List<Override> more = const [],
    }) => host(
      PinSheet(pin: p, by: by, onClose: onClose ?? () {}),
      pins,
      more: more,
    );

    testWidgets('own photo: the switch flips and calls setShared', (t) async {
      tallView(t);
      final pins = quietPins();
      when(() => pins.setShared('m1', shared: true)).thenAnswer((_) async {});
      await t.pumpWidget(sheet(pin(), pins));
      await t.pump();
      expect(
        find.text('Ảnh bật Chia sẻ: bạn bè và link có “Ảnh” đều thấy.'),
        findsOneWidget,
      );
      final sw = find.bySemanticsLabel('Chia sẻ');
      expect(t.widget<Switch>(find.byType(Switch)).value, isFalse);
      await t.tap(sw);
      await t.pump();
      verify(() => pins.setShared('m1', shared: true)).called(1);
      expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);
    });

    testWidgets('a refused flip goes back and says so', (t) async {
      tallView(t);
      final pins = quietPins();
      when(() => pins.setShared(any(), shared: any(named: 'shared')))
          .thenThrow(Exception('x'));
      await t.pumpWidget(sheet(pin(), pins));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Chia sẻ'));
      await t.pump();
      expect(t.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(
        find.text('Chưa làm được, thử lại sau chút nhé ✨'),
        findsOneWidget,
      );
    });

    testWidgets('videos get no switch', (t) async {
      tallView(t);
      const video = PinMedia(
        id: 'v',
        kind: 'video',
        status: 'ready',
        thumb: 't',
      );
      await t.pumpWidget(sheet(pin(media: [video]), quietPins()));
      await t.pump();
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets("a friend's pin is look-only", (t) async {
      tallView(t);
      await t.pumpWidget(sheet(pin(sub: 'f1'), quietPins(), by: 'Mai'));
      await t.pump();
      expect(find.textContaining('Ảnh của Mai · '), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.bySemanticsLabel('Chụp thêm ảnh'), findsNothing);
      expect(find.text('🗑️ Xoá'), findsNothing);
    });

    testWidgets('add more uses the camera', (t) async {
      tallView(t);
      final pins = quietPins();
      when(() => pins.uploadAll(any(), any(), any()))
          .thenAnswer((_) async => (failed: 0, message: ''));
      final picker = FakePicker();
      await t.pumpWidget(
        sheet(pin(), pins, more: [pinPickerProvider.overrideWithValue(picker)]),
      );
      await t.pump();
      await t.tap(find.bySemanticsLabel('Chụp thêm ảnh'));
      await t.pump();
      expect(picker.used, ['photo']);
    });

    testWidgets('shows the name, the date and a tile per file', (t) async {
      await t.pumpWidget(sheet(pin(media: [ready, waiting]), quietPins()));
      await t.pump();
      expect(find.text('Hồ Gươm'), findsOneWidget);
      expect(find.textContaining('2 ảnh/video'), findsOneWidget);
      expect(find.bySemanticsLabel('Xem ảnh'), findsOneWidget);
      expect(find.bySemanticsLabel('Xem video'), findsOneWidget);
      expect(find.bySemanticsLabel('Chụp thêm ảnh'), findsOneWidget);
    });

    testWidgets('delete asks first, then closes', (t) async {
      tallView(t); // the switches make the sheet taller than the test screen
      final pins = quietPins();
      when(() => pins.deletePin('a')).thenAnswer((_) async {});
      var closed = 0;
      await t.pumpWidget(sheet(pin(), pins, onClose: () => closed++));
      await t.pump();
      await t.tap(find.text('🗑️ Xoá'));
      await t.pumpAndSettle();
      await t.tap(find.text('Thôi'));
      await t.pumpAndSettle();
      verifyNever(() => pins.deletePin(any()));
      await t.tap(find.text('🗑️ Xoá'));
      await t.pumpAndSettle();
      await t.tap(find.text('Xoá'));
      await t.pumpAndSettle();
      verify(() => pins.deletePin('a')).called(1);
      expect(closed, 1);
    });

    testWidgets('a photo opens full screen and closes', (t) async {
      await t.pumpWidget(sheet(pin(), quietPins()));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Xem ảnh'));
      await t.pumpAndSettle();
      expect(find.text('✕'), findsNWidgets(2));
      await t.tap(find.text('✕').last);
      await t.pumpAndSettle();
      expect(find.text('✕'), findsOneWidget);
    });
  });
}
