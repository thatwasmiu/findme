import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One canned answer: status + JSON body (null = empty body).
typedef Reply = ({int status, Object? body});

/// A dio adapter that never touches the network: records every request and answers from [handler].
/// Throwing a [DioException] from [handler] simulates being offline.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);

  Reply Function(RequestOptions req) handler;
  final requests = <RequestOptions>[];

  /// `'GET https://api.test/track'` for each request so far (no query string).
  List<String> get calls => requests
      .map((r) => '${r.method} ${r.uri.scheme}://${r.uri.host}${r.uri.path}')
      .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final r = handler(options);
    final bytes = r.body == null
        ? Uint8List(0)
        : utf8.encode(jsonEncode(r.body));
    return ResponseBody.fromBytes(
      bytes,
      r.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A Dio wired to [adapter] that never throws on HTTP status (callers map statuses themselves).
Dio fakeDio(FakeAdapter adapter) => Dio()..httpClientAdapter = adapter;

/// What a request sent as JSON body.
Object? sentBody(RequestOptions r) =>
    r.data is String ? jsonDecode(r.data as String) : r.data;

DioException offline(Object? r) => DioException.connectionError(
  requestOptions: r! as RequestOptions,
  reason: 'offline',
);
