import 'dart:async';

import 'package:findme/core/theme/palette.dart';
import 'package:findme/features/auth/presentation/account_sheet.dart';
import 'package:findme/features/bag/presentation/bag_sheet.dart';
import 'package:findme/features/friends/presentation/friends_controller.dart';
import 'package:findme/features/friends/presentation/friends_sheet.dart';
import 'package:findme/features/pins/domain/pin.dart';
import 'package:findme/features/pins/presentation/add_pin_sheet.dart';
import 'package:findme/features/pins/presentation/friend_pins_controller.dart';
import 'package:findme/features/pins/presentation/pin_sheet.dart';
import 'package:findme/features/pins/presentation/pins_controller.dart';
import 'package:findme/features/replay/presentation/replay_bar.dart';
import 'package:findme/features/replay/presentation/replay_controller.dart';
import 'package:findme/features/shares/presentation/shares_sheet.dart';
import 'package:findme/features/tracker/data/trip_channel.dart';
import 'package:findme/features/tracker/presentation/track_button.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/tracker/presentation/tracker_sheet.dart';
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
        ref.read(pinsControllerProvider.notifier).paused();
        ref.read(friendPinsControllerProvider.notifier).paused();
        // Leaving the app: what the tracker queued goes now (iOS may suspend it soon).
        unawaited(ref.read(trackerControllerProvider.notifier).flush());
      },
      onShow: () {
        ref.read(trailControllerProvider.notifier).resumed();
        ref.read(friendsControllerProvider.notifier).resumed();
        ref.read(pinsControllerProvider.notifier).resumed();
        ref.read(friendPinsControllerProvider.notifier).resumed();
        // A trip ended elsewhere (the web, its timer) stops GPS here too.
        unawaited(ref.read(trackerControllerProvider.notifier).syncTrip());
      },
    );
    // Opened by the Quick Settings tile's long-press: straight to the trip presets.
    unawaited(
      ref.read(tripChannelProvider).takePicker().then((open) {
        if (open && mounted) unawaited(TrackerSheet.open(context));
      }),
    );
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  bool _adding = false;
  Spot? _spot; // where a new pin will go, while adding
  String? _openPinId;

  /// The trail sheet's height (fraction of the screen): the round buttons ride just above it.
  double _sheetExtent = TrailSheet.initialExtent;

  void _closeSheets() => setState(() {
    _adding = false;
    _spot = null;
    _openPinId = null;
  });

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
    // The tile was long-pressed while the app runs.
    ref.listen(
      trackerControllerProvider.select((s) => s.picker),
      (_, _) => unawaited(TrackerSheet.open(context)),
    );
    final trail = ref.watch(trailControllerProvider);
    final replay = ref.watch(replayControllerProvider);
    final friends = ref.watch(friendsOnMapProvider);
    final incoming = ref.watch(
      friendsControllerProvider.select((s) => s.relations.incoming.length),
    );
    // Friends' photos switched to "Chia sẻ", for the friends shown on the map. Yours first, so a bubble you share
    // opens as yours.
    final pins = [
      ...ref.watch(pinsControllerProvider),
      ...visibleFriendPins(
        ref.watch(friendPinsControllerProvider),
        ref.watch(friendsControllerProvider.select((s) => s.shown)),
      ),
    ];
    final openPin = pins.where((p) => p.id == _openPinId).firstOrNull;
    final pinOwner = openPin?.sub == null
        ? null
        : ref
              .read(friendsControllerProvider)
              .relations
              .friends
              .where((f) => f.id == openPin!.sub)
              .firstOrNull
              ?.name;
    final sheet = _adding
        ? AddPinSheet(
            stops: trail.track.stops,
            onSpot: (lat, lon) {
              setState(() => _spot = (lat: lat, lon: lon));
              ref.read(flyToProvider.notifier).go(lon, lat);
            },
            onAdded: () {
              setState(() {
                _adding = false;
                _spot = null;
              });
              unawaited(ref.read(pinsControllerProvider.notifier).refresh());
            },
            onClose: _closeSheets,
          )
        : openPin == null
        ? null
        : PinSheet(
            key: ValueKey(openPin.id),
            pin: openPin,
            by: pinOwner,
            onClose: _closeSheets,
          );
    return PopScope(
      canPop: sheet == null, // Android back closes the sheet, not the app
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSheets();
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, box) {
            final height = box.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: MapView(
                    pins: pins,
                    onPin: (p) => setState(() {
                      _adding = false;
                      _spot = null;
                      _openPinId = p.id;
                    }),
                    pickAt: _adding ? _spot : null,
                    myAvatar: ref.watch(
                      friendsControllerProvider.select((s) => s.me?.avatar),
                    ),
                    onFriend: (f) => openFriendBag(
                      context,
                      ref,
                      id: f.id,
                      name: f.name,
                      avatar: f.avatar,
                    ),
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
                            onAccount: () => AccountSheet.open(context),
                          ),
                  ),
                ),
                if (replay == null && sheet == null)
                  Positioned(
                    right: 12,
                    left: 12,
                    bottom: _sheetExtent * height + 12,
                    // Hidden once the sheet is dragged high, so they never sit on the top bar.
                    child: IgnorePointer(
                      ignoring: _sheetExtent > 0.4,
                      child: AnimatedOpacity(
                        opacity: _sheetExtent > 0.4 ? 0 : 1,
                        duration: const Duration(milliseconds: 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const TrackButton(),
                            const SizedBox(height: 12),
                            _CameraButton(
                              onTap: () => setState(() {
                                _openPinId = null;
                                _adding = true;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                NotificationListener<DraggableScrollableNotification>(
                  onNotification: (n) {
                    setState(() => _sheetExtent = n.extent);
                    return false;
                  },
                  child: TrailSheet(
                    track: trail.track,
                    oneDay: isOneDay(trail.range),
                    replaying: replay != null,
                    onReplay: _replay,
                    onSelect: (lon, lat) =>
                        ref.read(flyToProvider.notifier).go(lon, lat),
                  ),
                ),
                if (sheet != null)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      minimum: const EdgeInsets.only(bottom: 14),
                      child: sheet,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 📷 Chụp ảnh ở đây: opens the add-a-photo sheet.
class _CameraButton extends StatelessWidget {
  const _CameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Chụp ảnh ở đây',
    excludeSemantics: true,
    child: Material(
      color: Palette.pink,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Palette.pink,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 56,
          child: Center(child: Text('📷', style: TextStyle(fontSize: 24))),
        ),
      ),
    ),
  );
}
