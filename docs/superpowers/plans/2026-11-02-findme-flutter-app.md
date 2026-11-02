# Find Me Flutter App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Flutter app (Android now, iOS-ready) that does what the `travel-heatmap/web` viewer does for normal users, against the same API and Cognito pool, with the same look, plus beginner docs and CI.

**Architecture:** Feature-first folders (`auth`, `trail`, `replay`, `shares`, `friends`), each split into `data` / `domain` / `presentation`, with shared `core/`. Pure logic is ported one-to-one from the web's TypeScript together with its tests. Riverpod providers own state and polling; every account-scoped provider depends on the session, so signing out drops all of it.

**Tech Stack:** Flutter stable + Dart 3, flutter_map (OSM), Riverpod (+ riverpod_generator), go_router, dio, freezed + json_serializable, flutter_secure_storage, shared_preferences, share_plus, very_good_analysis, mocktail, http_mock_adapter, fake_async, integration_test.

**Spec:** `docs/superpowers/specs/2026-11-02-findme-flutter-app-design.md`. **Behaviour source of truth:** `C:\Users\DatNT4\Desktop\works\travel-heatmap\web\src` (abbreviated `WEB/` below). Read the named web file before each task; it is the detailed spec.

## Global Constraints

- Feature parity with `WEB/` for normal users; **no admin screen** (admin login → "no account" screen → sign out).
- No location recording, no backend/API change, no in-app public share page (`ShareView`).
- UI text Vietnamese, copied **verbatim** from the named web file (emoji included). No i18n framework.
- Palette from `WEB/styles.css :root`: pink `#ec4899`, pink-soft `#fce7f3`, lavender `#ede9fe`, ink `#3f2a3a`, muted `#9b7b92`, card `rgba(255,255,255,0.95)`, page background `#fff7fb`, error text `#be123c`, card radius 22, pills fully rounded. Font Nunito (bundled TTF, OFL, in `assets/fonts/`).
- "Today", presets and clock labels use the **device local time**, exactly like the web.
- Tokens only in `flutter_secure_storage`. Never log tokens, coordinates, share ids, friend codes, emails or passwords. `debugPrint` only behind `kDebugMode`.
- Tests never touch the network (dio is mocked with `http_mock_adapter`, repositories with mocktail).
- Android application id `app.findme.mobile`; dev flavor suffix `.dev`, app label "Find Me Dev". iOS bundle id `app.findme.mobile`.
- Config keys (from `--dart-define-from-file`): `API_URL`, `AUTHORITY`, `CLIENT_ID`, `WEB_ORIGIN`. Files `config/dev.json`, `config/prod.json` are gitignored; `config/example.json` committed.
- Every command in docs is copy-pasteable in Windows PowerShell. Docs in English, written for someone who has never built a mobile app.
- `flutter analyze` clean and `dart format --set-exit-if-changed .` clean before every commit. Generated code (`*.g.dart`, `*.freezed.dart`) **is committed** (beginner can run the app without running build_runner first; CI checks it is up to date).
- After a task, run `graphify update .` only if `graphify-out/` exists in this repo.

## Calls made in this plan (not in the spec)

- iOS has no flavors/schemes: creating Xcode schemes needs a Mac. iOS builds take config from `--dart-define-from-file` only; a "later" docs note covers adding schemes.
- Font bundled rather than `google_fonts` (works offline, no runtime fetch in tests).
- One `ApiClient` maps 401 → `AuthExpired`, 403 → `AccountMissing`; each repository maps its own 400/404/409 like the matching web function.

## Review Focus

1. **Offline or flaky network during a quiet refresh** → keep what is on screen, no error banner, session kept; next tick retries. (Task 9 test `quiet refresh failure keeps trail and shows no error`; Task 5 test `offline refresh keeps session`.)
2. **Refresh token expired while polling** → phase becomes signed out and every account-scoped provider is empty (no trail, friends, shown friends' data, replay). (Task 7 test `sign out wipes account state`; Task 13 test `friends state cleared on sign out`.)
3. **User switches range while a load is in flight** → the stale response never replaces the new range's data. (Task 9 test `stale load is ignored`.)
4. **App goes to background** → no polling while paused; on resume an immediate refresh and delay back to 7 s. (Task 9 test `resume refreshes at once and resets delay`.)
5. **Stop without a name / friend never seen today / share already expired** → fallbacks "Một nơi xinh xinh", "chưa thấy hôm nay", "đã hết hạn" with only Gia hạn / 🐾 / Xoá buttons. (Tasks 10, 12, 13 widget tests named below.)

---

## File Structure

```
findme/
  pubspec.yaml  analysis_options.yaml  build.yaml  README.md  CLAUDE.md  .gitignore
  config/example.json                     # committed; dev.json, prod.json gitignored
  assets/images/hachiware.webp            # copied from travel-heatmap/web/public
  assets/fonts/Nunito-*.ttf
  android/app/build.gradle.kts            # productFlavors dev/prod
  lib/
    main.dart                             # one entry; flavor = config, not code
    app.dart                              # MaterialApp.router + theme
    core/config/app_config.dart           # AppConfig.fromEnvironment()
    core/network/api_client.dart          # dio + bearer + 401/403 mapping
    core/errors/app_errors.dart           # sealed AppError family
    core/storage/prefs.dart               # start view, shown friends (shared_preferences)
    core/theme/app_theme.dart  core/theme/palette.dart
    core/widgets/pill.dart  core/widgets/card_box.dart  core/widgets/notice.dart
    core/time/format.dart                 # ago, duration, hhmm, remaining, dm
    features/auth/data/cognito_api.dart  session_store.dart  auth_repository.dart
    features/auth/presentation/auth_controller.dart  welcome_screen.dart  sign_in_form.dart
    features/trail/domain/models.dart  trail_math.dart  date_range.dart  colors.dart
    features/trail/data/track_repository.dart
    features/trail/presentation/trail_controller.dart  map_screen.dart  paw_layer.dart
      top_bar.dart  date_filter.dart  trail_sheet.dart  start_view.dart
    features/replay/domain/replay_math.dart
    features/replay/presentation/replay_controller.dart  replay_bar.dart
    features/shares/domain/share.dart  features/shares/data/shares_repository.dart
    features/shares/presentation/shares_sheet.dart  shares_controller.dart
    features/friends/domain/friend_models.dart  features/friends/data/friends_repository.dart
    features/friends/presentation/friends_controller.dart  friends_sheet.dart
  test/ (mirrors lib/)   integration_test/app_test.dart
  .github/workflows/ci.yml
  docs/guide/00-…md … 09-…md  docs/guide/README.md  docs/guide/cheatsheet.md  docs/HANDOFF.md
```

---

### Task 0: Toolchain and empty project that runs

Owner's machine today: no Flutter, no Android SDK; Java 17 and git present.

**Files:**
- Create: `docs/guide/README.md`, `docs/guide/00-flutter-for-web-devs.md`, `docs/guide/01-install-tools-windows.md`
- Create (by `flutter create`): project skeleton in `findme/`
- Create: `.gitignore` additions, `analysis_options.yaml`, `CLAUDE.md`, `README.md`, `docs/HANDOFF.md`

**Interfaces:**
- Produces: a buildable Flutter project named `findme`, org `app.findme`, platforms android + ios.

- [ ] **Step 1: Write docs chapters 00 and 01.** 00: what Flutter/Dart is, how an app differs from the PWA, concept map (component → widget, hooks/useState → Riverpod provider, fetch → dio, localStorage → secure storage / shared_preferences, Vite dev server → `flutter run` + hot reload, vitest → `flutter test`). 01: install Flutter SDK (zip to `C:\src\flutter`, add `C:\src\flutter\bin` to user PATH), Android Studio (SDK, Platform Tools, Command-line Tools, an emulator "Pixel 7, API 35"), `flutter doctor --android-licenses`, VS Code + Flutter extension, reading `flutter doctor` output. README index lists all chapters planned in the spec §6.
- [ ] **Step 2: Owner installs tools following chapter 01.** Stop and ask the owner; do not install GUI tools for them.
- [ ] **Step 3: Verify toolchain.** Run: `flutter doctor -v` → Expected: `[√] Flutter`, `[√] Android toolchain`, `[√] Android Studio`; Xcode line absent/failed is expected on Windows.
- [ ] **Step 4: Create project.** Run in `findme/`: `flutter create --org app.findme --project-name findme --platforms android,ios .` then `git init` and set `defaultConfig.applicationId = "app.findme.mobile"` (Android) and the iOS bundle id `app.findme.mobile` in `ios/Runner.xcodeproj/project.pbxproj`.
- [ ] **Step 5: Lints.** `flutter pub add --dev very_good_analysis`; `analysis_options.yaml` includes `package:very_good_analysis/analysis_options.yaml`, excludes `**/*.g.dart`, `**/*.freezed.dart`, and disables `public_member_api_docs`.
- [ ] **Step 6: Run on emulator.** Run: `flutter run` with the emulator started → counter app appears. Replace it with a placeholder `Text('Find Me')` and update `test/widget_test.dart` to find it.
- [ ] **Step 7: Verify.** Run: `flutter analyze` → `No issues found!`; `flutter test` → `All tests passed!`
- [ ] **Step 8: CLAUDE.md, README.md, docs/HANDOFF.md** in the style of `travel-heatmap` (commands, architecture summary, conventions from Global Constraints, current state). Commit.

```bash
git add -A
git commit -m "chore: create Flutter project, lints, guide chapters 0-1"
```

---

### Task 1: Config, flavors, dependencies, theme

**Files:**
- Create: `lib/core/config/app_config.dart`, `config/example.json`, `lib/core/theme/palette.dart`, `lib/core/theme/app_theme.dart`, `lib/core/widgets/{pill,card_box,notice}.dart`, `lib/main.dart`, `lib/app.dart`, `build.yaml`
- Modify: `pubspec.yaml`, `android/app/build.gradle.kts`, `.gitignore`
- Assets: copy `travel-heatmap/web/public/hachiware.webp` → `assets/images/`; Nunito Regular/Bold/ExtraBold TTF → `assets/fonts/`
- Test: `test/core/config/app_config_test.dart`, `test/core/widgets/pill_test.dart`
- Docs: `docs/guide/02-running-the-app.md`

**Interfaces:**
- Produces:
  - `class AppConfig { final String apiUrl, authority, clientId, webOrigin; const AppConfig(...); factory AppConfig.fromEnvironment(); factory AppConfig.fromMap(Map<String, String?> m); String get api; /* apiUrl without trailing slashes */ String get cognitoHost; /* Uri.parse(authority).host */ }`
  - `final appConfigProvider = Provider<AppConfig>(...)` (overridden in `main.dart` and tests)
  - `abstract final class Palette { static const pink, pinkSoft, lavender, ink, muted, card, page, error }`
  - `ThemeData buildTheme()`
  - `Pill({required String label, VoidCallback? onTap, PillStyle style = PillStyle.plain, bool selected = false, String? semanticLabel})` with `enum PillStyle { plain, on, lav, ghost }`; `CardBox({required Widget child, EdgeInsets? padding})`; `Notice(String text, {bool error = false})`

- [ ] **Step 1: Add dependencies** (latest stable of each): runtime `flutter_riverpod riverpod_annotation go_router dio freezed_annotation json_annotation flutter_secure_storage shared_preferences share_plus flutter_map latlong2`; dev `build_runner riverpod_generator freezed json_serializable mocktail http_mock_adapter fake_async custom_lint riverpod_lint`; sdk `integration_test`. Declare assets and the Nunito family in `pubspec.yaml`.
- [ ] **Step 2: Write failing tests** `test/core/config/app_config_test.dart`:
  - `fromMap` with all four keys → fields set; `api` of `'https://x.io/'` is `'https://x.io'`; `cognitoHost` of `'https://cognito-idp.ap-southeast-1.amazonaws.com/ap-southeast-1_AbC'` is `'cognito-idp.ap-southeast-1.amazonaws.com'`.
  - any key missing or empty → throws `StateError` whose message contains `config/example.json` (port the intent of `WEB/config.ts` `BAD`).
- [ ] **Step 3: Run** `flutter test test/core/config` → FAIL (no AppConfig).
- [ ] **Step 4: Implement `AppConfig`.** `fromEnvironment` reads `String.fromEnvironment('API_URL')` etc. and delegates to `fromMap`.
- [ ] **Step 5: Run tests** → PASS.
- [ ] **Step 6: Flavors.** In `android/app/build.gradle.kts`: `flavorDimensions += "env"`, `productFlavors { create("dev") { dimension = "env"; applicationIdSuffix = ".dev"; resValue("string", "app_name", "Find Me Dev") }; create("prod") { dimension = "env"; resValue("string", "app_name", "Find Me") } }`; manifest label `@string/app_name`. `config/example.json` holds the four keys with placeholder values; `.gitignore` adds `config/dev.json`, `config/prod.json`.
- [ ] **Step 7: Theme + widgets.** `Pill` colours: plain = white card bg, `on` = pink bg + white bold text, `lav` = lavender bg (selected → pink), `ghost` = transparent; padding 6×12, min tap target 44 px (accessibility). Widget test `pill_test.dart`: `Pill(style: PillStyle.on)` renders text in white; `semanticLabel` is exposed in semantics.
- [ ] **Step 8: Entry point.** `main.dart`: `WidgetsFlutterBinding.ensureInitialized()`, build `AppConfig.fromEnvironment()`, `runApp(ProviderScope(overrides: [appConfigProvider.overrideWithValue(cfg)], child: const FindMeApp()))`. Missing config → show a plain error screen with the `StateError` message instead of crashing.
- [ ] **Step 9: Docs chapter 02**: copy `config/example.json` → `config/dev.json` and fill with stack outputs (same values as `travel-heatmap/web/public/config.json`; `WEB_ORIGIN` = the CloudFront/own domain), `flutter run --flavor dev --dart-define-from-file=config/dev.json`, hot reload (`r`), hot restart (`R`), DevTools, `flutter logs`, VS Code `launch.json` (create `.vscode/launch.json` with dev and prod configurations and commit it).
- [ ] **Step 10: Verify** `flutter analyze`, `flutter test`, `flutter build apk --flavor dev --dart-define-from-file=config/example.json --debug` → `Built build\app\outputs\flutter-apk\app-dev-debug.apk`. Commit `feat: config, flavors, theme`.

---

### Task 2: Trail models and formatting helpers

Port from `WEB/trail.ts` (types, `friendColor`, `pawColor`, `bearing`, `distanceM`, `ago`, `duration`, `hhmm`) and `WEB/components/SharePanel.tsx` (`remaining`, `dm`).

**Files:**
- Create: `lib/features/trail/domain/models.dart`, `lib/features/trail/domain/colors.dart`, `lib/core/time/format.dart`
- Test: `test/features/trail/domain/models_test.dart`, `test/core/time/format_test.dart`, `test/features/trail/domain/colors_test.dart`

**Interfaces:**
- Produces:
  - `class TrackPoint { final double lon, lat; final int t; /* epoch s */ final double? acc; const TrackPoint(this.lon, this.lat, this.t, [this.acc]); factory TrackPoint.fromJson(List<dynamic> j); }` (wire format `[lon, lat, epochSec, acc|null]`; `==`/`hashCode` by value)
  - `@freezed class Stop { double lon, lat; String start, end; int seconds; String? name; }` with `fromJson`; `DateTime get startAt`, `endAt`
  - `@freezed class LastPoint { double lon, lat; String ts; }` with `fromJson`
  - `@freezed class Track { List<TrackPoint> points; List<Stop> stops; LastPoint? last; }` + `Track.empty`
  - `Color friendColor(String id)`; `Color pawColor(int epochSec)`
  - `double bearing(TrackPoint a, TrackPoint b)`; `double distanceM(({double lat, double lon}) a, ({double lat, double lon}) b)`
  - `String ago(String iso, {DateTime? now})`, `String duration(int seconds)`, `String hhmm(DateTime t)`, `String remaining(String iso, {DateTime? now})`, `String dm(String ymd)`

- [ ] **Step 1: Write failing tests** by porting every `it(...)` in `WEB/ui.test.ts` that covers these functions, same inputs and expected strings (e.g. `ago` → `'vừa xong'`, `'12 phút trước'`, `'3 giờ trước'`, `'2 ngày trước'`; `duration(2*3600+600)` → `'2 giờ 10 phút'`; `remaining` past → `'đã hết hạn'`, 25 min ahead → `'còn 25 phút'`). Add: `pawColor` at local 06:00 → `Color(0xFFFB923C)`, 12:00 → `0xFFEC4899`, 18:00 → `0xFFF43F5E`, 23:00 → `0xFF8B5CF6`; `friendColor` is stable for the same id and always one of the 8 web colours; `TrackPoint.fromJson([105.8, 21.0, 1700000000, null])` has `acc == null`; `hhmm` is 24 h `HH:mm`.
- [ ] **Step 2: Run** `flutter test test/core test/features/trail/domain` → FAIL.
- [ ] **Step 3: Implement.** `friendColor` uses the web's hash: `h = (h * 31 + codeUnit) & 0xFFFFFFFF` over UTF-16 code units, index `h % 8`, colours `0ea5e9 10b981 6366f1 14b8a6 84cc16 0891b2 a855f7 64748b`. Run `dart run build_runner build -d`.
- [ ] **Step 4: Run tests** → PASS. Commit `feat: trail models and formatting`.

---

### Task 3: Trail math and date ranges

Port `WEB/trail.ts` (`atTime`, `togetherSpan`, `at`, `timeline`, `topStops`, `tailFrom`, `mergeTail`), `WEB/dateRange.ts` (all), `WEB/components/ReplayBar.tsx` (`replayMs`, `advance`, `SPEEDS`).

**Files:**
- Create: `lib/features/trail/domain/trail_math.dart`, `lib/features/trail/domain/date_range.dart`, `lib/features/replay/domain/replay_math.dart`
- Test: `test/features/trail/domain/trail_math_test.dart`, `test/features/trail/domain/date_range_test.dart`, `test/features/replay/domain/replay_math_test.dart`

**Interfaces:**
- Consumes: Task 2 models.
- Produces:
  - `(double, double)? atTime(List<TrackPoint> pts, num t)`; `(int, int)? togetherSpan(List<TrackPoint> own, List<List<TrackPoint>> others)`; `(double lon, double lat, double t) at(List<TrackPoint> pts, double pos)`
  - `sealed class TimelineEntry` with `StopEntry(Stop stop)` and `MoveEntry({int start, int end, double km, (double, double) to})`; `List<TimelineEntry> timeline(List<TrackPoint>, List<Stop>)`
  - `List<Stop> topStops(List<Stop>, {int n = 10})`
  - `String tailFrom(Track prev, String rangeFrom)`; `Track mergeTail(Track prev, Track tail, String from)`
  - `class DateRange { final String from, to; }` (ISO UTC strings, value equality); `enum Preset { today, yesterday, d7, d30 }` with labels `Hôm nay, Hôm qua, 7 ngày, 30 ngày`; `DateRange presetRange(Preset, DateTime now)`; `DateRange customRange(String fromYmd, String toYmd)`; `bool isOneDay(DateRange)`; `bool isLive(DateRange, {DateTime? now})`; `String liveTo(DateRange, {DateTime? now})`
  - `int replayMs(int prints)` (120 ms/print, min 10 000); `double advance(double pos, double dtMs, double speed, double totalMs, int n)`; `const speeds = [0.5, 1, 2, 4, 8]`

- [ ] **Step 1: Write failing tests** by porting every `it(...)` in `WEB/dateRange.test.ts` and the remaining `WEB/ui.test.ts` cases for these functions, same inputs and outputs. ISO strings must match JS `toISOString()` (UTC, millisecond precision, `Z`): add a test `presetRange(today) from is local midnight in UTC ISO with .000Z`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** One helper `String iso(DateTime d) => d.toUtc().toIso8601String()` is not enough (Dart prints microseconds when present): truncate to milliseconds and always emit `.mmmZ`. `timeline` keeps the web's 100 m "GPS wobble" cut-off.
- [ ] **Step 4: Run tests** → PASS. Commit `feat: trail math, date ranges, replay math`.

---

### Task 4: API client and error types

**Files:**
- Create: `lib/core/errors/app_errors.dart`, `lib/core/network/api_client.dart`
- Test: `test/core/network/api_client_test.dart`
- Docs: `docs/guide/03-project-structure.md` (folders, layers, one request traced from a button to the API and back, where errors are mapped)

**Interfaces:**
- Consumes: `AppConfig` (Task 1).
- Produces:
  - `sealed class AppError implements Exception`; subclasses `AuthExpired`, `AccountMissing`, `NetworkError`, `ApiStatus(int status, Map<String, dynamic>? body)`, `HttpError(int status)`, `ShareInvalid(String field)`, `FriendError(String code)`, `AuthError(String code)`
  - `typedef TokenGetter = Future<String?> Function();`
  - `class ApiClient { ApiClient(AppConfig cfg, TokenGetter token, {Dio? dio}); Future<dynamic> send(String method, String path, {Object? body, Map<String, String>? query}); }` — throws `AuthExpired` if the token getter returns null or status 401; `AccountMissing` on 403; for any other non-2xx throws `ApiStatus` (repositories map it to their own errors; unmapped statuses become `HttpError(status)`); `DioException` without a response → `NetworkError`. 204 → returns null.
  - `final apiClientProvider = Provider<ApiClient>(...)`

- [ ] **Step 1: Write failing tests** with `http_mock_adapter`: bearer header `Authorization: Bearer t1` sent; 401 → `AuthExpired`; 403 → `AccountMissing`; 400 body `{"error":"label"}` → `ApiStatus(400, {error: label})`; 204 → null; connection error → `NetworkError`; null token → `AuthExpired` and no request made; base URL trailing slash not doubled.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS.
- [ ] **Step 5: Write chapter 03.** Commit `feat: api client and error types`.

---

### Task 5: Auth (Cognito sign-in, session, renewal)

Port `WEB/auth.ts` and `WEB/auth.test.ts`; messages from `WEB/components/SignIn.tsx` `WHY`.

**Files:**
- Create: `lib/features/auth/data/cognito_api.dart`, `session_store.dart`, `auth_repository.dart`
- Test: `test/features/auth/data/auth_repository_test.dart`

**Interfaces:**
- Consumes: `AppConfig.cognitoHost`, `AuthError`, `NetworkError`.
- Produces:
  - `class Session { String access, refresh; int expiresAt; /* epoch ms */ toJson/fromJson }`
  - `abstract interface class SessionStore { Future<Session?> load(); Future<void> save(Session? s); }` with `SecureSessionStore` (key `findme.session`) — the interface exists so tests use an in-memory fake.
  - `class CognitoApi { CognitoApi(AppConfig cfg, {Dio? dio}); Future<Map<String, dynamic>> call(String action, Map<String, dynamic> body); }` — POST `https://<cognitoHost>/`, headers `Content-Type: application/x-amz-json-1.1`, `X-Amz-Target: AWSCognitoIdentityProviderService.<action>`; non-2xx → `AuthError(<__type after last '#'>)`; no response → `NetworkError`.
  - `class AuthRepository { Future<void> login(String email, String password); Future<String?> getAccessToken(); Future<void> logout(); }` + `authRepositoryProvider`
  - `String signInMessage(Object error)` (the `WHY` map + fallbacks `Chưa đăng nhập được (<code>).` / `Không kết nối được, thử lại sau chút nhé ✨`)

- [ ] **Step 1: Write failing tests** porting all 7 cases of `WEB/auth.test.ts` plus: `login trims email and sends USER_PASSWORD_AUTH`; `challenge response throws AuthError(NEW_PASSWORD_REQUIRED)`; `token valid >60 s returns stored access without a call`; `two concurrent getAccessToken calls make one REFRESH_TOKEN_AUTH call`; `refresh AuthError clears session and returns null`; **`offline refresh keeps session`** (NetworkError → returns null, store unchanged); `logout clears store then RevokeToken, ignores its failure`; `signInMessage(AuthError('NotAuthorizedException'))` → `'Sai email hoặc mật khẩu.'`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** (shared renewal = one nullable `Future<String?>` field cleared in `whenComplete`). **Step 4: Run** → PASS. Commit `feat: cognito auth with quiet renewal`.

---

### Task 6: Repositories (track, shares, friends)

Port `WEB/api.ts` (`fetchTrack`, shares functions), `WEB/friendsApi.ts`, and their tests `WEB/api.test.ts`, `WEB/friendsApi.test.ts` (skip `fetchPublicLocation`: non-goal).

**Files:**
- Create: `lib/features/trail/data/track_repository.dart`, `lib/features/shares/domain/share.dart`, `lib/features/shares/data/shares_repository.dart`, `lib/features/friends/domain/friend_models.dart`, `lib/features/friends/data/friends_repository.dart`
- Test: one `*_repository_test.dart` per file, under the mirrored `test/` path

**Interfaces:**
- Consumes: `ApiClient.send`, `ApiStatus`, models from Task 2, `DateRange`.
- Produces:
  - `TrackRepository.fetch(DateRange r) → Future<Track>` (GET `/track?from&to`; missing fields → empty; 400 → `HttpError(400)`)
  - `@freezed Share { String id, label, createdAt, expiresAt; bool route; String? routeFrom; }`
  - `SharesRepository`: `create({required String label, required String expiresAt, bool route = false, String? routeFrom}) → Future<Share>`; `list() → Future<List<Share>>`; `edit(String id, {String? expiresAt, bool? route, String? routeFrom}) → Future<Share>`; `revoke(String id) → Future<void>`; 400 → `ShareInvalid(body.error ?? 'body')`; ids URL-encoded.
  - `@freezed Me { name, friendCode }`, `Friend { id, name, since, String? lastTs }`, `Pending { id, name, at }`, `Relations { friends, incoming, outgoing }` (+ `Relations.empty`), `LivePoint { id, lat, lon, ts }`
  - `FriendsRepository`: `me()`, `relations()`, `sendRequest(String code) → Future<({Pending? outgoing, Friend? friend})>`, `answer(String id, bool accept)`, `remove(String id)`, `live() → Future<List<LivePoint>>`, `today(String id) → Future<({List<TrackPoint> points, LastPoint? last})>`; 400/404/409 → `FriendError(body.error ?? 'not found')`.
  - Providers: `trackRepositoryProvider`, `sharesRepositoryProvider`, `friendsRepositoryProvider`

- [ ] **Step 1: Write failing tests** porting each `it(...)` from `WEB/api.test.ts` (except public) and `WEB/friendsApi.test.ts`: paths, methods, bodies, query strings, error mapping.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement**, `build_runner`. **Step 4: Run** → PASS. Commit `feat: track, shares, friends repositories`.

---

### Task 7: App shell — auth phase, routing, welcome and sign-in

Port `WEB/App.tsx` phases and welcome card, `WEB/components/SignIn.tsx`.

**Files:**
- Create: `lib/features/auth/presentation/auth_controller.dart`, `welcome_screen.dart`, `sign_in_form.dart`; `lib/app.dart` (router)
- Test: `test/features/auth/presentation/auth_controller_test.dart`, `welcome_screen_test.dart`
- Docs: `docs/guide/04-auth.md`

**Interfaces:**
- Consumes: `AuthRepository`, `AccountMissing`.
- Produces:
  - `enum AuthPhase { loading, signedOut, signedIn, noAccount }`
  - `@Riverpod(keepAlive: true) class AuthController` with state `AuthPhase`; methods `Future<void> signIn(String email, String password)` (rethrows for the form), `Future<void> signOut()`, `void expired()` (→ signedOut), `void noAccount()`
  - `final sessionEpochProvider` — an `int` bumped on every transition out of `signedIn`; **every account-scoped provider (trail, replay, shares, friends) must `ref.watch(sessionEpochProvider)`** so it is rebuilt empty after sign-out.
  - Routes: `/` (map, Task 8), `/welcome`; go_router `redirect` sends anything but `signedIn` to `/welcome`, `refreshListenable` from the auth phase.

- [ ] **Step 1: Write failing tests:** start with stored valid token → `signedIn`; no session → `signedOut`; `signIn` success → `signedIn`; `signIn` throws `AuthError('NotAuthorizedException')` → phase stays `signedOut`, form shows `'Sai email hoặc mật khẩu.'`; widget test: welcome card shows `📍`, `Find Me`, `'Đang khởi động…'` while loading and `'Mọi nơi bạn đã đi qua, gói gọn trong một tấm bản đồ xinh xắn.'` after; button `'Đăng nhập 💖'` → `'Đang đăng nhập…'` while busy; **noAccount** shows `'Tài khoản này chưa dùng được bản đồ. Đây có thể là tài khoản admin: hãy quản trị trên trang web /admin.'` and an `'Đăng xuất'` pill (the web text names `/admin`; this wording replaces it since the app has no admin page); **`sign out wipes account state`**: a test provider watching `sessionEpochProvider` holding data is empty after `signOut()`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** Email field `keyboardType: emailAddress`, `autofillHints: [AutofillHints.username]`, password `AutofillHints.password`, wrapped in `AutofillGroup` (password managers, like the web's autocomplete). **Step 4: Run** → PASS.
- [ ] **Step 5: Chapter 04** (how Cognito sign-in works here, secure storage, renewal, why no redirect page). Commit `feat: auth phases, routing, sign-in screen`.

---

### Task 8: Map screen with paw layer, stops and Hachiware

Port `WEB/components/MapView.tsx`, `WEB/paws.ts`, `WEB/startView.ts`.

**Files:**
- Create: `lib/features/trail/presentation/map_screen.dart`, `paw_layer.dart`, `start_view.dart`; `lib/core/storage/prefs.dart`
- Test: `test/features/trail/presentation/paw_layer_test.dart`, `start_view_test.dart`, `map_screen_test.dart`
- Docs: `docs/guide/05-map-and-paws.md`

**Interfaces:**
- Consumes: Task 2/3 models and colours.
- Produces:
  - `class Prefs { Future<(double lon, double lat)?> startPoint(); Future<void> rememberStart(double lon, double lat); Future<List<String>> shownFriends(); Future<void> saveShownFriends(List<String>); }` keys `findme:start`, `findme.shownFriends`; `prefsProvider`
  - `const home = (lon: 105.8542, lat: 21.0285)`; `Future<({LatLng center, double zoom})> startView(Prefs)` (saved → zoom 15, else home zoom 13; 4-decimal rounding on save)
  - `class PawLayer extends StatelessWidget { PawLayer({required List<TrackPoint> points, Color? color}); }` drawing via `CustomPainter` using `MapCamera.of(context).latLngToScreenPoint`; `bool samePoints(List<TrackPoint> a, List<TrackPoint> b)` (web's rule) used in `shouldRepaint` together with camera change; `TrackPoint? nearestPrint(List<TrackPoint> pts, Offset tap, Offset Function(TrackPoint) project, {double maxPx = 14})`; `double pawSize(double zoom)` (≥17 → 14, ≥15 → 11, ≥13 → 8, else 6)
  - `class MapView extends ConsumerStatefulWidget { MapView({required List<TrackPoint> points, required List<Stop> stops, LastPoint? last, List<MapFriend> friends = const [], (double, double)? flyTo, ReplayView? replay}); }` with `class MapFriend { String id, name; Color color; List<TrackPoint> points; LastPoint? last; }` and `class ReplayView { List<TrackPoint> track; double pos; int? atClock; }`

- [ ] **Step 1: Write failing tests:** `pawSize` thresholds; `samePoints` (same length + same first t + same last t/lon/lat → true; any differs → false); `nearestPrint` picks closest within 14 px and null beyond; `startView` with nothing saved → home, zoom 13; after `rememberStart(105.12345, 21.98765)` → `(105.1235, 21.9877)`, zoom 15; widget smoke test pumps `MapView` with 3 points and 1 stop (tile layer replaced by a no-op `TileProvider` in tests) and finds the stop marker `🐾` and the Hachiware `Image`.
- [ ] **Step 2: Run** → FAIL.
- [ ] **Step 3: Implement.** OSM `TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'app.findme.mobile', maxZoom: 19)` wrapped in a `ColorFiltered` matrix approximating `saturate(0.6) sepia(0.15) hue-rotate(-12deg) brightness(1.05)`; attribution `RichAttributionWidget` "© OpenStreetMap contributors" (OSM policy). Paws: alpha 0.85, alternate left/right offset `side * s * 0.35`, rotate by `bearing` to the next print, white 2 px shadow, skip prints >20 px outside the viewport, paw shape from `drawPaw`. Stops: circle sized `min(46, 20 + sqrt(seconds/60) * 2.2)`, `🐾`, tap → popup `<name ?? 'Một nơi xinh xinh'>` + `hhmm – hhmm · duration`. Tap on map → nearest print popup `🐾 HH:mm · ±N m`. Hachiware marker 56×66 anchored bottom centre on `last`; first data: centre on `last` zoom 16 and `rememberStart`, else fit points (padding 60, max zoom 16). `flyTo` → animate to zoom 17 over 0.8 s. Zoom buttons bottom-right.
- [ ] **Step 4: Run tests** → PASS; run on emulator with dev config and compare visually with the web on the same day. **Step 5: Chapter 05.** Commit `feat: map with paw prints, stops, hachiware`.

---

### Task 9: Trail controller — loading, live refresh, backoff

Port the load/poll logic of `WEB/App.tsx`.

**Files:**
- Create: `lib/features/trail/presentation/trail_controller.dart`
- Test: `test/features/trail/presentation/trail_controller_test.dart`
- Docs: `docs/guide/06-date-filter-and-live-refresh.md`

**Interfaces:**
- Consumes: `TrackRepository.fetch`, `tailFrom`, `mergeTail`, `liveTo`, `isLive`, `presetRange`, `AuthController.expired/noAccount`, `sessionEpochProvider`.
- Produces:
  - `@freezed TrailState { DateRange range; Track track; bool loading; String? error; }`
  - `@riverpod class TrailController` (watches `sessionEpochProvider`): `void setRange(DateRange r)` (full load), `Future<void> load({bool quiet = false})`; internal poll loop.
  - `@riverpod class FlyTo` (state `(double lon, double lat)?`, method `go(double lon, double lat)`), read by `MapView` to animate; used by the top bar's 👀 pill and the trail sheet rows.
  - Constants `pollMs = 7000`, `idlePollMs = 60000`.

- [ ] **Step 1: Write failing tests** (fake repo + `fake_async`): initial range = today, one full fetch; after 7 s a quiet fetch from `tailFrom(...)` merged with `mergeTail`; no new `last.ts` → next delays 14 s, 28 s, 56 s, 60 s (cap); new `last.ts` → back to 7 s; past range → no fetch, but the state notifies so `ago` labels re-render; 400 on full load → error `'Chọn tối đa 31 ngày một lần nhé 📅'`; other error → `'Chưa tải được dấu chân — thử lại sau chút nhé ✨'`; **`quiet refresh failure keeps trail and shows no error`**; `AuthExpired` → `AuthController.expired()` called; `AccountMissing` → `noAccount()`; **`stale load is ignored`** (setRange while first fetch pending: first result discarded); **`resume refreshes at once and resets delay`** (controller listens to `AppLifecycleListener`; paused → no ticks; resumed → immediate quiet load, delay 7 s).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** with a sequence counter like the web's `seq`, one `Timer`, a `busy` flag. **Step 4: Run** → PASS.
- [ ] **Step 5: Chapter 06.** Commit `feat: trail loading and live refresh`.

---

### Task 10: Top bar, date filter, trail sheet

Port `WEB/App.tsx` top bar, `WEB/components/DateFilter.tsx`, `WEB/components/TrailPanel.tsx`.

**Files:**
- Create: `lib/features/trail/presentation/top_bar.dart`, `date_filter.dart`, `trail_sheet.dart`; wire into `map_screen.dart`
- Test: `test/features/trail/presentation/date_filter_test.dart`, `trail_sheet_test.dart`, `top_bar_test.dart`
- Docs: `docs/guide/07-trail-panel.md`

**Interfaces:**
- Consumes: `TrailController`, `timeline`, `topStops`, `isOneDay`, `ago`, `duration`, `hhmm`.
- Produces: `TopBar({required VoidCallback onShare, required VoidCallback onFriends, required int incomingCount})`; `DateFilter({required DateRange value, required ValueChanged<DateRange> onChange})`; `TrailSheet({required Track track, required bool oneDay, required bool replaying, required VoidCallback onReplay, required void Function(double lon, double lat) onSelect})` as a `DraggableScrollableSheet`.

- [ ] **Step 1: Write failing widget tests:** top bar shows `📍 Find Me`, `👀 <ago>` pill when `last` exists (tap → flyTo), `🔗 Chia sẻ`, `👥` with badge count when incoming > 0, `👋` sign-out with semantics `'Đăng xuất'`; spinner text `'Đang lần theo dấu chân… 🐾'` while loading; date filter presets `Hôm nay / Hôm qua / 7 ngày / 30 ngày` and `📅` → two date pickers (`showDateRangePicker` is acceptable; from ≤ to enforced) calling `customRange`; trail sheet empty → `'Chưa có dấu chân nào trong khoảng này 🐾'`; one day → `'📅 Nhật ký ngày'`, stop row `HH:mm – HH:mm`, `🐾 <name>`, duration; move row `🛵 di chuyển · 1,2 km` (comma decimal); `▶️ Phát lại` only when > 1 point, `⏹ Dừng` while replaying; many days → `'⭐ Chỗ dừng nhiều nhất'` with 🥇🥈🥉 then 📍, empty → `'Chưa dừng chỗ nào lâu hơn 5 phút'`; **stop without name shows `'Một nơi xinh xinh'`**.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement**; top bar is a `CardBox` under the safe area, hidden (kept in tree with `Offstage`) while replaying. **Step 4: Run** → PASS.
- [ ] **Step 5: Chapter 07.** Commit `feat: top bar, date filter, trail sheet`.

---

### Task 11: Replay (alone and together)

Port `WEB/components/ReplayBar.tsx` and `replayAll` / together logic from `WEB/App.tsx`.

**Files:**
- Create: `lib/features/replay/presentation/replay_controller.dart`, `replay_bar.dart`; wire into `map_screen.dart`
- Test: `test/features/replay/presentation/replay_controller_test.dart`, `replay_bar_test.dart`
- Docs: `docs/guide/08-replay.md`

**Interfaces:**
- Consumes: `replayMs`, `advance`, `speeds`, `at`, `atTime`, `togetherSpan`, `isLive`, friends on map (Task 13 provides `friendsOnMapProvider`; until then an empty-list provider defined here in `replay_controller.dart` as `final friendsOnMapProvider = Provider<List<MapFriend>>((_) => const [])`, which Task 13 replaces).
- Produces: `@freezed ReplayState { List<TrackPoint>? track; List<TrackPoint>? frozenOwn; double pos; bool playing; double speed; int? totalMs; }`; `@riverpod class ReplayController` (watches `sessionEpochProvider`) with `start(List<TrackPoint> own)` (chooses alone vs together), `stop()`, `toggle()`, `seek(double pos)`, `cycleSpeed()`; ticker via `Ticker`/`createTicker` in the bar's state, calling `advance`. `const togetherMs = 60000`. Respect `MediaQuery.disableAnimations` (= web's reduced motion: jump to the end).

- [ ] **Step 1: Write failing tests:** `start` with no friends → track = own copy, `totalMs` null; with friends shown and a live range → two-point clock track `[t0, t1]` from `togetherSpan`, `totalMs == 60000`, `frozenOwn` = own points at press time; reaching the end sets `playing = false`; `toggle` at end restarts from 0; `seek` pauses; `cycleSpeed` 1 → 2 → 4 → 8 → 0.5 → 1; bar shows `⏸`/`▶️`, current `HH:mm`, range `HH:mm – HH:mm`, prefixed `dd/MM ` when the replay spans days, speed label `0,5×`, `✕` closes; setting a new range stops the replay.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement**; while replaying the map hides the Hachiware on `last`, shows a walking Hachiware at `at(track,pos)` (or `atTime(frozenOwn, clock)`, hidden before the first print), friends' pins at `atTime(f.points, clock)`, and pans when the walker leaves the inner 60 % of the view. **Step 4: Run** → PASS.
- [ ] **Step 5: Chapter 08.** Commit `feat: replay alone and together`.

---

### Task 12: Shares sheet

Port `WEB/components/SharePanel.tsx` (all copy verbatim, including `INVALID` messages and confirm texts).

**Files:**
- Create: `lib/features/shares/presentation/shares_controller.dart`, `shares_sheet.dart`
- Test: `test/features/shares/presentation/shares_sheet_test.dart`

**Interfaces:**
- Consumes: `SharesRepository`, `remaining`, `dm`, `AppConfig.webOrigin`, `AuthController.expired`.
- Produces: `String shareLink(AppConfig cfg, String id)` → `'${webOrigin without trailing /}/s/$id'`; `SharesSheet` opened with `showModalBottomSheet(isScrollControlled: true)` from the top bar.

- [ ] **Step 1: Write failing widget tests** (fake repo): list loads on open, empty → `'Chưa có link nào.'`; create with label + preset `1 giờ / 1 ngày / 7 ngày / Chọn ngày` sends `expiresAt` = now + preset; `Cho xem cả đường đi 🐾` off by default, on → `routeFrom` date (≤ today) sent; success note `'Đã tạo link ✨ — bấm Sao chép để gửi.'`; `ShareInvalid('label')` → `'Tên cần từ 1 đến 40 ký tự nhé.'`; `Sao chép` puts `shareLink` on the clipboard and shows `Đã sao chép link cho "<label>" 💖`; `Gửi` calls `share_plus` with text `Vị trí của mình (<label>)` and the link (inject a `ShareLauncher` function via provider for the test); `Sửa` reveals extend presets and a route-from date picker; 🐾 toggles route with the web's notes; `Thu hồi` asks `Thu hồi link của "<label>"? Người đó sẽ không xem được nữa.` in an `AlertDialog` before revoking; **expired share shows `'đã hết hạn'`, hides `Sao chép`/`Gửi`, shows `Gia hạn` and `Xoá` with the "Xoá hẳn…" confirm**; `shareLink` test with and without trailing slash; `AuthExpired` → `expired()`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS. Commit `feat: share links sheet`.

---

### Task 13: Friends — controller, sheet, map layers

Port `WEB/useFriends.ts` and `WEB/components/FriendsPanel.tsx`.

**Files:**
- Create: `lib/features/friends/presentation/friends_controller.dart`, `friends_sheet.dart`
- Modify: `lib/features/replay/presentation/replay_controller.dart` (remove the placeholder `friendsOnMapProvider`), `map_screen.dart` (pass friends to `MapView`, badge count to `TopBar`)
- Test: `test/features/friends/presentation/friends_controller_test.dart`, `friends_sheet_test.dart`
- Docs: `docs/guide/09-shares-and-friends.md` (covers Task 12 too)

**Interfaces:**
- Consumes: `FriendsRepository`, `Prefs.shownFriends/saveShownFriends`, `friendColor`, `sessionEpochProvider`, `AuthController.expired/noAccount`.
- Produces: `@freezed FriendsState { Me? me; Relations relations; List<String> shownIds; Map<String, LastPoint> live; Map<String, ({List<TrackPoint> points, LastPoint? last, int at})> today; }`; `@riverpod class FriendsController` with `refresh()`, `toggle(String id)`, `send(String code) → Future<String>` (returns the note), `answer(String id, bool accept)`, `remove(String id)`; `final friendsOnMapProvider = Provider<List<MapFriend>>` (shown ∩ current friends, colour, today points, `live[id] ?? today[id].last`). Constants `pollMs = 7000`, `routeMs = 60000`.

- [ ] **Step 1: Write failing tests** (`fake_async`, fake repo): refresh every 7 s while resumed and at once on resume; `me` fetched once then reused; `live()` called only when someone is shown; shown friend's `today` fetched on toggle-on, then every 60 s; a removed friend drops out of `friendsOnMapProvider` even though its id is still saved; shown ids persisted via `Prefs`; **`friends state cleared on sign out`** (bump `sessionEpochProvider` → `me` null, relations empty, live/today empty); sheet: `Mã của bạn` + code + `Sao chép` (`'Đã sao chép mã của bạn.'`); send → `'Đã gửi lời mời 💌'` or `Bạn và <name> đã là bạn bè 🎉`; `FriendError('self')` → `'Đây là mã của bạn mà 😄'`; incoming `Đồng ý`/`Từ chối`; friend row **`lastTs == null` → `'chưa thấy hôm nay'`**, else `thấy <ago>`; `Hiện trên bản đồ` checkbox; `Xoá bạn` with confirm `Xoá <name> khỏi bạn bè? Hai bạn sẽ không thấy nhau nữa.`; outgoing `Huỷ` → `'Đã huỷ lời mời.'`; empty → `'Chưa có bạn nào. Gửi mã của bạn cho người thân nhé.'`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement**; friend pins = 30 px white circle, 3 px border in their colour, initial letter bold. **Step 4: Run** → PASS.
- [ ] **Step 5: Chapter 09.** Commit `feat: friends`.

---

### Task 14: Integration test, CI, remaining docs

**Files:**
- Create: `integration_test/app_test.dart`, `.github/workflows/ci.yml`, `docs/guide/10-testing.md`, `docs/guide/11-codegen-lints-format.md`, `docs/guide/12-ci.md`, `docs/guide/13-later-ios-and-store-release.md`, `docs/guide/cheatsheet.md`
- Modify: `README.md`, `CLAUDE.md`, `docs/HANDOFF.md`, `docs/guide/README.md`

**Interfaces:**
- Consumes: everything; overrides `authRepositoryProvider`, `trackRepositoryProvider`, `sharesRepositoryProvider`, `friendsRepositoryProvider` with fakes.

- [ ] **Step 1: Write the integration test:** launch app with fakes → welcome → type email/password → map shows 🐾 trail sheet `📅 Nhật ký ngày` → open `🔗 Chia sẻ`, create a link, see it listed → close → `👋` → welcome again and no trail data in providers.
- [ ] **Step 2: Run on emulator** `flutter test integration_test --flavor dev --dart-define-from-file=config/example.json` → `All tests passed!`
- [ ] **Step 3: CI workflow** `ci.yml`: on `push` and `pull_request`: job `android` (ubuntu-latest, `subosito/flutter-action` pinned to the stable version used locally, `flutter pub get`, `dart run build_runner build -d` then `git diff --exit-code` (generated code up to date), `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test --coverage`, upload `coverage/lcov.info` artifact, `flutter build apk --flavor dev --debug --dart-define-from-file=config/example.json`, upload APK artifact). Job `ios` (macos-latest): runs only `if: github.ref == 'refs/heads/main' || github.event_name == 'workflow_dispatch'`; `flutter build ios --no-codesign --dart-define-from-file=config/example.json`. Add `workflow_dispatch:` trigger.
- [ ] **Step 4: Docs** 10 (unit/widget/integration, how to write each, fakes and providers, coverage report), 11 (build_runner, freezed, riverpod_generator, lints, format), 12 (creating the GitHub repo and remote, what each CI job does, reading a failed run, macOS minutes cost), 13 (iOS without a Mac: Codemagic / cloud Mac, adding Xcode schemes for flavors, signing, TestFlight, Play Console internal testing, app icons with `flutter_launcher_icons`), cheatsheet (every command and config key used anywhere in the guide). Update README quick start, CLAUDE.md, HANDOFF (what exists, what is not done: iOS never run, store release not done).
- [ ] **Step 5: Verify all** `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` → all pass. Commit `chore: integration test, CI, guide`.
