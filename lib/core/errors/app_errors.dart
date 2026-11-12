/// Every failure the app tells apart, mirroring the web's error classes.
sealed class AppError implements Exception {
  const AppError();
}

/// Signed out: no session, or the server said 401.
class AuthExpired extends AppError {
  const AuthExpired();
}

/// Signed in, but this login has no map account (e.g. the admin login): 403.
class AccountMissing extends AppError {
  const AccountMissing();
}

/// No answer at all (offline, DNS, timeout).
class NetworkError extends AppError {
  const NetworkError();
}

/// A non-2xx the API client does not map itself; repositories turn it into their own errors.
class ApiStatus extends AppError {
  const ApiStatus(this.status, this.body);
  final int status;
  final Map<String, dynamic>? body;

  /// The server's `{"error": "..."}` reason, if any.
  String? get reason => body?['error'] as String?;

  @override
  String toString() => 'HTTP $status';
}

/// Any other HTTP failure.
class HttpError extends AppError {
  const HttpError(this.status);
  final int status;

  @override
  String toString() => 'HTTP $status';
}

/// The server rejected one field of a share link: `label`, `expiresAt`, `routeFrom`, or `body`.
class ShareInvalid extends AppError {
  const ShareInvalid(this.field);
  final String field;
}

/// The friends API said no with a reason: `self`, `already`, `pending`, `code`, `not found`…
class FriendError extends AppError {
  const FriendError(this.code);
  final String code;
}

/// Cognito said no; [code] is its error name (NotAuthorizedException…) or the challenge it asked for.
class AuthError extends AppError {
  const AuthError(this.code, [this.detail = '']);
  final String code;

  /// The text our own Cognito triggers threw (UserLambdaValidationException), already Vietnamese, no prefix.
  final String detail;

  @override
  String toString() => code;
}
