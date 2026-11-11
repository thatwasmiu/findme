import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/core/network/api_client_provider.dart';
import 'package:findme/features/shares/domain/share.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Share links: create, list, edit, revoke (port of the share functions in the web's `api.ts`).
class SharesRepository {
  SharesRepository(this._api);

  final ApiClient _api;

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    try {
      return await _api.send(method, path, body: body);
    } on ApiStatus catch (e) {
      if (e.status == 400) throw ShareInvalid(e.reason ?? 'body');
      throw HttpError(e.status);
    }
  }

  Future<Share> create({
    required String label,
    required String expiresAt,
    bool route = false,
    String? routeFrom,
    bool bag = false,
  }) async => Share.fromJson(
    await _send('POST', '/shares', {
      'label': label,
      'expiresAt': expiresAt,
      'route': route,
      if (route && routeFrom != null) 'routeFrom': routeFrom,
      if (bag) 'bag': true,
    }) as Map<String, dynamic>,
  );

  Future<List<Share>> list() async {
    final b = await _send('GET', '/shares') as Map<String, dynamic>;
    return [
      for (final s in b['shares'] as List<dynamic>)
        Share.fromJson(s as Map<String, dynamic>),
    ];
  }

  /// A new expiry, the route on/off, the day it starts, and/or the bag on/off (expired links too).
  Future<Share> edit(
    String id, {
    String? expiresAt,
    bool? route,
    String? routeFrom,
    bool? bag,
  }) async => Share.fromJson(
    await _send('PATCH', '/shares/${Uri.encodeComponent(id)}', {
      'expiresAt': ?expiresAt,
      'route': ?route,
      'routeFrom': ?routeFrom,
      'bag': ?bag,
    }) as Map<String, dynamic>,
  );

  Future<void> revoke(String id) =>
      _send('DELETE', '/shares/${Uri.encodeComponent(id)}');
}

final sharesRepositoryProvider = Provider<SharesRepository>(
  (ref) => SharesRepository(ref.watch(apiClientProvider)),
);
