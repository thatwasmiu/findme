import 'package:dio/dio.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';

/// Cognito's user pool API, called directly (no hosted login page), like the web's `auth.ts`.
class CognitoApi {
  CognitoApi(this._cfg, {Dio? dio}) : _dio = dio ?? Dio();

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
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/x-amz-json-1.1',
            'X-Amz-Target': 'AWSCognitoIdentityProviderService.$action',
          },
          responseType: ResponseType.json,
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      throw const NetworkError();
    }
    final data = res.data is Map<String, dynamic>
        ? res.data as Map<String, dynamic>
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
