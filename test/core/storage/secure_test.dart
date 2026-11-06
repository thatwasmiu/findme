import 'package:findme/core/storage/secure.dart';
import 'package:findme/features/auth/data/session_store.dart';
import 'package:findme/features/tracker/data/tracker_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readable after the first unlock: a locked iPhone still tracks', () {
    expect(
      backgroundSafeStorage.iOptions.accessibility,
      KeychainAccessibility.first_unlock,
    );
  });

  test('the session and the ingest token both use it', () {
    expect(
      identical(SecureSessionStore().storage, backgroundSafeStorage),
      isTrue,
    );
    expect(
      identical(SecureTrackerStore().storage, backgroundSafeStorage),
      isTrue,
    );
  });
}
