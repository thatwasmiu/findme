import 'dart:async';

import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Friends' shared pictures change rarely: not on the trail's one-minute poll.
const friendPinsRefresh = Duration(minutes: 5);
const _grantMarginS = 60;

/// Friends' pins drawn only for the friends shown on the map, like their trail.
List<Pin> visibleFriendPins(List<Pin> all, List<String> shown) =>
    all.where((p) => shown.contains(p.sub)).toList();

/// Time for a new pass: none yet, or less than a minute left.
bool grantDue(int? exp, int nowS) => exp == null || exp - nowS < _grantMarginS;

/// How many friends you have; no friends, nothing is asked. Replaceable in tests.
final friendCountProvider = Provider<int>(
  (ref) => ref.watch(
    friendsControllerProvider.select((s) => s.relations.friends.length),
  ),
);

/// Every friend's shared pins (the web's `useFriendsSharedPins`), refreshed every 5 minutes and on return to the
/// app. Any failure leaves the list empty and the map unharmed.
class FriendPinsController extends Notifier<List<Pin>> {
  int _seq = 0; // an answer from before a sign-out (or a friend change) must not land after it
  Timer? _timer;
  bool _paused = false;
  ({String grant, int exp})? _grant;

  @override
  List<Pin> build() {
    final signedIn = ref.watch(signedInProvider);
    final friends = ref.watch(friendCountProvider);
    ref.onDispose(() => _timer?.cancel());
    _seq++;
    _grant = null;
    if (signedIn && friends > 0) {
      unawaited(Future.microtask(_load));
      _timer = Timer.periodic(friendPinsRefresh, (_) {
        if (!_paused) unawaited(_load());
      });
    }
    return const [];
  }

  Future<void> _load() async {
    final mine = _seq;
    final repo = ref.read(pinsRepositoryProvider);
    final nowS = ref.read(nowProvider)().millisecondsSinceEpoch ~/ 1000;
    if (grantDue(_grant?.exp, nowS)) _grant = await repo.pinGrant();
    if (mine != _seq || !ref.mounted) return;
    final g = _grant;
    final got = g == null ? const <Pin>[] : await repo.loadSharedPins(g.grant);
    if (mine != _seq || !ref.mounted) return;
    state = got;
  }

  /// The app went to the background: stop asking.
  void paused() => _paused = true;

  /// Back in the app: refresh right away.
  void resumed() {
    _paused = false;
    if (_timer != null) unawaited(_load());
  }
}

final friendPinsControllerProvider =
    NotifierProvider<FriendPinsController, List<Pin>>(FriendPinsController.new);
