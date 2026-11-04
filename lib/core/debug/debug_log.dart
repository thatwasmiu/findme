import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The 🐞 debug console exists only in dev builds (`--flavor dev`); prod builds compile it out.
const debugConsoleEnabled = appFlavor == 'dev';

sealed class DebugEntry {
  DebugEntry() : at = DateTime.now();
  final DateTime at;
}

/// One HTTP call. [status] null: no answer (offline, timeout).
class HttpEntry extends DebugEntry {
  HttpEntry({
    required this.method,
    required this.what,
    required this.status,
    required this.ms,
    this.error,
  });

  final String method;

  /// The masked path (`/api/friends/•`) or the Cognito action (`Cognito InitiateAuth`).
  final String what;
  final int? status;
  final int ms;

  /// The server's error code (`UserNotFoundException`, `self`…) or why there was no answer.
  final String? error;

  bool get failed => status == null || status! >= 400;
}

class ErrorEntry extends DebugEntry {
  ErrorEntry(this.type, String message)
    : message = message.length > 400
          ? '${message.substring(0, 400)}…'
          : message;
  final String type;
  final String message;
}

/// What the console shows, newest first. In memory only: nothing leaves the phone or survives a restart.
// ponytail: one global log, not a provider; the dio interceptor and the error hooks live outside Riverpod.
class DebugLog extends ChangeNotifier {
  static final instance = DebugLog();
  static const max = 200;

  final http = <HttpEntry>[];
  final errors = <ErrorEntry>[];

  void add(DebugEntry e) {
    final list = switch (e) {
      HttpEntry() => http,
      ErrorEntry() => errors,
    };
    list.insert(0, e);
    if (list.length > max) list.removeLast();
    notifyListeners();
  }

  void clear() {
    http.clear();
    errors.clear();
    notifyListeners();
  }

  /// Flutter errors (layout, build) and uncaught async errors go to the console too; the old handlers still run.
  void hookErrors() {
    final flutter = FlutterError.onError;
    FlutterError.onError = (d) {
      add(
        ErrorEntry(d.exception.runtimeType.toString(), d.exceptionAsString()),
      );
      flutter?.call(d);
    };
    final platform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (e, s) {
      add(ErrorEntry(e.runtimeType.toString(), e.toString()));
      return platform?.call(e, s) ?? false;
    };
  }
}

// Path words that are routes, not data. Everything else (friend, share and request ids) shows as •.
const _routeWords = {
  'api',
  'track',
  'me',
  'friends',
  'requests',
  'accept',
  'decline',
  'shares',
  'live',
  'today',
};

/// A URL as the console may show it: route words kept, ids masked, query values dropped (they hold times and
/// friend ids). CLAUDE.md: never show tokens, coordinates, share ids, friend codes, emails or passwords.
String maskUrl(Uri u) {
  final path = u.pathSegments
      .where((s) => s.isNotEmpty)
      .map((s) => _routeWords.contains(s) ? s : '•')
      .join('/');
  final keys = u.queryParameters.keys.join('&');
  return '/$path${keys.isEmpty ? '' : '?$keys'}';
}

/// Times every request and writes it to [DebugLog]. Bodies are read only for an error code.
class DebugHttpLog extends Interceptor {
  DebugHttpLog([DebugLog? log]) : _log = log ?? DebugLog.instance;
  final DebugLog _log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['debugStart'] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _write(response.requestOptions, response.statusCode, response.data, null);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _write(
      err.requestOptions,
      err.response?.statusCode,
      err.response?.data,
      err.type.name,
    );
    handler.next(err);
  }

  void _write(RequestOptions o, int? status, Object? body, String? why) {
    final start = o.extra['debugStart'] as DateTime?;
    final target = o.headers['X-Amz-Target'] as String?;
    _log.add(
      HttpEntry(
        method: o.method,
        what: target != null
            ? 'Cognito ${target.split('.').last}'
            : maskUrl(o.uri),
        status: status,
        ms: start == null ? 0 : DateTime.now().difference(start).inMilliseconds,
        error: why ?? (status != null && status >= 400 ? _code(body) : null),
      ),
    );
  }

  /// Cognito's `__type` or the API's `error`: short codes, never user data.
  static String? _code(Object? body) {
    var b = body;
    if (b is String) {
      try {
        b = jsonDecode(b);
      } on FormatException {
        return null;
      }
    }
    if (b is! Map) return null;
    final c = b['__type'] ?? b['error'];
    return c is String && c.length <= 60 ? c.split('#').last : null;
  }
}

/// The Dio every real client starts from: with the console's logger in dev builds.
Dio appDio() =>
    Dio()..interceptors.addAll([if (debugConsoleEnabled) DebugHttpLog()]);
