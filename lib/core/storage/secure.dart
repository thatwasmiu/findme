import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keychain / Keystore for the sign-in session and the ingest token. iOS: readable after the first unlock since the
/// phone started (not only while unlocked), so a tracker running in a locked phone's pocket can still read them.
const backgroundSafeStorage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
