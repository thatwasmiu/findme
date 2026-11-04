import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SecureTrackerStore s;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    s = SecureTrackerStore();
  });

  test('saveToken trims spaces and newlines', () async {
    await s.saveToken('  ab12\n', 'sub-1');
    expect((await s.token())!.token, 'ab12');
  });

  test('empty token refused', () async {
    expect(() => s.saveToken(' \n ', 'sub-1'), throwsArgumentError);
    expect(await s.token(), isNull);
  });

  test('token round-trip with sub', () async {
    await s.saveToken('ab12', 'sub-1');
    expect(await s.token(), (token: 'ab12', sub: 'sub-1'));
  });

  test('enabled defaults false and is a plain prefs bool', () async {
    expect(await s.enabled(), isFalse);
    await s.setEnabled(on: true);
    expect(await s.enabled(), isTrue);
    // Android's boot receiver reads this key natively.
    expect(
      (await SharedPreferences.getInstance()).getBool('findme.tracking'),
      isTrue,
    );
  });

  test('forget clears token and flag', () async {
    await s.saveToken('ab12', 'sub-1');
    await s.setEnabled(on: true);
    await s.forget();
    expect(await s.token(), isNull);
    expect(await s.enabled(), isFalse);
  });
}
