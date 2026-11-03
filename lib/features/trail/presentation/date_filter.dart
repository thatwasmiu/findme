import 'package:findme/core/time/format.dart';
import 'package:findme/core/widgets/pill.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:flutter/material.dart';

/// Presets plus 📅 for a picked range (the web's DateFilter.tsx). At most 31 days: the server refuses more.
class DateFilter extends StatefulWidget {
  const DateFilter({
    required this.value,
    required this.onChange,
    super.key,
    this.now,
  });

  final DateRange value;
  final ValueChanged<DateRange> onChange;
  final DateTime Function()? now;

  @override
  State<DateFilter> createState() => _DateFilterState();
}

class _DateFilterState extends State<DateFilter> {
  Object _active = Preset.today; // a Preset, or 'custom'

  DateTime _now() => (widget.now ?? DateTime.now)();

  Future<void> _pick() async {
    final from = DateTime.parse(widget.value.from).toLocal();
    final to = DateTime.parse(widget.value.to).toLocal();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: _now(),
      initialDateRange: DateTimeRange(
        start: DateUtils.dateOnly(from),
        end: DateUtils.dateOnly(to.isAfter(_now()) ? _now() : to),
      ),
      helpText: 'Chọn ngày',
      saveText: 'Xong',
    );
    if (picked == null) return;
    setState(() => _active = 'custom');
    widget.onChange(customRange(ymd(picked.start), ymd(picked.end)));
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final p in Preset.values)
        Pill(
          label: p.label,
          selected: _active == p,
          onTap: () {
            setState(() => _active = p);
            widget.onChange(presetRange(p, _now()));
          },
        ),
      Pill(
        label: '📅',
        style: PillStyle.lav,
        selected: _active == 'custom',
        semanticLabel: 'Chọn ngày',
        onTap: _pick,
      ),
    ],
  );
}
