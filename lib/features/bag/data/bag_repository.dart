import 'dart:async';

import 'package:dio/dio.dart';
import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/core/network/api_client_provider.dart';
import 'package:findme/features/bag/domain/bag.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 'failed': Look Back could not use the picture. 'timeout': still not processed. Anything else: a message to show.
@immutable
class CardError implements Exception {
  const CardError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      other is CardError && other.message == message;
  @override
  int get hashCode => message.hashCode;
  @override
  String toString() => 'CardError($message)';
}

/// What to tell the person when a picture did not make it.
String cardErrorText(Object e) {
  if (e is! CardError) return 'Chưa lưu được ảnh, thử lại nhé ✨';
  return switch (e.message) {
    'failed' => 'Ảnh này không dùng được, thử ảnh khác nhé.',
    'timeout' => 'Ảnh xử lý lâu quá, thử lại sau chút nhé.',
    final m => m,
  };
}

/// Asks until the picture is processed (409 meanwhile; [onWait] runs once, on the first 409).
Future<String> waitForReceipt(
  String id,
  Future<Response<dynamic>?> Function(String path) get, {
  int tries = 40,
  Duration delay = const Duration(milliseconds: 1500),
  void Function()? onWait,
}) async {
  for (var i = 0; i < tries; i++) {
    final r = await get('/card-media/${Uri.encodeComponent(id)}/receipt');
    if (r == null) throw const NetworkError();
    final s = r.statusCode ?? 0;
    if (s >= 200 && s < 300) {
      return (r.data as Map<String, dynamic>)['receipt'] as String;
    }
    if (s != 409) throw const CardError('failed');
    if (i == 0) onWait?.call();
    if (i < tries - 1) await Future<void>.delayed(delay);
  }
  throw const CardError('timeout');
}

/// A receipt lasts 10 minutes, and filling a bag can take longer: at save time every picture not yet in the stored
/// bag gets a fresh one (Look Back gives as many as asked). Saved pictures need none.
Future<Slots> freshReceipts(
  Slots slots,
  Set<String> saved,
  Future<String> Function(String media) get,
) => Future.wait([
  for (final s in slots)
    if (s?.media != null && !saved.contains(s!.media))
      get(s.media!).then((r) => s.copyWith(receipt: r))
    else
      Future.value(s),
]);

/// The bag and avatar API (port of the web's `bagApi.ts` and `cardUpload.ts`). The pictures go to Look Back like pin
/// photos, but into the account's album without a pin; Look Back hands back a receipt Find Me checks before keeping
/// the picture.
class BagRepository {
  BagRepository(this._api, this._lb);

  final ApiClient _api;
  final PinsRepository _lb;

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    try {
      return await _api.send(method, path, body: body);
    } on ApiStatus catch (e) {
      if (e.status == 400 || e.status == 404 || e.status == 409) {
        throw FriendError(e.reason ?? 'not found');
      }
      throw HttpError(e.status);
    }
  }

  static Slots _slots(dynamic b) =>
      slotsFrom((b as Map<String, dynamic>)['slots'] as List<dynamic>? ?? []);

  Future<Slots> myBag() async => _slots(await _send('GET', '/me/bag'));

  /// The whole bag. New pictures carry the receipt Look Back gave for them.
  Future<Slots> saveMyBag(Slots slots) async => _slots(
    await _send('PUT', '/me/bag', {
      'slots': [for (final s in slots) s?.toSave()],
    }),
  );

  Future<Slots> friendBag(String id) async =>
      _slots(await _send('GET', '/friends/${Uri.encodeComponent(id)}/bag'));

  /// A new avatar by its [receipt], or none ([receipt] null). Returns the new media id or null.
  Future<String?> setAvatar(String? receipt) async =>
      (await _send(
            'PUT',
            '/me/avatar',
            receipt == null ? {'clear': true} : {'receipt': receipt},
          ) as Map<String, dynamic>)['avatar']
          as String?;

  Future<String> receipt(String media, {void Function()? onWait}) =>
      waitForReceipt(media, (p) => _lb.lookBack('GET', p), onWait: onWait);

  /// [onProcessing]: the file is up and Look Back is still making the picture (say so instead of "100%").
  Future<({String media, String receipt})> uploadCard(
    PinFile file,
    String role,
    void Function(double) onProgress, {
    void Function()? onProcessing,
  }) async {
    final res = await _lb.lookBack('POST', '/card-album');
    if (res == null) throw const CardError('Mất kết nối rồi, thử lại nhé 📶');
    final s = res.statusCode ?? 0;
    if (s < 200 || s >= 300) {
      throw CardError(uploadMessage(res.statusCode, null));
    }
    final album = (res.data as Map<String, dynamic>)['album'] as String;
    final String media;
    try {
      media = await _lb.uploadTus(
        {'albumId': album, 'role': role},
        file,
        onProgress,
      );
    } on PinUploadFailed catch (e) {
      throw CardError(
        e.word == 'too-big' ? 'Ảnh này lớn quá, tối đa 20 MB nhé.' : e.message,
      );
    }
    return (media: media, receipt: await receipt(media, onWait: onProcessing));
  }

  /// A picture no longer in the bag or replaced as avatar. Best effort: one left behind only uses quota.
  void deleteCard(String id) => unawaited(
    _lb.lookBack('DELETE', '/card-media/${Uri.encodeComponent(id)}'),
  );
}

final bagRepositoryProvider = Provider<BagRepository>(
  (ref) => BagRepository(
    ref.watch(apiClientProvider),
    ref.watch(pinsRepositoryProvider),
  ),
);
