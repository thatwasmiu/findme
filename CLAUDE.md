# CLAUDE.md

Guidance for Claude Code in this repository.

"Find Me" mobile: a Flutter app (Android now, iOS-ready) that does what the `travel-heatmap/web` viewer does for
normal users, against the same AWS API and Cognito pool, same pastel look, Vietnamese UI. The backend and the web app
live in `C:\Users\DatNT4\Desktop\works\travel-heatmap` (read its `CLAUDE.md`); the web source (`web/src`) is the
behaviour spec. Design: `docs/superpowers/specs/2026-11-02-findme-flutter-app-design.md`; plan:
`docs/superpowers/plans/2026-11-02-findme-flutter-app.md`. Learning guide for the owner (new to mobile):
`docs/guide/`.

## Commands (PowerShell)

Flutter lives in `C:\src\flutter` (`C:\src\flutter\bin\flutter` if not on PATH).

```powershell
flutter pub get
dart run build_runner build -d          # after changing freezed / json / riverpod annotated code
flutter analyze
dart format .
flutter test                            # unit + widget tests, no device needed
flutter test test/features/trail        # one folder
flutter run --flavor dev --dart-define-from-file=config/dev.json
flutter test integration_test --flavor dev --dart-define-from-file=config/example.json   # needs emulator
flutter build apk --flavor dev --debug --dart-define-from-file=config/example.json
```

## Architecture

Feature-first: `lib/features/<auth|trail|replay|shares|friends|tracker|pins>/{data,domain,presentation}`, shared code in
`lib/core/`. Pure logic is ported one-to-one from `travel-heatmap/web/src` (`trail.ts`, `dateRange.ts`, …) with its
tests. Riverpod providers own state and polling; every account-scoped provider watches `sessionEpochProvider`, so
signing out rebuilds them empty. Exception: the tracker (background GPS -> `/ingest`, replaces Overland) ignores
the session; only a deliberate sign-out or another account signing in ends it. One `ApiClient` (dio) adds the bearer token and maps 401/403; repositories map their
own 400/404/409 like the matching web function.

## Conventions

- UI copy is Vietnamese, copied verbatim from the matching web file. No admin screen (normal users only).
- Tokens only in `flutter_secure_storage`. Never log tokens, coordinates, share ids, friend codes, emails, passwords.
- Tests never touch the network. Generated code (`*.g.dart`, `*.freezed.dart`) is committed.
- `config/dev.json` and `config/prod.json` are gitignored; `config/example.json` is the template.
- Deliberate shortcuts are marked `ponytail:` with their ceiling.
- A feature gets a guide chapter or section plus cheatsheet lines.
- `docs/HANDOFF.md` is the current state; update it in the same change whenever that state changes.
