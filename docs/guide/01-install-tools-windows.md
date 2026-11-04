# 01. Install the tools on Windows

By the end of this chapter `flutter doctor` is green for Android and a virtual phone (emulator) boots on your PC.
Plan about 1–2 hours, mostly downloads, and **~15 GB of free disk space**.

What you will install:

| Tool | Why |
|---|---|
| Flutter SDK (includes Dart) | Builds and runs the app |
| Android Studio | Brings the Android SDK, the emulator and the Device Manager |
| VS Code + Flutter extension | Comfortable editor for daily work (you can also code in Android Studio) |

Already on this PC: **git** (2.53) and **Java 17**. Nothing to do for those.

All commands below are for **Windows PowerShell**. Open it from the Start menu ("Windows PowerShell"). When a step
says "open a **new** PowerShell", close the old window first so it picks up the new PATH.

> **Company laptop note.** Steps 1 and 4 change Windows settings that may need admin rights. If a setting is greyed
> out or blocked, ask your IT team to turn it on; the rest of the guide works once it is on.

---

## Step 1. Turn on Developer Mode and virtualization

**Developer Mode** lets Flutter create symbolic links, which Flutter plugins need on Windows. Without it, builds fail
with "Building with plugins requires symlink support".

```powershell
start ms-settings:developers
```

Switch **Developer Mode** on and confirm.

**Virtualization** makes the emulator fast. Check it:

```powershell
systeminfo | Select-String "Virtualization|Hyper-V"
```

- If you see `Virtualization Enabled In Firmware: Yes` or `A hypervisor has been detected`, you are fine.
- If it says `No`, virtualization is off in the BIOS. Ask IT to enable it (Intel VT-x / AMD-V).

Then turn on **Windows Hypervisor Platform**: Start → "Turn Windows features on or off" → tick
**Windows Hypervisor Platform** → OK → restart the PC.

---

## Step 2. Install the Flutter SDK

We put Flutter in `C:\src\flutter` (not in `Program Files`, which needs admin rights and breaks updates). Cloning
the `stable` branch with git gives you an easy `flutter upgrade` later.

```powershell
New-Item -ItemType Directory -Force C:\src
git clone https://github.com/flutter/flutter.git -b stable C:\src\flutter
```

Add `C:\src\flutter\bin` to your user PATH (only your account, no admin needed):

```powershell
$p = [Environment]::GetEnvironmentVariable('Path', 'User')
[Environment]::SetEnvironmentVariable('Path', "$p;C:\src\flutter\bin", 'User')
```

Open a **new** PowerShell and check:

```powershell
flutter --version
```

The first run downloads the Dart SDK and takes a few minutes. You should see `Flutter 3.x.x • channel stable`.

> If you are behind a company proxy and downloads fail, set it for the session first:
> `$env:HTTPS_PROXY = "http://proxy.company:8080"` (ask IT for the address).

---

## Step 3. Install Android Studio

> **No admin rights, or not enough room on C:?** Skip Steps 3–5 and use [Step 3b](#step-3b-no-android-studio-sdk-and-emulator-from-zip-files)
> instead: the same SDK and emulator from zip files, in a folder of your choice. This is how the owner's PC is set up.

Install it with winget (built into Windows 10/11):

```powershell
winget install --id Google.AndroidStudio -e
```

If winget is not available, download the installer from <https://developer.android.com/studio> and run it with the
default options.

Start **Android Studio** from the Start menu. The **Setup Wizard** opens:

1. Choose **Standard** install.
2. Accept the licences and let it download the Android SDK, Platform-Tools and the Emulator (several GB).
3. Finish. You land on the "Welcome to Android Studio" screen.

Add the missing SDK pieces Flutter needs:

1. On the Welcome screen: **More Actions → SDK Manager**.
2. Tab **SDK Platforms**: make sure the newest **Android API** (e.g. "Android 15.0, API 35") is ticked.
3. Tab **SDK Tools**: tick
   - **Android SDK Command-line Tools (latest)** ← Flutter needs this, it is *not* ticked by default
   - Android SDK Build-Tools
   - Android SDK Platform-Tools
   - Android Emulator
4. **Apply** → OK, wait for the download.

Optional but handy: **More Actions → Plugins** → search **Flutter** → Install (also installs Dart) → restart
Android Studio. Lets you run the app from Android Studio too.

---

## Step 4. Accept the Android licences

Open a **new** PowerShell:

```powershell
flutter doctor --android-licenses
```

Type `y` and Enter for every question.

---

## Step 5. Create a virtual phone (emulator)

1. Android Studio Welcome screen: **More Actions → Virtual Device Manager**.
2. **Create Virtual Device** (the `+` button).
3. Pick **Phone → Pixel 7** → Next.
4. Pick the newest system image with a **Google Play** or **Google APIs** label (API 35). Click the download arrow next
   to it if needed → Next.
5. Name it `Pixel_7_API_35` → Finish.
6. Press **▶** next to it. A phone window boots (first boot takes 1–3 minutes).

You can also start it from PowerShell later:

```powershell
flutter emulators
flutter emulators --launch Pixel_7_API_35
```

> **Slow or black emulator?** Usually Step 1's virtualization is off. In Virtual Device Manager → ✏️ (edit) →
> **Show Advanced Settings** → Graphics: **Hardware**. If still black, try **Software**.

---

## Step 3b. No Android Studio: SDK and emulator from zip files

Android Studio's installer needs admin rights and ~12–15 GB on C:. Everything it installs for Flutter also comes as
plain zip files that need neither. Here: all on `D:\Android` (about 6.5 GB, plus ~3 GB of Gradle cache after the first
build). The emulator still needs the **Windows Hypervisor Platform**; Step 4 checks it.

**1. Command-line tools.** On <https://developer.android.com/studio>, section "Command line tools only", download the
Windows zip (`commandlinetools-win-…_latest.zip`, ~150 MB). Unzip it so this file exists:
`D:\Android\Sdk\cmdline-tools\latest\bin\android.exe` (the zip holds a `cmdline-tools` folder: rename it to `latest`
and put it inside `D:\Android\Sdk\cmdline-tools\`).

**2. SDK packages** (~2.5 GB download). Newer tools replace `sdkmanager` with `android sdk`, and package names use
`/`. (`sdkmanager.bat` still exists but now forwards to `android sdk`, which reads `;` as a separator, so
`"platforms;android-36"` fails with "Package platforms not found".)

```powershell
$a = "D:\Android\Sdk\cmdline-tools\latest\bin\android.exe"
foreach ($p in "platform-tools", "emulator", "platforms/android-36", "build-tools/36.0.0", "ndk/28.2.13676358", "system-images/android-35/default/x86_64") {
  & $a --sdk=D:\Android\Sdk sdk install $p
}
```

`platforms/android-36`, `build-tools/36.0.0` and `ndk/28.2.13676358` (~2.5 GB unpacked) are what Flutter 3.47 builds
with (`flutter doctor -v` lists the platform and build-tools; the NDK version is `ndkVersion` in Flutter's
`FlutterExtension.kt`, and a build that misses it says which). Android Studio would fetch the NDK on the first build;
without it, the build stops with "sdkmanager did not install NDK …", so install it here. The `default` system image is plain Android without Google apps: smaller, and Find Me needs no
Google services. Installing means you accept the Android SDK licence.

**3. Tell Windows and Flutter where things are** (once; open a new PowerShell afterwards):

```powershell
[Environment]::SetEnvironmentVariable('ANDROID_HOME', 'D:\Android\Sdk', 'User')
[Environment]::SetEnvironmentVariable('ANDROID_AVD_HOME', 'D:\Android\avd', 'User')    # the virtual phone's files
[Environment]::SetEnvironmentVariable('GRADLE_USER_HOME', 'D:\Android\gradle', 'User') # build cache, several GB
flutter config --android-sdk "D:\Android\Sdk"
```

**4. Check the emulator can run fast:**

```powershell
D:\Android\Sdk\emulator\emulator.exe -accel-check
```

`WHPX(…) is installed and usable` = good. Anything else: the Windows Hypervisor Platform is off, and turning it on
(Windows Features) needs an admin. Without it the emulator is too slow to use; use a real phone (Step 8) instead.

**5. Create the virtual phone** (2 GB RAM, 2 GB storage: enough for Find Me, light on the PC):

```powershell
New-Item -ItemType Directory -Force D:\Android\avd
D:\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat create avd -n findme -k "system-images;android-35;default;x86_64" -d pixel_6
```

Answer `no` to "custom hardware profile". Then open `D:\Android\avd\findme.avd\config.ini` in a text editor and set
`hw.ramSize=2048`, `disk.dataPartition.size=2G`, `hw.keyboard=yes` (type with the PC keyboard).

**6. Start it** (the first boot takes 1–3 minutes):

```powershell
D:\Android\Sdk\emulator\emulator.exe -avd findme -no-boot-anim
```

Then `flutter devices` lists `emulator-5554`, and Chapter 02's `flutter run …` installs Find Me on it. This replaces
Steps 3–5 (the licence is accepted in point 2); continue with Step 6.

| Problem | Fix |
|---|---|
| `Package platforms not found` | You used `;` with `sdkmanager`: use `android sdk install` with `/` (point 2) |
| `sdkmanager did not install NDK 28.2.13676358` | `android.exe --sdk=D:\Android\Sdk sdk install ndk/28.2.13676358` (the version from the message) |
| `PANIC: Unknown AVD name` | `ANDROID_AVD_HOME` is not set in this PowerShell: open a new one after point 3 |
| Emulator window black / very slow | Close other apps (it needs ~3 GB of free RAM); try `-gpu swiftshader_indirect` |
| Only a black strip at the top of the screen | The window opened mostly above the screen (a 2400-px phone is taller than a laptop screen). Drag it down by its title bar, or close it and start again; the owner's local `dev emu` moves and shrinks it automatically |
| Shut it down | `D:\Android\Sdk\platform-tools\adb.exe emu kill` or the window's ✕ (both save its state for a quick next start) |
| Build fills up C: | `GRADLE_USER_HOME` not picked up: open a new PowerShell (point 3) |

---

## Step 6. Install VS Code and the Flutter extension

```powershell
winget install --id Microsoft.VisualStudioCode -e
```

Open VS Code → Extensions (Ctrl+Shift+X) → search **Flutter** (publisher *Dart Code*) → Install. It installs the
**Dart** extension too.

Useful VS Code commands (Ctrl+Shift+P):

- **Flutter: Run Flutter Doctor**
- **Flutter: Select Device** (pick the emulator; it also shows in the bottom-right status bar)
- **Flutter: Launch Emulator**

---

## Step 7. Check everything with `flutter doctor`

Open a **new** PowerShell:

```powershell
flutter doctor -v
```

What you want to see:

```
[√] Flutter (Channel stable, 3.x.x, ...)
[√] Windows Version (...)
[√] Android toolchain - develop for Android devices (Android SDK version 35.x.x)
[√] Android Studio (version 202x.x)
[√] VS Code (version 1.x)
[√] Connected device (... available)
[√] Network resources
```

These lines are **fine to ignore**:

| Line | Why it's OK |
|---|---|
| `[X] Visual Studio - develop Windows apps` | Only for Windows desktop apps; we build for phones |
| `[!] Chrome` | Only for Flutter web; not needed |
| No `Xcode` line | Xcode exists only on a Mac. iOS is built in CI (chapter 12) |

### Fixing common doctor errors

| Message | Fix |
|---|---|
| `cmdline-tools component is missing` | Step 3: SDK Manager → SDK Tools → **Android SDK Command-line Tools (latest)** |
| `Android license status unknown` | Step 4: `flutter doctor --android-licenses` |
| `Unable to locate Android SDK` | `flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"` |
| `Unable to find bundled Java version` / Java errors during build | Point Flutter to Android Studio's JDK: `flutter config --jdk-dir "C:\Program Files\Android\Android Studio\jbr"` |
| `flutter` is not recognized | PATH not picked up: open a **new** PowerShell, or recheck Step 2 |
| `Building with plugins requires symlink support` | Step 1: Developer Mode |

---

## Step 8 (optional). Use your own Android phone

1. On the phone: **Settings → About phone** → tap **Build number** 7 times ("You are now a developer").
2. **Settings → System → Developer options** → turn on **USB debugging**.
3. Plug it in with a USB cable and accept the "Allow USB debugging?" prompt on the phone.
4. `flutter devices` should list it.

---

## Done? Tell Claude

When `flutter doctor` shows `[√]` for **Flutter**, **Android toolchain** and **Android Studio**, and the emulator
boots, paste the output of:

```powershell
flutter doctor -v
```

into the chat. Claude then creates the project (rest of Task 0) and you will see the first app on the emulator in
[02. Running the app](02-running-the-app.md).
