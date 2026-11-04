import 'package:dio/dio.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/features/tracker/data/ingest_client.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_adapter.dart';
import '../../../helpers/fakes.dart';

final fixes = [
  Fix(at: DateTime.utc(2026, 11, 4), lat: 10.77, lon: 106.7, acc: 9),
  Fix(at: DateTime.utc(2026, 11, 4, 0, 1), lat: 10.78, lon: 106.7, acc: 9),
];

void main() {
  Future<(IngestResult, FakeAdapter)> answer(
    Reply Function(RequestOptions) h,
  ) async {
    final a = FakeAdapter(h);
    final r = await IngestClient(
      testConfig,
      ApiClient(testConfig, () async => 'access'),
      dio: fakeDio(a),
    ).send('tok', fixes, 'android');
    return (r, a);
  }

  Future<(String, FakeAdapter)> issue(Reply Function(RequestOptions) h) async {
    final a = FakeAdapter(h);
    final api = ApiClient(testConfig, () async => 'access', dio: fakeDio(a));
    return (await IngestClient(testConfig, api).newToken(), a);
  }

  test('newToken posts to /me/ingest-token with the sign-in token', () async {
    final (t, a) = await issue(
      (_) => (
        status: 200,
        body: {'url': 'https://findme.test/api/ingest', 'token': 'ab' * 32},
      ),
    );
    expect(t, 'ab' * 32);
    expect(a.calls, ['POST https://api.test/me/ingest-token']);
    expect(a.requests.single.headers['Authorization'], 'Bearer access');
  });

  test('newToken 403 -> AccountMissing, 429 -> ApiStatus', () async {
    await expectLater(
      issue((_) => (status: 403, body: null)),
      throwsA(isA<AccountMissing>()),
    );
    await expectLater(
      issue((_) => (status: 429, body: null)),
      throwsA(isA<ApiStatus>().having((e) => e.status, 'status', 429)),
    );
  });

  test('sends bearer and body to <api>/ingest', () async {
    final (_, a) = await answer((_) => (status: 200, body: {'result': 'ok'}));
    expect(a.calls, ['POST https://api.test/ingest']);
    expect(a.requests.single.headers['Authorization'], 'Bearer tok');
    final body = sentBody(a.requests.single)! as Map<String, dynamic>;
    expect((body['locations'] as List).length, 2);
  });

  test('200 ok -> ok', () async {
    final (r, _) = await answer((_) => (status: 200, body: {'result': 'ok'}));
    expect(r, IngestResult.ok);
  });

  test('200 with another body -> retry', () async {
    final (r, _) = await answer((_) => (status: 200, body: {'x': 1}));
    expect(r, IngestResult.retry);
  });

  test('401 -> unauthorized', () async {
    final (r, _) = await answer((_) => (status: 401, body: {'error': 'u'}));
    expect(r, IngestResult.unauthorized);
  });

  test('400 -> rejected', () async {
    final (r, _) = await answer((_) => (status: 400, body: {'error': 'b'}));
    expect(r, IngestResult.rejected);
  });

  test('500 -> retry', () async {
    final (r, _) = await answer((_) => (status: 500, body: null));
    expect(r, IngestResult.retry);
  });

  test('offline -> retry', () async {
    final (r, _) = await answer((req) => throw offline(req));
    expect(r, IngestResult.retry);
  });
}
