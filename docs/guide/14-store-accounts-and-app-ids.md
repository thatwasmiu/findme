# 14. Store accounts and app IDs (Apple and Google)

How to get the accounts and identifiers you need to put Find Me on real phones: for free (test installs) and paid
(App Store / Google Play). Prices and rules were checked in November 2026; stores change them, so check the linked
pages before paying.

## The IDs, and which ones you already have

| Name | What it is | Find Me's value | Where it is set |
|---|---|---|---|
| **Bundle ID** (iOS) | The app's permanent unique name on Apple's side | `app.findme.mobile` | `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`) |
| **Application ID** (Android) | The app's permanent unique name on Google's side | `app.findme.mobile` (prod), `app.findme.mobile.dev` (dev) | `android/app/build.gradle.kts` (`applicationId`, `applicationIdSuffix`) |
| **Apple ID** | Your personal Apple login (an email) | yours | appleid.apple.com |
| **Team ID** | 10 characters naming your Apple developer team (free or paid) | given by Apple | Xcode → Signing & Capabilities, or developer.apple.com → Membership |
| **Google account** | The login that owns the Play Console | yours | accounts.google.com |

> **Pick the IDs once.** After the first upload to a store, the bundle ID / application ID can never change for
> that app. `app.findme.mobile` must not already be taken on the store. If you own a domain, use it reversed
> (`com.yourdomain.findme`) and change both files before the first upload.

---

## iPhone

| | Free Apple ID ("Personal Team") | Apple Developer Program |
|---|---|---|
| Cost | 0 | **99 USD per year** (shown in local currency when you enrol) |
| Needs a Mac with Xcode | yes, or Sideloadly on Windows (A2) | to build and sign: yes, or a cloud Mac / Codemagic (chapter 13) |
| Installs on | your own iPhone(s), plugged into the Mac (or the Windows PC, A2) | any iPhone, through TestFlight or the App Store |
| App expires after | **7 days**: the app stops opening; re-install from Xcode | 90 days per TestFlight build; App Store: never |
| Limits | about 3 apps per device; no TestFlight, no App Store, no push notifications | none relevant to Find Me |
| Good for | trying the app on your own phone | sharing with family and friends, publishing |

### A. Free: install on your own iPhone for 7 days

You need a Mac (borrowed is fine) and a USB cable.

1. **Apple ID with two-factor authentication.** If you have an iPhone you already have one. Check it at
   <https://account.apple.com>. No Apple ID yet? It is free and needs no Apple device:
   - <https://account.apple.com> → **Create Your Apple Account** (on an iPhone: Settings → Sign in → Create Apple
     Account);
   - name, birthday, an email you own (any provider; it becomes the Apple ID), a password, and a phone number that
     gets SMS (any phone);
   - enter the codes sent to the email and the phone. Two-factor authentication is then on, which Xcode needs. No
     payment card is asked for.
2. On the Mac: install **Xcode** from the Mac App Store, then Flutter (flutter.dev → macOS install), and clone this
   repo.
3. `flutter pub get`, then open `ios/Runner.xcworkspace` in Xcode.
4. **Xcode → Settings → Accounts → +** → Apple ID → sign in. Xcode creates a free **Personal Team** for you.
5. Select **Runner** (left) → target **Runner** → **Signing & Capabilities**:
   - tick **Automatically manage signing**;
   - **Team**: "Your Name (Personal Team)";
   - **Bundle Identifier**: a free team cannot use an ID someone else registered. If Xcode says it is unavailable,
     use something personal like `com.yourname.findme` (only on this Mac; do not commit it).
6. Plug in the iPhone, unlock it, tap **Trust**. On iOS 16+: **Settings → Privacy & Security → Developer Mode → On**
   (the phone restarts).
7. In the terminal: `flutter run --release --dart-define-from-file=config/dev.json`.
8. First launch says "Untrusted Developer": **Settings → General → VPN & Device Management** → your Apple ID →
   **Trust**.

After 7 days the app no longer opens. Plug in and repeat step 7.

### A2. Free, without a Mac: Sideloadly on Windows (third-party)

**Sideloadly** (sideloadly.io, free, donations) signs an `.ipa` with a free Apple ID on Windows and installs it over the
cable. Same limits as A: 7 days, about 3 apps per device.

> **Caution.** Sideloadly is not Apple's: you type your Apple ID password into it, and Apple does not support it. Use
> a **second Apple ID made only for this** (steps in A.1), never the one with your photos, iCloud and payments.

You need:

- an iPhone and its USB cable;
- **iTunes** and **iCloud** for Windows, the versions downloaded from apple.com (not the Microsoft Store ones), so
  Windows can talk to the iPhone;
- an **unsigned `findme.ipa`**. CI makes it: GitHub → **Actions** → CI → **Run workflow** (or any push to `main`) →
  the finished run → **Artifacts** → `findme-unsigned-ipa` (a zip; unzip it). Set the `FINDME_DEV_CONFIG` secret
  first (chapter 12, step 1.3), or the app opens on "Config missing or invalid". The same on a Mac by hand:

  ```bash
  flutter build ios --release --no-codesign --dart-define-from-file=config/dev.json
  mkdir -p Payload && cp -R build/ios/iphoneos/Runner.app Payload/
  zip -qr findme.ipa Payload
  ```

Steps:

1. Install iTunes and iCloud (apple.com), then Sideloadly. Restart Windows.
2. Plug in the iPhone, unlock it, tap **Trust**. On iOS 16+: **Settings → Privacy & Security → Developer Mode → On**
   (the phone restarts).
3. Sideloadly: drag `findme.ipa` in, pick the iPhone, type the (second) Apple ID, **Start**. Enter the Apple ID
   password and the two-factor code when asked.
4. Bundle ID: a free team cannot use one someone else registered. If Sideloadly reports it, set
   **Advanced options → Bundle ID** to something personal like `com.yourname.findme`.
5. First launch says "Untrusted Developer": **Settings → General → VPN & Device Management** → the Apple ID →
   **Trust**.

After 7 days the app no longer opens: run step 3 again (or Sideloadly's **Automatic refresh**, which needs the PC on
and on the same Wi-Fi as the phone).

### B. Paid: Apple Developer Program (TestFlight and App Store)

**1. Enrol** at <https://developer.apple.com/programs/enroll/>:

- Use your Apple ID (two-factor authentication on). Enrolling in the **Apple Developer app** on an iPhone is the
  quickest way for individuals: it checks your ID document with the camera.
- **Individual**: your legal name is shown as the seller in the App Store. **Organization**: the company name is
  shown, and you need a **D-U-N-S number** (free from Dun & Bradstreet, takes days to weeks) and the legal right to
  sign for the company.
- Pay 99 USD. Approval usually takes 24–48 hours, sometimes longer.
- When it is active, your **Team ID** is at developer.apple.com → **Account → Membership details**.

**2. Register the bundle ID** at <https://developer.apple.com/account/resources/identifiers/list>:

- **+** → **App IDs** → **App** → Description "Find Me", **Explicit** Bundle ID `app.findme.mobile`.
- Capabilities: none needed (Find Me only reads data from the API; it does not use the phone's GPS or push).
- Optional for a dev build next to prod: register `app.findme.mobile.dev` too (needs the iOS schemes from chapter
  13).

**3. Create the app** in App Store Connect, <https://appstoreconnect.apple.com> → **Apps → + → New App**:

- Platform iOS, name "Find Me" (must be unique on the App Store; try "Find Me – dấu chân" if taken), primary language
  Vietnamese, bundle ID `app.findme.mobile`, SKU any text (e.g. `findme-ios`).

**4. Signing: certificates and profiles.** iOS apps are signed with a **distribution certificate** (who you are) and a
**provisioning profile** (which app, which team).

- With Xcode on a Mac: keep **Automatically manage signing**, pick your paid team, and Xcode creates both.
- Without a Mac (Codemagic): App Store Connect → **Users and Access → Integrations → App Store Connect API → +**,
  role **App Manager**. Download the `.p8` key **once** (it cannot be downloaded again) and note the **Key ID** and
  **Issuer ID**. Give these to Codemagic's "App Store Connect" integration: it creates the certificate and profile
  and uploads the build. Keep the `.p8` out of git.

**5. Upload and test with TestFlight.**

- Bump `version:` in `pubspec.yaml` for every upload (e.g. `1.0.0+2`: the number after `+` must grow).
- Build: `flutter build ipa --release --dart-define-from-file=config/prod.json` (Mac), or Codemagic's workflow.
- Upload with Xcode's Organizer, Apple's **Transporter** app, or Codemagic.
- App Store Connect → **TestFlight**: **internal testers** (up to 100 people in your team, no review) or **external
  testers** (up to 10,000 by email or public link; the first build gets a short Beta App Review). Testers install
  the **TestFlight** app. Each build works for 90 days.

**6. Publish on the App Store.** App Store Connect → your app → the version page:

- Screenshots (6.7"/6.9" iPhone at least), description, keywords, support URL.
- **Privacy policy URL**: required. Find Me shows where people have been, so say what is stored (location history,
  email, friends) and how to delete an account.
- **App Privacy** ("nutrition label"): declare **Location → Precise Location**, **Contact Info → Email Address**,
  linked to the user, used for app functionality, not for tracking.
- **Sign-in information for the reviewer**: Find Me is login-only, so create a demo account with some trail data
  (admin page on the web) and enter its email/password here. Without it the review is rejected.
- **Submit for Review**. Reviews usually take one to a few days.

---

## Android

| | No account (install the APK) | Google Play Console |
|---|---|---|
| Cost | 0 | **25 USD once** |
| Installs on | any Android phone you can copy a file to | anyone, from Google Play |
| Expires | never | never |
| Updates | send a new APK by hand | automatic through Play |
| Good for | you, family, testing | publishing |

### A. Free: install the APK directly

1. Build (chapter 02): `flutter build apk --flavor prod --release --dart-define-from-file=config/prod.json`. Until
   you add your own key (step B.3), release builds are signed with the debug key (see `build.gradle.kts`), which is
   fine for this.
2. Send `build\app\outputs\flutter-apk\app-prod-release.apk` to the phone (USB, Drive, Zalo…).
3. Open it on the phone → allow **Install unknown apps** for the app you opened it from → Install.

> Google has announced **developer verification** for apps installed outside Play on certified Android phones,
> starting in some countries in 2026 and spreading after. If an install is blocked with a verification message,
> check <https://developer.android.com/developer-verification> for the current rules.

### B. Paid: Google Play

**1. Create the developer account** at <https://play.google.com/console/signup>:

- Sign in with the Google account that should own the app (consider a dedicated one, e.g. `findme.dev@gmail.com`).
- **Personal** or **Organization**. Organization needs a D-U-N-S number, and is exempt from the testing rule
  below.
- Pay **25 USD once**, then verify your identity with an ID document, and verify a phone number and email. Approval
  can take a few days.

**2. Know the testing rule for new personal accounts.** Before an app can go to **Production**, it needs a **closed
test with at least 12 testers who stay opted in for 14 days in a row**. This is per app, and only for the first
release. Plan for it: collect 12+ Gmail addresses (family, friends) early.

**3. Create your upload key** (once, on your PC; keep it forever):

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\findme-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

(`keytool` comes with Java; if it is not found, use `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"`.)
Back up the `.jks` file and both passwords somewhere safe (a password manager). If you lose them you need Google
support to reset the upload key.

Create `android/key.properties` (already ignored by git; never commit it):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/YOU/findme-upload.jks
```

In `android/app/build.gradle.kts`, load it and sign release builds with it. At the top of the file:

```kotlin
import java.util.Properties

val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
```

Inside `android { … }`, before `buildTypes`:

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keyProps["keyAlias"] as String?
        keyPassword = keyProps["keyPassword"] as String?
        storeFile = (keyProps["storeFile"] as String?)?.let { file(it) }
        storePassword = keyProps["storePassword"] as String?
    }
}
```

and in `buildTypes { release { … } }` replace `signingConfigs.getByName("debug")` with
`signingConfigs.getByName("release")`.

**4. Build the bundle** Play wants (`.aab`, not `.apk`):

```powershell
flutter build appbundle --flavor prod --release --dart-define-from-file=config/prod.json
```

Output: `build\app\outputs\bundle\prodRelease\app-prod-release.aab`. Bump `version:` in `pubspec.yaml` for every
upload.

**5. Create the app in Play Console** → **Create app**: name "Find Me", default language Vietnamese, App, Free.
On the first upload, accept **Play App Signing**: Google keeps the real signing key, and your upload key only proves
uploads come from you.

**6. Fill in "Set up your app"** (Dashboard checklist):

- **Privacy policy** URL (same as for Apple).
- **App access**: "All or some functionality is restricted" → give the reviewer a demo account's email/password.
- **Ads**: no. **Content rating** questionnaire. **Target audience**: 18+ (or 13+; not children).
- **Data safety**: collects **Location → Precise location** and **Personal info → Email address**; encrypted in
  transit; users can request deletion; not shared with third parties.
- **Government apps / financial features / health**: no.

**7. Test, then publish.**

1. **Internal testing** (up to 100 people, available in minutes): upload the `.aab`, add testers' emails, share the
   opt-in link.
2. **Closed testing**: create a track, upload, add the 12+ testers, and wait 14 days with them opted in.
3. **Production**: Dashboard → **Apply for production access** (answers a few questions about the test), then create
   a production release with the same `.aab`. Reviews usually take a few hours to a few days.

---

## Never commit

`*.jks`, `android/key.properties`, Apple `.p8` keys, `.p12` certificates, `config/prod.json`. All are in
`.gitignore`, but keep them outside the project folder anyway.

Sources checked: [Apple Developer Program](https://developer.apple.com/programs/),
[Play Console testing requirements](https://support.google.com/googleplay/android-developer/answer/14151465).
