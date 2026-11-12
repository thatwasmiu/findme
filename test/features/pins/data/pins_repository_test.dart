import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/bag/data/bag_repository.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

const _lb = 'https://findme.test/lb/api/findme';
const _pins = '$_lb/pins';
const _ticket = 'https://api.test/media-ticket';
const _session = '$_lb/session';
const _upload = '$_lb/uploads';
const _uploadUrl = '$_upload/u1';

/// One canned answer, with headers.
typedef R = ({int status, Object? body, Map<String, String> headers});

R reply(int status, [Object? body, Map<String, String> headers = const {}]) =>
    (status: status, body: body, headers: headers);

final R cookieOk = reply(204, null, {
  'set-cookie': 'fm_user=abc.def; Max-Age=43200; Path=/lb; HttpOnly',
});

/// Answers by `METHOD url`, each list in order (the last repeats). Throwing = offline.
class Server implements HttpClientAdapter {
  Server(this.routes);

  final Map<String, List<R Function()>> routes;
  final requests = <RequestOptions>[];
  final bodies = <String>[];

  int count(String key) => calls.where((c) => c == key).length;
  List<String> get calls => [for (final r in requests) '${r.method} ${r.uri}'];
  RequestOptions first(String key) =>
      requests.firstWhere((r) => '${r.method} ${r.uri}' == key);

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<List<int>>? body,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    bodies.add(
      body == null ? '' : utf8.decode(await body.expand((c) => c).toList()),
    );
    final key = '${o.method} ${o.uri}';
    final list = routes[key];
    if (list == null) throw StateError('unexpected $key');
    final r = (list.length > 1 ? list.removeAt(0) : list.first)();
    return ResponseBody.fromString(
      r.body == null ? '' : jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        for (final e in r.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Never down() => throw DioException.connectionError(
  requestOptions: RequestOptions(),
  reason: 'offline',
);

({PinsRepository repo, Server s}) make(
  Map<String, List<R Function()>> routes, {
  String? token = 't',
  DateTime Function()? now,
}) {
  final s = Server(routes);
  final dio = Dio()..httpClientAdapter = s;
  final api = ApiClient(testConfig, () async => token, dio: dio);
  return (
    repo: PinsRepository(
      testConfig,
      api,
      dio: dio,
      now: now ?? DateTime.now,
      retryDelays: const [Duration.zero, Duration.zero],
    ),
    s: s,
  );
}

Map<String, List<R Function()>> ticketOk() => {
  'POST $_ticket': [
    () => reply(200, {'ticket': 'tk'}),
  ],
  'POST $_session': [() => cookieOk],
};

const Map<String, Object> _onePin = {
  'id': 'a',
  'lat': 1.0,
  'lon': 2.0,
  'createdAt': 'T',
  'media': <Object>[],
};

void main() {
  group('openPins', () {
    test('trades the login for a cookie first, then reads with it', () async {
      final m = make({
        ...ticketOk(),
        'GET $_pins': [
          () => reply(200, [_onePin]),
        ],
      });
      expect((await m.repo.openPins())!.single.id, 'a');
      expect(m.s.calls, ['POST $_ticket', 'POST $_session', 'GET $_pins']);
      expect(m.s.bodies[1], jsonEncode({'ticket': 'tk'}));
      expect(m.s.first('GET $_pins').headers['Cookie'], 'fm_user=abc.def');
      expect(m.repo.mediaHeaders, {'Cookie': 'fm_user=abc.def'});
    });

    test('a fresh session is not exchanged again', () async {
      final m = make({
        ...ticketOk(),
        'GET $_pins': [() => reply(200, <Object>[])],
      });
      await m.repo.openPins();
      await m.repo.openPins();
      expect(m.s.count('POST $_ticket'), 1);
    });

    test('after 6 hours it is exchanged again', () async {
      var t = DateTime(2026, 11, 10);
      final m = make({
        ...ticketOk(),
        'GET $_pins': [() => reply(200, <Object>[])],
      }, now: () => t);
      await m.repo.openPins();
      t = t.add(const Duration(hours: 7));
      await m.repo.openPins();
      expect(m.s.count('POST $_ticket'), 2);
    });

    test(
      'no ticket (403, admin login): no pins, no read, no sign-out',
      () async {
        final m = make({
          'POST $_ticket': [
            () => reply(403, {'error': 'account'}),
          ],
        });
        expect(await m.repo.openPins(), isNull);
        expect(m.s.count('GET $_pins'), 0);
      },
    );

    test('signed out: no calls', () async {
      final m = make({}, token: null);
      expect(await m.repo.openPins(), isNull);
      expect(m.s.calls, isEmpty);
    });

    test('Look Back refusing the ticket or sending no cookie: null', () async {
      final refused = make({
        'POST $_ticket': [
          () => reply(200, {'ticket': 'tk'}),
        ],
        'POST $_session': [
          () => reply(401, {'error': 'ticket'}),
        ],
      });
      expect(await refused.repo.openPins(), isNull);
      final noCookie = make({
        'POST $_ticket': [
          () => reply(200, {'ticket': 'tk'}),
        ],
        'POST $_session': [() => reply(204)],
      });
      expect(await noCookie.repo.openPins(), isNull);
    });

    test(
      'null (not an empty list) on a 500 or when Look Back is down',
      () async {
        final bad = make({
          ...ticketOk(),
          'GET $_pins': [() => reply(500)],
        });
        expect(await bad.repo.openPins(), isNull);
        final away = make({
          ...ticketOk(),
          'GET $_pins': [down],
        });
        expect(await away.repo.openPins(), isNull);
      },
    );

    test(
      're-exchanges once on 401, then retries; stops after a second',
      () async {
        final once = make({
          ...ticketOk(),
          'GET $_pins': [
            () => reply(401),
            () => reply(200, [_onePin]),
          ],
        });
        expect(await once.repo.openPins(), hasLength(1));
        expect(once.s.count('POST $_ticket'), 2);
        final twice = make({
          ...ticketOk(),
          'GET $_pins': [() => reply(401)],
        });
        expect(await twice.repo.openPins(), isNull);
        expect(twice.s.count('GET $_pins'), 2);
      },
    );
  });

  test('create, delete: method, URL and body', () async {
    final m = make({
      'POST $_pins': [() => reply(201, _onePin)],
      'DELETE $_pins/a': [() => reply(204)],
    });
    final p = await m.repo.createPin((lat: 1, lon: 2, name: 'x', note: null));
    expect(p.id, 'a');
    await m.repo.deletePin('a');
    expect(jsonDecode(m.s.bodies.first), {'lat': 1, 'lon': 2, 'name': 'x'});
    expect(
      m.repo.mediaUrl('i/t.webp'),
      'https://findme.test/lb/media/i/t.webp',
    );
  });

  test('a refused call throws', () async {
    final m = make({
      'DELETE $_pins/a': [() => reply(500)],
    });
    await expectLater(m.repo.deletePin('a'), throwsA(anything));
  });

  test('uploadMessage says something different for each refusal', () {
    final texts = [
      uploadMessage(413, 'too-big'),
      uploadMessage(413, 'quota'),
      uploadMessage(413, 'full'),
      uploadMessage(400, 'type'),
      uploadMessage(500, null),
      uploadMessage(null, null),
    ];
    expect(texts.toSet(), hasLength(texts.length));
  });

  test('PinFile.type comes from the extension', () {
    expect(const PinFile('p', 'A.JPG').type, 'image/jpeg');
    expect(const PinFile('p', 'v.mov').type, 'video/quicktime');
    expect(const PinFile('p', 'x.heic').type, 'application/octet-stream');
  });

  group('uploads', () {
    late Directory dir;
    late PinFile file;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('pins');
      final f = File('${dir.path}/a.jpg')..writeAsStringSync('hello');
      file = PinFile(f.path, 'a.jpg');
    });
    tearDown(() => dir.deleteSync(recursive: true));

    R created() => reply(201, null, {'location': '/lb/api/findme/uploads/u1'});
    R Function() moved(int to) =>
        () => reply(204, null, {'upload-offset': '$to'});

    test('tus: creates with base64 metadata, sends the bytes', () async {
      final m = make({
        'POST $_upload': [created],
        'PATCH $_uploadUrl': [moved(5)],
      });
      final seen = <double>[];
      await m.repo.uploadFile('p1', file, seen.add);
      final post = m.s.first('POST $_upload');
      expect(post.headers['Tus-Resumable'], '1.0.0');
      expect(post.headers['Upload-Length'], '5');
      final meta = {
        for (final kv in (post.headers['Upload-Metadata'] as String).split(','))
          kv.split(' ')[0]: utf8.decode(base64.decode(kv.split(' ')[1])),
      };
      expect(meta, {
        'pinId': 'p1',
        'filename': 'a.jpg',
        'filetype': 'image/jpeg',
      });
      final patch = m.s.first('PATCH $_uploadUrl');
      expect(patch.headers['Upload-Offset'], '0');
      expect(patch.contentType, 'application/offset+octet-stream');
      expect(m.s.bodies.last, 'hello');
      expect(seen.last, 1);
    });

    test(
      'bag pictures: an album, the role, a receipt; too big says 20 MB',
      () async {
        final m = make({
          ...ticketOk(),
          'POST $_lb/card-album': [
            () => reply(201, {'album': 'A'}),
          ],
          'POST $_upload': [created],
          'PATCH $_uploadUrl': [moved(5)],
          'GET $_lb/card-media/u1/receipt': [
            () => reply(200, {'receipt': 'R'}),
          ],
        });
        final bag = BagRepository(
          ApiClient(testConfig, () async => 't'),
          m.repo,
        );
        final r = await bag.uploadCard(file, 'bag', (_) {});
        expect((r.media, r.receipt), ('u1', 'R'));
        final meta =
            (m.s.first('POST $_upload').headers['Upload-Metadata'] as String)
                .split(',')
                .map((kv) => utf8.decode(base64.decode(kv.split(' ')[1])))
                .toList();
        expect(meta.take(2), ['A', 'bag']);

        final big = make({
          ...ticketOk(),
          'POST $_lb/card-album': [
            () => reply(201, {'album': 'A'}),
          ],
          'POST $_upload': [
            () => reply(413, {'error': 'too-big'}),
          ],
        });
        await expectLater(
          BagRepository(
            ApiClient(testConfig, () async => 't'),
            big.repo,
          ).uploadCard(file, 'bag', (_) {}),
          throwsA(const CardError('Ảnh này lớn quá, tối đa 20 MB nhé.')),
        );
      },
    );

    test('a dropped chunk asks how far it got and sends the rest', () async {
      final m = make({
        'POST $_upload': [created],
        'PATCH $_uploadUrl': [down, moved(5)],
        'HEAD $_uploadUrl': [
          () => reply(200, null, {'upload-offset': '2'}),
        ],
      });
      await m.repo.uploadFile('p1', file, (_) {});
      expect(m.s.bodies.last, 'llo');
      expect(m.s.requests.last.headers['Upload-Offset'], '2');
    });

    test('offline for good gives up with the connection message', () async {
      final m = make({
        'POST $_upload': [down],
      });
      await expectLater(
        m.repo.uploadFile('p1', file, (_) {}),
        throwsA(
          isA<PinUploadFailed>().having(
            (e) => e.message,
            'message',
            uploadMessage(null, null),
          ),
        ),
      );
      expect(m.s.count('POST $_upload'), 3);
    });

    test('a refusal is not retried and says why', () async {
      final m = make({
        'POST $_upload': [
          () => reply(413, {'error': 'quota'}),
        ],
      });
      await expectLater(
        m.repo.uploadFile('p1', file, (_) {}),
        throwsA(
          isA<PinUploadFailed>().having(
            (e) => e.message,
            'message',
            uploadMessage(413, 'quota'),
          ),
        ),
      );
      expect(m.s.count('POST $_upload'), 1);
    });

    test('progress runs over all the files', () async {
      final m = make({
        'POST $_upload': [created],
        'PATCH $_uploadUrl': [moved(5)],
      });
      final seen = <double>[];
      await m.repo.uploadAll('p1', [file, file], seen.add);
      expect(seen.last, 1);
      expect(seen, contains(0.5));
    });

    Map<String, List<R Function()>> withPin(List<R Function()> post) => {
      'POST $_pins': [() => reply(201, _onePin)],
      'POST $_upload': post,
      'PATCH $_uploadUrl': [moved(5)],
      'DELETE $_pins/a': [() => reply(204)],
    };

    const input = (lat: 1.0, lon: 2.0, name: null, note: null);

    test('addFiles deletes the pin when every upload fails', () async {
      final m = make(
        withPin([
          () => reply(413, {'error': 'quota'}),
        ]),
      );
      final r = await m.repo.addFiles(input, [file], (_) {});
      expect(r.pin, isNull);
      expect(r.failed, 1);
      expect(r.message, uploadMessage(413, 'quota'));
      expect(m.s.count('DELETE $_pins/a'), 1);
    });

    test('addFiles keeps it when one succeeds', () async {
      final m = make(
        withPin([
          () => reply(400, {'error': 'type'}),
          created,
        ]),
      );
      final r = await m.repo.addFiles(input, [file, file], (_) {});
      expect(r.pin?.id, 'a');
      expect(r.failed, 1);
      expect(m.s.count('DELETE $_pins/a'), 0);
    });
  });

  group('setShared', () {
    test('sends PUT with {"shared":true}', () async {
      final m = make({
        'PUT $_lb/media/m1/shared': [() => reply(204)],
      });
      await m.repo.setShared('m1', shared: true);
      expect(jsonDecode(m.s.bodies.single), {'shared': true});
    });

    test('a 404 throws', () async {
      final m = make({
        'PUT $_lb/media/m1/shared': [() => reply(404)],
      });
      await expectLater(
        m.repo.setShared('m1', shared: false),
        throwsA(isA<HttpError>()),
      );
    });
  });

  group('placeName', () {
    const url = 'https://api.test/place-name?lat=10.5&lon=106.25';

    test('asks again while pending', () async {
      final waits = <Duration>[];
      final m = make({
        'GET $url': [
          () => reply(200, {'name': null, 'pending': true}),
          () => reply(200, {'name': null, 'pending': true}),
          () => reply(200, {'name': 'Hồ Gươm', 'pending': false}),
        ],
      });
      final name = await m.repo.placeName(
        10.5,
        106.25,
        wait: (d) async => waits.add(d),
      );
      expect(name, 'Hồ Gươm');
      expect(m.s.count('GET $url'), 3);
      expect(waits, [const Duration(seconds: 3), const Duration(seconds: 3)]);
    });

    test('stops after 4 tries', () async {
      final m = make({
        'GET $url': [
          () => reply(200, {'name': null, 'pending': true}),
        ],
      });
      expect(await m.repo.placeName(10.5, 106.25, wait: (_) async {}), '');
      expect(m.s.count('GET $url'), 4);
    });

    test('gives up quietly', () async {
      final bad = make({
        'GET $url': [() => reply(500)],
      });
      expect(await bad.repo.placeName(10.5, 106.25, wait: (_) async {}), '');
      final off = make({
        'GET $url': [down],
      });
      expect(await off.repo.placeName(10.5, 106.25, wait: (_) async {}), '');
    });
  });

  group('shared pins of friends', () {
    const grant = 'https://api.test/pin-grant';
    const shared = '$_lb/shared/session';

    test('pinGrant: no friends is null', () async {
      final none = make({
        'POST $grant': [
          () => reply(200, {'grant': null, 'exp': null}),
        ],
      });
      expect(await none.repo.pinGrant(), isNull);
      final some = make({
        'POST $grant': [
          () => reply(200, {'grant': 'g', 'exp': 9}),
        ],
      });
      expect(await some.repo.pinGrant(), (grant: 'g', exp: 9));
      final off = make({
        'POST $grant': [down],
      });
      expect(await off.repo.pinGrant(), isNull);
    });

    test('loadSharedPins keeps the friends cookie beside your own', () async {
      final m = make({
        ...ticketOk(),
        'GET $_pins': [() => reply(200, <Object>[])],
        'POST $shared': [
          () => reply(
            200,
            [
              {..._onePin, 'sub': 'f1'},
            ],
            {'set-cookie': 'fm_shared_friends=g1; Max-Age=900; Path=/lb'},
          ),
        ],
      });
      await m.repo.openPins();
      final got = await m.repo.loadSharedPins('g');
      expect(got.single.sub, 'f1');
      expect(jsonDecode(m.s.bodies.last), {'grant': 'g'});
      final cookie = m.repo.mediaHeaders['Cookie']!;
      expect(cookie, contains('fm_user=abc.def'));
      expect(cookie, contains('fm_shared_friends=g1'));
    });

    test('loadSharedPins: a failure is empty', () async {
      final refused = make({
        'POST $shared': [() => reply(403)],
      });
      expect(await refused.repo.loadSharedPins('g'), isEmpty);
      final off = make({
        'POST $shared': [down],
      });
      expect(await off.repo.loadSharedPins('g'), isEmpty);
    });
  });
}
