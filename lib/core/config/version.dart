/// This build: `<git commit> <build time UTC>`, passed in with `--dart-define=APP_VERSION=…` (CI, and the build
/// commands in guide chapter 02); 'dev' without it. Shown at the bottom of the 👥 sheet and printed at start-up, so you
/// can tell which build a phone is running (the web's `version.ts`).
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
