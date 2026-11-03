import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the app talks to: the same stack outputs as the web's `config.json`, passed at build time with
/// `--dart-define-from-file=config/dev.json`.
@immutable
class AppConfig {
  const AppConfig({
    required this.apiUrl,
    required this.authority,
    required this.clientId,
    required this.webOrigin,
  });

  factory AppConfig.fromEnvironment() => AppConfig.fromMap(const {
    'API_URL': String.fromEnvironment('API_URL'),
    'AUTHORITY': String.fromEnvironment('AUTHORITY'),
    'CLIENT_ID': String.fromEnvironment('CLIENT_ID'),
    'WEB_ORIGIN': String.fromEnvironment('WEB_ORIGIN'),
  });

  factory AppConfig.fromMap(Map<String, String?> m) {
    String need(String k) {
      final v = m[k];
      if (v == null || v.isEmpty) throw StateError(bad);
      return v;
    }

    return AppConfig(
      apiUrl: need('API_URL'),
      authority: need('AUTHORITY'),
      clientId: need('CLIENT_ID'),
      webOrigin: need('WEB_ORIGIN'),
    );
  }

  static const bad =
      'Config missing or invalid - copy config/example.json to config/dev.json, fill in the stack '
      'outputs, and run with --dart-define-from-file=config/dev.json';

  final String apiUrl;

  /// Cognito issuer: https://cognito-idp.<region>.amazonaws.com/<pool id>.
  final String authority;
  final String clientId;

  /// The web app's origin; share links are `<webOrigin>/s/<id>` and open the web share page.
  final String webOrigin;

  /// [apiUrl] without trailing slashes.
  String get api => apiUrl.replaceFirst(RegExp(r'/+$'), '');

  /// The user pool's API lives on the issuer's host.
  String get cognitoHost => Uri.parse(authority).host;

  String get web => webOrigin.replaceFirst(RegExp(r'/+$'), '');
}

/// Overridden in `main.dart` (and in tests).
final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError('override appConfigProvider'),
);
