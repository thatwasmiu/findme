import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/data/friends_repository.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/trail/domain/colors.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/presentation/map_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The list and where shown friends are now: small, so often.
const friendsPollMs = 7000;

/// A shown friend's prints for today: bigger, so less often.
const routeMs = 60000;

class FriendDay {
  const FriendDay({required this.points, required this.last, required this.at});
  final List<TrackPoint> points;
  final LastPoint? last;

  /// When it was fetched (epoch ms).
  final int at;
}

class FriendsState {
  const FriendsState({
    this.me,
    this.relations = Relations.empty,
    this.shownIds = const [],
    this.live = const {},
    this.today = const {},
  });

  final Me? me;
  final Relations relations;
  final List<String> shownIds;
  final Map<String, LastPoint> live;
  final Map<String, FriendDay> today;

  /// Only current friends can be on the map: a removed friend drops out by itself.
  List<String> get shown =>
      shownIds.where((id) => relations.friends.any((f) => f.id == id)).toList();

  FriendsState copyWith({
    Me? me,
    Relations? relations,
    List<String>? shownIds,
    Map<String, LastPoint>? live,
    Map<String, FriendDay>? today,
  }) => FriendsState(
    me: me ?? this.me,
    relations: relations ?? this.relations,
    shownIds: shownIds ?? this.shownIds,
    live: live ?? this.live,
    today: today ?? this.today,
  );
}

/// Your friends, requests and which friends are on your map (port of the web's useFriends.ts).
class FriendsController extends Notifier<FriendsState> {
  Timer? _list;
  Timer? _routes;
  bool _paused = false;

  FriendsRepository get _repo => ref.read(friendsRepositoryProvider);

  @override
  FriendsState build() {
    final signedIn = ref.watch(
      signedInProvider,
    ); // signing out forgets everything of that account
    ref.onDispose(() {
      _list?.cancel();
      _routes?.cancel();
    });
    if (signedIn) {
      // Timers are made here, synchronously, so onDispose always cancels them (Riverpod makes a new notifier on
      // every rebuild, e.g. at sign-out, even while the first load below is still waiting).
      _list = Timer.periodic(const Duration(milliseconds: friendsPollMs), (_) {
        if (!_paused) unawaited(refresh());
      });
      _routes = Timer.periodic(const Duration(milliseconds: routeMs), (_) {
        if (!_paused) unawaited(_loadToday(force: true));
      });
      unawaited(
        Future.microtask(() async {
          final ids = await ref.read(prefsProvider).shownFriends();
          if (!ref.mounted) return;
          state = state.copyWith(shownIds: ids);
          await refresh();
          await _loadToday();
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
      final shown = state.shown.isNotEmpty || state.shownIds.isNotEmpty;
      final (me, rel, live) = await (
        state.me != null ? Future.value(state.me!) : _repo.me(),
        _repo.relations(),
        shown ? _repo.live() : Future.value(const <LivePoint>[]),
      ).wait;
      if (!ref.mounted) return;
      state = state.copyWith(
        me: me,
        relations: rel,
        live: {
          for (final p in live)
            p.id: LastPoint(lon: p.lon, lat: p.lat, ts: p.ts),
        },
      );
    } on ParallelWaitError<dynamic, dynamic> catch (e) {
      final errs =
          e.errors
              as (
                AsyncError<Object?>?,
                AsyncError<Object?>?,
                AsyncError<Object?>?,
              );
      _failed((errs.$1 ?? errs.$2 ?? errs.$3)!.error);
    } on Object catch (e) {
      _failed(e);
    }
  }

  /// Today's prints of each shown friend that is due (or all of them when [force]).
  Future<void> _loadToday({bool force = false, List<String>? only}) async {
    if (!ref.mounted) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final due = (only ?? state.shown)
        .where(
          (id) =>
              force ||
              only != null ||
              state.today[id] == null ||
              now - state.today[id]!.at >= routeMs,
        )
        .toList();
    if (due.isEmpty) return;
    try {
      final got = await Future.wait(
        due.map((id) async => MapEntry(id, await _repo.today(id))),
      );
      if (!ref.mounted) return;
      state = state.copyWith(
        today: {
          ...state.today,
          for (final e in got)
            e.key: FriendDay(
              points: e.value.points,
              last: e.value.last,
              at: now,
            ),
        },
      );
    } on Object catch (e) {
      _failed(e);
    }
  }

  Future<void> toggle(String id) async {
    final on = !state.shownIds.contains(id);
    final next = on
        ? [...state.shownIds, id]
        : state.shownIds.where((x) => x != id).toList();
    state = state.copyWith(shownIds: next);
    await ref.read(prefsProvider).saveShownFriends(next);
    if (on) {
      await Future.wait([
        refresh(),
        _loadToday(only: [id]),
      ]);
    }
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
          last: s.live[id] ?? s.today[id]?.last,
        ),
  ];
});
