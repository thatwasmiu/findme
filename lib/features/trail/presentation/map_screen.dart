import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/friends/presentation/friends_sheet.dart';
import 'package:findme/features/replay/presentation/replay_bar.dart';
import 'package:findme/features/replay/presentation/replay_controller.dart';
import 'package:findme/features/shares/presentation/shares_sheet.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/presentation/map_view.dart';
import 'package:findme/features/trail/presentation/top_bar.dart';
import 'package:findme/features/trail/presentation/trail_controller.dart';
import 'package:findme/features/trail/presentation/trail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in screen: map, top bar (or the replay bar), trail sheet. Pauses polling in the background.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.showTiles = true});

  final bool showTiles;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onHide: () {
        ref.read(trailControllerProvider.notifier).paused();
        ref.read(friendsControllerProvider.notifier).paused();
      },
      onShow: () {
        ref.read(trailControllerProvider.notifier).resumed();
        ref.read(friendsControllerProvider.notifier).resumed();
      },
    );
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  void _replay() {
    final replay = ref.read(replayControllerProvider.notifier);
    if (ref.read(replayControllerProvider) != null) return replay.stop();
    final s = ref.read(trailControllerProvider);
    replay.start(
      s.track.points,
      others: [for (final f in ref.read(friendsOnMapProvider)) f.points],
      live: isLive(s.range, now: ref.read(nowProvider)()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trail = ref.watch(trailControllerProvider);
    final replay = ref.watch(replayControllerProvider);
    final friends = ref.watch(friendsOnMapProvider);
    final incoming = ref.watch(
      friendsControllerProvider.select((s) => s.relations.incoming.length),
    );
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapView(
              points: trail.track.points,
              stops: trail.track.stops,
              last: trail.track.last,
              friends: friends,
              flyTo: ref.watch(flyToProvider),
              showTiles: widget.showTiles,
              replay: replay == null
                  ? null
                  : ReplayView(
                      track: replay.track,
                      pos: replay.pos,
                      clock: replay.clock ? replay.clockAt : null,
                      own: replay.own,
                    ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: replay != null
                  ? const ReplayBar()
                  : TopBar(
                      incomingCount: incoming,
                      onShare: () => SharesSheet.open(context),
                      onFriends: () => FriendsSheet.open(context),
                    ),
            ),
          ),
          TrailSheet(
            track: trail.track,
            oneDay: isOneDay(trail.range),
            replaying: replay != null,
            onReplay: _replay,
            onSelect: (lon, lat) =>
                ref.read(flyToProvider.notifier).go(lon, lat),
          ),
        ],
      ),
    );
  }
}
