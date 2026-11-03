import 'package:findme/core/theme/palette.dart';
import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/card_box.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:findme/features/trail/domain/trail_math.dart';
import 'package:flutter/material.dart';

const _medals = ['🥇', '🥈', '🥉'];
String _name(Stop s) => s.name ?? 'Một nơi xinh xinh';

/// One day: the diary (stays and the moves between them). Several days: the places you stayed longest
/// (the web's TrailPanel.tsx), in a sheet you can drag up.
class TrailSheet extends StatelessWidget {
  const TrailSheet({
    required this.track,
    required this.oneDay,
    required this.replaying,
    required this.onReplay,
    required this.onSelect,
    super.key,
  });

  final Track track;
  final bool oneDay;
  final bool replaying;
  final VoidCallback onReplay;
  final void Function(double lon, double lat) onSelect;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.22,
    minChildSize: 0.1,
    maxChildSize: 0.6,
    builder: (context, scroll) => CardBox(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
      child: ListView(
        controller: scroll,
        padding: EdgeInsets.zero,
        children: _rows(),
      ),
    ),
  );

  List<Widget> _rows() {
    final handle = Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Palette.lavender,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
    if (track.points.isEmpty && track.stops.isEmpty) {
      return [
        handle,
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Notice('Chưa có dấu chân nào trong khoảng này 🐾'),
        ),
      ];
    }
    if (!oneDay) {
      final top = topStops(track.stops);
      return [
        handle,
        const _Title('⭐ Chỗ dừng nhiều nhất'),
        for (final (i, s) in top.indexed)
          _Row(
            lead: i < 3 ? _medals[i] : '📍',
            name: _name(s),
            time: duration(s.seconds),
            onTap: () => onSelect(s.lon, s.lat),
          ),
        if (top.isEmpty) const Notice('Chưa dừng chỗ nào lâu hơn 5 phút'),
        const SizedBox(height: 16),
      ];
    }
    return [
      handle,
      Row(
        children: [
          const Expanded(child: _Title('📅 Nhật ký ngày')),
          if (track.points.length > 1)
            Pill(
              label: replaying ? '⏹ Dừng' : '▶️ Phát lại',
              selected: replaying,
              onTap: onReplay,
            ),
        ],
      ),
      for (final r in timeline(track.points, track.stops))
        switch (r) {
          StopEntry(:final stop) => _Row(
            when: '${hhmmIso(stop.start)} – ${hhmmIso(stop.end)}',
            name: '🐾 ${_name(stop)}',
            time: duration(stop.seconds),
            onTap: () => onSelect(stop.lon, stop.lat),
          ),
          MoveEntry(:final start, :final end, :final km, :final to) => _Row(
            when: '${hhmmSec(start)} – ${hhmmSec(end)}',
            name:
                '🛵 di chuyển · ${km.toStringAsFixed(1).replaceAll('.', ',')} km',
            time: duration(end - start),
            muted: true,
            onTap: () => onSelect(to.$1, to.$2),
          ),
        },
      const SizedBox(height: 16),
    ];
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.name,
    required this.time,
    required this.onTap,
    this.lead,
    this.when,
    this.muted = false,
  });

  final String? lead;
  final String? when;
  final String name;
  final String time;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (lead != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(lead!),
            ),
          if (when != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                when!,
                style: const TextStyle(color: Palette.muted, fontSize: 12),
              ),
            ),
          Expanded(
            child: Text(
              name,
              style: TextStyle(color: muted ? Palette.muted : Palette.ink),
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Palette.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
