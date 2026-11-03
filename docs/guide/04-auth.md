# 04. Sign-in (Cognito) and secure storage

Files: `lib/features/auth/` — `data/cognito_api.dart`, `data/session_store.dart`, `data/auth_repository.dart`,
`presentation/auth_controller.dart`, `presentation/welcome_screen.dart`. Web twin: `web/src/auth.ts`, `SignIn.tsx`.

## How it works

Like the web, the app talks **directly** to Cognito's API. There is no redirect to a Cognito web page.

1. `login(email, password)` → `POST https://cognito-idp.<region>.amazonaws.com/` with header
   `X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth` and `AuthFlow: USER_PASSWORD_AUTH`.
2. Cognito answers with an **access token** (lives 1 hour) and a **refresh token** (lives 30 days).
3. Both are saved as one `Session` in **secure storage**: the Android Keystore / iPhone Keychain. They are encrypted
   by the phone. (The web keeps them in `localStorage`, which any script on the page could read.)
4. Every API call asks `getAccessToken()`:
   - more than 60 s left → the stored access token;
   - nearly expired → trades the refresh token for a new access token (`REFRESH_TOKEN_AUTH`). If several calls ask
     at the same moment, they share **one** renewal;
   - Cognito refuses the refresh token → session deleted → you see the sign-in form;
   - no internet → `null` but the session is **kept**, so the next try can still renew.
5. `logout()` deletes the session here and revokes the refresh token at Cognito (best effort).

## The four screens before the map

`AuthController` holds an `AuthPhase`:

| Phase | Shown |
|---|---|
| `loading` | "Đang khởi động…" while checking the stored session |
| `signedOut` | the email + password form |
| `signedIn` | the map |
| `noAccount` | the login worked but has no map (the admin login): a message pointing to the web `/admin` page, and Đăng xuất |

The app has **no admin screen** on purpose: admin work stays on the web.

## Password managers

The form is wrapped in an `AutofillGroup` with `AutofillHints.username` / `password`, so Google Password Manager (and
the iPhone Keychain) offer to save and fill the password, like the web's `autocomplete` attributes.

## Error messages

`signInMessage()` turns Cognito's error codes into the web's Vietnamese wording: `NotAuthorizedException` → "Sai
email hoặc mật khẩu.", `NEW_PASSWORD_REQUIRED` → "Tài khoản cần mật khẩu mới: nhờ admin đặt lại giúp nhé.", etc.

## Tests

`test/features/auth/` — the web's `auth.test.ts` cases ported (fake HTTP adapter, in-memory session store), plus the
phase changes and the welcome screen.

Next: [05. The map and paw prints](05-map-and-paws.md).
