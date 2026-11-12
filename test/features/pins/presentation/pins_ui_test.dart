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
  @override
  Future<List<PinFile>> photo() async => next;
  @override
  Future<List<PinFile>> video() async => next;
  @override
  Future<List<PinFile>> gallery() async => next;
  @override
  Future<PinFile?> image({double? maxSide}) async => next.firstOrNull;
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
    late ValueNotifier<Spot> center;
    late FakePicker picker;
    const stop = Stop(
      name: 'Hồ Gươm',
      lat: 21.03,
      lon: 105.78,
      start: 'S',
      end: 'E',
      seconds: 60,
    );

    setUp(() {
      center = ValueNotifier((lat: 21.03, lon: 105.78));
      picker = FakePicker();
    });

    Widget sheet(
      MockPins pins, {
      VoidCallback? onAdded,
      void Function(double, double)? onStart,
      Spot? gps,
    }) => host(
      AddPinSheet(
        stops: const [stop],
        last: null,
        center: center,
        onStart: onStart ?? (_, _) {},
        onAdded: onAdded ?? () {},
        onClose: () {},
      ),
      pins,
      more: [
        pinPickerProvider.overrideWithValue(picker),
        pinGpsProvider.overrideWithValue(() async => gps),
      ],
    );

    testWidgets('starts at GPS, names itself from a stop near the map centre', (
      t,
    ) async {
      (double, double)? started;
      await t.pumpWidget(
        sheet(
          quietPins(),
          gps: (lat: 1, lon: 2),
          onStart: (lat, lon) => started = (lat, lon),
        ),
      );
      await t.pump();
      expect(started, (1.0, 2.0));
      final name = t.widget<TextField>(find.byKey(const Key('pinName')));
      expect(name.controller!.text, 'Hồ Gươm');
      center.value = (lat: 22, lon: 106);
      expect(name.controller!.text, '');
    });

    testWidgets('a typed name stays when the map moves, and is what is sent', (
      t,
    ) async {
      final pins = quietPins();
      when(() => pins.addFiles(any(), any(), any()))
          .thenAnswer((_) async => (pin: pin(), failed: 0, message: ''));
      var added = 0;
      await t.pumpWidget(sheet(pins, onAdded: () => added++));
      await t.pump();
      await t.enterText(find.byKey(const Key('pinName')), 'Nhà');
      center.value = (lat: 22, lon: 106);
      await t.tap(find.text('📷 Chụp ảnh'));
      await t.pump();
      expect(added, 1);
      final sent =
          verify(() => pins.addFiles(captureAny(), any(), any()))
                  .captured
                  .single
              as PinInput;
      expect((sent.name, sent.lat, sent.lon), ('Nhà', 22.0, 106.0));
    });

    testWidgets('picking nothing uploads nothing', (t) async {
      tallView(t);
      final pins = quietPins();
      picker.next = const [];
      await t.pumpWidget(sheet(pins));
      await t.pump();
      await t.tap(find.text('🖼️ Chọn từ máy'));
      await t.pump();
      verifyNever(() => pins.addFiles(any(), any(), any()));
    });

    testWidgets('all failed: tells why and stays open', (t) async {
      tallView(t);
      final pins = quietPins();
      when(() => pins.addFiles(any(), any(), any()))
          .thenAnswer((_) async => (pin: null, failed: 1, message: 'Đầy rồi'));
      var added = 0;
      await t.pumpWidget(sheet(pins, onAdded: () => added++));
      await t.pump();
      await t.tap(find.text('🎥 Quay video'));
      await t.pump();
      await t.pump();
      expect(find.text('Đầy rồi'), findsOneWidget);
      expect(added, 0);
    });
  });

  group('PinSheet', () {
    Widget sheet(
      Pin p,
      MockPins pins, {
      VoidCallback? onClose,
      List<Override> more = const [],
    }) => host(
      PinSheet(pin: p, onClose: onClose ?? () {}),
      pins,
      more: more,
    );

    testWidgets('shows the name, the date and a tile per file', (t) async {
      await t.pumpWidget(sheet(pin(media: [ready, waiting]), quietPins()));
      await t.pump();
      expect(find.text('Hồ Gươm'), findsOneWidget);
      expect(find.textContaining('2 ảnh/video'), findsOneWidget);
      expect(find.bySemanticsLabel('Xem ảnh'), findsOneWidget);
      expect(find.bySemanticsLabel('Xem video'), findsOneWidget);
      expect(find.bySemanticsLabel('Thêm ảnh hoặc video'), findsOneWidget);
    });

    testWidgets('delete asks first, then closes', (t) async {
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
