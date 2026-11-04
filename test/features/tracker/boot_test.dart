import 'package:findme/features/tracker/boot.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/tracker_fakes.dart';

void main() {
  test('headless start (Android boot) resumes tracking', () async {
    final c = await startTrackerHeadless(baseOverrides(auth: fakeAuth()));
    addTearDown(c.dispose);
    expect(
      (c.read(trackerControllerProvider.notifier) as FakeTracker).resumes,
      1,
    );
  });
}
