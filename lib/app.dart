import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/auth/presentation/welcome_screen.dart';
import 'package:findme/features/trail/presentation/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signed in: the map. Otherwise: the welcome card (starting up, sign-in, or "this login has no map").
class FindMeApp extends ConsumerStatefulWidget {
  const FindMeApp({super.key, this.showTiles = true});

  final bool showTiles;

  @override
  ConsumerState<FindMeApp> createState() => _FindMeAppState();
}

class _FindMeAppState extends ConsumerState<FindMeApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Leaving the signed-in phase also closes open sheets and dialogs: they hold that account's data
    // (e.g. secret share links) and would otherwise stay on top of the welcome screen.
    ref.listen(signedInProvider, (_, signedIn) {
      if (!signedIn) _navigator.currentState?.popUntil((r) => r.isFirst);
    });
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Find Me',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: ref.watch(signedInProvider)
          ? MapScreen(showTiles: widget.showTiles)
          : const WelcomeScreen(),
    );
  }
}

/// Shown instead of the app when the build has no config (see docs/guide/02-running-the-app.md).
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CardBox(
            padding: const EdgeInsets.all(24),
            child: Notice(message, error: true),
          ),
        ),
      ),
    ),
  );
}
