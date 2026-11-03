import 'package:findme/core/time/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ago / duration', () {
    final now = DateTime.parse('2026-10-27T12:00:00Z');

    test('reads like a friend would say it', () {
      expect(ago('2026-10-27T11:59:45Z', now: now), 'vừa xong');
      expect(ago('2026-10-27T11:48:00Z', now: now), '12 phút trước');
      expect(ago('2026-10-27T09:00:00Z', now: now), '3 giờ trước');
      expect(ago('2026-10-26T12:00:00Z', now: now), '1 ngày trước');
      expect(ago('2026-10-24T12:00:00Z', now: now), '3 ngày trước');
    });

    test('durations', () {
      expect(duration(20), '1 phút');
      expect(duration(45 * 60), '45 phút');
      expect(duration(2 * 3600), '2 giờ');
      expect(duration(2 * 3600 + 10 * 60), '2 giờ 10 phút');
    });
  });

  group('remaining', () {
    final now = DateTime.parse('2026-10-27T12:00:00Z');
    String at(int ms) =>
        now.add(Duration(milliseconds: ms)).toUtc().toIso8601String();

    test('says how long a link still lives', () {
      expect(remaining(at(30 * 1000), now: now), 'còn 1 phút');
      expect(remaining(at(25 * 60000), now: now), 'còn 25 phút');
      expect(remaining(at(5 * 3600000), now: now), 'còn 5 giờ');
      expect(remaining(at(3 * 86400000), now: now), 'còn 3 ngày');
      expect(remaining(at(-1000), now: now), 'đã hết hạn');
    });
  });

  test('hhmm is 24 h local HH:mm', () {
    expect(hhmm(DateTime(2026, 10, 27, 7, 5)), '07:05');
    expect(hhmm(DateTime(2026, 10, 27, 23, 59)), '23:59');
  });

  test('dm turns YYYY-MM-DD into DD/MM', () {
    expect(dm('2026-10-03'), '03/10');
  });
}
