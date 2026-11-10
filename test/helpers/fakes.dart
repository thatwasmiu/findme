import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/friends/data/friends_repository.dart';
import 'package:findme/features/friends/domain/friend_models.dart';
import 'package:findme/features/pins/data/pins_repository.dart';
import 'package:findme/features/shares/data/shares_repository.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:findme/features/tracker/presentation/tracker_controller.dart';
import 'package:findme/features/trail/data/track_repository.dart';
import 'package:findme/features/trail/domain/date_range.dart';
import 'package:findme/features/trail/domain/models.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'tracker_fakes.dart';

class MockAuth extends Mock implements AuthRepository;

class MockTrack extends Mock implements TrackRepository;

class MockShares extends Mock implements SharesRepository;

class MockFriends extends Mock implements FriendsRepository;

class MockPins extends Mock implements PinsRepository;

/// Prefs kept in memory.
class MemoryPrefs implements Prefs {
  (double, double)? start;
  List<String> shown = [];

  @override
  Future<(double, double)?> startPoint() async => start;
  @override
  Future<void> rememberStart(double lon, double lat) async =>
      start = (lon, lat);
  @override
  Future<List<String>> shownFriends() async => shown;
  @override
  Future<void> saveShownFriends(List<String> ids) async => shown = [...ids];
  ({String who, String day, TodayCache cache})? today;
  @override
  Future<TodayCache?> readToday(String who, String day) async =>
      today?.who == who && today?.day == day ? today!.cache : null;
  @override
  Future<void> writeToday(
    String who,
    String day,
    Track mine,
    Map<String, FriendTrail> friends,
  ) async =>
      today = (who: who, day: day, cache: (mine: mine, friends: friends));
  @override
  Future<void> clearToday() async => today = null;

  @override
  Future<void> clear() async {
    start = null;
    shown = [];
    today = null;
  }
}

/// `fetch` answers [answer]'s trail for any range and options (no friends' parts).
void stubFetch(MockTrack t, Future<Track> Function(DateRange r) answer) =>
    when(
      () => t.fetch(
        any(),
        have: any(named: 'have'),
        friends: any(named: 'friends'),
      ),
    ).thenAnswer(
      (i) async =>
          TrackAnswer(await answer(i.positionalArguments.single as DateRange)),
    );

/// A Look Back with no pins.
MockPins quietPins() {
  final p = MockPins();
  when(p.openPins).thenAnswer((_) async => const []);
  when(() => p.mediaUrl(any())).thenAnswer(
    (i) => 'https://findme.test/lb/media/${i.positionalArguments.single}',
  );
  when(() => p.mediaHeaders).thenReturn(const {});
  return p;
}

/// A friends API with no friends and no requests.
MockFriends quietFriends() {
  final f = MockFriends();
  when(f.me).thenAnswer((_) async => const Me(name: 'Đạt', friendCode: 'K'));
  when(f.relations).thenAnswer((_) async => Relations.empty);
  return f;
}

const testConfig = AppConfig(
  apiUrl: 'https://api.test',
  authority: 'https://cognito-idp.x.amazonaws.com/p',
  clientId: 'c',
  webOrigin: 'https://findme.test',
);

/// A signed-in (or not) auth fake: `getAccessToken` answers [token].
MockAuth fakeAuth({String? token = 't'}) {
  final a = MockAuth();
  when(a.getAccessToken).thenAnswer((_) async => token);
  when(a.logout).thenAnswer((_) async {});
  return a;
}

List<Override> baseOverrides({
  required MockAuth auth,
  MockTrack? track,
  MockShares? shares,
  MockFriends? friends,
  MockPins? pins,
  MemoryPrefs? prefs,
  MemoryTrackerStore? trackerStore,
  bool fakeTracker = true,
}) => [
  appConfigProvider.overrideWithValue(testConfig),
  authRepositoryProvider.overrideWithValue(auth),
  prefsProvider.overrideWithValue(prefs ?? MemoryPrefs()),
  if (track != null) trackRepositoryProvider.overrideWithValue(track),
  if (shares != null) sharesRepositoryProvider.overrideWithValue(shares),
  friendsRepositoryProvider.overrideWithValue(friends ?? quietFriends()),
  pinsRepositoryProvider.overrideWithValue(pins ?? quietPins()),
  trackerStoreProvider.overrideWithValue(trackerStore ?? MemoryTrackerStore()),
  if (fakeTracker) trackerControllerProvider.overrideWith(FakeTracker.new),
];

/// A tall test screen, so long lazy lists build every row.
void tallView(WidgetTester t) {
  t.view
    ..physicalSize = const Size(1080, 6000)
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
}
