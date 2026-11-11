import 'package:dio/dio.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/bag/data/bag_repository.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_adapter.dart';
import '../../../helpers/fakes.dart';

Response<dynamic> res(int status, [Object? data]) =>
    Response(requestOptions: RequestOptions(), statusCode: status, data: data);

/// Answers in order; the last one repeats.
({List<String> calls, Future<Response<dynamic>?> Function(String) get}) fake(
  List<Response<dynamic>> replies,
) {
  final calls = <String>[];
  return (
    calls: calls,
    get: (p) async {
      calls.add(p);
      return replies.length > 1 ? replies.removeAt(0) : replies.first;
    },
  );
}

void main() {
  group('waitForReceipt', () {
    test(
      'waits while the picture is processed, then returns the receipt',
      () async {
        final f = fake([
          res(409),
          res(409),
          res(200, {'receipt': 'R'}),
        ]);
        var waits = 0;
        expect(
          await waitForReceipt(
            'm1',
            f.get,
            delay: Duration.zero,
            onWait: () => waits++,
          ),
          'R',
        );
        expect(f.calls, List.filled(3, '/card-media/m1/receipt'));
        expect(waits, 1); // said once, on the first 409
      },
    );

    test('ready at once: never says it is processing', () async {
      var waits = 0;
      await waitForReceipt(
        'm1',
        fake([
          res(200, {'receipt': 'R'}),
        ]).get,
        delay: Duration.zero,
        onWait: () => waits++,
      );
      expect(waits, 0);
    });

    test('a picture Look Back could not process: failed', () async {
      await expectLater(
        waitForReceipt('m1', fake([res(422)]).get, delay: Duration.zero),
        throwsA(const CardError('failed')),
      );
    });

    test('still processing after every try: timeout', () async {
      final f = fake([res(409)]);
      await expectLater(
        waitForReceipt('m1', f.get, tries: 3, delay: Duration.zero),
        throwsA(const CardError('timeout')),
      );
      expect(f.calls, hasLength(3));
    });
  });

  test(
    'freshReceipts asks again for every new picture, never for saved ones',
    () async {
      final asked = <String>[];
      final out = await freshReceipts(
        [
          const BagItem(type: ItemType.qr, media: 'old'),
          const BagItem(type: ItemType.photo, media: 'new', receipt: 'stale'),
          null,
          const BagItem(type: ItemType.note, value: 'x'),
        ],
        {'old'},
        (id) async {
          asked.add(id);
          return 'R-$id';
        },
      );
      expect(asked, ['new']);
      expect([for (final s in out) s?.receipt], [null, 'R-new', null, null]);
    },
  );

  test('cardErrorText: a picture that cannot be used says to pick another', () {
    expect(
      cardErrorText(const CardError('failed')),
      'Ảnh này không dùng được, thử ảnh khác nhé.',
    );
    expect(
      cardErrorText(const CardError('timeout')),
      'Ảnh xử lý lâu quá, thử lại sau chút nhé.',
    );
    expect(
      cardErrorText(const CardError('Ảnh này lớn quá, tối đa 20 MB nhé.')),
      'Ảnh này lớn quá, tối đa 20 MB nhé.',
    );
    expect(cardErrorText(Exception('x')), 'Chưa lưu được ảnh, thử lại nhé ✨');
  });

  group('the API', () {
    late FakeAdapter adapter;
    BagRepository repo() {
      final api = ApiClient(testConfig, () async => 't', dio: fakeDio(adapter));
      return BagRepository(api, PinsRepository(testConfig, api));
    }

    test('each call: method, URL and body; slots always 8', () async {
      adapter = FakeAdapter(
        (r) => (
          status: 200,
          body: r.uri.path.endsWith('/avatar')
              ? {'avatar': 'AV'}
              : {
                  'slots': [
                    {'type': 'phone', 'value': '1'},
                  ],
                },
        ),
      );
      final r = repo();
      expect((await r.myBag()).first?.value, '1');
      expect(await r.friendBag('a b'), hasLength(8));
      await r.saveMyBag([
        const BagItem(type: ItemType.qr, media: 'm', receipt: 'R'),
        null,
      ]);
      expect(await r.setAvatar('R'), 'AV');
      await r.setAvatar(null);
      expect(adapter.calls, [
        'GET https://api.test/me/bag',
        'GET https://api.test/friends/a%20b/bag',
        'PUT https://api.test/me/bag',
        'PUT https://api.test/me/avatar',
        'PUT https://api.test/me/avatar',
      ]);
      expect(sentBody(adapter.requests[2]), {
        'slots': [
          {'type': 'qr', 'media': 'm', 'receipt': 'R'},
          null,
        ],
      });
      expect(sentBody(adapter.requests[3]), {'receipt': 'R'});
      expect(sentBody(adapter.requests[4]), {'clear': true});
    });

    test('a refused bag says why', () async {
      adapter = FakeAdapter((_) => (status: 400, body: {'error': 'twice'}));
      await expectLater(
        repo().saveMyBag(const []),
        throwsA(isA<FriendError>().having((e) => e.code, 'code', 'twice')),
      );
      adapter = FakeAdapter((_) => (status: 401, body: null));
      await expectLater(repo().myBag(), throwsA(isA<AuthExpired>()));
    });
  });
}
