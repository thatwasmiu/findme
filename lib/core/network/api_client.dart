import 'package:dio/dio.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/errors/app_errors.dart';

typedef TokenGetter = Future<String?> Function();

/// The one way to call the Find Me API: adds the bearer token and maps 401/403 like every web `call()` does.
/// Repositories map the remaining statuses (400/404/409) to their own errors.
class ApiClient {
  ApiClient(this._cfg, this._token, {Dio? dio}) : _dio = dio ?? Dio();

  final AppConfig _cfg;
  final TokenGetter _token;
  final Dio _dio;

  Future<dynamic> send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final t = await _token();
    if (t == null) throw const AuthExpired();
    final Response<dynamic> res;
    try {
      res = await _dio.request<dynamic>(
        '${_cfg.api}$path',
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {'Authorization': 'Bearer $t'},
          contentType: body == null ? null : Headers.jsonContentType,
          validateStatus: (_) =>
              true, // statuses are mapped below, not thrown by dio
        ),
      );
    } on DioException {
      throw const NetworkError();
    }
    final status = res.statusCode ?? 0;
    if (status == 401) throw const AuthExpired();
    if (status == 403) throw const AccountMissing();
    if (status == 204) return null;
    final data = res.data == '' ? null : res.data;
    if (status < 200 || status >= 300) {
      throw ApiStatus(status, data is Map<String, dynamic> ? data : null);
    }
    return data;
  }
}
