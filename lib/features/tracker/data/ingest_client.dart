import 'package:dio/dio.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/core/network/api_client_provider.dart';
import 'package:findme/features/tracker/domain/fix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ok: stored, drop the batch. unauthorized: the ingest token is wrong, rotated, or the account is off.
/// rejected: the server says the batch is malformed (our bug). retry: anything else, try again later.
/// tripOver: stored like ok, but this trip-mode account has no trip on (ended on the web, or on its timer).
enum IngestResult { ok, tripOver, unauthorized, rejected, retry }

/// Uploads a batch to `/ingest` like Overland does. Not `ApiClient`: that one sends the sign-in token and treats a
/// 401 as "signed out", while a bad ingest token must only stop uploads.
class IngestClient {
  IngestClient(this._cfg, this._api, {Dio? dio}) : _dio = dio ?? appDio();

  final AppConfig _cfg;
  final ApiClient _api;
  final Dio _dio;

  /// `POST /me/ingest-token` with the sign-in token: a new ingest token for this account; its old one stops at once.
  /// Throws like [ApiClient.send]: AuthExpired (401), AccountMissing (403), ApiStatus (429…), NetworkError.
  // ponytail: the answer's `url` is ignored, uploads go to `<API_URL>/ingest` (the same place); store it if they differ.
  Future<String> newToken() async =>
      (await _api.send('POST', '/me/ingest-token')
              as Map<String, dynamic>)['token']
          as String;

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
        200 when data is Map && data['result'] == 'ok' =>
          data['trip'] == false ? IngestResult.tripOver : IngestResult.ok,
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
  (ref) =>
      IngestClient(ref.watch(appConfigProvider), ref.watch(apiClientProvider)),
);
