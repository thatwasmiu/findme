import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/data/friends_repository.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:findme/features/trail/presentation/map_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The list of friends and requests (it drives the request count on the 👥 button).
const friendsPollMs = 60000;

class FriendsState {
  const FriendsState({
    this.me,
    this.relations = Relations.empty,
    this.shownIds = const [],
    this.today = const {},
  });

  final Me? me;
  final Relations relations;
  final List<String> shownIds;

  /// Shown friends' prints and newest point today, filled in by the trail's /track request.
  final Map<String, FriendTrail> today;

  /// Only current friends can be on the map: a removed friend drops out by itself.
  List<String> get shown =>
      shownIds.where((id) => relations.friends.any((f) => f.id == id)).toList();

  FriendsState copyWith({
    Me? me,
    Relations? relations,
    List<String>? shownIds,
    Map<String, FriendTrail>? today,
  }) => FriendsState(
    me: me ?? this.me,
    relations: relations ?? this.relations,
    shownIds: shownIds ?? this.shownIds,
    today: today ?? this.today,
  );
}

/// Your friends, requests and which friends are on your map (port of the web's useFriends.ts). The list is refreshed
/// every minute while the app is visible and as soon as it comes back. Shown friends' prints and positions come with
/// your own trail in one /track request (TrailController): [ask] says what to ask for, [apply] takes the answer.
class FriendsController extends Notifier<FriendsState> {
  Timer? _list;
  bool _paused = false;

  FriendsRepository get _repo => ref.read(friendsRepositoryProvider);

  @override
  FriendsState build() {
    final signedIn = ref.watch(
      signedInProvider,
    ); // signing out forgets everything of that account
    ref.onDispose(() => _list?.cancel());
    if (signedIn) {
      // The timer is made here, synchronously, so onDispose always cancels it (Riverpod makes a new notifier on
      // every rebuild, e.g. at sign-out, even while the first load below is still waiting).
      _list = Timer.periodic(const Duration(milliseconds: friendsPollMs), (_) {
        if (!_paused) unawaited(refresh());
      });
      unawaited(
        Future.microtask(() async {
          final ids = await ref.read(prefsProvider).shownFriends();
          if (!ref.mounted) return;
          state = state.copyWith(shownIds: ids);
          await refresh();
        }),
      );
    }
    return const FriendsState();
  }

  void _failed(Object e) {
    if (!ref.mounted) return;
    if (e is AuthExpired) ref.read(authControllerProvider.notifier).expired();
    if (e is AccountMissing) {
      ref.read(authControllerProvider.notifier).noAccount();
    }
    // anything else: keep what we have; the next tick tries again
  }

  Future<void> refresh() async {
    if (!ref.mounted) return;
    try {
      final (me, rel) = await (
        state.me != null ? Future.value(state.me!) : _repo.me(),
        _repo.relations(),
      ).wait;
      if (!ref.mounted) return;
      state = state.copyWith(me: me, relations: rel);
    } on ParallelWaitError<dynamic, dynamic> catch (e) {
      final errs = e.errors as (AsyncError<Object?>?, AsyncError<Object?>?);
      _failed((errs.$1 ?? errs.$2)!.error);
    } on Object catch (e) {
      _failed(e);
    }
  }

  /// The `friends` parameter for /track: one `<id>~<since>~<have>` per shown friend.
  String ask(DateTime now) {
    final day = isoMs(midnightOf(now));
    return state.shown
        .map((id) => friendAsk(id, state.today[id], day))
        .join(',');
  }

  /// Fold /track's `friends` answer in. Only the friends that request asked for ([asked]: what [ask] returned)
  /// change: a friend asked for but left out of the answer is no longer allowed to be seen; the others are kept as
  /// they are (the first request on opening goes out before the friend list is in, and must not drop friends
  /// restored from the phone).
  Map<String, FriendTrail> apply(
    List<FriendPart> parts,
    String asked,
    DateTime now,
  ) {
    final start = midnightOf(now).millisecondsSinceEpoch;
    final next = {...state.today};
    for (final a in asked.split(',').where((a) => a.isNotEmpty)) {
      next.remove(a.split('~').first);
    }
    for (final p in parts) {
      next[p.id] = friendMerge(state.today[p.id], p, start);
    }
    state = state.copyWith(today: next);
    return next;
  }

  /// Today's prints kept on the phone: drawn at once, then only the newest part is asked for.
  void restore(Map<String, FriendTrail> saved) =>
      state = state.copyWith(today: saved);

  Future<void> toggle(String id) async {
    final on = !state.shownIds.contains(id);
    final next = on
        ? [...state.shownIds, id]
        : state.shownIds.where((x) => x != id).toList();
    state = state.copyWith(shownIds: next);
    await ref.read(prefsProvider).saveShownFriends(next);
    // The trail controller sees `shown` change and asks /track for them right away.
  }

  /// Sends a request by code; returns the note to show.
  Future<String> send(String code) async {
    final r = await _repo.sendRequest(code);
    unawaited(refresh());
    return r.friend != null
        ? 'Bạn và ${r.friend!.name} đã là bạn bè 🎉'
        : 'Đã gửi lời mời 💌';
  }

  Future<void> answer(String id, {required bool accept}) async {
    await _repo.answer(id, accept: accept);
    unawaited(refresh());
  }

  /// Ends a friendship or cancels your own request.
  Future<void> remove(String id) async {
    await _repo.remove(id);
    unawaited(refresh());
  }

  /// Your avatar just changed (the cached `me` is otherwise never re-read).
  void setAvatar(String? avatar) {
    final m = state.me;
    if (m != null) state = state.copyWith(me: m.copyWith(avatar: avatar));
  }

  void paused() => _paused = true;

  void resumed() {
    _paused = false;
    unawaited(refresh());
  }
}

final friendsControllerProvider =
    NotifierProvider<FriendsController, FriendsState>(FriendsController.new);

/// What the map draws: each shown friend in their colour, with today's prints and where they are now.
final friendsOnMapProvider = Provider<List<MapFriend>>((ref) {
  final s = ref.watch(friendsControllerProvider);
  return [
    for (final id in s.shown)
      for (final f in s.relations.friends.where((f) => f.id == id))
        MapFriend(
          id: id,
          name: f.name,
          color: friendColor(id),
          points: s.today[id]?.points ?? const [],
          last: s.today[id]?.last,
          avatar: f.avatar,
        ),
  ];
});
