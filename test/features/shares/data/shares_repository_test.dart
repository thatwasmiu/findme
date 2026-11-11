import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/shares/data/shares_repository.dart';
import 'package:findme/features/shares/domain/share.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_adapter.dart';

const cfg = AppConfig(
  apiUrl: 'https://api.test',
  authority: 'https://cognito-idp.x.amazonaws.com/p',
  clientId: 'c',
  webOrigin: 'https://findme.test',
);
final shareJson = <String, Object?>{
  'id': 'a' * 22,
  'label': 'Mẹ',
  'createdAt': '2026-10-27T00:00:00.000Z',
  'expiresAt': '2026-10-28T00:00:00.000Z',
  'route': false,
  'routeFrom': null,
};

void main() {
  late FakeAdapter adapter;
  SharesRepository repo() =>
      SharesRepository(ApiClient(cfg, () async => 't', dio: fakeDio(adapter)));

  test('create posts JSON and returns the share', () async {
    adapter = FakeAdapter((_) => (status: 201, body: shareJson));
    final s = await repo().create(
      label: 'Mẹ',
      expiresAt: '2026-10-28T00:00:00.000Z',
    );
    expect(s, Share.fromJson(shareJson));
    expect(adapter.calls, ['POST https://api.test/shares']);
    expect(sentBody(adapter.requests.single), {
      'label': 'Mẹ',
      'expiresAt': '2026-10-28T00:00:00.000Z',
      'route': false,
    });
  });

  test('create with the route sends routeFrom', () async {
    adapter = FakeAdapter((_) => (status: 201, body: shareJson));
    await repo().create(
      label: 'a',
      expiresAt: 'x',
      route: true,
      routeFrom: '2026-10-20',
    );
    expect(sentBody(adapter.requests.single), {
      'label': 'a',
      'expiresAt': 'x',
      'route': true,
      'routeFrom': '2026-10-20',
    });
  });

  test('400 -> ShareInvalid(field); 401 -> AuthExpired', () async {
    adapter = FakeAdapter((_) => (status: 400, body: {'error': 'label'}));
    await expectLater(
      repo().create(label: '', expiresAt: 'x'),
      throwsA(isA<ShareInvalid>().having((e) => e.field, 'field', 'label')),
    );
    adapter = FakeAdapter((_) => (status: 400, body: null));
    await expectLater(
      repo().edit('a', expiresAt: 'x'),
      throwsA(isA<ShareInvalid>().having((e) => e.field, 'field', 'body')),
    );
    adapter = FakeAdapter((_) => (status: 401, body: null));
    await expectLater(repo().list(), throwsA(isA<AuthExpired>()));
  });

  test('list returns the shares', () async {
    adapter = FakeAdapter(
      (_) => (
        status: 200,
        body: {
          'shares': [shareJson],
        },
      ),
    );
    expect(await repo().list(), [Share.fromJson(shareJson)]);
    expect(adapter.calls, ['GET https://api.test/shares']);
  });

  test('edit PATCHes only what changes, id URL-encoded', () async {
    adapter = FakeAdapter((_) => (status: 200, body: shareJson));
    await repo().edit('a b', route: true);
    expect(adapter.calls, ['PATCH https://api.test/shares/a%20b']);
    expect(sentBody(adapter.requests.single), {'route': true});
  });

  test('the bag: sent only when on, read back from the link', () async {
    adapter = FakeAdapter(
      (_) => (status: 200, body: {...shareJson, 'bag': true}),
    );
    final s = await repo().create(label: 'Mẹ', expiresAt: 'x', bag: true);
    expect(s.bag, isTrue);
    expect((sentBody(adapter.requests.single)! as Map)['bag'], true);
    adapter = FakeAdapter((_) => (status: 200, body: shareJson));
    expect((await repo().create(label: 'Mẹ', expiresAt: 'x')).bag, isFalse);
    expect(
      (sentBody(adapter.requests.single)! as Map).containsKey('bag'),
      isFalse,
    );
    await repo().edit('a', bag: false);
    expect(sentBody(adapter.requests.last), {'bag': false});
  });

  test('revoke sends DELETE', () async {
    adapter = FakeAdapter((_) => (status: 204, body: null));
    await repo().revoke('abc_-');
    expect(adapter.calls, ['DELETE https://api.test/shares/abc_-']);
  });
}
