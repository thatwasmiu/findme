import 'package:findme/core/errors/app_errors.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

/// An account-scoped value: rebuilt (empty) whenever the user leaves the signed-in phase.
final _scoped = NotifierProvider<_Bag, List<String>>(_Bag.new);

class _Bag extends Notifier<List<String>> {
  @override
  List<String> build() {
    ref.watch(signedInProvider);
    return [];
  }
}

Future<void> settle(ProviderContainer c) async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('stored token -> signedIn; none -> signedOut', () async {
    var c = ProviderContainer(overrides: baseOverrides(auth: fakeAuth()));
    expect(c.read(authControllerProvider), AuthPhase.loading);
    await settle(c);
    expect(c.read(authControllerProvider), AuthPhase.signedIn);
    c = ProviderContainer(
      overrides: baseOverrides(auth: fakeAuth(token: null)),
    );
    c.read(authControllerProvider);
    await settle(c);
    expect(c.read(authControllerProvider), AuthPhase.signedOut);
  });

  test(
    'signIn success -> signedIn; failure rethrows and stays signedOut',
    () async {
      final auth = fakeAuth(token: null);
      final c = ProviderContainer(overrides: baseOverrides(auth: auth));
      c.read(authControllerProvider);
      await settle(c);
      when(() => auth.login(any(), any()))
          .thenThrow(const AuthError('NotAuthorizedException'));
      await expectLater(
        c.read(authControllerProvider.notifier).signIn('a', 'b'),
        throwsA(isA<AuthError>()),
      );
      expect(c.read(authControllerProvider), AuthPhase.signedOut);
      when(() => auth.login(any(), any())).thenAnswer((_) async {});
      await c.read(authControllerProvider.notifier).signIn('a', 'b');
      expect(c.read(authControllerProvider), AuthPhase.signedIn);
    },
  );

  test('sign out wipes account state', () async {
    final auth = fakeAuth();
    final c = ProviderContainer(overrides: baseOverrides(auth: auth));
    c.listen(_scoped, (_, _) {});
    c.read(authControllerProvider);
    await settle(c);
    c.read(_scoped.notifier).state = ['friend data'];
    await c.read(authControllerProvider.notifier).signOut();
    expect(c.read(authControllerProvider), AuthPhase.signedOut);
    expect(c.read(_scoped), isEmpty);
    verify(auth.logout).called(1);
  });

  test('expired and noAccount move the phase and also wipe', () async {
    final c = ProviderContainer(overrides: baseOverrides(auth: fakeAuth()));
    c.listen(_scoped, (_, _) {});
    c.read(authControllerProvider);
    await settle(c);
    c.read(_scoped.notifier).state = ['x'];
    c.read(authControllerProvider.notifier).noAccount();
    expect(c.read(authControllerProvider), AuthPhase.noAccount);
    expect(c.read(_scoped), isEmpty);
    c.read(authControllerProvider.notifier).expired();
    expect(c.read(authControllerProvider), AuthPhase.signedOut);
  });

  test('cold start offline with a stored session: stay signed in', () async {
    final auth = fakeAuth();
    when(auth.getAccessToken).thenThrow(const NetworkError());
    final c = ProviderContainer(overrides: baseOverrides(auth: auth));
    c.read(authControllerProvider);
    await settle(c);
    expect(c.read(authControllerProvider), AuthPhase.signedIn);
  });
}
