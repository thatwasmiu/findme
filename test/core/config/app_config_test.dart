import 'package:findme/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

const full = {
  'API_URL': 'https://x.io/',
  'AUTHORITY':
      'https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_AbC',
  'CLIENT_ID': 'c',
  'WEB_ORIGIN': 'https://findme.test/',
};

void main() {
  test('reads all four keys; api and web drop trailing slashes', () {
    final c = AppConfig.fromMap(full);
    expect(c.api, 'https://x.io');
    expect(c.web, 'https://findme.test');
    expect(c.clientId, 'c');
    expect(c.cognitoHost, 'cognito-idp.ap-southeast-1.amazonaws.com');
  });

  test('a missing or empty key says how to fix it', () {
    for (final k in full.keys) {
      expect(
        () => AppConfig.fromMap({...full, k: ''}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('config/example.json'),
          ),
        ),
      );
      expect(
        () => AppConfig.fromMap({...full}..remove(k)),
        throwsA(isA<StateError>()),
      );
    }
  });

  test('a relative API_URL (as in the web config: /api) is refused', () {
    expect(
      () => AppConfig.fromMap(Map.of(full)..['API_URL'] = '/api'),
      throwsA(isA<StateError>()),
    );
  });
}
