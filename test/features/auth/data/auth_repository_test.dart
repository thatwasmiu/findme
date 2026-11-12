import 'dart:convert';

import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/data/cognito_api.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_adapter.dart';

const cfg = AppConfig(
  apiUrl: 'https://api.test',
  authority: 'https://cognito-idp.ap-southeast-1.amazonaws.com/pool',
  clientId: 'c',
  webOrigin: 'https://findme.test',
);
const api = 'https://cognito-idp.ap-southeast-1.amazonaws.com/';

class MemoryStore implements SessionStore {
  Session? s;
  @override
  Future<Session?> load() async => s;
  @override
  Future<void> save(Session? next) async => s = next;
}

Reply ok(Map<String, Object?> b) => (status: 200, body: b);
Reply fail(String type) =>
    (status: 400, body: {'__type': 'com.amazonaws#$type'});
Map<String, Object?> tokens(
  String access, {
  int expiresIn = 3600,
  String? refresh,
}) => {
  'AuthenticationResult': {
    'AccessToken': access,
    'ExpiresIn': expiresIn,
    'RefreshToken': ?refresh,
  },
};

void main() {
  late FakeAdapter adapter;
  late MemoryStore store;
  late AuthRepository repo;

  void answer(Reply Function(dynamic r) h) => adapter.handler = h;
  Map<String, Object?> sent([int i = 0]) => {
    'target': adapter.requests[i].headers['X-Amz-Target'],
    'body': sentBody(adapter.requests[i]),
  };
  void signedIn(int expiresInMs) => store.s = Session(
    access: 'old',
    refresh: 'R',
    expiresAt: DateTime.now().millisecondsSinceEpoch + expiresInMs,
  );

  setUp(() {
    adapter = FakeAdapter((_) => ok({}))
      ..contentType = 'application/x-amz-json-1.1'; // what Cognito really sends
    store = MemoryStore();
    repo = AuthRepository(CognitoApi(cfg, dio: fakeDio(adapter)), store);
  });

  group('login', () {
    test(
      'sends trimmed email + password to Cognito and stores the session',
      () async {
        answer((_) => ok(tokens('A', refresh: 'R')));
        await repo.login(' me@x.vn ', 'pw');
        expect(adapter.calls, ['POST $api']);
        expect(
          adapter.requests.single.headers['Content-Type'],
          'application/x-amz-json-1.1',
        );
        expect(sent(), {
          'target': 'AWSCognitoIdentityProviderService.InitiateAuth',
          'body': {
            'AuthFlow': 'USER_PASSWORD_AUTH',
            'ClientId': 'c',
            'AuthParameters': {'USERNAME': 'me@x.vn', 'PASSWORD': 'pw'},
          },
        });
        // What Cognito really receives: JSON text, not dio's form encoding.
        expect(jsonDecode(adapter.wire.single), sent()['body']);
        expect(store.s?.access, 'A');
        expect(store.s?.refresh, 'R');
        expect(await repo.getAccessToken(), 'A');
      },
    );

    test("wrong password / a challenge: AuthError with Cognito's code, "
        'nothing stored', () async {
      answer((_) => fail('NotAuthorizedException'));
      await expectLater(
        repo.login('a', 'b'),
        throwsA(
          isA<AuthError>().having(
            (e) => e.code,
            'code',
            'NotAuthorizedException',
          ),
        ),
      );
      answer((_) => ok({'ChallengeName': 'NEW_PASSWORD_REQUIRED'}));
      await expectLater(
        repo.login('a', 'b'),
        throwsA(
          isA<AuthError>().having(
            (e) => e.code,
            'code',
            'NEW_PASSWORD_REQUIRED',
          ),
        ),
      );
      expect(store.s, isNull);
    });
  });

  group('getAccessToken', () {
    test('none stored: null; fresh: returned without a call', () async {
      expect(await repo.getAccessToken(), isNull);
      signedIn(3600000);
      expect(await repo.getAccessToken(), 'old');
      expect(adapter.requests, isEmpty);
    });

    test('nearly expired: renewed once for concurrent callers; '
        'refresh token kept', () async {
      signedIn(10000);
      answer((_) => ok(tokens('new')));
      expect(
        await Future.wait([repo.getAccessToken(), repo.getAccessToken()]),
        ['new', 'new'],
      );
      expect(adapter.requests, hasLength(1));
      expect(sent()['body'], {
        'AuthFlow': 'REFRESH_TOKEN_AUTH',
        'ClientId': 'c',
        'AuthParameters': {'REFRESH_TOKEN': 'R'},
      });
      expect(store.s?.access, 'new');
      expect(store.s?.refresh, 'R');
    });

    test(
      'offline refresh keeps session and says "offline", not "signed out"',
      () async {
        signedIn(-1);
        answer((r) => throw offline(r));
        await expectLater(repo.getAccessToken(), throwsA(isA<NetworkError>()));
        expect(store.s, isNotNull);
      },
    );

    test('Cognito hiccup (5xx, throttling) keeps the session', () async {
      signedIn(-1);
      answer((_) => fail('TooManyRequestsException'));
      await expectLater(repo.getAccessToken(), throwsA(isA<NetworkError>()));
      answer((_) => (status: 500, body: null));
      await expectLater(repo.getAccessToken(), throwsA(isA<NetworkError>()));
      expect(store.s, isNotNull);
    });

    test('refresh refused: signed out (session dropped)', () async {
      signedIn(-1);
      answer((_) => fail('NotAuthorizedException'));
      expect(await repo.getAccessToken(), isNull);
      expect(store.s, isNull);
    });
  });

  test(
    'logout drops the session and revokes the refresh token (best effort)',
    () async {
      signedIn(3600000);
      answer((_) => fail('InternalErrorException'));
      await repo.logout();
      expect(store.s, isNull);
      expect(sent(), {
        'target': 'AWSCognitoIdentityProviderService.RevokeToken',
        'body': {'Token': 'R', 'ClientId': 'c'},
      });
    },
  );

  test('signInMessage maps Cognito codes to the web wording', () {
    expect(
      signInMessage(const AuthError('NotAuthorizedException')),
      'Sai email hoặc mật khẩu.',
    );
    expect(
      signInMessage(const AuthError('NEW_PASSWORD_REQUIRED')),
      'Tài khoản cần mật khẩu mới: nhờ admin đặt lại giúp nhé.',
    );
    expect(signInMessage(const AuthError('Weird')), 'Chưa được (Weird).');
    expect(
      signInMessage(const NetworkError()),
      'Không kết nối được, thử lại sau chút nhé ✨',
    );
  });

  group('sign-up', () {
    test(
      'SignUp sends trimmed fields and the invite, stores nothing',
      () async {
        answer((_) => ok({'UserConfirmed': false}));
        await repo.signUp(' me@x.vn ', 'pw', ' Bơ ', ' inv ');
        expect(sent(), {
          'target': 'AWSCognitoIdentityProviderService.SignUp',
          'body': {
            'ClientId': 'c',
            'Username': 'me@x.vn',
            'Password': 'pw',
            'UserAttributes': [
              {'Name': 'email', 'Value': 'me@x.vn'},
              {'Name': 'name', 'Value': 'Bơ'},
            ],
            'ClientMetadata': {'invite': 'inv'},
          },
        });
        expect(store.s, isNull);
      },
    );

    test(
      'ConfirmSignUp and ResendConfirmationCode take the email and code',
      () async {
        await repo.confirmSignUp('me@x.vn', ' 123456 ');
        await repo.resendCode('me@x.vn');
        expect(sent(), {
          'target': 'AWSCognitoIdentityProviderService.ConfirmSignUp',
          'body': {
            'ClientId': 'c',
            'Username': 'me@x.vn',
            'ConfirmationCode': '123456',
          },
        });
        expect(sent(1), {
          'target': 'AWSCognitoIdentityProviderService.ResendConfirmationCode',
          'body': {'ClientId': 'c', 'Username': 'me@x.vn'},
        });
      },
    );

    test("a trigger refusal keeps the trigger's own words, without Cognito's prefix", () async {
      answer(
        (_) => (
          status: 400,
          body: {
            '__type': 'UserLambdaValidationException',
            'message': 'PreSignUp failed with error Mã mời không đúng.',
          },
        ),
      );
      await expectLater(
        repo.signUp('a@x.vn', 'pw', 'B', 'x'),
        throwsA(
          isA<AuthError>()
              .having((e) => e.code, 'code', 'UserLambdaValidationException')
              .having((e) => e.detail, 'detail', 'Mã mời không đúng.'),
        ),
      );
      expect(
        signInMessage(
          const AuthError(
            'UserLambdaValidationException',
            'Mã mời không đúng.',
          ),
        ),
        'Mã mời không đúng.',
      );
    });
  });
}
