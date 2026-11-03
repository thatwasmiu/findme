# 13. Later: iOS without a Mac, signing, App Store and Play Store

Not done yet. This chapter is the map for when you want it.

## iPhone without a Mac

Building, signing and installing an iPhone app needs Xcode, which only runs on macOS. Options:

| Option | Cost | Notes |
|---|---|---|
| **Codemagic** (codemagic.io) | free tier with limited macOS minutes | Made for Flutter; connects to your GitHub repo, signs and uploads to TestFlight |
| Cloud Mac (MacinCloud, AWS EC2 Mac) | hourly | A full Mac in the browser; you run Xcode yourself |
| Borrow a Mac | free | Install Xcode, `flutter run` on a plugged-in iPhone |

Either way you need an **Apple Developer account** (99 USD/year) to install on iPhones beyond 7-day test installs
and to use **TestFlight** (Apple's beta app for testers).

### dev/prod on iOS

Android has `dev` and `prod` flavors. iOS does not yet: Xcode **schemes** for flavors have to be created in Xcode.
Until then iOS builds take their config only from `--dart-define-from-file`. On a Mac: duplicate the Runner scheme
as `dev` and `prod`, add build configurations `Debug-dev`, `Release-prod`…, and set `PRODUCT_BUNDLE_IDENTIFIER`
(`app.findme.mobile.dev` for dev). Flutter's docs: "Set up flavors for iOS".

## Google Play

1. **Upload key:** `keytool -genkey -v -keystore $env:USERPROFILE\findme-upload.jks -keyalg RSA -keysize 2048
   -validity 10000 -alias upload`. Keep the file and passwords safe and **never commit them** (`*.jks` and
   `key.properties` are in `.gitignore`).
2. Point `android/app/build.gradle.kts` at it with a `signingConfigs { create("release") { … } }` block reading
   `key.properties` (Flutter docs: "Build and release an Android app").
3. Build: `flutter build appbundle --flavor prod --dart-define-from-file=config/prod.json`.
4. Google Play Console (25 USD once) → create app → **Internal testing** → upload the `.aab` → add testers.

## App icon and name

- Icon: add `flutter_launcher_icons` as a dev dependency, point it at `travel-heatmap/web/public/icon-512.png`, run
  `dart run flutter_launcher_icons`.
- Name: Android `resValue("string", "app_name", …)` in `build.gradle.kts`; iOS `CFBundleDisplayName` in
  `ios/Runner/Info.plist`.

## The web's Nunito font

The app currently uses the phone's system font. To match the web: download Nunito (OFL licence) from Google Fonts into
`assets/fonts/`, declare it under `flutter: fonts:` in `pubspec.yaml`, and set `fontFamily: 'Nunito'` in
`lib/core/theme/app_theme.dart`.

## Crash reporting

When real people use the app: Sentry (`sentry_flutter`) or Firebase Crashlytics show crashes from their phones.
Remember the logging rule: no tokens, coordinates, codes, emails or passwords in reports.

Accounts, bundle/application IDs, signing keys and store setup step by step: [14. Store accounts and app IDs](14-store-accounts-and-app-ids.md).
