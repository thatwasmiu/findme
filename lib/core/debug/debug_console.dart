import 'dart:async';

import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/config/version.dart';
import 'package:findme/core/debug/debug_log.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/auth/presentation/auth_controller.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String _hms(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:'
    '${t.second.toString().padLeft(2, '0')}';

const _mono = TextStyle(fontFamily: 'monospace', fontSize: 12);

/// Dev builds: a draggable 🐞 over every screen; a tap opens the console. A red dot: errors were logged.
class DebugOverlay extends StatefulWidget {
  const DebugOverlay({required this.navigator, required this.child, super.key});

  /// The app's navigator: the overlay sits above it, so the sheet is opened through it.
  final GlobalKey<NavigatorState> navigator;
  final Widget child;

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  Offset? _at;

  void _open() {
    final ctx = widget.navigator.currentContext;
    if (ctx == null) return;
    unawaited(
      showModalBottomSheet<void>(
        context: ctx,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white, // the app's sheets are 95% white; logs need a solid background
        builder: (_) =>
            const FractionallySizedBox(heightFactor: 0.85, child: DebugSheet()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final at = _at ?? Offset(size.width - 64, size.height * 0.6);
    return Stack(
      children: [
        widget.child,
        Positioned(
          left: at.dx,
          top: at.dy,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() {
              final p = at + d.delta;
              _at = Offset(
                p.dx.clamp(0, size.width - 48),
                p.dy.clamp(0, size.height - 48),
              );
            }),
            child: Material(
              color: Colors.black.withValues(alpha: 0.55),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _open,
                child: Semantics(
                  label: 'Debug console',
                  button: true,
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: ListenableBuilder(
                      listenable: DebugLog.instance,
                      builder: (_, _) => Badge(
                        isLabelVisible: DebugLog.instance.errors.isNotEmpty,
                        smallSize: 10,
                        child: const Center(
                          child: Text('🐞', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The console: HTTP calls, errors, and where this build points. Dev tool, so English.
class DebugSheet extends ConsumerWidget {
  const DebugSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = DebugLog.instance;
    return ListenableBuilder(
      listenable: log,
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TabBar(
                    tabs: [
                      Tab(text: 'HTTP (${log.http.length})'),
                      Tab(text: 'Errors (${log.errors.length})'),
                      const Tab(text: 'Env'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: log.clear,
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _list(log.http.map(_httpRow).toList(), 'No calls yet'),
                  _list(log.errors.map(_errorRow).toList(), 'No errors'),
                  const _Env(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _list(List<Widget> rows, String empty) => rows.isEmpty
      ? Center(child: Text(empty))
      : ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: rows.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => rows[i],
        );

  static Widget _httpRow(HttpEntry e) {
    final color = e.failed ? Colors.red.shade700 : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_hms(e.at)}  ${e.status ?? '—'}  ${e.ms} ms',
            style: _mono.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          Text('${e.method} ${e.what}', style: _mono),
          if (e.error != null)
            Text(e.error!, style: _mono.copyWith(color: color)),
        ],
      ),
    );
  }

  static Widget _errorRow(ErrorEntry e) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_hms(e.at)}  ${e.type}',
          style: _mono.copyWith(
            color: Colors.red.shade700,
            fontWeight: FontWeight.w700,
          ),
        ),
        SelectableText(e.message, style: _mono),
      ],
    ),
  );
}

class _Env extends ConsumerWidget {
  const _Env();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(appConfigProvider);
    final phase = ref.watch(authControllerProvider);
    final session = ref.watch(_sessionExpiry);
    final rows = <(String, String)>[
      ('Flavor', appFlavor ?? '(none)'),
      ('Version', appVersion),
      ('API', cfg.api),
      ('Cognito', cfg.cognitoHost),
      ('Web', cfg.web),
      ('Auth', phase.name),
      (
        'Token expires',
        session.when(
          data: (t) => t == null ? '(no session)' : _hms(t),
          loading: () => '…',
          error: (_, _) => '(unreadable)',
        ),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 110, child: Text(k, style: _mono)),
                Expanded(child: SelectableText(v, style: _mono)),
              ],
            ),
          ),
      ],
    );
  }
}

/// When the stored access token runs out (the time only, never the token).
final FutureProvider<DateTime?> _sessionExpiry =
    FutureProvider.autoDispose<DateTime?>((ref) async {
      ref.watch(authControllerProvider);
      final s = await ref.watch(sessionStoreProvider).load();
      return s == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(s.expiresAt);
    });
