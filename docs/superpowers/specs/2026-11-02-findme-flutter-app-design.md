# Find Me mobile app (Flutter): design

Date: 2026-11-02. Status: draft, waiting for owner approval.

## 1. Intent and why

The owner runs "Find Me" (`C:\Users\DatNT4\Desktop\works\travel-heatmap`): the Overland iPhone app uploads location
fixes to an AWS serverless API, and a Vietnamese pastel PWA (`travel-heatmap/web`, Vite + React 19 + Leaflet) shows a
paw-print trail, stops, a day diary, replay, share links, friends and an admin page.

This project is a **native Flutter app for iOS and Android that does exactly what the web app does, against the same
API and the same Cognito user pool**, with the same look. The owner wants it set up the way a professional team would:
clean layered code, testing from day one, standard mobile tooling, and CI.

The owner has **no mobile development experience**, so detailed, beginner-friendly docs are a first-class deliverable,
not an afterthought. They should teach, the way `travel-heatmap/docs/guide/` teaches each AWS piece.

## 2. Goals

1. **Feature parity with `travel-heatmap/web`** (the web code is the behaviour spec; read it for any detail this
   document does not state):
   - Sign-in: email + password straight against Cognito's API (`InitiateAuth` `USER_PASSWORD_AUTH`), quiet refresh
     with the refresh token (one shared renewal for concurrent callers), sign-out with `RevokeToken`
     (`web/src/auth.ts`). Phases: loading / signed out / signed in / "no account" (login has no map, e.g. admin).
   - Map: OSM tiles, own paw prints coloured by local hour, each print pointing toward the next and stepping
     left/right (`paws.ts`), stops as 🐾 markers sized by stay length, the Hachiware marker on the last point, start
     view = last point this device showed (zoom 15) else Hà Nội (zoom 13) (`startView.ts`, `MapView.tsx`).
   - Date filter: presets today / yesterday / 7 days / 30 days / all, plus a custom range; max 31 days per request
     (HTTP 400 → the same Vietnamese message) (`dateRange.ts`, `DateFilter.tsx`).
   - Live refresh: full range once, then only the newest part (`tailFrom` + `mergeTail`), polling every 7 s, backing
     off ×2 to 60 s when nothing is new, immediately on returning to the foreground; a past range only re-renders the
     "👀 x phút trước" label. Only the latest load may update state.
   - Trail panel: one day → timeline of stops and moves (`timeline`); many days → top places (`topStops`); tap → fly
     to it (`TrailPanel.tsx`).
   - Replay: alone, print by print; with friends shown and a range reaching today, everyone together by the clock
     (`atTime`, `togetherSpan`, ~60 s at 1×) (`ReplayBar.tsx`).
   - Share links: create (label, expiry, route on/off, route start day), list, edit, revoke, copy link, system share
     sheet (`SharePanel.tsx`, `api.ts`). Link = `<web origin>/s/<id>`; it opens the **web** share page, so the app
     needs the web origin in its config.
   - Friends: my name + friend code (copy), send request by code, accept/decline, remove/cancel, show/hide a friend on
     the map (remembered on the device), friends' live positions every 7 s, a shown friend's today prints every 60 s,
     each friend in a stable colour (`friendColor`), incoming-request badge (`useFriends.ts`, `FriendsPanel.tsx`).
   - **Normal users only (owner's decision):** no admin screen. A login without a map account (e.g. the admin)
     lands on the "no account" screen: a Vietnamese message saying this account has no map and admin work is done on
     the web's `/admin` page, plus a sign-out button.
   - Signing out wipes everything of that account from memory (trail, replay, friends, shown friends' data).
2. **Same design**: same pastel palette (`styles.css` `:root`), same emoji-rich Vietnamese wording, same paw prints
   and Hachiware marker (`web/public/hachiware.webp`), adapted to a phone layout (panels become bottom sheets, safe
   areas respected).
3. **Professional structure and tooling** (section 5).
4. **Beginner docs** (section 6).

## 3. Non-goals

- Recording or uploading location. Overland keeps doing that; the app is a viewer.
- Any backend or API change, any new AWS resource, any change to `travel-heatmap`.
- The public share page inside the app (`ShareView`): share links keep opening in the browser.
- The admin page (`web/src/admin/`): stays web-only.
- A redesign. Fresh mobile design is a later, separate decision.
- App Store / Play Store release now (documented as a later chapter, not done).
- Crash reporting, analytics, push notifications (polling stays, as on the web).
- Other languages than Vietnamese (no i18n framework).

## 4. Anti-goals (would be a failure even if it runs)

- Behaviour that silently differs from the web (different "today", different backoff, a share link pointing at the
  wrong host, a friend's data surviving sign-out).
- Tokens in plain storage (`SharedPreferences`), or tokens, coordinates, codes, emails or passwords in logs.
- Tests that call the real AWS API or Cognito.
- An over-abstracted codebase a beginner cannot follow: no layer, interface or package without a job.
- Docs that assume prior Flutter, Android or iOS knowledge.

## 5. Constraints and decided how

### Environment

- Owner's machine: Windows 10, **no Mac**. Daily development and testing on the **Android emulator** (Android Studio).
- **v1 audience (owner's answer):** the Android emulator or an Android phone is enough. Installing on an iPhone
  (cloud Mac, signing, TestFlight, Apple developer account) is out of v1 scope.
- Code stays iOS-ready: iOS project generated, only plugins that support both platforms, iOS settings
  (Info.plist entries, bundle id) filled in. iOS is compiled in CI on a GitHub Actions macOS runner
  (`flutter build ios --no-codesign`) so iOS breakage is caught without a Mac. Running on a real iPhone and signing
  is a later chapter.
- Location: `C:\Users\DatNT4\Desktop\works\findme` (currently empty, not a git repo).

### Stack (builder's defaults, stated to the owner, changeable)

| Concern | Choice | Why |
|---|---|---|
| Framework | Flutter stable (latest at build time), Dart 3 | the owner's ask |
| Map | `flutter_map` + OSM tiles | Flutter twin of Leaflet, same tiles, no API key |
| Paw prints | one `CustomPainter` layer over the map (port of `PawLayer`) | thousands of prints, no widget per print |
| State | Riverpod (with code generation) | testable, common in professional Flutter |
| Routing | go_router | declarative routes, redirect on auth phase |
| HTTP | dio, one client with an auth interceptor (bearer + 401/403 mapping) | central error mapping like the web's `call()` |
| Models | freezed + json_serializable | immutable models, generated JSON |
| Secure storage | flutter_secure_storage (Keychain / Android Keystore) | session tokens |
| Small prefs | shared_preferences | start view, shown friends (not secret) |
| Share sheet / clipboard | share_plus / `Clipboard` | web's `navigator.share` / clipboard |
| Lints | very_good_analysis | strict, well known |
| Tests | flutter_test, mocktail, http mocking at the dio layer, integration_test | no network in tests |

### Architecture

Feature-first, each feature split into `data` (API client, DTOs, repository implementation), `domain` (models, pure
logic) and `presentation` (screens, widgets, Riverpod providers). Shared code in `core/` (config, HTTP client, error
types, theme, formatting helpers). Pure logic from `trail.ts` / `dateRange.ts` (ago, duration, timeline, topStops,
tailFrom, mergeTail, atTime, togetherSpan, presetRange, customRange, liveTo…) is ported **one-to-one with its unit
tests**, ported from the web's `*.test.ts`.

```
lib/
  main_dev.dart, main_prod.dart      # one entry point per flavor
  app.dart                           # MaterialApp.router, theme
  core/       config/ network/ errors/ storage/ theme/ utils/
  features/   auth/ trail/ replay/ shares/ friends/
test/         mirrors lib/
integration_test/
```

### Environments (flavors)

`dev` and `prod` Android product flavors and iOS schemes, each with its own app id suffix and config (`apiUrl`,
`authority`, `clientId`, `webOrigin`). Config comes from gitignored JSON files passed with `--dart-define-from-file`
(e.g. `config/dev.json`), with a committed `config/example.json`, mirroring the web's gitignored `config.json`. Both
may point at the same stack today (the owner has one); the split exists so a staging stack can be added without code
changes.

### Errors and logging

Typed errors mirroring the web (`AuthExpired`, `AccountMissing`, `ShareInvalid(field)`,
`ShareExpired`, `FriendError(code)`), mapped in one place. User-facing messages in
Vietnamese, same strings as the web. Debug logging only in dev builds, never with personal data.

### Quality gates and CI (GitHub Actions)

On every push / PR (Ubuntu): `dart format --set-exit-if-changed`, `flutter analyze`, `flutter test --coverage`,
build Android debug APK (dev flavor). *Builder's call:* `flutter build ios --no-codesign` on macOS runs only on
pushes to `main` and on manual dispatch, because macOS minutes cost 10× on private repos. The repo starts with
`git init` locally; creating the GitHub repo and remote is a docs step the owner does. Integration tests run locally on the
emulator (CI emulator runs are optional, documented). Generated code (`*.g.dart`, `*.freezed.dart`) is committed
**or** generated in CI: builder's call, documented.

## 6. Docs (deliverable)

`docs/guide/`, one chapter per topic, in English (owner's working language with Claude), plain words, every command
copy-pasteable for **Windows PowerShell**, screenshots optional. Proposed chapters:

0. What Flutter is, how a mobile app differs from the web app you know (with a web → Flutter concept map:
   component → widget, useState/hooks → Riverpod providers, fetch → dio, localStorage → secure storage/prefs).
1. Installing tools on Windows: Flutter SDK, Android Studio, Android SDK, an emulator, VS Code + Flutter extension,
   `flutter doctor` and fixing what it reports.
2. Running the app: config files, flavors, `flutter run`, hot reload, debugging, reading logs.
3. Project structure and architecture: folders, layers, how a request flows from a button to the API and back.
4. One chapter per feature (auth, map + paws, date filter + live refresh, trail panel, replay, shares, friends):
   what it does, which files, how it maps to the web code.
5. Testing: unit, widget, integration; how to run, how to write one, coverage.
6. Code generation, lints and formatting.
7. CI: what the workflow does, reading a failed run.
8. Later: iOS without a Mac (cloud Mac / Codemagic), signing, App Store and Play Store release.

Plus `docs/guide/cheatsheet.md` (every command and config key), a `README.md` quick start, a `CLAUDE.md` for future
sessions, and `docs/HANDOFF.md` kept current, mirroring the `travel-heatmap` conventions.

## 7. Left to the builder

- Exact phone layout of each panel (bottom sheet heights, where the top bar buttons sit), within "same design".
- Package versions, Riverpod style details, folder names below the feature level.
- How the paw painter maps lat/lon to screen (via `flutter_map`'s camera) and when it skips redraws.
- Whether generated code is committed.
- Font: Nunito via bundled asset or `google_fonts`.
- App id (`com.<owner>.findme` or similar) and app icon (reuse `web/public/icon-512.png`).
