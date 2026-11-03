import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/trail/data/track_repository.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_adapter.dart';

const cfg = AppConfig(
  apiUrl: 'https://api.test/',
  authority: 'https://cognito-idp.x.amazonaws.com/p',
  clientId: 'c',
  webOrigin: 'https://findme.test',
);
const range = DateRange(
  from: '2026-10-01T00:00:00.000Z',
  to: '2026-10-02T00:00:00.000Z',
);

void main() {
  late FakeAdapter adapter;
  TrackRepository repo() =>
      TrackRepository(ApiClient(cfg, () async => 't', dio: fakeDio(adapter)));

  test('sends the range to /track and returns points, stops, last', () async {
    adapter = FakeAdapter(
      (_) => (
        status: 200,
        body: {
          'points': [
            [105.78, 21.03, 1793000000, 8],
          ],
          'stops': [
            {
              'lon': 1,
              'lat': 2,
              'start': 'a',
              'end': 'b',
              'seconds': 600,
              'name': 'X',
            },
          ],
          'last': {'lon': 1, 'lat': 2, 'ts': 'T'},
        },
      ),
    );
    final t = await repo().fetch(range);
    expect(t.points, const [TrackPoint(105.78, 21.03, 1793000000, 8)]);
    expect(t.stops.single.name, 'X');
    expect(t.last, const LastPoint(lon: 1, lat: 2, ts: 'T'));
    expect(adapter.calls, ['GET https://api.test/track']);
    expect(adapter.requests.single.uri.queryParameters, {
      'from': range.from,
      'to': range.to,
    });
  });

  test('fills missing fields', () async {
    adapter = FakeAdapter((_) => (status: 200, body: <String, Object?>{}));
    expect(await repo().fetch(range), Track.empty);
  });

  test(
    '403 -> AccountMissing; 401 -> AuthExpired; 400 -> HttpError(400)',
    () async {
      adapter = FakeAdapter((_) => (status: 403, body: {'error': 'account'}));
      await expectLater(repo().fetch(range), throwsA(isA<AccountMissing>()));
      adapter = FakeAdapter((_) => (status: 401, body: null));
      await expectLater(repo().fetch(range), throwsA(isA<AuthExpired>()));
      adapter = FakeAdapter((_) => (status: 400, body: null));
      await expectLater(
        repo().fetch(range),
        throwsA(isA<HttpError>().having((e) => e.status, 'status', 400)),
      );
    },
  );
}
