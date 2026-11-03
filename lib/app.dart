import 'package:findme/core/theme/app_theme.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';
import 'package:findme/features/auth/presentation/welcome_screen.dart';
import 'package:findme/features/trail/presentation/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Signed in: the map. Otherwise: the welcome card (starting up, sign-in, or "this login has no map").
class FindMeApp extends ConsumerWidget {
  const FindMeApp({super.key, this.showTiles = true});

  final bool showTiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'Find Me',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: ref.watch(signedInProvider)
        ? MapScreen(showTiles: showTiles)
        : const WelcomeScreen(),
  );
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
