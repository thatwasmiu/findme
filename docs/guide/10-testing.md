# 10. Testing

Three kinds of tests, from fast and small to slow and complete:

| Kind | Folder | Runs on | What it checks | Example |
|---|---|---|---|---|
| Unit | `test/core`, `test/features/*/domain`, `*/data` | your PC, no device | pure logic, API mapping | `trail_math_test.dart`, `track_repository_test.dart` |
| Widget | `test/features/*/presentation`, `test/app_test.dart` | your PC, no device (a fake screen) | a widget renders and reacts to taps | `trail_ui_test.dart`, `shares_sheet_test.dart` |
| Integration | `integration_test/` | emulator or phone | the whole app on a real device | `integration_test/app_test.dart` |

## Running

```powershell
flutter test                                   # all unit + widget tests (~15 s)
flutter test test/features/trail               # one folder
flutter test --name "stale load"               # tests whose name contains this
flutter test --coverage                        # writes coverage/lcov.info
flutter test integration_test --flavor dev --dart-define-from-file=config/example.json   # emulator running
```

The tests assume **Vietnam time** (UTC+7), like the web tests. Your PC is set to it; CI sets `TZ=Asia/Ho_Chi_Minh`.

## Rule: tests never touch the network

- **API calls:** `test/helpers/fake_adapter.dart` plugs a fake into dio. It records every request and answers what
  the test says: `FakeAdapter((req) => (status: 400, body: {'error': 'label'}))`.
- **Repositories:** replaced with **mocktail** mocks: `when(() => repo.fetch(any())).thenAnswer((_) async => track)`.
- **Providers:** `test/helpers/fakes.dart` → `baseOverrides(...)` swaps config, auth, prefs and repositories in a
  `ProviderScope` / `ProviderContainer`.
- **Map tiles:** `MapView(showTiles: false)`.

## Writing a unit test

```dart
test('durations', () {
  expect(duration(45 * 60), '45 phút');
});
```

## Writing a widget test

```dart
testWidgets('empty range', (t) async {
  await t.pumpWidget(sheet(Track.empty));                 // build the widget
  expect(find.text('Chưa có dấu chân nào trong khoảng này 🐾'), findsOneWidget);
});
```

- `pumpWidget` builds; `pump()` advances one frame; `pumpAndSettle()` waits until animations finish.
- `find.text`, `find.byKey`, `find.bySemanticsLabel` locate widgets; `t.tap(...)`, `t.enterText(...)` act.
- Long lists build lazily; call `tallView(t)` to make the fake screen tall enough.

## Testing timers

`fake_async` controls time: `fakeAsync((f) { ...; f.elapse(Duration(seconds: 7)); ... })`. See
`trail_controller_test.dart`.

## When a test fails

The output shows `Expected:` and `Actual:` and the test file line. Read the test name, then the line. Fix the code,
not the test, unless the test is wrong about what the web does.

Next: [11. Code generation, lints, formatting](11-codegen-lints-format.md).
