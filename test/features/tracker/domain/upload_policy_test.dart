import 'package:findme/features/tracker/domain/upload_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);
  bool go(int queued, {Duration? sinceOk, Duration? waitLeft}) => shouldUpload(
    queued: queued,
    lastOk: sinceOk == null ? null : now.subtract(sinceOk),
    now: now,
    notBefore: waitLeft == null ? null : now.add(waitLeft),
  );

  test('backoff doubles from 1 min, capped at 30', () {
    expect(
      [for (var i = 1; i <= 7; i++) backoff(i).inMinutes],
      [
        1, 2, 4, 8, 16, 30, 30, //
      ],
    );
  });

  test('empty queue never uploads', () {
    expect(go(0), isFalse);
  });

  test('50 queued uploads at once', () {
    expect(go(50, sinceOk: const Duration(seconds: 5)), isTrue);
  });

  test('few queued wait 5 min after the last ok', () {
    expect(go(3, sinceOk: const Duration(minutes: 4)), isFalse);
    expect(go(3, sinceOk: const Duration(minutes: 6)), isTrue);
  });

  test('never uploaded -> upload', () {
    expect(go(1), isTrue);
  });

  test('inside backoff window -> wait, even when full', () {
    expect(go(500, waitLeft: const Duration(seconds: 30)), isFalse);
  });
}
