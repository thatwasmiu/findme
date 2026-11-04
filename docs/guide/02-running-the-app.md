# 02. Running the app

You need [chapter 01](01-install-tools-windows.md) done: `flutter doctor` green for Android and an emulator that
boots. Open a PowerShell in the project folder:

```powershell
cd C:\Users\DatNT4\Desktop\works\findme
```

## Step 1. Get the packages

```powershell
flutter pub get
```

Like `npm install`: downloads every package listed in `pubspec.yaml` (the project's `package.json`).

## Step 2. Create your config file

The app needs four values, the same ones the web app reads from `travel-heatmap/web/public/config.json`:

| Key | What it is | Where to find it |
|---|---|---|
| `API_URL` | The Find Me HTTP API | `WEB_ORIGIN` + `/api`, e.g. `https://findme.example.com/api` (the web's `config.json` says only `/api`: the app needs the full address) |
| `AUTHORITY` | The Cognito issuer URL | web `config.json` → `authority` |
| `CLIENT_ID` | The Cognito app client id | web `config.json` → `clientId` |
| `WEB_ORIGIN` | The web app's address (share links open there) | the CloudFront / own domain you open in the browser, e.g. `https://findme.example.com` |

```powershell
Copy-Item config\example.json config\dev.json
notepad config\dev.json
```

Fill in the four values and save. `config/dev.json` is in `.gitignore`: it never gets committed.

> **Why not hard-code them?** The same code builds a "dev" and a "prod" app. Each build reads its own file, so you
> can point dev at a test stack later without touching code.

If you forget the file, the app starts with a red message telling you how to fix it, instead of crashing.

## Step 3. Start the emulator

```powershell
flutter emulators --launch Pixel_7_API_35
flutter devices
```

`flutter devices` should list `sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64`.

## Step 4. Run

```powershell
flutter run --flavor dev --dart-define-from-file=config/dev.json
```

- `--flavor dev` builds the **dev** variant: app name "Find Me Dev", id `app.findme.mobile.dev`. It can sit next to
  the prod app on the same phone.
- `--dart-define-from-file` passes your config into the app.

The first build takes several minutes (Gradle downloads Android build tools). Later builds take seconds.

While it runs, the terminal accepts keys:

| Key | Does |
|---|---|
| `r` | **Hot reload**: swaps your changed code into the running app in about a second, keeps the screen you are on |
| `R` | Hot restart: restarts the app (state is lost), needed after changing `main()` or providers' setup |
| `d` | Detach (app keeps running) |
| `q` | Quit |

## Running from VS Code

The repo ships `.vscode/launch.json` with two configurations. In VS Code: Run and Debug (Ctrl+Shift+D) → pick
**Find Me (dev)** → ▶ (F5). Breakpoints work: click left of a line number, then use the app.

## Seeing logs

- In the `flutter run` terminal, `print`/`debugPrint` output appears directly.
- `flutter logs` shows the device log in another window.
- **DevTools** (link printed by `flutter run`, or VS Code: "Dart: Open DevTools"): widget inspector (like React
  DevTools), network tab, performance.

The app never logs tokens, coordinates, share ids, friend codes, emails or passwords (same rule as the backend).

## Building an APK to install on a phone

```powershell
flutter build apk --flavor dev --debug --dart-define-from-file=config/dev.json
```

The file is `build\app\outputs\flutter-apk\app-dev-debug.apk`. Copy it to an Android phone and open it (allow
"install unknown apps" when asked). A release build for the Play Store is [chapter 13](13-later-ios-and-store-release.md).

**Build stamp.** The bottom of the 👥 sheet says which build a phone runs ("Phiên bản 3f2a1bc 2026-11-03 10:14",
`lib/core/config/version.dart`, like the web's `version.ts`); it is also printed at start-up (`flutter logs`). It
comes from one more define; without it the sheet says "Phiên bản dev". CI adds it to its builds. By hand:

```powershell
flutter build apk --flavor dev --debug --dart-define-from-file=config/dev.json --dart-define="APP_VERSION=$(git rev-parse --short HEAD) $((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm'))"
```

## Trouble?

| Symptom | Fix |
|---|---|
| `No supported devices connected` | Start the emulator (Step 3) |
| Red "Config missing or invalid" screen | Step 2; check all four keys are filled in, and `API_URL` is a full `https://…/api` address |
| Sign-in says "Không kết nối được" | Emulator has no internet, or `AUTHORITY` is wrong |
| Map is grey | Emulator has no internet (tiles come from openstreetmap.org) |
| Gradle error about Java | `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"` |

Next: [03. Project structure](03-project-structure.md).
