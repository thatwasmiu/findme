import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/data/cognito_api.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sign-in with email + password straight against Cognito, quiet renewal, sign-out (port of the web's `auth.ts`).
class AuthRepository {
  AuthRepository(this._api, this._store);

  final CognitoApi _api;
  final SessionStore _store;
  Future<String?>? _renewing;

  String get _cid => _api.clientId;

  Session _fromResult(Map<String, dynamic> a, String refresh) => Session(
    access: a['AccessToken'] as String,
    refresh: (a['RefreshToken'] as String?) ?? refresh,
    expiresAt:
        DateTime.now().millisecondsSinceEpoch +
        (a['ExpiresIn'] as num).toInt() * 1000,
  );

  /// Self sign-up: Cognito checks the invite code and name (PreSignUp trigger), creates the user unconfirmed and
  /// emails a 6-digit code. The person is not signed in until [confirmSignUp].
  Future<void> signUp(
    String email,
    String password,
    String name,
    String invite,
  ) => _api.call('SignUp', {
    'ClientId': _cid,
    'Username': email.trim(),
    'Password': password,
    'UserAttributes': [
      {'Name': 'email', 'Value': email.trim()},
      {'Name': 'name', 'Value': name.trim()},
    ],
    'ClientMetadata': {'invite': invite.trim()},
  });

  /// The emailed code; on success the PostConfirmation trigger makes the account.
  Future<void> confirmSignUp(String email, String code) =>
      _api.call('ConfirmSignUp', {
        'ClientId': _cid,
        'Username': email.trim(),
        'ConfirmationCode': code.trim(),
      });

  /// A new code by email (counts toward the 4 emails a day per address).
  Future<void> resendCode(String email) => _api.call('ResendConfirmationCode', {
    'ClientId': _cid,
    'Username': email.trim(),
  });

  Future<void> login(String email, String password) async {
    final r = await _api.call('InitiateAuth', {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': _cid,
      'AuthParameters': {'USERNAME': email.trim(), 'PASSWORD': password},
    });
    // A challenge (e.g. NEW_PASSWORD_REQUIRED) is not handled here: the admin sets permanent passwords.
    final result = r['AuthenticationResult'] as Map<String, dynamic>?;
    if (result == null) {
      throw AuthError((r['ChallengeName'] as String?) ?? 'Challenge');
    }
    await _store.save(_fromResult(result, ''));
  }

  /// A valid access token, or null (signed out). Throws [NetworkError] when renewal could not reach Cognito. The access token lives 1 h; when it is (nearly) gone,
  /// trade the refresh token (30 days) for a new one quietly. Concurrent callers share one renewal.
  Future<String?> getAccessToken() async {
    final s = await _store.load();
    if (s == null) return null;
    if (s.expiresAt - DateTime.now().millisecondsSinceEpoch > 60000) {
      return s.access;
    }
    return await (_renewing ??= _renew(s).whenComplete(() => _renewing = null));
  }

  Future<String?> _renew(Session s) async {
    try {
      final r = await _api.call('InitiateAuth', {
        'AuthFlow': 'REFRESH_TOKEN_AUTH',
        'ClientId': _cid,
        'AuthParameters': {'REFRESH_TOKEN': s.refresh},
      });
      final n = _fromResult(
        r['AuthenticationResult'] as Map<String, dynamic>,
        s.refresh,
      );
      await _store.save(n);
      return n.access;
    } on AuthError catch (e) {
      // Only a refused refresh token means "sign in again"; throttling or a Cognito outage is temporary.
      if (e.code != 'NotAuthorizedException') throw const NetworkError();
      await _store.save(null); // refresh token expired or revoked
      return null;
    }
    // NetworkError (offline) goes to the caller: the session is kept for the next try.
  }

  /// Ends the session here and at Cognito (the refresh token stops working). Best effort.
  Future<void> logout() async {
    final s = await _store.load();
    await _store.save(null);
    if (s == null) return;
    try {
      await _api.call('RevokeToken', {'Token': s.refresh, 'ClientId': _cid});
    } on AppError {
      // signed out here anyway
    }
  }
}

const _why = {
  'NotAuthorizedException': 'Sai email hoặc mật khẩu.',
  'UserNotFoundException': 'Sai email hoặc mật khẩu.',
  'UserNotConfirmedException':
      'Email chưa xác nhận: nhập mã đã gửi tới email nhé.',
  'PasswordResetRequiredException': 'Cần đặt lại mật khẩu: nhờ admin giúp nhé.',
  'NEW_PASSWORD_REQUIRED':
      'Tài khoản cần mật khẩu mới: nhờ admin đặt lại giúp nhé.',
  'TooManyRequestsException': 'Thử nhiều quá rồi, đợi vài phút nhé.',
  'LimitExceededException': 'Thử nhiều quá rồi, đợi vài phút nhé.',
  'UsernameExistsException':
      'Email này đã đăng ký. Đăng nhập, hoặc nhập mã nếu chưa xác nhận.',
  'InvalidPasswordException': 'Mật khẩu cần ít nhất 8 ký tự, có chữ hoa, chữ thường, số và ký tự đặc biệt.',
  'CodeMismatchException': 'Mã chưa đúng, xem lại email nhé.',
  'ExpiredCodeException': 'Mã hết hạn rồi: bấm "Gửi lại mã".',
  'CodeDeliveryFailureException': 'Không gửi được email, thử lại sau nhé.',
};

/// What the sign-in / sign-up form says for a failure (the web's `SignIn.tsx` `why`): our triggers' own words
/// first, then the table, then the raw code.
String signInMessage(Object error) => error is AuthError
    ? (error.detail.isNotEmpty
          ? error.detail
          : _why[error.code] ?? 'Chưa được (${error.code}).')
    : 'Không kết nối được, thử lại sau chút nhé ✨';

final sessionStoreProvider = Provider<SessionStore>(
  (_) => SecureSessionStore(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final cfg = ref.watch(appConfigProvider);
  return AuthRepository(CognitoApi(cfg), ref.watch(sessionStoreProvider));
});
