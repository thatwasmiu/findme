import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/friends/data/friends_repository.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_adapter.dart';

const cfg = AppConfig(
  apiUrl: 'https://api.test/',
  authority: 'https://cognito-idp.x.amazonaws.com/p',
  clientId: 'c',
  webOrigin: 'https://findme.test',
);

void main() {
  late FakeAdapter adapter;
  FriendsRepository repo() =>
      FriendsRepository(ApiClient(cfg, () async => 't', dio: fakeDio(adapter)));

  test(
    'each call: method, URL and bearer; bodies and answers unwrapped',
    () async {
      adapter = FakeAdapter((r) {
        final p = r.uri.path;
        final Object? body = p.endsWith('/me')
            ? {'name': 'Đạt', 'friendCode': 'K7QM-3XPA'}
            : p.endsWith('/live')
            ? {
                'friends': [
                  {'id': 'b', 'lat': 1, 'lon': 2, 'ts': 'T'},
                ],
              }
            : p.endsWith('/today')
            ? {
                'points': [
                  [2, 1, 100, 8],
                ],
                'last': {'lat': 1, 'lon': 2, 'ts': 'T'},
              }
            : p.endsWith('/friends')
            ? {'friends': [], 'incoming': [], 'outgoing': []}
            : p.endsWith('/requests')
            ? {
                'outgoing': {'id': 'b', 'name': 'B', 'at': 'A'},
              }
            : null;
        return (status: body == null ? 204 : 200, body: body);
      });
      final r = repo();
      expect(await r.me(), const Me(name: 'Đạt', friendCode: 'K7QM-3XPA'));
      expect(await r.relations(), Relations.empty);
      final sent = await r.sendRequest('k7qm 3xpa');
      expect(sent.outgoing, const Pending(id: 'b', name: 'B', at: 'A'));
      expect(sent.friend, isNull);
      await r.answer('a b', accept: true);
      await r.remove('b');
      expect(await r.live(), const [
        LivePoint(id: 'b', lat: 1, lon: 2, ts: 'T'),
      ]);
      final today = await r.today('b');
      expect(today.points, const [TrackPoint(2, 1, 100, 8)]);
      expect(today.last, const LastPoint(lon: 2, lat: 1, ts: 'T'));
      expect(adapter.calls, [
        'GET https://api.test/me',
        'GET https://api.test/friends',
        'POST https://api.test/friends/requests',
        'POST https://api.test/friends/requests/a%20b/accept',
        'DELETE https://api.test/friends/b',
        'GET https://api.test/friends/live',
        'GET https://api.test/friends/b/today',
      ]);
      expect(
        adapter.requests.every((q) => q.headers['Authorization'] == 'Bearer t'),
        isTrue,
      );
      expect(sentBody(adapter.requests[2]), {'code': 'k7qm 3xpa'});
    },
  );

  test('401 -> AuthExpired; 403 -> AccountMissing; '
      '400/404/409 -> FriendError(code)', () async {
    adapter = FakeAdapter((_) => (status: 401, body: null));
    await expectLater(repo().relations(), throwsA(isA<AuthExpired>()));
    adapter = FakeAdapter((_) => (status: 403, body: {'error': 'account'}));
    await expectLater(repo().relations(), throwsA(isA<AccountMissing>()));
    for (final (status, code) in [
      (409, 'self'),
      (404, 'code'),
      (400, 'code'),
    ]) {
      adapter = FakeAdapter((_) => (status: status, body: {'error': code}));
      await expectLater(
        repo().sendRequest('x'),
        throwsA(isA<FriendError>().having((e) => e.code, 'code', code)),
      );
    }
    adapter = FakeAdapter((_) => (status: 404, body: null));
    await expectLater(
      repo().remove('x'),
      throwsA(isA<FriendError>().having((e) => e.code, 'code', 'not found')),
    );
  });
}
