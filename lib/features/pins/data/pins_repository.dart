import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/core/network/api_client_provider.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/pins/data/client_files.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sessionRefresh = Duration(hours: 6); // the cookie lives 12 h
const int _chunk =
    8 *
    1024 *
    1024; // small enough for a phone's uplink and CloudFront's timeout
const _cookieName = 'fm_user';
const _friendsCookie = 'fm_shared_friends';
const _nameTries = 4;
const _nameRetry = Duration(seconds: 3);

const _refused = <String, String>{
  'too-big': 'File này lớn quá, tối đa 500 MB nhé.',
  'quota': 'Bạn đã dùng hết dung lượng ảnh rồi 💾',
  'full': 'Find Me đang đầy chỗ, thử lại sau nhé.',
  'type': 'Không hỗ trợ loại file này.',
};

/// What to tell the person. [error] is Look Back's machine word; no [status] = it never got an answer.
String uploadMessage(int? status, String? error) =>
    _refused[error] ??
    (status == null
        ? 'Mất kết nối rồi, thử lại nhé 📶'
        : 'Chưa tải lên được, thử lại sau chút nhé ✨');

class PinUploadFailed implements Exception {
  const PinUploadFailed(this.message, [this.word]);
  final String message;

  /// Look Back's machine word (`too-big`, `quota`…), if it gave one.
  final String? word;
}

/// A file from the camera or the gallery. Look Back decides by [type]; one it does not take answers "type".
class PinFile {
  const PinFile(this.path, this.name);

  final String path;
  final String name;

  static const _types = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'webm': 'video/webm',
  };

  String get type =>
      _types[name.split('.').last.toLowerCase()] ?? 'application/octet-stream';
}

typedef PinInput = ({double lat, double lon, String? name, String? note});

/// Photo pins live on Look Back, reached on this app's own address under /lb (port of the web's `pins.ts` and
/// `pinUpload.ts`). A Find Me token buys a short ticket, the ticket buys a cookie. Reading pins fails quietly: Look
/// Back being away must never disturb the map.
///
/// The cookie is kept in memory only and this object is rebuilt on every sign-in, so the next account never holds
/// the previous one's (the server keeps no session, there is nothing to delete there).
class PinsRepository {
  PinsRepository(
    this._cfg,
    this._api, {
    Dio? dio,
    this._now = DateTime.now,
    this._encoder,
    List<Duration> retryDelays = const [
      Duration.zero,
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  }) : _dio = dio ?? appDio(),
       _delays = retryDelays;

  final AppConfig _cfg;
  final ApiClient _api;
  final Dio _dio;
  final DateTime Function() _now;
  final List<Duration> _delays;

  /// Makes a photo's small files on the phone (client_files.dart). null: Look Back makes them, as it always did.
  final ClientEncoder? _encoder;
  var _clientStrikes = 0;
  var _clientOn = true; // off after two slow or failed photos in a row, until the next sign-in rebuilds this
  String? _cookie;
  String? _sharedCookie; // opens friends' shared pictures
  DateTime? _exchangedAt;

  String get _lb => '${_cfg.web}/lb/api/findme';

  String mediaUrl(String key) => '${_cfg.web}/lb/media/$key';

  /// For images and video: they have no other way to prove who is asking.
  Map<String, String> get mediaHeaders {
    final all = [?_cookie, ?_sharedCookie];
    return all.isEmpty ? const {} : {'Cookie': all.join('; ')};
  }

  static String? _cookieFrom(Response<dynamic> r, String name) => r
      .headers['set-cookie']
      ?.map((c) => c.split(';').first)
      .where((c) => c.startsWith('$name='))
      .firstOrNull;

  bool get _sessionIsOld =>
      _exchangedAt == null ||
      _now().difference(_exchangedAt!) > _sessionRefresh;

  /// Trade the login for a Look Back cookie. false: signed out, no account (admin login), or Look Back away.
  Future<bool> ensureSession() async {
    try {
      final t =
          await _api.send('POST', '/media-ticket') as Map<String, dynamic>;
      final s = await _dio.post<dynamic>(
        '$_lb/session',
        data: {'ticket': t['ticket']},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
      );
      final cookie = _cookieFrom(s, _cookieName);
      if (cookie == null || (s.statusCode ?? 0) >= 300) return false;
      _cookie = cookie;
      _exchangedAt = _now();
      return true;
    } on Object {
      return false;
    }
  }

  Future<Response<dynamic>> _once(
    String method,
    String url, {
    Object? data,
    Map<String, String>? headers,
    String? contentType,
    void Function(int, int)? onSendProgress,
  }) => _dio.request<dynamic>(
    url,
    data: data,
    onSendProgress: onSendProgress,
    options: Options(
      method: method,
      headers: {...mediaHeaders, ...?headers},
      contentType: contentType,
      validateStatus: (_) => true,
    ),
  );

  /// One call, with one re-exchange if the cookie has run out.
  Future<Response<dynamic>> _call(
    String method,
    String url, {
    Object? data,
    Map<String, String>? headers,
    String? contentType,
    void Function(int, int)? onSendProgress,
  }) async {
    Future<Response<dynamic>> go() => _once(
      method,
      url,
      data: data,
      headers: headers,
      contentType: contentType,
      onSendProgress: onSendProgress,
    );
    final r = await go();
    return r.statusCode == 401 && await ensureSession() ? await go() : r;
  }

  Future<dynamic> _must(String method, String path, [Object? body]) async {
    final Response<dynamic> r;
    try {
      r = await _call(
        method,
        '$_lb$path',
        data: body,
        contentType: body == null ? null : Headers.jsonContentType,
      );
    } on DioException {
      throw const NetworkError();
    }
    final status = r.statusCode ?? 0;
    if (status < 200 || status >= 300) throw HttpError(status);
    return r.data;
  }

  /// null = couldn't read them (not "no pins"): keep what is on the map.
  Future<List<Pin>?> openPins() async {
    if (_sessionIsOld && !await ensureSession()) return null;
    try {
      final r = await _call('GET', '$_lb/pins');
      if (r.statusCode != 200) return null;
      return [
        for (final p in r.data as List<dynamic>)
          Pin.fromJson(p as Map<String, dynamic>),
      ];
    } on Object {
      return null;
    }
  }

  Future<Pin> createPin(PinInput p) async => Pin.fromJson(
    await _must('POST', '/pins', {
      'lat': p.lat,
      'lon': p.lon,
      'name': ?p.name,
      'note': ?p.note,
    }) as Map<String, dynamic>,
  );

  Future<void> deletePin(String id) => _must('DELETE', '/pins/$id');

  /// The "Chia sẻ" switch on one picture: all friends, and links with "Ảnh" on, see it.
  Future<void> setShared(String mediaId, {required bool shared}) =>
      _must('PUT', '/media/$mediaId/shared', {'shared': shared});

  /// A name for where a new pin is taken, when no stop is near: Find Me's cache, else its naming queue looks it up,
  /// so ask again every 3 s, 4 tries. '' when there is none or anything fails (the name is optional).
  Future<String> placeName(
    double lat,
    double lon, {
    Future<void> Function(Duration)? wait,
  }) async {
    final pause = wait ?? Future<void>.delayed;
    try {
      for (var i = 0; i < _nameTries; i++) {
        if (i > 0) await pause(_nameRetry);
        final r = await _api.send(
          'GET',
          '/place-name',
          query: {'lat': '$lat', 'lon': '$lon'},
        ) as Map<String, dynamic>;
        final name = r['name'] as String?;
        if (name != null || r['pending'] != true) return name ?? '';
      }
    } on Object {
      // quietly
    }
    return '';
  }

  /// A 15-minute pass to friends' shared pictures. null: no friends, or the call failed.
  Future<({String grant, int exp})?> pinGrant() async {
    try {
      final g = await _api.send('POST', '/pin-grant') as Map<String, dynamic>;
      final grant = g['grant'] as String?;
      final exp = (g['exp'] as num?)?.toInt();
      return grant == null || exp == null ? null : (grant: grant, exp: exp);
    } on Object {
      return null;
    }
  }

  /// The shared pins a grant opens, and the cookie for their files. Any failure: none, quietly.
  Future<List<Pin>> loadSharedPins(String grant) async {
    try {
      final r = await _dio.post<dynamic>(
        '$_lb/shared/session',
        data: {'grant': grant},
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
      );
      if (r.statusCode != 200) return const [];
      _sharedCookie = _cookieFrom(r, _friendsCookie) ?? _sharedCookie;
      return [
        for (final p in r.data as List<dynamic>)
          Pin.fromJson(p as Map<String, dynamic>),
      ];
    } on Object {
      return const [];
    }
  }

  /// null = no answer at all.
  Future<Response<dynamic>?> _try(
    String method,
    String url, {
    Object? data,
    Map<String, String>? headers,
    String? contentType,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _call(
        method,
        url,
        data: data,
        headers: {'Tus-Resumable': '1.0.0', ...?headers},
        contentType: contentType,
        onSendProgress: onSendProgress,
      );
    } on DioException {
      return null;
    }
  }

  // Like tus-js-client: 4xx will not get better, except a lost race over the offset (409) or a lock (423).
  static bool _retryable(Response<dynamic>? r) {
    final s = r?.statusCode ?? 0;
    return s < 400 || s >= 500 || s == 409 || s == 423;
  }

  static PinUploadFailed _failure(Response<dynamic>? r) {
    final body = r?.data;
    final word = body is Map ? body['error'] as String? : null;
    return PinUploadFailed(uploadMessage(r?.statusCode, word), word);
  }

  static int? _offsetOf(Response<dynamic>? r) =>
      int.tryParse(r?.headers.value('upload-offset') ?? '');

  /// Any other Look Back call (the bag's pictures), with the cookie and one re-exchange. null = no answer at all.
  Future<Response<dynamic>?> lookBack(String method, String path) async {
    if (_sessionIsOld && !await ensureSession()) return null;
    try {
      return await _call(method, '$_lb$path');
    } on DioException {
      return null;
    }
  }

  Future<void> uploadFile(
    String pinId,
    PinFile file,
    void Function(double fraction) onProgress,
  ) => uploadTus({'pinId': pinId}, file, onProgress);

  /// Resumable upload (tus 1.0.0) in 8 MiB chunks. A dropped connection asks the server how far it got and goes on.
  /// Returns the upload id, which is also the media id.
  ///
  /// A photo's small files are made here on the phone while it uploads (client_files.dart) and handed in when the
  /// upload ends, so the picture is ready at once. That work never delays or fails an upload: whatever is not ready
  /// or does not go through is left to Look Back, exactly as before.
  // ponytail: runs only while the app is open and is not resumed after a restart, same as the web.
  Future<String> uploadTus(
    Map<String, String> metadata,
    PinFile file,
    void Function(double fraction) onProgress,
  ) async {
    final raf = await File(file.path).open();
    try {
      final size = await raf.length();
      var client =
          _clientOn && _encoder != null && file.type.startsWith('image/');
      // Started now, beside the upload. `made` stays null until it is done (and if it fails).
      ClientFiles? made;
      if (client) unawaited(_makeClientFiles(file.path).then((m) => made = m));
      String meta({required bool flagged}) =>
          {
                ...metadata,
                'filename': file.name,
                'filetype': file.type,
                if (flagged) 'clientFiles': '1',
              }.entries
              .map((e) => '${e.key} ${base64.encode(utf8.encode(e.value))}')
              .join(',');
      String? location;
      for (var i = 0; location == null; i++) {
        final r = await _try(
          'POST',
          '$_lb/uploads',
          headers: {
            'Upload-Length': '$size',
            'Upload-Metadata': meta(flagged: client),
          },
        );
        if (r?.statusCode == 201) {
          location = r!.headers.value('location');
          if (location == null) throw _failure(r);
        } else if (client && _failure(r).word == 'quota') {
          // A flagged photo reserves room for its small files (4.3 MB) on top of itself. It may still fit without.
          client = false;
        } else {
          if (!_retryable(r) || i == _delays.length) throw _failure(r);
          await Future<void>.delayed(_delays[i]);
        }
      }
      final url = Uri.parse(_cfg.web).resolve(location).toString();

      var offset = 0;
      var tries = 0;
      while (offset < size) {
        await raf.setPosition(offset);
        final bytes = await raf.read(_chunk);
        final from = offset;
        final r = await _try(
          'PATCH',
          url,
          data: bytes,
          contentType: 'application/offset+octet-stream',
          headers: {
            'Upload-Offset': '$from',
            Headers.contentLengthHeader: '${bytes.length}',
          },
          onSendProgress: (sent, _) => onProgress((from + sent) / size),
        );
        final moved = r?.statusCode == 204 ? _offsetOf(r) : null;
        if (moved != null) {
          offset = moved;
          tries = 0;
          onProgress(offset / size);
          continue;
        }
        if (!_retryable(r) || tries == _delays.length) throw _failure(r);
        await Future<void>.delayed(_delays[tries++]);
        final head = await _try('HEAD', url);
        if (head?.statusCode == 200) offset = _offsetOf(head) ?? offset;
      }
      final id = Uri.parse(url).pathSegments.last;
      if (client) await _handInClientFiles(id, made);
      return id;
    } finally {
      await raf.close();
    }
  }

  void _clientStrike() {
    if (++_clientStrikes >= 2) _clientOn = false;
  }

  /// null: could not be made. Two slow or failed photos in a row end it for this sign-in.
  Future<ClientFiles?> _makeClientFiles(String path) async {
    final began = _now();
    try {
      final m = await _encoder!(path);
      if (tooSlow(_now().difference(began), m.width, m.height)) {
        _clientStrike();
      } else {
        _clientStrikes = 0;
      }
      return m;
    } on Object {
      _clientStrike();
      return null;
    }
  }

  /// The upload has ended and Look Back is waiting for this photo's small files: send them, or say it should make
  /// them itself ([files] null: not ready in time, or not made). Best effort: if nothing gets through, Look Back
  /// takes the photo anyway after its own wait.
  Future<void> _handInClientFiles(String id, ClientFiles? files) async {
    final media = '$_lb/media/$id';
    Future<Response<dynamic>> put(String name, List<int> bytes) => _call(
      'PUT',
      '$media/client-files/$name',
      data: bytes,
      contentType: 'application/octet-stream',
      headers: {Headers.contentLengthHeader: '${bytes.length}'},
    );
    Future<Response<dynamic>> result(Map<String, Object> body) => _call(
      'POST',
      '$media/client-result',
      data: body,
      contentType: Headers.jsonContentType,
    );
    try {
      if (files != null) {
        if ((await put('thumb', files.thumb)).statusCode == 204 &&
            (await put('display', files.display)).statusCode == 204) {
          await result({
            'width': files.width,
            'height': files.height,
            'blurDataUrl': files.blurDataUrl,
          });
          return;
        }
        _clientStrike(); // refused: a proxy that will not take the bodies would cost every photo these calls
      }
      await result({'skip': true});
    } on Object {
      // quietly
    }
  }

  /// One after the other. [onProgress] covers all of them.
  Future<({int failed, String message})> uploadAll(
    String pinId,
    List<PinFile> files,
    void Function(double fraction) onProgress,
  ) async {
    var failed = 0;
    var message = '';
    for (final (i, file) in files.indexed) {
      try {
        await uploadFile(
          pinId,
          file,
          (f) => onProgress((i + f) / files.length),
        );
      } on Object catch (e) {
        failed++;
        if (message.isEmpty) {
          message = e is PinUploadFailed
              ? e.message
              : uploadMessage(null, null);
        }
      }
    }
    return (failed: failed, message: message);
  }

  /// A new pin with its files. If none of them made it, the pin goes too: no empty pins.
  Future<({Pin? pin, int failed, String message})> addFiles(
    PinInput input,
    List<PinFile> files,
    void Function(double fraction) onProgress,
  ) async {
    final pin = await createPin(input);
    final r = await uploadAll(pin.id, files, onProgress);
    if (r.failed < files.length) {
      return (pin: pin, failed: r.failed, message: r.message);
    }
    try {
      await deletePin(pin.id);
    } on Object {
      // Look Back hides empty pins anyway.
    }
    return (pin: null, failed: r.failed, message: r.message);
  }
}

final pinsRepositoryProvider = Provider<PinsRepository>((ref) {
  ref.watch(signedInProvider); // a new cookie for every sign-in
  return PinsRepository(
    ref.watch(appConfigProvider),
    ref.watch(apiClientProvider),
    encoder: encodeClientFiles,
  );
});
