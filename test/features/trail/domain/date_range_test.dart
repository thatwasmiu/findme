import 'package:findme/features/trail/domain/date_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('yesterday / isOneDay', () {
    final now = DateTime.parse('2026-10-27T05:00:00Z'); // 12:00 in Hà Nội
    test('yesterday is the whole previous local day', () {
      expect(
        presetRange(Preset.yesterday, now),
        const DateRange(
          from: '2026-10-25T17:00:00.000Z',
          to: '2026-10-26T16:59:59.999Z',
        ),
      );
    });
    test('one-day ranges vs longer ones', () {
      expect(isOneDay(presetRange(Preset.today, now)), isTrue);
      expect(isOneDay(presetRange(Preset.yesterday, now)), isTrue);
      expect(isOneDay(customRange('2026-10-01', '2026-10-01')), isTrue);
      expect(isOneDay(presetRange(Preset.d7, now)), isFalse);
    });
  });

  group('dateRange', () {
    final now = DateTime.parse('2026-10-27T05:00:00Z');
    test('today starts at local midnight, in JS ISO form', () {
      expect(presetRange(Preset.today, now).from, '2026-10-26T17:00:00.000Z');
      expect(presetRange(Preset.today, now).to, '2026-10-27T05:00:00.000Z');
    });
    test('7d starts local midnight 6 days before today', () {
      expect(presetRange(Preset.d7, now).from, '2026-10-20T17:00:00.000Z');
    });
    test('30d', () {
      expect(presetRange(Preset.d30, now).from, '2026-09-27T17:00:00.000Z');
    });
    test('customRange covers the whole local day', () {
      expect(
        customRange('2026-10-01', '2026-10-01'),
        const DateRange(
          from: '2026-09-30T17:00:00.000Z',
          to: '2026-10-01T16:59:59.999Z',
        ),
      );
    });
    test('preset labels are the web ones', () {
      expect(Preset.values.map((p) => p.label).toList(), [
        'Hôm nay',
        'Hôm qua',
        '7 ngày',
        '30 ngày',
      ]);
    });
    test('isoMs always has milliseconds and Z', () {
      expect(
        isoMs(DateTime.utc(2026, 1, 2, 3, 4, 5, 6, 7)),
        '2026-01-02T03:04:05.006Z',
      );
    });
  });

  group('isLive', () {
    final now = DateTime(2026, 10, 28, 15);
    test('ranges reaching today keep refreshing; past days do not', () {
      expect(
        isLive(presetRange(Preset.today, DateTime(2026, 10, 28, 9)), now: now),
        isTrue,
      );
      expect(isLive(presetRange(Preset.d7, now), now: now), isTrue);
      expect(isLive(customRange('2026-10-20', '2026-10-28'), now: now), isTrue);
      expect(isLive(presetRange(Preset.yesterday, now), now: now), isFalse);
      expect(
        isLive(customRange('2026-10-20', '2026-10-27'), now: now),
        isFalse,
      );
    });
  });

  group('liveTo', () {
    test('a range reaching today ends now; a past range keeps its end', () {
      final now = DateTime(2026, 10, 28, 15);
      expect(
        liveTo(presetRange(Preset.today, DateTime(2026, 10, 28, 9)), now: now),
        isoMs(now),
      );
      final y = presetRange(Preset.yesterday, now);
      expect(liveTo(y, now: now), y.to);
    });
  });
}
