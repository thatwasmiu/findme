import 'dart:async';

import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// noAccount: signed in, but this login has no map (e.g. the admin).
enum AuthPhase { loading, signedOut, signedIn, noAccount }

/// Which screen the app shows. Starts by checking the stored session.
class AuthController extends Notifier<AuthPhase> {
  @override
  AuthPhase build() {
    unawaited(
      Future.microtask(() async {
        AuthPhase next;
        try {
          final t = await ref.read(authRepositoryProvider).getAccessToken();
          next = t == null ? AuthPhase.signedOut : AuthPhase.signedIn;
        } on NetworkError {
          next = AuthPhase.signedIn; // a session exists but cannot be renewed offline: show the map, retry later
        }
        if (state != AuthPhase.loading) return;
        state = next;
        // No session: a trail kept from an earlier one must not wait for the next person on this phone.
        if (next == AuthPhase.signedOut) {
          unawaited(ref.read(prefsProvider).clearToday());
        }
      }),
    );
    return AuthPhase.loading;
  }

  /// Rethrows the login error so the form can show it.
  Future<void> signIn(String email, String password) async {
    final auth = ref.read(authRepositoryProvider);
    await auth.login(email, password);
    // Another account on this phone: the previous one's tracking (its token, its unsent points) ends first, so
    // nobody's points go out under someone else's token.
    final pasted = await ref.read(trackerStoreProvider).token();
    if (pasted != null &&
        pasted.sub != subOf(await auth.getAccessToken() ?? '')) {
      await ref.read(trackerControllerProvider.notifier).forget();
    }
    state = AuthPhase.signedIn;
  }

  /// A deliberate sign-out also ends tracking on this phone (a lapsed session, [expired], does not).
  Future<void> signOut() async {
    state = AuthPhase.signedOut;
    await ref.read(trackerControllerProvider.notifier).forget();
    await Future.wait([
      ref.read(authRepositoryProvider).logout(),
      ref.read(prefsProvider).clear(),
    ]);
  }

  /// The server said 401 (or the session is gone). Tracking carries on: its token is not the session's.
  void expired() {
    state = AuthPhase.signedOut;
    // The next login may be someone else: forget where this account's map was and whom it showed.
    unawaited(ref.read(prefsProvider).clear());
  }

  /// The server said 403. Like the web: a login without a map forgets today's trail kept on this phone.
  void noAccount() {
    state = AuthPhase.noAccount;
    unawaited(ref.read(prefsProvider).clearToday());
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthPhase>(
  AuthController.new,
);

/// True while signed in. Every account-scoped provider watches this, so leaving the signed-in phase rebuilds it
/// empty: the next person to sign in on this phone never sees the previous account's trail or friends.
final signedInProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider) == AuthPhase.signedIn,
);
