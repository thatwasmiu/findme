# Pins taken where you are, shared per picture (mobile port) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app's 📷 takes a photo where you stand, each photo gets a "Chia sẻ" switch, friends' shared photos show on the map, share links get "Ảnh" — the web's version (`travel-heatmap` 296cb0d → 24f0c21) on the phone.

**Architecture:** Port one-to-one from `travel-heatmap/web/src` (`pins.ts`, `geo.ts`, `sharedPins.ts`, `AddPinSheet.tsx`, `PinSheet.tsx`, `PinLayer.ts`, `SharePanel.tsx`, `api.ts`). Look Back calls stay in `PinsRepository` (cookies kept by hand in memory); a new `FriendPinsController` polls friends' shared pins every 5 min. The public share page is **not** ported (owner, 2026-11-12: links keep opening the web).

**Tech Stack:** Flutter, Riverpod, dio, geolocator, image_picker, freezed (Share).

**Spec:** `travel-heatmap/docs/superpowers/specs/2026-11-12-pins-here-and-shared-design.md` (§5 behaviour, §6.2 Find Me/web). Web code at 24f0c21 is the reference for copy and edge cases.

## Global Constraints

- UI text Vietnamese, copied verbatim from the web (strings quoted below).
- New pins: photos only, camera only. No gallery, no video for new pins or "add more". Existing videos still play, never get a switch.
- A pin needs a fresh fix: no permission or no fix → no pin. Fix timeout 15 s, overall deadline 20 s.
- Reading pins (own and friends') fails quietly into "keep what is shown" / `[]`; the map never breaks.
- Never log coordinates, grants, cookies, media ids (`debug_log`: counts and flags only).
- Every account-scoped provider watches `signedInProvider`/`sessionEpochProvider` like `PinsController`.
- Commands (PowerShell, repo root): `flutter analyze`, `dart format .`, `flutter test`, `dart run build_runner build -d` after freezed changes.

## Review Focus

1. **Signing out while friends' shared pins are shown** → friend bubbles and the `fm_shared_friends` cookie are gone; the next account never sees them. Test in Task 4.
2. **A friend hidden on the map** → their shared bubbles vanish at once (no wait for the 5-min poll). Test in Task 4 (`visibleFriendPins`).
3. **Switch flip fails (offline / 404)** → switch goes back, "Chưa làm được, thử lại sau chút nhé ✨". Test in Task 3.
4. **Location service off (not just permission)** → treated as failed with reason `off`, retry shown, no pin. Test in Task 2.
5. **Typing a name before `/place-name` answers** → typed name wins, late answer does not overwrite. Test in Task 2.

---

### Task 1: Repository and model

**Files:**
- Modify: `lib/features/pins/domain/pin.dart`, `lib/features/pins/data/pins_repository.dart`
- Test: `test/features/pins/domain/pin_test.dart`, `test/features/pins/data/pins_repository_test.dart`

**Interfaces:**
- Produces:
  - `PinMedia.shared` (`bool`, from json `shared`, default false).
  - `Pin.sub` (`String?`, from json `sub`; non-null = a friend's shared pin). `Pin.shareCode` removed. `startPosition` removed.
  - `PinsRepository.setShared(String mediaId, bool shared) → Future<void>`: `PUT $_lb/media/$mediaId/shared` body `{"shared": shared}`, via `_must` (throws on non-2xx).
  - `PinsRepository.placeName(double lat, double lon, {Future<void> Function(Duration)? wait}) → Future<String>`: `_api.send('GET', '/place-name', query: {lat, lon})` → `{name, pending}`; up to 4 tries, 3 s apart while `name == null && pending`; `''` on any failure.
  - `PinsRepository.pinGrant() → Future<({String grant, int exp})?>`: `_api.send('POST', '/pin-grant')`; null when `grant`/`exp` null or anything throws.
  - `PinsRepository.loadSharedPins(String grant) → Future<List<Pin>>`: `POST $_lb/shared/session` `{"grant": grant}` with `_dio` (no 401 retry); keeps the `fm_shared_friends` cookie from `set-cookie`; `[]` on any failure.
  - `mediaHeaders` sends every held cookie joined by `'; '` (`fm_user`, `fm_shared_friends`).
  - Removed: `shareLink`, `sharePin`, `unsharePin`.

- [ ] **Step 1: Write failing tests** in `pins_repository_test.dart` (use the file's `Server` fake):
  - `setShared sends PUT with {"shared":true}` — body equals `{"shared":true}`; a 404 throws `HttpError`.
  - `placeName asks again while pending` — answers `{name:null,pending:true}` ×2 then `{name:'Hồ Gươm',pending:false}` → `'Hồ Gươm'`, 3 calls, `wait` called with 3 s twice.
  - `placeName gives up quietly` — 500 → `''`; offline → `''`.
  - `pinGrant: no friends is null` — `{grant:null,exp:null}` → null; `{grant:'g',exp:9}` → `(grant:'g',exp:9)`.
  - `loadSharedPins keeps the friends cookie` — set-cookie `fm_shared_friends=g1; Path=/lb` → returned pins have `sub`; `mediaHeaders['Cookie']` contains both `fm_user=abc.def` and `fm_shared_friends=g1`.
  - `loadSharedPins failure is empty` — 403 → `[]`, offline → `[]`.
  - In `pin_test.dart`: `fromJson reads shared and sub` (missing → false / null). Delete tests for `startPosition`.
- [ ] **Step 2:** `flutter test test/features/pins` → FAIL (members undefined).
- [ ] **Step 3:** Implement the members above; delete removed ones and fix callers enough to compile (pin_sheet's link UI goes in Task 3 — delete it now).
- [ ] **Step 4:** `flutter test test/features/pins` → PASS; `flutter analyze` → no issues.
- [ ] **Step 5:** Commit `feat(pins): shared switch, place names, friends' shared pins in the repository`.

### Task 2: Taking a pin where you are

**Files:**
- Modify: `lib/features/pins/presentation/pins_controller.dart` (`pinGpsProvider` → `pinFixProvider`; `PinPicker` drops `video()`/`gallery()` from pin use — keep `image()` for bag/avatar), `lib/features/pins/presentation/add_pin_sheet.dart`, `lib/features/trail/presentation/map_screen.dart`, `lib/features/trail/presentation/map_view.dart` (drop the `center` notifier and the 📍 overlay if only pins used them)
- Test: `test/features/pins/presentation/pins_ui_test.dart`, `test/features/pins/domain/pin_test.dart`

**Interfaces:**
- Consumes: `PinsRepository.placeName`, `nameNear`.
- Produces:
  - `sealed class Fix` in `pin.dart`: `FixOk(lat, lon)`, `FixDenied()`, `FixFailed(String reason)`.
  - `String? geoMessage(Fix f)`: denied → `'Cần quyền vị trí để ghim ảnh ở đây. Bật trong Cài đặt › Find Me › Vị trí nhé.'`; failed → `'Chưa lấy được vị trí, thử lại nhé ($reason)'`; ok → null.
  - `pinFixProvider = Provider<Future<Fix> Function()>`: service off → `FixFailed('off')`; permission denied/deniedForever after asking → `FixDenied()`; `getCurrentPosition(LocationSettings(accuracy: high, timeLimit: 15 s))`, whole call capped at 20 s → `FixFailed('silent')`; other error → `FixFailed('error')`.
  - `AddPinSheet({stops, onSpot(lat, lon), onAdded, onClose})`.

- [ ] **Step 1: Write failing tests** (replace the old AddPinSheet group):
  - `geoMessage` unit test with the exact strings above.
  - `denied: says why, no camera, no pin` — fake fix `FixDenied` → text contains `Cần quyền vị trí`, no `📷 Chụp ảnh`, no `POST /pins`.
  - `failed: retry asks again` — first `FixFailed('silent')`, tap `Thử lại`, then `FixOk` → `onSpot` called once with the fix, camera button shown.
  - `ok near a stop: names from the stop, no /place-name call`.
  - `ok, no stop: names from /place-name` — fake repo `placeName` → `'Chợ Bến Thành'` appears in `pinName`.
  - `typed name beats a late place name` (Review Focus 5) — type before `placeName` completes → field keeps the typed text and it is what `createPin` gets.
  - `camera photo uploads at the fix` — `createPin` gets the fix's lat/lon; no `🎥`/`🖼️` buttons exist.
  - `service off is a failure with retry` (Review Focus 4) — unit test of the mapping function behind `pinFixProvider` (extract `Future<Fix> currentFix(GeoApi geo)` with a thin `GeoApi` over `Geolocator` static calls so it is testable).
- [ ] **Step 2:** `flutter test test/features/pins` → FAIL.
- [ ] **Step 3:** Implement. Copy: title `'Chụp ảnh ở đây'`; while locating `'Đang tìm vị trí của bạn… 📍'`; retry pill `'Thử lại'`; name hint `'Đang tìm tên nơi này…'` while asking, else `'Tên nơi này (không bắt buộc)'`; note hint unchanged; one button `'📷 Chụp ảnh'` (`picker.photo`). Fields and the button appear only after `FixOk`. `map_screen` passes `onSpot` = fly the map there (as `onStart` did); remove `last`/`center` plumbing that only pins used. FAB semantic label `'Chụp ảnh ở đây'`.
- [ ] **Step 4:** `flutter test` → PASS; `flutter analyze` → no issues.
- [ ] **Step 5:** Commit `feat(pins): a pin goes where you are, from the camera`.

### Task 3: The pin sheet — "Chia sẻ" switch, read-only for friends

**Files:**
- Modify: `lib/features/pins/presentation/pin_sheet.dart`
- Test: `test/features/pins/presentation/pins_ui_test.dart`

**Interfaces:**
- Consumes: `PinsRepository.setShared`, `Pin.sub`, `PinMedia.shared`.
- Produces: `PinSheet({required Pin pin, required VoidCallback onClose, String? by})`. `pin.sub != null` = read-only (no switch, no ＋, no 🗑️), header notice prefixed `'Ảnh của $by · '` when `by` given.

- [ ] **Step 1: Write failing tests** (replace the two link tests):
  - `own photo: switch flips and calls setShared` — switch labelled `'Chia sẻ'` per image, off for `shared:false`; tap → `PUT …/media/m1/shared {"shared":true}`, switch on, pins refreshed.
  - `switch failure goes back and says so` (Review Focus 3) — PUT 500 → switch off again, `'Chưa làm được, thử lại sau chút nhé ✨'`.
  - `videos get no switch`.
  - `friend's pin is look-only` — `sub: 'f1'`, `by: 'Mai'` → `'Ảnh của Mai · '` shown; no `Chia sẻ`, no `＋`, no `🗑️ Xoá`.
  - `add more uses the camera` — tapping ＋ calls `picker.photo` (fake records which method), label `'Chụp thêm ảnh'`.
  - Owner sees notice `'Ảnh bật Chia sẻ: bạn bè và link có “Ảnh” đều thấy.'`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Implement. Switch = small pill-style toggle under each image tile (pink when on); optimistic local map `id → bool`, reverts on throw. Remove link UI, `_copy`, `shareLauncherProvider` import if unused.
- [ ] **Step 4:** `flutter test test/features/pins` → PASS.
- [ ] **Step 5:** Commit `feat(pins): a Chia sẻ switch on each photo; friends' pins open look-only`.

### Task 4: Friends' shared pins on the map

**Files:**
- Create: `lib/features/pins/presentation/friend_pins_controller.dart`
- Modify: `lib/features/pins/presentation/pin_layer.dart`, `lib/features/trail/presentation/map_screen.dart`, `lib/features/trail/presentation/map_view.dart`
- Test: `test/features/pins/presentation/friend_pins_test.dart`, `pins_ui_test.dart`

**Interfaces:**
- Consumes: `pinGrant`, `loadSharedPins`, `friendsControllerProvider` (`relations.friends`, `shown`), `friendColor`.
- Produces:
  - `List<Pin> visibleFriendPins(List<Pin> all, List<String> shown)` — keep `p.sub in shown`.
  - `bool grantDue(int? exp, int nowS)` — `exp == null || exp - nowS < 60`.
  - `FriendPinsController extends Notifier<List<Pin>>`, `friendPinsControllerProvider`: watches `signedInProvider` and the friend count (`friendsControllerProvider.select((s) => s.relations.friends.length)`); 0 friends or signed out → `[]` and no calls; else load now and every 5 min (`friendPinsRefresh = Duration(minutes: 5)`), reusing the grant until `grantDue`; `paused()` / `resumed()` like `PinsController` (resumed loads at once). Stale-load guard with a sequence number like `PinsController`.
  - `PinBubbles` draws a 3 px border in `friendColor(sub)` when every pin in the bubble has the same non-null `sub`, and a small `💗` (semantics `'Đang chia sẻ'`) when any media in the bubble is `shared` (own pins only have it set).

- [ ] **Step 1: Write failing tests:**
  - `visibleFriendPins` and `grantDue` (59 s left → due, 61 s → not, null → due).
  - `no friends: asks nothing` — fake repo counts 0 `pinGrant` calls, state `[]`.
  - `loads once, reuses the grant, new grant when near expiry` — fake clock/timers (`fakeAsync`): 2 loads 5 min apart = 1 `pinGrant`; after exp − 30 s a 3rd load asks a new grant.
  - `signing out empties them; a late answer cannot refill` (Review Focus 1) — mirror the existing PinsController test.
  - `hidden friend's bubble disappears at once` (Review Focus 2) — widget test of map_screen's merge: toggle shown → bubble count drops without a new load.
  - `friend bubble has their colour; shared own bubble has 💗`.
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Implement. `map_screen`: `allPins = [...own, ...visibleFriendPins(friendPins, shown)]`; open lookup over `allPins`; friend pin → `PinSheet(pin, by: friend name)`. Lifecycle `paused/resumed` calls added beside `pinsControllerProvider`'s. Sign-out drops the cookie because `PinsRepository` is rebuilt per sign-in (check, no new code expected).
- [ ] **Step 4:** `flutter test` → PASS; `flutter analyze` clean.
- [ ] **Step 5:** Commit `feat(pins): friends' shared photos on the map`.

### Task 5: Share links get "Ảnh"

**Files:**
- Modify: `lib/features/shares/domain/share.dart` (+ regenerate), `lib/features/shares/data/shares_repository.dart`, `lib/features/shares/presentation/shares_sheet.dart`
- Test: `test/features/shares/…` (existing repository + sheet tests)

**Interfaces:**
- Produces: `Share.pics` (`@Default(false) bool`); `create(…, bool pics = false)` sends `'pics': true` only when on; `edit(…, bool? pics)` sends `pics` when non-null.

- [ ] **Step 1: Write failing tests** mirroring the `bag` ones: create with pics sends `"pics":true`, without sends no key; edit `pics:false`; sheet checkbox `'Cho xem ảnh đã chia sẻ 🖼️'` asks `'Ai có link này đều thấy mọi ảnh bạn đã bật Chia sẻ. Bật nhé?'` and stays off on cancel; list row label gains `' · 🖼️'`; 🖼️ pill toggles with notes `'Đã tắt ảnh với "<label>".'` / `'"<label>" xem được ảnh đã chia sẻ 🖼️'` (on asks first, off does not).
- [ ] **Step 2:** run → FAIL.
- [ ] **Step 3:** Implement next to `bag`; `dart run build_runner build -d`.
- [ ] **Step 4:** `flutter test test/features/shares` → PASS.
- [ ] **Step 5:** Commit `feat(shares): links can show your shared photos (Ảnh)`.

### Task 6: Docs and whole check

**Files:** `docs/guide/16-*.md` (photo pins chapter: rewrite "taking a pin", add the switch, friends' pins, "Ảnh", device test steps from spec §9), `docs/guide/cheatsheet.md` (`PUT /lb/api/findme/media/:id/shared`, `POST /pin-grant`, `GET /place-name`, `POST /lb/api/findme/shared/session`), `docs/HANDOFF.md` (new entry: follows `travel-heatmap` 24f0c21, unit/widget tested only, server side not deployed — Look Back first, then Find Me; public share page stays on the web by owner's call), `CLAUDE.md` if the pins description there mentions links or gallery.

- [ ] **Step 1:** `dart format .`, `flutter analyze`, `flutter test` → all clean / pass.
- [ ] **Step 2:** Write the docs.
- [ ] **Step 3:** Commit `docs: pins taken where you are, shared photos`.
