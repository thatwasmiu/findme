import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// noAccount: signed in, but this login has no map (e.g. the admin).
enum AuthPhase { loading, signedOut, signedIn, noAccount }

/// Which screen the app shows. Starts by checking the stored session.
class AuthController extends Notifier<AuthPhase> {
  @override
  AuthPhase build() {
    Future.microtask(() async {
      final t = await ref.read(authRepositoryProvider).getAccessToken();
      if (state == AuthPhase.loading)
        state = t == null ? AuthPhase.signedOut : AuthPhase.signedIn;
    });
    return AuthPhase.loading;
  }

  /// Rethrows the login error so the form can show it.
  Future<void> signIn(String email, String password) async {
    await ref.read(authRepositoryProvider).login(email, password);
    state = AuthPhase.signedIn;
  }

  Future<void> signOut() async {
    state = AuthPhase.signedOut;
    await ref.read(authRepositoryProvider).logout();
  }

  /// The server said 401 (or the session is gone).
  void expired() => state = AuthPhase.signedOut;

  /// The server said 403.
  void noAccount() => state = AuthPhase.noAccount;
}

final authControllerProvider = NotifierProvider<AuthController, AuthPhase>(
  AuthController.new,
);

/// True while signed in. Every account-scoped provider watches this, so leaving the signed-in phase rebuilds it
/// empty: the next person to sign in on this phone never sees the previous account's trail or friends.
final signedInProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider) == AuthPhase.signedIn,
);
