import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

  test(
    "owner: the token's account, else the one that switched it on",
    () async {
      expect(await s.owner(), isNull);
      await s.setOwner('sub-9');
      expect(await s.owner(), 'sub-9');
      await s.saveToken('t', 'sub-1');
      expect(await s.owner(), 'sub-1');
      await s.forget();
      expect(await s.owner(), isNull);
    },
  );

  test(
    'indicator: off by default, kept across forget (a phone setting)',
    () async {
      expect(await s.indicator(), isFalse);
      await s.setIndicator(on: true);
      await s.forget();
      expect(await s.indicator(), isTrue);
    },
  );

  test('upload interval: 1 min by default, kept across forget', () async {
    expect(await s.uploadEvery(), const Duration(minutes: 1));
    await s.setUploadEvery(const Duration(seconds: 10));
    await s.forget();
    expect(await s.uploadEvery(), const Duration(seconds: 10));
  });

  test('a token that cannot be read is not "no token"', () async {
    final locked = _LockedStorage();
    expect(
      () => SecureTrackerStore(locked).token(),
      throwsA(isA<StorageUnreadable>()),
    );
  });
}

/// The Keychain while the iPhone is locked: every read fails.
class _LockedStorage extends Mock implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => throw PlatformException(code: '-25308', message: 'locked');
}
