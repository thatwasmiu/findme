import 'package:findme/features/replay/domain/replay_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('replay pace: same time per print on every day, at least 10 s', () {
    expect(replayMs(101), 12000);
    expect(replayMs(1001), 120000);
    expect(replayMs(5), 10000);
    expect(replayMs(1001) / 1000, replayMs(101) / 100);
  });

  test('advance: whole span in totalMs at 1x, faster with speed, '
      'never past the end', () {
    expect(advance(0, 60000, 1, 60000, 1), 1);
    expect(advance(0, 30000, 1, 60000, 1), 0.5);
    expect(advance(0, 15000, 4, 60000, 1), 1);
    expect(advance(0.9, 30000, 1, 60000, 1), 1);
  });

  test('speeds cycle like the web', () {
    expect(speeds, [0.5, 1, 2, 4, 8]);
    expect(nextSpeed(1), 2);
    expect(nextSpeed(8), 0.5);
  });
}
