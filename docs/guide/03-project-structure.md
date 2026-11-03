# 03. Project structure

## Folders

```
findme/
  lib/                      ← the app's Dart code (like web/src)
    main.dart               ← entry point: reads config, starts the app
    app.dart                ← picks the screen: welcome card or map
    core/                   ← shared by every feature
      config/               ← AppConfig (the four config values)
      errors/               ← AppError and its kinds (AuthExpired, NetworkError, …)
      network/              ← ApiClient: every API call goes through it
      storage/              ← Prefs: small settings kept on the phone
      theme/                ← Palette (the web's CSS colours), ThemeData
      time/                 ← "12 phút trước", "2 giờ 10 phút", "HH:mm"
      widgets/              ← Pill, CardBox, Notice (the web's .pill, .card, .notice)
    features/
      auth/                 ← sign-in with Cognito
      trail/                ← the map, paw prints, date filter, day diary
      replay/               ← ▶️ replay alone or together
      shares/               ← 🔗 share links
      friends/              ← 👥 friends
  test/                     ← tests, same folder layout as lib/
  integration_test/         ← a full-app test that runs on the emulator
  android/  ios/            ← native project shells (rarely touched)
  config/                   ← example.json (committed), dev.json / prod.json (yours, not committed)
  assets/images/            ← Hachiware
  docs/                     ← this guide, the design, the plan, HANDOFF.md
```

## Inside a feature: three layers

Each folder under `features/` has up to three sub-folders:

| Layer | Contains | Knows about Flutter? | Example |
|---|---|---|---|
| `domain/` | Data shapes and pure logic | No | `trail_math.dart`: `timeline()`, `tailFrom()` |
| `data/` | Talking to the outside world (API, storage) | No | `track_repository.dart`: `GET /track` |
| `presentation/` | Screens, widgets, and the **controllers** that hold state | Yes | `trail_controller.dart`, `map_view.dart` |

The rule: arrows point **down** only. Presentation uses data and domain; data uses domain; domain uses nothing.
This keeps the logic testable without a phone and lets you swap the API layer without touching screens.

Most `domain/` code is a line-by-line port of the web's TypeScript (`trail.ts`, `dateRange.ts`), with the web's own
tests ported too. When you change behaviour, change both, or the web and the app drift apart.

## How state works: Riverpod in two minutes

A **provider** is a named, shared piece of state or a shared object. Widgets **watch** providers and rebuild when they
change. Three kinds are used here:

```dart
// 1. A shared object (no changing state): the API client
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(...));

// 2. State with methods (a "controller"): the trail on screen
final trailControllerProvider = NotifierProvider<TrailController, TrailState>(TrailController.new);

// 3. Derived state: computed from other providers
final signedInProvider = Provider<bool>((ref) => ref.watch(authControllerProvider) == AuthPhase.signedIn);
```

In a widget:

```dart
class TopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(trailControllerProvider);           // rebuild when the trail changes
    final ctl = ref.read(trailControllerProvider.notifier);  // call methods, e.g. ctl.setRange(...)
    ...
  }
}
```

**Signing out wipes everything.** Every account-scoped controller (trail, replay, friends) does
`ref.watch(signedInProvider)` in its `build()`. When you sign out, that value changes, Riverpod rebuilds those
controllers, and they start empty. The next person to sign in on the phone never sees the previous account's data.

## One request, end to end

What happens when you tap **7 ngày**:

1. `DateFilter` (presentation) calls `onChange(presetRange(Preset.d7, now))`.
2. `TopBar` passed `TrailController.setRange` as that callback; it stores the range and calls `load()`.
3. `load()` asks `TrackRepository.fetch(range)` (data).
4. `TrackRepository` calls `ApiClient.send('GET', '/track', query: {...})`.
5. `ApiClient` gets a token from `AuthRepository.getAccessToken()` (renewing it if needed), sends the request with
   `Authorization: Bearer …`, and turns HTTP statuses into typed errors: 401 → `AuthExpired`, 403 →
   `AccountMissing`, no answer → `NetworkError`, other → `ApiStatus`.
6. `TrackRepository` turns the JSON into a `Track` (domain) or maps `ApiStatus(400)` to `HttpError(400)`.
7. Back in `load()`: success → new state; `AuthExpired` → sign out; `HttpError(400)` → "Chọn tối đa 31 ngày một lần
   nhé 📅".
8. Every widget watching `trailControllerProvider` (map, top bar, trail sheet) rebuilds.

## Where errors are turned into words

| Error | Mapped in | Shown as |
|---|---|---|
| HTTP status → `AppError` | `core/network/api_client.dart` | (nothing yet) |
| 400/404/409 → feature error | each `*_repository.dart` | (nothing yet) |
| `AppError` → Vietnamese text | the controller or sheet that made the call | the same words as the web |

Next: [04. Sign-in](04-auth.md).
