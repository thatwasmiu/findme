# 00. Flutter for web developers

You already know the Find Me web app: React components, `fetch`, `localStorage`, Vite, Vitest. This chapter maps
those ideas onto Flutter so the rest of the guide reads naturally. No commands yet.

## What Flutter is

- **Flutter** is Google's toolkit for building one app that runs on Android, iOS (and web/desktop). You write the
  code once; Flutter compiles it to a real native app for each platform.
- **Dart** is the language. It looks like TypeScript with classes: static types, `async`/`await`, `null` safety
  (`String?` means "may be null", like `string | null`).
- Flutter does **not** use the phone's built-in buttons and lists. It draws every pixel itself (like a game engine
  drawing a canvas). That is why the app can look the same on Android and iPhone: the same pastel pills everywhere.

## How a mobile app differs from the PWA

| Web (PWA) | Mobile app |
|---|---|
| Opens from a URL; updates when you reload | Installed as a file (`.apk` on Android, `.ipa` on iPhone); updates by installing a new version |
| Runs in the browser; the browser gives you `fetch`, `localStorage`, `navigator.share` | Runs directly on the phone; you add **packages** (libraries) for HTTP, storage, sharing |
| One build works everywhere | One build **per platform**: Android needs the Android SDK (works on Windows), iPhone needs Xcode (only on a Mac) |
| Dev server on `localhost:5173`, refresh the tab | `flutter run` installs the app on an **emulator** (a fake phone on your PC) or a real phone; **hot reload** updates it in about a second |
| Hosted on S3 + CloudFront | Distributed through Google Play / App Store (or by sending the `.apk` file) |
| Background tabs get throttled | Apps get **paused** when you switch away; the app must stop polling and resume when you come back |

The Find Me app still talks to the **same AWS API and the same Cognito user pool** as the web. Nothing changes on the
server.

## Concept map: React → Flutter

| React / web concept | Flutter concept | Notes |
|---|---|---|
| Component (`function TopBar()`) | **Widget** (`class TopBar extends StatelessWidget`) | Everything on screen is a widget: text, padding, a whole screen |
| JSX `<div><span/></div>` | Nested widget constructors `Column(children: [Text('hi')])` | Layout is widgets too: `Row`, `Column`, `Padding`, `Stack` |
| CSS (`styles.css`) | Widget properties + a **Theme** | No stylesheet; colours live in one `Palette` class |
| `useState` | `StatefulWidget` + `setState` | Fine for tiny local state (a text field) |
| Custom hooks (`useFriends`), context | **Riverpod providers** | Shared state and logic live in providers; widgets *watch* them and rebuild when they change |
| `useEffect` + `setTimeout` polling | A provider with a `Timer` | Plus an app-lifecycle listener to pause when the app is in the background |
| `fetch` | **dio** (an HTTP package) | One client adds the `Authorization: Bearer` header for every call |
| `localStorage` (session) | **flutter_secure_storage** | Uses Android Keystore / iPhone Keychain: encrypted, safer than the web |
| `localStorage` (small settings) | **shared_preferences** | Start view, which friends are shown |
| URL routes (`/`, `/s/:id`) | **go_router** | Screens have paths; a redirect sends signed-out users to the sign-in screen |
| TypeScript interfaces for API data | **freezed** classes | Immutable data classes; JSON parsing code is *generated* for you |
| Leaflet | **flutter_map** | Same OpenStreetMap tiles, same idea of layers and markers |
| Canvas paw layer (`paws.ts`) | **CustomPainter** | Draws thousands of paws in one go |
| `navigator.share`, clipboard | **share_plus**, `Clipboard` | |
| Vite dev server | `flutter run` + hot reload | Press `r` to reload, `R` to restart |
| Vitest | `flutter test` | Unit tests for logic, **widget tests** for screens, **integration tests** on the emulator |
| ESLint / Prettier | `flutter analyze` / `dart format` | Strict rules from the `very_good_analysis` package |
| `package.json` | `pubspec.yaml` | `flutter pub add <name>` is like `npm install <name>` |
| `node_modules` | Packages cached by `flutter pub get` | |

## Words you will meet

- **SDK**: a toolbox you install (Flutter SDK, Android SDK).
- **Emulator**: a virtual Android phone that runs on your PC.
- **Gradle**: Android's build tool. Flutter calls it for you; you rarely touch it.
- **Flavor**: a build variant. This project has `dev` and `prod`, each with its own config and app name, so both can
  be installed side by side.
- **APK**: the Android app file you can install on a phone.
- **Hot reload**: Flutter swaps changed code into the running app without losing where you are.
- **Code generation**: some files (`*.g.dart`, `*.freezed.dart`) are written by a tool (`build_runner`) from your
  code. Never edit them by hand.

Next: [01. Install the tools on Windows](01-install-tools-windows.md).
