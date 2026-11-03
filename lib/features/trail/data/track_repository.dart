import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/network/api_client.dart';
import 'package:findme/core/network/api_client_provider.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Paw prints, stops (named) and the last point for a range of at most ~31 days (`GET /track`).
class TrackRepository {
  TrackRepository(this._api);

  final ApiClient _api;

  /// [have]: your newest point time the app holds (the answer is then `unchanged` if nothing new came in).
  /// [friends]: shown friends, `<id>~<since>~<have>,…` (`friendAsk`); their parts come back in `friends`.
  Future<TrackAnswer> fetch(
    DateRange r, {
    String? have,
    String? friends,
  }) async {
    final Map<String, dynamic> b;
    try {
      b =
          ((await _api.send(
            'GET',
            '/track',
            query: {
              'from': r.from,
              'to': r.to,
              if (have != null && have.isNotEmpty) 'have': have,
              if (friends != null && friends.isNotEmpty) 'friends': friends,
            },
          )) as Map<String, dynamic>?) ??
          {};
    } on ApiStatus catch (e) {
      throw HttpError(e.status); // 400 = range too long
    }
    return TrackAnswer(
      Track(
        points: trackPointsFromJson(b['points']),
        stops: [
          for (final s in (b['stops'] as List<dynamic>? ?? const []))
            Stop.fromJson(s as Map<String, dynamic>),
        ],
        last: b['last'] == null
            ? null
            : LastPoint.fromJson(b['last'] as Map<String, dynamic>),
      ),
      unchanged: b['unchanged'] == true,
      friends: [
        for (final f in (b['friends'] as List<dynamic>? ?? const []))
          FriendPart.fromJson(f as Map<String, dynamic>),
      ],
    );
  }
}

final trackRepositoryProvider = Provider<TrackRepository>(
  (ref) => TrackRepository(ref.watch(apiClientProvider)),
);
