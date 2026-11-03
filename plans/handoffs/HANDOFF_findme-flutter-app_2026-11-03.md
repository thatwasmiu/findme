# Find Me Flutter app built and pushed; local Android toolchain blocked (no admin, 8.8 GB free)

**Date:** 2026-11-03
**Status:** IN PROGRESS (app code complete; waiting on the owner's choice for installing the Android SDK)
**Bead(s):** none (no `bd` on this machine)
**Epic:** Find Me mobile (Flutter port of `travel-heatmap/web`)
**Chain:** `standalone-7058c711` seq `1`
**Parent:** `none — first in chain`
**Prior chain:** none — first in chain

---

## Reference Documents

- `CLAUDE.md` (repo root): commands, architecture, conventions for this Flutter repo.
- `docs/HANDOFF.md`: the repo's own short "current state" file (project convention copied from `travel-heatmap`:
  update it in the same change whenever state changes). This plans/handoffs file is the long session record.
- `docs/superpowers/specs/2026-11-02-findme-flutter-app-design.md`: approved design (the binding authority).
- `docs/superpowers/plans/2026-11-02-findme-flutter-app.md`: the 15-task implementation plan (Tasks 0–14).
- `docs/guide/README.md` + chapters `00`–`14` + `cheatsheet.md`: beginner guide for the owner.
- Behaviour source of truth: `C:\Users\DatNT4\Desktop\works\travel-heatmap\web\src` (React 19 + Leaflet PWA) and
  `C:\Users\DatNT4\Desktop\works\travel-heatmap\CLAUDE.md` / `docs/HANDOFF.md` (backend architecture, AWS CDK).
- `C:\Users\DatNT4\CLAUDE.md` mentions graphify (`graphify-out/`); no `graphify-out/` exists in this repo, so the
  graphify rules did not apply.

## The Goal

The owner (no mobile-dev experience, Windows 10 Enterprise LTSC laptop, no Mac) wants a native Flutter app for iOS and
Android that does exactly what the existing "Find Me" web viewer does, calling the same AWS API and the same Cognito
user pool, with the same pastel design and Vietnamese UI, set up "like an enterprise / professional project": clean
layered code, testing from day one, standard tooling (emulator, CI) and detailed beginner docs. Overland keeps
uploading location; the app is a viewer only. Normal users only (no admin screen). v1 targets Android
(emulator/phone); iOS must stay buildable (checked in CI), App Store/Play release is documented for later. End state
the owner is heading to: run the app on a real Android device with their real config, then distribute.

## Where We Are

- Repo: `C:\Users\DatNT4\Desktop\works\findme`, branch `main`, pushed to **https://github.com/thatwasmiu/findme**
  (private). Working tree clean at `02e1f93`. 14 commits, all with the `Co-Authored-By: Claude Opus 5.5` trailer.
- All plan tasks 0–14 implemented. **131 unit + widget tests pass** (`flutter test`, ~17 s), `flutter analyze` →
  "No issues found!". ~6,900 lines of hand-written Dart (lib + test + integration_test, excluding generated files).
- Features done: Cognito sign-in with quiet token renewal; flutter_map with a CustomPainter paw layer, stops,
  Hachiware; date filter + live refresh (7 s → 60 s backoff, pause in background); day diary / top places sheet;
  replay alone and together; share links sheet; friends sheet + friends on the map; app shell with config-error app.
- Final whole-branch review (Opus subagent) found 1 Critical, 2 Important, 6 Minor: **all 9 fixed**, each with a test
  that failed first (commits `78ef324`, `58d3ed8`).
- CI (`.github/workflows/ci.yml`) has run on GitHub. First run failed at "Generated code is up to date"
  (`.flutter-plugins-dependencies` tracked); fixed in `fdff069`. Second run failed at the APK build ("Product Flavor
  dev contains custom resource values, but the feature is disabled", AGP 9.1); fixed in `098c8ee`. The owner then
  said "ci done what is the output", implying the third run finished; **the run's green/red status was never shown
  to me** (private repo, no `gh`, API returns 404).
- Guide chapter 14 (store accounts, app IDs, Apple free 7-day vs 99 USD program, APK sideload vs Google Play) added
  in `02e1f93`.
- **Never run on a device or emulator.** No APK built locally. Integration test (`integration_test/app_test.dart`)
  never run on a device.
- Toolchain on this PC: Flutter **3.47.9** (Dart **3.13.7**, DevTools 2.60.0) cloned by me to `C:\src\flutter`
  (`git clone --depth 1 -b stable`); **not on PATH** (user or machine). Java 17.0.12 present. git 2.53. No `gh`.
  No Android SDK (`%LOCALAPPDATA%\Android\Sdk` absent). `python` is the Windows Store stub (hangs).
- **Android Studio install attempt failed** (last action of the session): installer
  `C:\Users\DatNT4\Downloads\android-studio-rabbit2-windows.exe` (1,531,611,648 bytes, Authenticode **Valid**, signer
  Google LLC, ProductVersion 2026.2.2.8). Ran `Start-Process … -ArgumentList "/S" -Verb RunAs -Wait` → exit code
  **1812**, nothing installed (no `C:\Program Files\Android`, no uninstall registry entry).
- Cause found: the account is **not in the Administrators group** (token lacks S-1-5-32-544, not elevated), and C:
  has only **8.8 GB free** (Studio ~3 GB + SDK ~2–3 GB + emulator image ~4 GB + Gradle caches need ~12–15 GB).
- **Open question to the owner (unanswered):** go ahead with option A = Android command-line tools + SDK in
  `%LOCALAPPDATA%\Android\Sdk` (no admin, ~3–4 GB) and run on a real Android phone over USB? Options B (IT installs
  Studio, free disk first) and C (Studio zip in user folder; emulator still needs Hypervisor Platform = admin) were
  also offered.
- Execution ledger/workspace (`.superpowers/sdd/…`) was deleted after the final review per the executing-plans skill;
  its rulings are reproduced in Key Decisions below. `.superpowers/` is gitignored.

## What We Tried (Chronological)

1. **Brainstorming (superpowers:brainstorming).** User's first answer: "create flutter mobile app (IOS, Android)
   with exact function to (calling the same api) …/travel-heatmap/web" + "project set up of an enter price and
   profesionall project". I read the web app (`App.tsx`, `api.ts`, `friendsApi.ts`, `auth.ts`, `config.ts`,
   `admin/adminApi.ts`, `trail.ts`, `dateRange.ts`, `useFriends.ts`, components) and travel-heatmap `CLAUDE.md` /
   `docs/HANDOFF.md`. Asked what "enterprise" meant → "clean code structure, also some set up for testing and
   integrate with other tool, I dont have mobile app dev experience so have detail docs for me". Proposed toolkit
   (Android Studio emulator, flavors, very_good_analysis, unit/widget/integration tests, GitHub Actions CI, crash
   reporting later). "No Mac for now" → Android emulator dev, iOS compiled in CI macOS runner. "same design for now".
2. **Design doc + builder check.** Wrote the spec; a fresh general-purpose subagent ("builder check") raised 3
   questions: admin access model, who uses v1 on which phone, GitHub repo private (macOS minutes ×10). I settled
   admin + CI cadence myself; asked the owner the phone question → "Android/emulator fine". Owner later said "login
   normal user only" → admin removed from the app entirely (admin login → "no account" screen).
3. **Plan (superpowers:writing-plans).** 15 tasks; Review Focus of 5 input classes. Owner chose **Native** execution
   (I recommended subagent-driven) and asked to "complete set up chapter first so I can start install dependencies"
   → wrote guide README + ch.00 + ch.01 first, committed `7c34f82`, paused for the owner's install.
4. **Owner could not install** ("cannot set up for now continue the implementation, resume setup later"). Writing
   code blind was rejected; I asked permission (AskUserQuestion) to clone only the Flutter SDK (no admin, ~2 GB) →
   **"Yes, install SDK"**. First `flutter --version` took >10 min (Dart SDK download, run in background).
5. **Tests written before implementation** for Tasks 2–6 while the SDK downloaded (ported every relevant `it()` from
   web `ui.test.ts`, `dateRange.test.ts`, `auth.test.ts`, `api.test.ts`, `friendsApi.test.ts`). Implementations were
   written before I could watch the tests fail (ledgered as a ruling). After `flutter create` + codegen: 45/45 green,
   then 64/64 with repositories (one fix: Dart records don't deep-compare maps → auth test `sent()` returns a Map).
6. **`.gitignore` mistake.** My early `printf '.superpowers/\n' > .gitignore` meant `flutter create` kept my file, so
   the first feature commit included `.dart_tool/` and `build/`. Fixed in `bfd37e5`/`db827bf` (full Flutter ignore
   list, untracked). **Missed**: `.flutter-plugins-dependencies`, `.idea/*`, `*.iml` stayed tracked until CI failed
   (fixed `fdff069` via `git ls-files -ci --exclude-standard`).
7. **Tasks 1/7/9** (flavors, theme, auth phases, welcome screen, trail controller). Riverpod 3 rebuilds are scheduled
   through timers: in fakeAsync tests `f.flushMicrotasks()` was not enough → use `f.elapse(Duration.zero)`.
   `AuthController.build` used `Future(...)` (Timer.run) → changed to `Future.microtask`. Resume-test expectation
   changed to match the web (next refresh 14 s, not 7 s). 83/83 green → commit `e214142`.
8. **Tasks 8/10–13** (map, paws, UI pieces, replay, shares, friends). Gotchas hit: `flutter_map`/`latlong2` export a
   `Path<LatLng>` that clashes with `dart:ui` `Path` → `import 'package:latlong2/latlong.dart' show LatLng;`;
   `share_plus` exports `Share` clashing with the domain `Share` → `show ShareParams, SharePlus`; Riverpod 3
   `Override` type lives in `package:flutter_riverpod/misc.dart`; lazy `ListView` rows beyond the viewport aren't built
   in widget tests → `tallView(t)` helper (1080×6000); `bySemanticsLabel('Đóng')` didn't find the ✕ inside a modal
   bottom sheet in the app test (used `find.text('✕')`); `round4(21.98765)` = 21.9876 (binary float, JS same) →
   fixture changed to 21.98766; an `async` test inside `fakeAsync` timed out → rewritten synchronously. Lint pass:
   `dart fix --apply` (38 fixes) + manual `unawaited(...)` wraps. 119/119 → commit `3566c3d`.
9. **Task 14** (CI, integration test, guide 02–13, cheatsheet, HANDOFF, `.gitattributes`, `.vscode/launch.json`) →
   `b6018e7`.
10. **Final review** (Opus subagent via superpowers:requesting-code-review template, review package diff ~500 KB).
    Fix pass for C1/I1/I2 with RED→GREEN tests → `78ef324`, 124/124.
11. **Push**: owner pasted `https://github.com/thatwasmiu/findme.git`; checked `git ls-remote` (empty) and that no
    secrets were tracked; `git remote add origin` + `git push -u origin main`.
12. **Six minors fixed** after the owner re-sent "Fix the 6 deferred minor issues now?" (treated as yes): tests RED
    first; one needed `package:clock` because fakeAsync doesn't control `DateTime.now()`. 131/131 → `58d3ed8`.
13. **CI failure 1** (owner pasted log): `git diff --exit-code` after build_runner showed
    `.flutter-plugins-dependencies` differing (Windows vs Linux paths) → untracked 7 files, narrowed the check to
    `'*.g.dart' '*.freezed.dart'` → `fdff069`.
14. **CI failure 2** (owner pasted log): AGP **9.1.0** (`android/settings.gradle.kts` line 22) disables `resValues` by
    default → added `buildFeatures { resValues = true }` in `android/app/build.gradle.kts` → `098c8ee`. Not
    verifiable locally (no SDK).
15. **Docs ch.14** on request "add docs about how to obtain IOS id for deploy app store (both $90 and 7 day expired)
    … and android also". Two WebSearch (standard) calls: Apple fee 99 USD/yr (mostly third-party blogs); Google Play
    25 USD once + 12 testers × 14 days for personal accounts created after 2023-11-13. Corrected the owner's "$90".
16. **Owner asked** "is flutter install in this computer" → installed, not on PATH, no Android SDK. "is it necessary
    to install android studio" → no, the SDK is what's needed; offered 3 options. "install for me, check error" →
    verified signature, silent install failed (exit 1812), diagnosed no-admin + low disk, offered options A/B/C.

## Key Decisions

- **Native execution** (owner's choice) instead of subagent-driven; one Opus review at the end.
- **Flutter SDK cloned by me** to `C:\src\flutter` with the owner's explicit OK; not added to PATH (owner's machine
  setting left to them; guide ch.01 step 2 does it).
- **Plain Riverpod** `Provider`/`Notifier`, **no riverpod_generator** (spec said codegen) — fewer generated files for a
  beginner. Rejected: riverpod_annotation + generator (removed from pubspec).
- **No go_router** — two screens chosen by auth phase in `FindMeApp`; rejected because there are no deep links.
- **`signedInProvider` (bool)** replaces the planned `sessionEpochProvider`: every account-scoped notifier does
  `ref.watch(signedInProvider)` so leaving the signed-in phase rebuilds it empty.
- **Admin removed** (owner: "login normal user only"); admin login lands on the "no account" screen with text
  pointing to the web `/admin` page.
- **No iOS flavors/schemes** (needs Xcode); iOS takes config only from `--dart-define-from-file`.
- **iOS CI job only on `main` or manual dispatch** (macOS minutes ×10 on private repos).
- **Generated code committed** (beginner can run without build_runner); CI checks it is current.
- **No bundled Nunito font** (would need a download) — system font; ch.13 explains adding it.
- **FakeAdapter** (50 lines, `test/helpers/fake_adapter.dart`) instead of `http_mock_adapter` dependency.
- **SnackBar** for stop/paw/friend taps instead of Leaflet-style popups; hand-written `AnimationController` fly-to
  instead of `flutter_map_animations`; Material `showDateRangePicker` instead of two date inputs.
- **Resume refresh delay = 14 s** (matches web exactly; plan text said 7 s).
- **Lints disabled**: `public_member_api_docs`, `lines_longer_than_80_chars`, `unnecessary_type_name_in_constructor`
  (Dart 3.13 suggests `const new(...)`, confusing), `cascade_invocations`, `avoid_catching_errors` (main catches the
  config `StateError`; friends refresh unpacks `ParallelWaitError`).
- **Offline token renewal throws `NetworkError`** (web returns null): returning null meant "signed out" to
  `ApiClient`. Only Cognito `NotAuthorizedException` drops the session; throttling/5xx are transient.
- **Prefs cleared on sign-out / expiry** (`findme:start`, `findme.shownFriends`) — differs from the web (keeps them);
  chosen for shared-phone privacy.
- **Android app id `app.findme.mobile`** (+`.dev` suffix for dev flavor), Kotlin namespace left `app.findme.findme`;
  iOS bundle id `app.findme.mobile`.
- Rejected when the owner couldn't install tools: writing all code without running tests.

## Evidence & Data

### Commit log

| Hash | Time (11-xx) | Summary |
|---|---|---|
| `7c34f82` | 02 16:52 | docs: design spec, implementation plan, guide chapters 0-1 |
| `0cc446c` | 03 11:23 | feat: project skeleton, domain logic, API client, auth, repositories (64 tests) |
| `bfd37e5` | 03 11:23 | chore: ignore Flutter build output and local files |
| `db827bf` | 03 11:23 | chore: untrack build output |
| `e214142` | 03 11:29 | feat: flavors, theme, auth phases, sign-in screen, trail live refresh (83 tests) |
| `3566c3d` | 03 11:47 | feat: map, paw prints, trail sheet, replay, share links, friends (119 tests) |
| `b6018e7` | 03 11:50 | chore: CI, integration test, guide chapters 2-13, cheatsheet, handoff |
| `da16325` | 03 11:50 | docs: link chapter 02 from chapter 01 |
| `78ef324` | 03 11:59 | fix: keep the session offline, close sheets on sign-out, no friends timer leak (124) |
| `a02046b` | 03 12:44 | docs: handoff notes the GitHub remote |
| `58d3ed8` | 03 12:56 | fix: the six minor review findings (131) |
| `fdff069` | 03 12:59 | ci: untrack generated IDE/plugin files; check only generated Dart |
| `098c8ee` | 03 13:08 | fix(android): enable resValues so flavors can set the app name |
| `02e1f93` | 03 13:39 | docs: chapter 14, store accounts and app IDs |

### Test count history

| Point | Tests | Analyzer |
|---|---:|---|
| Domain + core (Tasks 2–4) | 45 | – |
| + auth + repositories (Tasks 5–6) | 64 | – |
| + theme, auth UI, trail controller (Tasks 1/7/9) | 83 | – |
| + map, UI, replay, shares, friends (Tasks 8/10–13) | 119 | 66 issues → 0 |
| + C1/I1/I2 fixes | 124 | 0 |
| + six minors | 131 | 0 |

### Final review findings and outcome

| ID | Finding | Fix | Test (RED→GREEN) |
|---|---|---|---|
| C1 | Offline renewal returned null → `ApiClient` threw `AuthExpired` → user signed out after >1 h background on flaky network; 5xx/throttling from Cognito wiped the session | `_renew` rethrows `NetworkError`, only `NotAuthorizedException` drops session; `AuthController.build` treats `NetworkError` as signedIn | `offline refresh keeps session and says "offline"…`, `Cognito hiccup (5xx, throttling) keeps the session`, `cold start offline with a stored session: stay signed in`, api_client `token renewal offline -> NetworkError` |
| I1 | Shares/Friends bottom sheet survived sign-out (secret share links visible on the welcome screen) | `FindMeApp` → ConsumerStatefulWidget with `navigatorKey`; `ref.listen(signedInProvider)` → `popUntil(isFirst)` | `an open sheet closes when the session expires` (app_test) |
| I2 | FriendsController created `Timer.periodic` after awaits; sign-out mid-load leaked 2 timers + `UnmountedRefException` | timers created synchronously in `build`, cancelled in `onDispose`; `ref.mounted` guards | `sign out during the first load leaves no timers behind` (periodicTimerCount 2 → 0) |
| M1 | Unnamed stops never renamed (no port of web `RENAME_MS`) | `load({quiet, full})`, `_renamed`, `_rename` timer, `renameMs = 20000` | `unnamed stops after a full load: one full reload 20 s later…`, `named stops: no extra full reload` |
| M2 | Range switch during a quiet tick → next refresh 14 s | `_tick` returns without rescheduling if `_seq != seq + 1` | `switching range during a background refresh keeps the 7 s rhythm` |
| M3 | Resume didn't refresh stale friend routes | `resumed()` also `_loadToday()`; `clock.now()` | `back in the app: stale friend routes refresh at once` |
| M4 | `findme:start` / `findme.shownFriends` carried over to next account | `Prefs.clear()`, called in `signOut` (with logout) and `expired` | `leaving the account forgets this phone's map start and shown friends` |
| M5 | `flyToProvider` survived sign-out | `FlyTo.build` watches `signedInProvider` | `the fly-to target is dropped on sign out` |
| M6 | Shares sheet read `ref` after dismissal mid-call | `if (mounted)` before `ref.read` in `_run` | `closing the sheet while a call is running does not crash` |

### CI failures (owner-pasted logs)

| Run | Failing step | Error | Fix |
|---|---|---|---|
| 1 | Generated code is up to date | `diff --git a/.flutter-plugins-dependencies` (Windows `C:\\Users\\…` vs `/home/runner/…` paths) | untrack `.flutter-plugins-dependencies`, `.idea/libraries/Dart_SDK.xml`, `.idea/libraries/KotlinJavaRuntime.xml`, `.idea/modules.xml`, `.idea/runConfigurations/main_dart.xml`, `.idea/workspace.xml`, `android/findme_android.iml`, `findme.iml`; check only `*.g.dart`/`*.freezed.dart` |
| 2 | build apk (`assembleDevDebug`, after NDK r28c download, 2m49s) | `Build file '/home/runner/work/findme/findme/android/build.gradle.kts' line: 19 … Product Flavor dev contains custom resource values, but the feature is disabled.` | `buildFeatures { resValues = true }` |
| 3 | unknown | owner said "ci done"; status not shown | – |

Also seen in run 1 log: `W These options have been removed and were ignored: --delete-conflicting-outputs` (new
build_runner ignores `-d`; harmless, left as is).

### Environment facts

| Item | Value |
|---|---|
| OS | Windows 10 Enterprise LTSC 2021 10.0.19044, TZ "SE Asia Standard Time" (UTC+7) |
| Flutter | 3.47.9 stable, rev c197ca5199 (2026-10-29), engine 9e025265be, at `C:\src\flutter`, not on PATH |
| Dart | 3.13.7 |
| Java | 17.0.12 LTS (Oracle) |
| Android SDK | absent |
| Admin rights | none (not in Administrators) |
| Free disk C: | 8.8 GB |
| Android Studio installer | `C:\Users\DatNT4\Downloads\android-studio-rabbit2-windows.exe`, 2026.2.2.8, signed Google LLC (DigiCert G4), `/S` + RunAs → exit 1812 |
| AGP in project | 9.1.0 |
| GitHub | `thatwasmiu/findme`, private; `gh` not installed |

### Dependencies (pubspec.yaml)

```yaml
dependencies: clock ^1.1.3, dio ^5.11.1, flutter_map ^8.3.2, flutter_riverpod ^3.4.3,
  flutter_secure_storage ^11.2.0, freezed_annotation ^3.1.0, json_annotation ^4.12.0,
  latlong2 ^0.10.1, share_plus ^13.3.1, shared_preferences ^2.5.6
dev_dependencies: build_runner ^2.16.2, fake_async ^1.3.3, freezed ^4.0.3, integration_test (sdk),
  json_serializable ^6.15.2, mocktail ^1.0.5, very_good_analysis ^11.0.0
```

### Store facts researched (ch.14)

| Store | Free path | Paid path |
|---|---|---|
| Apple | Free Apple ID "Personal Team" in Xcode: own devices, installs expire after 7 days, ~3 apps/device, no TestFlight | Apple Developer Program 99 USD/yr; approval 24–48 h; Org needs D-U-N-S; TestFlight builds 90 days |
| Google | Sideload APK, no account | Play Console 25 USD once; personal accounts (after 2023-11-13): closed test ≥12 testers × 14 days before production; org accounts exempt |

## Code Analysis

- `lib/core/network/api_client.dart` — `ApiClient(AppConfig cfg, TokenGetter token, {Dio? dio})`,
  `Future<dynamic> send(String method, String path, {Object? body, Map<String, String>? query})`. Null token →
  `AuthExpired`; `DioException` → `NetworkError`; 401 → `AuthExpired`; 403 → `AccountMissing`; 204 → null; other
  non-2xx → `ApiStatus(status, body)` (`reason` = `body['error']`). `validateStatus: (_) => true`.
- `lib/core/errors/app_errors.dart` — sealed `AppError`: `AuthExpired`, `AccountMissing`, `NetworkError`,
  `ApiStatus`, `HttpError`, `ShareInvalid(field)`, `FriendError(code)`, `AuthError(code)`.
- `lib/features/auth/data/auth_repository.dart` — `login`, `getAccessToken` (renew when <60 000 ms left, shared
  `_renewing` future), `logout` (save null then RevokeToken best effort), `signInMessage(Object)` (web `WHY` map).
  `CognitoApi.call(action, body)` POSTs `https://<cognitoHost>/` with `X-Amz-Target:
  AWSCognitoIdentityProviderService.<action>`; error code = `__type` after last `#`.
- `lib/features/auth/presentation/auth_controller.dart` — `enum AuthPhase { loading, signedOut, signedIn, noAccount }`;
  `signedInProvider`.
- `lib/features/trail/presentation/trail_controller.dart` — constants `pollMs = 7000`, `idlePollMs = 60000`,
  `renameMs = 20000`; `nowProvider` (clock injection); `TrailState {range, track, loading, error, tick}`;
  `load({quiet, full})` with `_seq` guard; `_tick` doubles `_delay` when `last.ts` unchanged; `paused()`/`resumed()`;
  `FlyTo` notifier.
- `lib/features/friends/presentation/friends_controller.dart` — `friendsPollMs = 7000`, `routeMs = 60000`;
  `FriendsState {me, relations, shownIds, live, today}`; `shown` getter filters to current friends;
  `friendsOnMapProvider` builds `MapFriend`s (`live[id] ?? today[id].last`).
- `lib/features/replay/presentation/replay_controller.dart` — `togetherMs = 60000`; `ReplayState {track, own, clock,
  pos, playing, speed, totalMs}`; `start(own, {others, live})` uses `togetherSpan`; stops on range change.
- `lib/features/trail/domain/` — `TrackPoint(lon, lat, t, [acc])` wire format `[lon, lat, epochSec, acc|null]`;
  `isoMs()` always emits `.mmmZ`; `Preset { today, yesterday, d7, d30 }`; `tailFrom` margin 15 min; `timeline` drops
  moves <100 m; `topStops` n=10; `friendColor` = web hash `(h*31 + codeUnit) & 0xFFFFFFFF` % 8.
- `lib/features/trail/presentation/paw_layer.dart` — `pawSize` 14/11/8/6 at zoom ≥17/15/13; `samePoints`;
  `nearestPrint(maxPx 14)`; paws alpha 0.85, side offset `±s*0.35`.
- `lib/features/trail/presentation/map_view.dart` — `home = LatLng(21.0285, 105.8542)`; first data: last point zoom
  16 + `rememberStart`, else fit points (padding 60, maxZoom 16); fly zoom 17 / 800 ms; stop marker size
  `min(46, 20 + sqrt(sec/60)*2.2)`; tiles `tile.openstreetmap.org`, `userAgentPackageName: 'app.findme.mobile'`,
  pastel `ColorFilter.matrix`; `showTiles` false in tests.
- `lib/core/storage/prefs.dart` — keys `findme:start` (4-decimal `[lon, lat]`), `findme.shownFriends`; `clear()`.
- `lib/app.dart` — `FindMeApp` (navigatorKey + sheet popping) and `ConfigErrorApp`; `lib/main.dart` catches the
  config `StateError`.

## Files Changed

### Source code (lib/)
- `main.dart`, `app.dart` — entry, config error app, screen switch, pop sheets on sign-out.
- `core/config/app_config.dart` — `AppConfig.fromEnvironment/fromMap` (keys `API_URL`, `AUTHORITY`, `CLIENT_ID`,
  `WEB_ORIGIN`), `api`, `web`, `cognitoHost`, `appConfigProvider`.
- `core/network/api_client.dart`, `api_client_provider.dart`; `core/errors/app_errors.dart`.
- `core/storage/prefs.dart`; `core/time/format.dart` (`ago`, `duration`, `remaining`, `hhmm`, `hhmmIso`, `hhmmSec`,
  `dm`, `dayMonth`, `ymd`).
- `core/theme/palette.dart`, `app_theme.dart`; `core/widgets/pill.dart` (`PillStyle {plain,on,lav,ghost}`, badge),
  `card_box.dart` (`CardBox`, `Notice`).
- `features/auth/data/{cognito_api,session_store,auth_repository}.dart`;
  `features/auth/presentation/{auth_controller,welcome_screen}.dart` (`noAccountText`, `SignInForm`).
- `features/trail/domain/{models,colors,date_range,trail_math}.dart` (+ `models.freezed.dart`, `models.g.dart`).
- `features/trail/data/track_repository.dart`.
- `features/trail/presentation/{trail_controller,map_view,paw_layer,map_screen,top_bar,date_filter,trail_sheet}.dart`.
- `features/replay/domain/replay_math.dart`; `features/replay/presentation/{replay_controller,replay_bar}.dart`.
- `features/shares/domain/share.dart` (+generated); `data/shares_repository.dart`; `presentation/shares_sheet.dart`
  (`shareLink`, `shareLauncherProvider`).
- `features/friends/domain/friend_models.dart` (+generated); `data/friends_repository.dart`;
  `presentation/{friends_controller,friends_sheet}.dart`.

### Tests
- `test/helpers/fake_adapter.dart` (FakeAdapter, `fakeDio`, `sentBody`, `offline`), `test/helpers/fakes.dart`
  (MockAuth/Track/Shares/Friends, MemoryPrefs, `testConfig`, `fakeAuth`, `baseOverrides`, `tallView`).
- `test/core/{config,network,time,widgets}/…`, `test/features/{auth,trail,replay,shares,friends}/…`,
  `test/app_test.dart` (2 full-app flows), `integration_test/app_test.dart` (wraps app_test on device).

### Config / platform / CI
- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `.gitattributes` (`* text=auto eol=lf`),
  `config/example.json`, `.vscode/launch.json`, `.github/workflows/ci.yml`.
- `android/app/build.gradle.kts` (applicationId `app.findme.mobile`, flavors dev/prod, `resValues = true`),
  `android/app/src/main/AndroidManifest.xml` (INTERNET permission, `@string/app_name`),
  `ios/Runner.xcodeproj/project.pbxproj` (bundle id), `ios/Runner/Info.plist` (display name "Find Me").
- `assets/images/hachiware.webp` (copied from `travel-heatmap/web/public`).

### Docs
- `CLAUDE.md`, `README.md`, `docs/HANDOFF.md`, `docs/guide/00…14 + README + cheatsheet`, spec, plan.

## User Feedback & Preferences (REQUIRED — never omit)

- Session runs with **caveman mode** (terse prose) and **ponytail mode** (laziest working solution, no unrequested
  abstractions) active from hooks.
- "project set up of an enter price and profesionall project" → meaning: "clean code structure, also some set up for
  testing and intergrate with other tool, I dont have mobile app dev experience so have detail docs for me".
- On tools: "tools like emulator or something, what does a mobile project usually need ?" (delegates tooling choices).
- "no Mac for now"; "same design for now"; "Android/emulator fine" (v1 audience).
- "login normal user only" (no admin in the app).
- Approved the design ("Approve, plan it"); chose **"native"** execution; "complete set up chapter first so I can
  start install depenances".
- "cannot set up for now continue the implementation, resume setup latter"; approved me installing the Flutter SDK.
- Gave the GitHub URL without words → treated as "add remote and push" (done after checking remote empty).
- Pasted CI logs without comment → expects me to diagnose and fix.
- Asked for docs on iOS ids "(both $90 and 7 day expired)" and "android also" (fee is actually 99 USD).
- "is flutter install in this computer", "is it neccessary to install android studio", then "install for me, check
  error if any" (wants hands-off help with machine setup).
- Wants beginner-level explanations; prefers concrete commands (PowerShell, copy-pasteable).

## Where We're Going

1. **Get the owner's answer on the Android SDK route.** Recommended **option A**: download Android command-line tools
   from `dl.google.com` (needs explicit download permission, ~150 MB), unzip to
   `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest`, then `sdkmanager "platform-tools" "platforms;android-35/36"
   "build-tools;…"`, `flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk"`, `flutter doctor
   --android-licenses`. Run on a real phone with USB debugging (no emulator: needs Hypervisor Platform/admin and
   ~4 GB). Check the exact platform/build-tools versions Flutter 3.47.9 / AGP 9.1 want via `flutter doctor -v`.
   Consider adding these steps to guide ch.01 as an "SDK without Android Studio" alternative (offered, not done).
2. Add `C:\src\flutter\bin` to the user PATH (command given to the owner; not done).
3. Create `config/dev.json` from `travel-heatmap/web/public/config.json` + `WEB_ORIGIN`; `flutter run --flavor dev
   --dart-define-from-file=config/dev.json` on the phone; compare with the web on the same day (paw colours/sizes,
   stop sizes, tile tint, wording).
4. Run `flutter test integration_test --flavor dev --dart-define-from-file=config/example.json` on the device.
5. Confirm CI run 3 (and the macOS iOS job) passed — ask the owner for the Actions result; the iOS job is the first
   ever iOS build.
6. Keep `docs/HANDOFF.md` current with each of these.

## Risks & Blockers

- **No admin rights** on a company-managed laptop: blocks Program Files installs, Windows Hypervisor Platform
  (emulator), Developer Mode may also be blocked (Flutter plugins need symlinks → "Building with plugins requires
  symlink support"; `flutter pub get` already worked, but Android builds may hit it).
- **8.8 GB free on C:** — tight even for option A once Gradle caches and NDK (r28c was downloaded in CI) land locally.
- iOS never built; first macOS CI job may surface iOS-only errors (e.g. minimum iOS version for plugins).
- Real API untested from the app: field names were ported from web code/tests, not exercised against the live stack.
- CI-produced APK uses `config/example.json` placeholders: sign-in can't work with it.

## Open Questions

- Option A / B / C for the Android SDK? (asked, unanswered)
- Did CI run 3 (and the iOS job) go green?
- Real `WEB_ORIGIN` (CloudFront / own domain) for share links — unknown to me.
- Does the owner have an Android phone available for USB testing?
- Should ch.01 get an "SDK without Android Studio" section?

## Quick Start for Next Session

```bash
# Reference docs
cat CLAUDE.md docs/HANDOFF.md
# docs/superpowers/specs/2026-11-02-findme-flutter-app-design.md
# docs/superpowers/plans/2026-11-02-findme-flutter-app.md

# Key files to read first
# lib/app.dart, lib/features/trail/presentation/trail_controller.dart,
# lib/features/auth/data/auth_repository.dart, lib/core/network/api_client.dart, .github/workflows/ci.yml

# Verify current state (Flutter is not on PATH)
C:/src/flutter/bin/flutter test        # expect: All tests passed! (131)
C:/src/flutter/bin/flutter analyze     # expect: No issues found!
git log --oneline -3                   # expect 02e1f93 at top

# Machine state
powershell -c "Test-Path $env:LOCALAPPDATA\Android\Sdk"   # False until the SDK is installed

# Next action
# Ask the owner: "Go ahead with option A (Android SDK command-line tools in your user folder, no admin,
# ~3-4 GB, run on your Android phone over USB)?" — then download only with their explicit OK.
```

## Rulings Ledger (from the deleted execution ledger, in order)

| # | Ruling | Cost if wrong |
|---|---|---|
| 1 | `git init` before `flutter create` (scripts needed a repo) | none |
| 2 | Tasks 2–3 implemented before watching tests fail (SDK still downloading); tests written first, ported with concrete web values | a vacuous test could slip through |
| 3 | Claude cloned Flutter 3.47.9 with owner OK; APK/emulator/integration deferred to owner setup | Android-only build errors surface later (two did, in CI) |
| 4 | FakeAdapter instead of http_mock_adapter | none |
| 5 | Lint `unnecessary_type_name_in_constructor` disabled | none |
| 6 | Plain Riverpod, no riverpod_generator | mechanical to add later |
| 7 | No go_router | add later if deep links |
| 8 | `signedInProvider` instead of `sessionEpochProvider` | none |
| 9 | No bundled Nunito | slightly different letterforms |
| 10 | Resume next refresh 14 s (web-exact) | none |
| 11 | SnackBar instead of popups | looks different from Leaflet |
| 12 | Hand-written fly-to animation | none |
| 13 | `showDateRangePicker` for custom range | different interaction from web's two inputs |
| 14 | Lints `cascade_invocations`, `avoid_catching_errors` disabled | none |
| 15 | `getAccessToken` throws `NetworkError` offline (web returns null) | none found; web keeps old behaviour |
| 16 | Prefs cleared on sign-out/expiry (web keeps) | same user re-signing loses shown-friends choice |

## Web Parity Reference (values ported verbatim)

| Area | Value |
|---|---|
| Share link | `${WEB_ORIGIN without trailing /}/s/<id>` (opens the web share page) |
| Share presets | `1 giờ` / `1 ngày` / `7 ngày` / `Chọn ngày`; route opt-in "Cho xem cả đường đi 🐾" |
| Share invalid messages | label: "Tên cần từ 1 đến 40 ký tự nhé."; expiresAt: "Hạn dùng phải ở tương lai và tối đa 365 ngày."; routeFrom: "Ngày bắt đầu đường đi phải là hôm nay hoặc trước đó." |
| Friend errors | code "Không tìm thấy mã này.", self "Đây là mã của bạn mà 😄", already "Hai bạn đã là bạn bè rồi.", pending "Đã gửi lời mời rồi, chờ bạn ấy nhé." |
| Track errors | 400 "Chọn tối đa 31 ngày một lần nhé 📅", other "Chưa tải được dấu chân — thử lại sau chút nhé ✨" |
| Sign-in | button "Đăng nhập 💖" / busy "Đang đăng nhập…"; NotAuthorized/UserNotFound "Sai email hoặc mật khẩu." |
| Welcome | "Đang khởi động…" / "Mọi nơi bạn đã đi qua, gói gọn trong một tấm bản đồ xinh xắn." |
| No account (app wording) | "Tài khoản này chưa dùng được bản đồ. Đây có thể là tài khoản admin: hãy quản trị trên trang web /admin." |
| Trail sheet | "📅 Nhật ký ngày", "⭐ Chỗ dừng nhiều nhất", "🛵 di chuyển · 2,2 km" (comma decimal), "Một nơi xinh xinh", empty "Chưa có dấu chân nào trong khoảng này 🐾" |
| Paw colours | 05–11 `#fb923c`, 11–17 `#ec4899`, 17–21 `#f43f5e`, else `#8b5cf6` |
| Friend colours | `0ea5e9 10b981 6366f1 14b8a6 84cc16 0891b2 a855f7 64748b` |
| Palette | pink `#ec4899`, pinkSoft `#fce7f3`, lavender `#ede9fe`, ink `#3f2a3a`, muted `#9b7b92`, page `#fff7fb`, error `#be123c` |
| Replay | 120 ms/print, min 10 s; together 60 s; speeds 0.5,1,2,4,8 |
| Timings | trail 7 s → ×2 → 60 s; friends list 7 s; friend route 60 s; token renew when <60 s; rename reload 20 s |

## Spec Highlights Not Repeated Above

- Spec non-goals: no location recording, no backend/API change, no in-app public share page (`ShareView`), no
  admin page, no redesign, no store release now, no crash reporting/analytics/push, Vietnamese only.
- Anti-goals: behaviour silently different from web; tokens in plain storage or sensitive data in logs; tests hitting
  AWS; over-abstraction; docs assuming prior mobile knowledge.
- Plan Review Focus (all checked by the final reviewer as OK after fixes): quiet-refresh offline, refresh-token expiry
  wipes state, stale range response ignored, background pause/resume, fallbacks for unnamed stop / unseen friend /
  expired share.
- Builder-check subagent questions (answered): admin access model (later moot: admin removed), v1 phone ("Android/
  emulator fine"), private repo macOS minutes (iOS job only on main/dispatch).

## What the CI Run Produces (as explained to the owner)

- Artifacts: `app-dev-debug-apk` (zip with `app-dev-debug.apk`, placeholder config → installs, sign-in won't work)
  and `coverage` (`lcov.info`). iOS job produces no file (compile check only).
- Local working APK requires real `config/dev.json`:
  `flutter build apk --flavor dev --debug --dart-define-from-file=config/dev.json`.

## Gotchas for the Next Agent (Windows shell)

- `python` on this PC is the Microsoft Store stub: any command invoking it **hangs** (a whole Bash call timed out at
  600 s because of `python - <<'EOF'`). Use PowerShell or sed/awk.
- A bare `cat > file` with no heredoc waits on stdin and hangs the Bash call (happened once, 120 s timeout).
- Multi-line `sed` inserts on Windows Git Bash collapse newlines in some forms (`sed -i "Ni\\ …"` produced one line);
  prefer the Edit tool for code edits.
- Long Flutter commands: wrap with `timeout N` and keep output in a file (`> /tmp/t.log`), then grep.
- `dart format` runs after edits reformat files; the harness then reports "file changed on disk" — expected.
- Git warns "LF will be replaced by CRLF" on every add; `.gitattributes` now forces LF.
- First `flutter` invocation on a fresh SDK takes >10 min (Dart SDK download); run it in the background.
- In fakeAsync tests, Riverpod rebuilds need `f.elapse(Duration.zero)`, and time-based logic must use
  `package:clock` (`clock.now()`), not `DateTime.now()`.

## Session Closed
**Closed at:** 2026-11-03 13:59 +0700
**Commit:** the `session: findme-flutter-app` commit that includes this note
**Session status:** Handed off to next session
