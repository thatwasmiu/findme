import 'package:dio/dio.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ok: stored, drop the batch. unauthorized: the ingest token is wrong, rotated, or the account is off.
/// rejected: the server says the batch is malformed (our bug). retry: anything else, try again later.
enum IngestResult { ok, unauthorized, rejected, retry }

/// Uploads a batch to `/ingest` like Overland does. Not `ApiClient`: that one sends the sign-in token and treats a
/// 401 as "signed out", while a bad ingest token must only stop uploads.
class IngestClient {
  IngestClient(this._cfg, {Dio? dio}) : _dio = dio ?? appDio();

  final AppConfig _cfg;
  final Dio _dio;

  Future<IngestResult> send(
    String token,
    List<Fix> fixes,
    String deviceId,
  ) async {
    try {
      final res = await _dio.post<dynamic>(
        '${_cfg.api}/ingest',
        data: overlandBatch(fixes, deviceId),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          contentType: Headers.jsonContentType,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          validateStatus: (_) => true,
        ),
      );
      final data = res.data;
      return switch (res.statusCode) {
        200 when data is Map && data['result'] == 'ok' => IngestResult.ok,
        401 => IngestResult.unauthorized,
        400 => IngestResult.rejected,
        _ => IngestResult.retry,
      };
    } on DioException {
      return IngestResult.retry;
    }
  }
}

final ingestClientProvider = Provider<IngestClient>(
  (ref) => IngestClient(ref.watch(appConfigProvider)),
);
