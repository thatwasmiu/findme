# 11. Code generation, lints, formatting

## Code generation (freezed + json_serializable)

Data classes like `Stop`, `Share`, `Friend` are written short, with an annotation:

```dart
@freezed
abstract class Share with _$Share {
  const factory Share({required String id, required String label, ...}) = _Share;
  factory Share.fromJson(Map<String, dynamic> json) => _$ShareFromJson(json);
}
```

A tool writes the rest (equality, `copyWith`, `toString`, JSON parsing) into `share.freezed.dart` and `share.g.dart`.
After changing an annotated class:

```powershell
dart run build_runner build -d
```

Never edit `*.g.dart` / `*.freezed.dart` by hand. They **are committed**, so you can run the app without generating
first; CI checks they are up to date.

## Lints (`flutter analyze`)

`analysis_options.yaml` uses the strict **very_good_analysis** rule set, with a few rules turned off (each one has a
comment saying why).

```powershell
flutter analyze        # must say "No issues found!"
dart fix --apply       # fixes many issues automatically
```

## Formatting (`dart format`)

```powershell
dart format .
```

One official style, no options to argue about (like Prettier). CI fails if a file is not formatted.

## Before every commit

```powershell
dart format .
flutter analyze
flutter test
```

Next: [12. CI with GitHub Actions](12-ci.md).
