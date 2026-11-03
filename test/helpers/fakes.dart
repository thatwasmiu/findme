import 'package:findme/core/config/app_config.dart';
import 'package:findme/core/storage/prefs.dart';
import 'package:findme/features/auth/data/auth_repository.dart';
import 'package:findme/features/friends/data/friends_repository.dart';
import 'package:findme/features/shares/data/shares_repository.dart';
import 'package:findme/features/trail/data/track_repository.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements AuthRepository;

class MockTrack extends Mock implements TrackRepository;

class MockShares extends Mock implements SharesRepository;

class MockFriends extends Mock implements FriendsRepository;

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
  MemoryPrefs? prefs,
}) => [
  appConfigProvider.overrideWithValue(testConfig),
  authRepositoryProvider.overrideWithValue(auth),
  prefsProvider.overrideWithValue(prefs ?? MemoryPrefs()),
  if (track != null) trackRepositoryProvider.overrideWithValue(track),
  if (shares != null) sharesRepositoryProvider.overrideWithValue(shares),
  if (friends != null) friendsRepositoryProvider.overrideWithValue(friends),
];

/// A tall test screen, so long lazy lists build every row.
void tallView(WidgetTester t) {
  t.view
    ..physicalSize = const Size(1080, 6000)
    ..devicePixelRatio = 1;
  addTearDown(t.view.reset);
}
