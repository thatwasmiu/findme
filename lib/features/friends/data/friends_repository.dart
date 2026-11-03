import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/core/network/api_client_provider.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The friends API (port of the web's `friendsApi.ts`).
class FriendsRepository {
  FriendsRepository(this._api);

  final ApiClient _api;

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

  static String _one(String id) => Uri.encodeComponent(id);

  Future<Me> me() async =>
      Me.fromJson(await _send('GET', '/me') as Map<String, dynamic>);

  Future<Relations> relations() async => Relations.fromJson(
    await _send('GET', '/friends') as Map<String, dynamic>,
  );

  /// By the other person's code (typed any way): a new request, or friends at once if they had already asked you.
  Future<({Pending? outgoing, Friend? friend})> sendRequest(String code) async {
    final b = await _send('POST', '/friends/requests', {
      'code': code,
    }) as Map<String, dynamic>;
    return (
      outgoing: b['outgoing'] == null
          ? null
          : Pending.fromJson(b['outgoing'] as Map<String, dynamic>),
      friend: b['friend'] == null
          ? null
          : Friend.fromJson(b['friend'] as Map<String, dynamic>),
    );
  }

  Future<void> answer(String id, {required bool accept}) => _send(
    'POST',
    '/friends/requests/${_one(id)}/${accept ? 'accept' : 'decline'}',
  );

  /// Ends a friendship, or cancels your own request. Silent for the other person.
  Future<void> remove(String id) => _send('DELETE', '/friends/${_one(id)}');

  // Shown friends' positions and today's prints come with your own trail: TrackRepository.fetch(…, friends:).
}

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepository(ref.watch(apiClientProvider)),
);
