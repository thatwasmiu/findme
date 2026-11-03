import 'package:findme/app.dart';
import 'package:findme/core/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final cfg = AppConfig.fromEnvironment();
    runApp(
      ProviderScope(
        overrides: [appConfigProvider.overrideWithValue(cfg)],
        child: const FindMeApp(),
      ),
    );
  } on StateError catch (e) {
    runApp(
      ConfigErrorApp(e.message),
    ); // missing config: say how to fix it instead of crashing
  }
}
