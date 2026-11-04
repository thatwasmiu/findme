import 'package:dio/dio.dart';
import 'package:findme/core/debug/debug_console.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_adapter.dart';
import '../../helpers/fakes.dart';

void main() {
  test('maskUrl keeps route words, hides ids, drops query values', () {
    expect(
      maskUrl(Uri.parse('https://x.vn/api/friends/requests/abc-123/accept')),
      '/api/friends/requests/•/accept',
    );
    expect(
      maskUrl(Uri.parse('https://x.vn/api/track?from=2026&have=T&friends=f~~')),
      '/api/track?from&have&friends',
    );
    expect(
      maskUrl(Uri.parse('https://x.vn/api/shares/Zx9_secret')),
      '/api/shares/•',
    );
  });

  group('DebugHttpLog', () {
    late DebugLog log;
    late FakeAdapter adapter;
    late Dio dio;
    setUp(() {
      log = DebugLog();
      adapter = FakeAdapter((_) => (status: 200, body: {'ok': true}));
      dio = fakeDio(adapter)..interceptors.add(DebugHttpLog(log));
    });

    test('an API call: method, masked path, status', () async {
      await dio.get<dynamic>('https://x.vn/api/friends/abc?x=1');
      final e = log.http.single;
      expect('${e.method} ${e.what} ${e.status}', 'GET /api/friends/•?x 200');
      expect(e.failed, isFalse);
    });

    test(
      "a Cognito error: the action and Cognito's code, never the body",
      () async {
        adapter
          ..contentType = 'application/x-amz-json-1.1'
          ..handler = (_) => (
            status: 400,
            body: {
              '__type': 'com.amazonaws#UserNotFoundException',
              'message': 'x',
            },
          );
        await dio.post<dynamic>(
          'https://cognito-idp.x.amazonaws.com/',
          data: '{"AuthParameters":{"PASSWORD":"secret"}}',
          options: Options(
            headers: {
              'X-Amz-Target': 'AWSCognitoIdentityProviderService.InitiateAuth',
            },
            responseType: ResponseType.plain,
            validateStatus: (_) => true,
          ),
        );
        final e = log.http.single;
        expect(e.what, 'Cognito InitiateAuth');
        expect(e.error, 'UserNotFoundException');
        expect(e.failed, isTrue);
      },
    );

    test(
      'no answer: status empty, the reason kept; at most 200 entries',
      () async {
        adapter.handler = (r) => throw offline(r);
        await expectLater(
          dio.get<dynamic>('https://x.vn/api/me'),
          throwsA(isA<DioException>()),
        );
        expect(log.http.single.status, isNull);
        expect(log.http.single.error, 'connectionError');
        for (var i = 0; i < 250; i++) {
          log.add(ErrorEntry('E', '$i'));
        }
        expect(log.errors, hasLength(DebugLog.max));
        expect(log.errors.first.message, '249');
      },
    );
  });

  testWidgets('the 🐞 opens the console with the calls and errors', (t) async {
    addTearDown(DebugLog.instance.clear);
    DebugLog.instance
      ..add(
        HttpEntry(method: 'GET', what: '/api/track?from', status: 200, ms: 143),
      )
      ..add(ErrorEntry('StateError', 'Bad state: boom'));
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(auth: fakeAuth()),
        child: MaterialApp(
          navigatorKey: nav,
          builder: (_, child) => DebugOverlay(navigator: nav, child: child!),
          home: const Scaffold(body: SizedBox()),
        ),
      ),
    );
    await t.tap(find.text('🐞'));
    await t.pumpAndSettle();
    expect(find.text('HTTP (1)'), findsOneWidget);
    expect(find.text('GET /api/track?from'), findsOneWidget);
    await t.tap(find.text('Errors (1)'));
    await t.pumpAndSettle();
    expect(find.text('Bad state: boom'), findsOneWidget);
    await t.tap(find.text('Env'));
    await t.pumpAndSettle();
    expect(find.text('https://api.test'), findsOneWidget);
  });
}
