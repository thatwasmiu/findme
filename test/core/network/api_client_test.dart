import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_adapter.dart';

const cfg = AppConfig(
  apiUrl: 'https://api.test/',
  authority: 'https://cognito-idp.ap-southeast-1.amazonaws.com/pool',
  clientId: 'c',
  webOrigin: 'https://findme.test',
);

void main() {
  late FakeAdapter adapter;
  ApiClient client({String? token = 't1'}) =>
      ApiClient(cfg, () async => token, dio: fakeDio(adapter));

  test(
    'sends the bearer token; base URL trailing slash is not doubled',
    () async {
      adapter = FakeAdapter((_) => (status: 200, body: {'ok': true}));
      expect(await client().send('GET', '/me'), {'ok': true});
      expect(adapter.calls, ['GET https://api.test/me']);
      expect(adapter.requests.single.headers['Authorization'], 'Bearer t1');
    },
  );

  test('query parameters and JSON body are sent', () async {
    adapter = FakeAdapter((_) => (status: 201, body: {'id': 'x'}));
    await client().send(
      'POST',
      '/shares',
      body: {'label': 'Mẹ'},
      query: {'a': 'b'},
    );
    final r = adapter.requests.single;
    expect(r.uri.queryParameters, {'a': 'b'});
    expect(sentBody(r), {'label': 'Mẹ'});
  });

  test('401 -> AuthExpired; 403 -> AccountMissing', () async {
    adapter = FakeAdapter((_) => (status: 401, body: null));
    await expectLater(client().send('GET', '/x'), throwsA(isA<AuthExpired>()));
    adapter = FakeAdapter((_) => (status: 403, body: {'error': 'account'}));
    await expectLater(
      client().send('GET', '/x'),
      throwsA(isA<AccountMissing>()),
    );
  });

  test('other non-2xx -> ApiStatus with status and body', () async {
    adapter = FakeAdapter((_) => (status: 400, body: {'error': 'label'}));
    await expectLater(
      client().send('POST', '/shares'),
      throwsA(
        isA<ApiStatus>().having((e) => e.status, 'status', 400).having(
          (e) => e.body,
          'body',
          {'error': 'label'},
        ),
      ),
    );
  });

  test('204 -> null', () async {
    adapter = FakeAdapter((_) => (status: 204, body: null));
    expect(await client().send('DELETE', '/shares/a'), isNull);
  });

  test('offline -> NetworkError', () async {
    adapter = FakeAdapter((r) => throw offline(r));
    await expectLater(client().send('GET', '/x'), throwsA(isA<NetworkError>()));
  });

  test('no token -> AuthExpired and no request', () async {
    adapter = FakeAdapter((_) => (status: 200, body: null));
    await expectLater(
      client(token: null).send('GET', '/x'),
      throwsA(isA<AuthExpired>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('token renewal offline -> NetworkError, not AuthExpired', () async {
    adapter = FakeAdapter((_) => (status: 200, body: null));
    final c = ApiClient(
      cfg,
      () async => throw const NetworkError(),
      dio: fakeDio(adapter),
    );
    await expectLater(c.send('GET', '/x'), throwsA(isA<NetworkError>()));
  });
}
