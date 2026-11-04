import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/core/errors/app_errors.dart';

/// Cognito's user pool API, called directly (no hosted login page), like the web's `auth.ts`.
class CognitoApi {
  CognitoApi(this._cfg, {Dio? dio}) : _dio = dio ?? appDio();

  final AppConfig _cfg;
  final Dio _dio;

  String get clientId => _cfg.clientId;

  Future<Map<String, dynamic>> call(
    String action,
    Map<String, dynamic> body,
  ) async {
    final Response<dynamic> res;
    try {
      res = await _dio.post<dynamic>(
        'https://${_cfg.cognitoHost}/',
        // Cognito's own content type is not JSON to dio, which would form-encode a Map: send JSON text.
        data: jsonEncode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action',
          },
          // Same in reverse: dio leaves the `application/x-amz-json-1.1` answer as a string; decoded below.
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      throw const NetworkError();
    }
    Object? decoded;
    try {
      decoded = jsonDecode(res.data as String? ?? '');
    } on FormatException {
      decoded = null; // not JSON (e.g. a proxy's error page): reported by status below
    }
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
    final status = res.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw AuthError(
        ((data['__type'] as String?) ?? 'HTTP $status').split('#').last,
      );
    }
    return data;
  }
}
