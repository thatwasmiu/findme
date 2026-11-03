# Find Me (mobile)

Flutter app for Android and iOS: the Find Me paw-print trail, day diary, replay, share links and friends, on your
phone. Same AWS API and Cognito sign-in as the web app in `travel-heatmap`.

New to mobile development? Start with the guide: [docs/guide/README.md](docs/guide/README.md).

Quick start (after [chapter 01](docs/guide/01-install-tools-windows.md)):

```powershell
flutter pub get
Copy-Item config/example.json config/dev.json   # then fill in the stack outputs
flutter test
flutter run --flavor dev --dart-define-from-file=config/dev.json
```
