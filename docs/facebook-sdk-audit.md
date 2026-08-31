# Meta (Facebook) SDK integration — audit findings

Audit date: 2026-08-17. Flutter 3.47.0 stable, `facebook_app_events` 0.30.5.

## Scope

The only Meta SDK in the project is **`facebook_app_events` 0.30.5** (App Events
/ ad attribution). There is **no Facebook Login** — `flutter_facebook_auth` is
not a dependency, despite login config and README docs implying otherwise
(see #14).

Everything funnels through `lib/core/services/facebook_events_service.dart`.

Findings are verified by `test/facebook_events_service_test.dart`, which
intercepts the plugin's MethodChannel and asserts the exact payload that would
reach the native SDK. 15 tests, all passing. Tests still named `BUG:` pin
known-incorrect behaviour that has not been fixed yet.

## Status

**Fixed 2026-08-18: #4, #5, #6, #7, #8.** The tests that previously pinned the
broken payloads now assert the corrected ones, so they fail if the behaviour
regresses.

**Fixed 2026-08-26: #1, #2, #3, #9, #10, #11, #14, #15.** #1 wired into the
`CustomOrderView` flow (below); #9/#10/#11 fixed together by rewriting
`initialize()` to reuse the existing `_guard` helper per call; #2/#3 fixed by
restoring AD_ID and adding a real ATT flow (below) — #2/#3 still need a
manual, non-code step before release, see each finding; #14 removed the dead
config and corrected the README; #15 wired advanced matching, registration,
and push-token APIs into the real auth/logout/FCM flows (below).

**Outstanding:** #12 (no consent gating) — left alone deliberately: there is
no consent UI anywhere in this app, so wiring `setLimitEventAndDataUsage` to
nothing would be unused plumbing, not a fix. Needs a real consent flow first,
which is a product decision outside this audit's scope. #13 needs no action —
already documented as by-design.

---

## High severity

### 1. Every conversion event is dead code

**Where:** `facebook_events_service.dart:24,41,54,66` define `logViewContent`,
`logAddToCart`, `logInitiatedCheckout`, `logPurchase`. A search across `lib/`
finds **zero call sites** for any of them. The only call into the service in the
whole app is `FacebookEventsService.initialize()` at `main.dart:26`.

**Impact:** The app reports installs and app launches only. No ViewContent,
AddToCart, InitiatedCheckout or Purchase ever reaches Meta, so campaigns cannot
optimise for purchases and ROAS is unmeasurable. The service docstring claims it
attributes "in-app conversions" — it does not.

**Fix:** Wire the four methods into the product-detail, cart, checkout and
order-confirmation flows. Every finding below is latent until this is done.

**Fixed 2026-08-26.** The app has no shopping cart — `CustomOrderView`
(`lib/features/customer/custom_order/view/custom_order_view.dart`) is the only
flow that carries a real product price through to a submitted order, via three
phases (Calculator → Plan Review → Personal Details → Submit). The four events
now map onto that funnel's four user-driven transitions:

- `logViewContent` — plan successfully calculated, entering Plan Review
  (`_calculatePlan`)
- `logAddToCart` — "Proceed to Personal Details" tapped (`onProceed` in the
  Plan Review phase)
- `logInitiatedCheckout` — "Confirm Order" tapped, before the network call
  (`_submitOrder`, using `totalPayable`)
- `logPurchase` — order submission succeeds (`_submitOrder`, `state.isSuccess`)

`lead_form`/`make_offer` (the simpler, priceless lead-capture flow) is left
unwired — it has no product price to report and instrumenting it is a separate
decision, not part of this fix.

### 2. The Android manifest forbids exactly what the code requests

**Where:** `android/app/src/main/AndroidManifest.xml:9-11` removes
`com.google.android.gms.permission.AD_ID` with `tools:node="remove"`, while
`facebook_events_service.dart:14` calls
`setAdvertiserTracking(enabled: true, collectId: true)` — which on Android
reduces to `setAdvertiserIDCollectionEnabled(true)`.

**Impact:** On Android 13+ the Google Advertising ID is unreadable without that
permission. The SDK is told to collect the advertiser ID and then denied the
permission to do so, so install/conversion attribution is crippled by
construction.

**Fix:** Decide which goal wins. Either restore the `AD_ID` permission (and
declare it in the Play Console data-safety form), or stop requesting advertiser
ID collection and accept non-GAID attribution. The current state is the worst of
both — the privacy cost of asking without the benefit.

**Fixed 2026-08-26.** Restored the `AD_ID` permission in
`AndroidManifest.xml` (the code already asks to collect it, and the whole
point of this integration is measurable ad attribution). This still needs a
**manual step before release that no code change can do**: declare
Advertising ID usage in the Play Console's Data Safety form. Shipping the
restored permission without that declaration risks a policy rejection.

**Follow-up fixed 2026-08-31.** A second store-readiness pass (verified with
a real `flutter build apk --release` and inspection of the merged/packaged
manifest, not just the source XML) found the original fix was incomplete:
`ACCESS_ADSERVICES_AD_ID` — the Privacy Sandbox counterpart to the classic
GMS `AD_ID` permission, for Android's newer AdServices AdId API — was still
being stripped via `tools:node="remove"` a few lines below the restored
permission, while three sibling AdServices permissions
(`ACCESS_ADSERVICES_ATTRIBUTION`/`CUSTOM_AUDIENCE`/`TOPICS`, auto-added to
the manifest by a dependency) were left alone. Same bug as this finding,
just on Google's newer attribution path. Removed the `tools:node="remove"`;
verified all four AdServices permissions plus the classic `AD_ID` now land
together in the packaged manifest.

### 3. iOS has no App Tracking Transparency support

**Where:** `ios/Runner/Info.plist` has **no `NSUserTrackingUsageDescription`**
and **no `SKAdNetworkItems`**. No ATT package in `pubspec.yaml`. Yet
`facebook_events_service.dart:14` asserts advertiser tracking is enabled.

**Impact:** Two separate problems.

- Per the plugin's own deprecation note, **iOS 17+ ignores that setter** and
  derives consent from `ATTrackingManager.trackingAuthorizationStatus`. Without
  `NSUserTrackingUsageDescription` you cannot even present the ATT prompt, so
  IDFA is never available on iOS.
- Missing `SKAdNetworkItems` means Meta's install attribution on iOS is degraded
  regardless of ATT.

Asserting tracking-enabled with no ATT prompt is also an App Store review risk.
The shipped version is `1.0.3+2 # ios`, so this is live.

**Fix:** Add `NSUserTrackingUsageDescription` plus Meta's `SKAdNetworkItems`
list, request ATT before enabling collection, and gate advertiser-ID collection
on the result.

**Fixed 2026-08-26.**

- Added `NSUserTrackingUsageDescription` to `Info.plist`.
- Added `SKAdNetworkItems` with Meta's own identifier
  (`v9wttpbfk9.skadnetwork`). This is Meta's ID for its own attribution, well
  documented across independent sources; I could not get Meta's docs pages to
  render a complete, current list via automated fetch, and did not want to
  fabricate entries. If this app ever mediates third-party ad networks
  through Audience Network (it doesn't today), that would need a longer list
  from Meta's Audience Network SKAdNetwork docs — **verify the current list
  against Meta's developer docs before an App Store submission.**
- Added the `app_tracking_transparency` package and rewrote
  `FacebookEventsService._advertiserIdCollectionAllowed()`
  (`lib/core/services/facebook_events_service.dart`) to check
  `AppTrackingTransparency.trackingAuthorizationStatus`, request the prompt
  when not yet determined, and gate `setAdvertiserIdCollectionEnabled` on the
  result. Android and other platforms resolve to `TrackingStatus.notSupported`
  from the package itself and are treated as allowed — unaffected by this
  change; only iOS behavior changes.

### 4. Non-reproducible build that can violate the plugin's version range

**Where:** `android/app/build.gradle.kts:80` declares
`com.facebook.android:facebook-android-sdk:latest.release`. The plugin declares
`com.facebook.android:facebook-android-sdk:[18.0,19.0)`. The iOS podspec pins
`FBSDKCoreKit ~> 18.0`.

**Impact:** Gradle resolves conflicts to the highest version, so
`latest.release` wins and can pull an SDK **outside** the plugin's supported
range — producing `NoSuchMethodError` at runtime or a broken build, triggered by
Meta's release schedule rather than by any change of yours. Builds are also not
reproducible: two builds of the same commit can embed different SDK versions.

**Fix:** Delete the line. The plugin already supplies the SDK transitively. If
an explicit pin is wanted, use `18.+` to stay inside the supported range.

**Fixed 2026-08-18.** Line removed, with a comment recording why it must not
come back. Safe because no app-module source references `com.facebook` — the
only references are the two manifest metadata strings, which need the SDK at
runtime, not on the compile classpath. The plugin's `implementation` dependency
is on the app's runtime classpath transitively.

Verified by a real `flutter build apk --release`:

- The SDK now resolves to **18.3.0**, inside the plugin's `[18.0,19.0)` range,
  instead of whatever `latest.release` happened to point at.
- `com.facebook.appevents` and friends are present in the release APK's dex, so
  R8 did not strip them and the transitive dependency genuinely ships.

---

## Medium severity

### 5. Currency defaults to USD in a PKR-denominated app

**Where:** `facebook_events_service.dart:28,44,56,68` all default to
`currency = 'USD'`. The app is entirely PKR: `formatPKR()` returning `'Rs. …'`
(`seller_instalments_model.dart:743`), `'Pricing (PKR)'`, `'PKR 0'`. No call
site passes a currency.

**Impact:** Rs. 5,000 would be reported to Meta as $5,000 — roughly a 280×
overstatement of conversion value, corrupting ROAS and any value-based bidding.

**Fix:** Default to `'PKR'`, or better, require the parameter so it cannot be
wrong by omission.

**Fixed 2026-08-18.** All four methods now default to a single
`FacebookEventsService.defaultCurrency = 'PKR'` constant rather than four
repeated `'USD'` literals.

### 6. `fb_num_items` is coerced to zero

**Where:** `facebook_events_service.dart:62` — `numItems: numItems ?? 0`.

**Impact:** The plugin omits the parameter when null; forcing `0` actively tells
Meta the basket was empty at checkout.

**Fix:** Pass `numItems` straight through as nullable.

**Fixed 2026-08-18.** `numItems` is now forwarded unchanged, so the plugin omits
`fb_num_items` when the caller has no count.

### 7. `logViewContent` reimplements a plugin method, worse

**Where:** `facebook_events_service.dart:30-38` hand-rolls
`logEvent(name: 'fb_mobile_content_view', …)`. The plugin already provides
`logViewContent({content, id, type, currency, price})`.

**Impact:** Three defects versus the built-in:

- `fb_content` is sent as a bare product name. Meta specifies a **JSON-encoded**
  array of objects; the plugin does `json.encode(content)`. Item id, quantity
  and price cannot be parsed.
- `fb_content_type` is never sent.
- `fb_currency` is gated behind `price != null`, so a priceless view drops
  currency.

**Fix:** Delegate to the plugin's `logViewContent`.

**Fixed 2026-08-18.** Now delegates to the plugin method, which supplies
`fb_content_type` and stops gating currency on price. One caveat found while
fixing it: the plugin's `content:` argument JSON-encodes a bare *object*, but
Meta specifies an *array* of item objects — so `fb_content` is built here as
`jsonEncode([{id, quantity, item_name, item_price}])` and passed via
`parameters:` instead of `content:`.

### 8. Log methods are unguarded

**Where:** `initialize()` (`:12-21`) wraps its work in try/catch. None of the
four log methods do.

**Impact:** A `PlatformException` propagates into whatever UI flow logged the
event. The project ships `web/`, `windows/`, `linux/` and `macos/` targets where
this plugin has **no implementation**, so `MissingPluginException` escapes there.
Separately, invalid parameters raise `ArgumentError` **synchronously** — before
the Future exists — so a caller using `.catchError()` will not catch it; only
try/catch works.

**Fix:** Apply the same best-effort guard used by `initialize()` to all log
methods. Analytics must never break a checkout.

**Fixed 2026-08-18.** All four methods now route through a private `_guard`
helper. It invokes the action *inside* its try block rather than merely awaiting
it, which is what catches the synchronous `ArgumentError` case — awaiting a
future returned from outside the try would not.

### 9. Deprecated API in use

**Where:** `facebook_events_service.dart:14` — `setAdvertiserTracking`.
Deprecated in 0.30.5; `flutter analyze` reports it.

**Fix:** Use `setAdvertiserIdCollectionEnabled`, which maps 1:1 to the native
setting on both platforms.

**Fixed 2026-08-26.** `initialize()` now calls `setAdvertiserIdCollectionEnabled`.
`flutter analyze` no longer reports the deprecation.

### 10. Partial initialisation fails silently

**Where:** `facebook_events_service.dart:12-21` — all three setup calls share a
single try block.

**Impact:** If the first call fails, the other two never run. The app starts
normally and reports nothing beyond a `debugPrint`, so attribution can be dead
in production with no signal. Verified by test.

**Fix:** Guard each call independently, and report failures somewhere durable
(Crashlytics) rather than only `debugPrint`.

**Fixed 2026-08-26.** Each setup call now runs through the same `_guard`
helper used by the log methods, so a failure in one no longer skips the
other. Durable failure reporting (Crashlytics) is not wired up — the project
has no Crashlytics dependency, so that half of the fix is out of scope here.

### 11. `activateApp()` called with auto-logging already enabled

**Where:** `facebook_events_service.dart:13` then `:15`.

**Impact:** Plugin docs state `activateApp` is only needed when automatic
logging has been disabled or delayed. Calling both risks double-counted
activation events.

**Fix:** Drop `activateApp()` unless auto-logging is intentionally deferred for
consent.

**Fixed 2026-08-26.** Call removed, with a comment recording why.

---

## Low / cleanup

### 12. No consent gating

Auto-logging is switched on unconditionally at startup, with no call to
`setDataProcessingOptions` (LDU/CCPA) or `setLimitEventAndDataUsage`. Relevant
if the app has EU or California users. Verified by test.

### 13. Client token committed to the repo

`facebook_client_token` appears in `android/.../strings.xml:5` and
`Info.plist:21`. This matches Meta's documented approach and client tokens are
extractable from any shipped binary, so severity is low — noted only so it is a
conscious choice.

### 14. Dead Facebook Login configuration

- `fb_login_protocol_scheme` — `strings.xml:6`
- `fb2249660285429838` URL scheme — `Info.plist:9-17`
- `README.md:1053-1061` documents `FacebookAuth.instance.login()` and
  `README.md:973` advertises "Social login buttons (Google, Facebook)"

None of it is functional: `flutter_facebook_auth` is not a dependency and there
is no `FacebookActivity` in the manifest. Either implement login or remove the
config and correct the README, which currently documents a feature that does not
exist.

**Fixed 2026-08-26.** Removed `fb_login_protocol_scheme` from `strings.xml`
and the dead `CFBundleURLTypes`/`fb2249660285429838` block from `Info.plist`
(nothing else in either manifest referenced them). Corrected the three README
passages to say plainly that the Facebook button/handler shown is unwired
example code, not a real feature — didn't implement actual Facebook Login,
which is a real feature addition outside this audit's scope, not a cleanup.

### 15. Unused high-value APIs

- `setUserData` / `setUserID` — advanced matching, materially improves match
  rates for a logged-in e-commerce app.
- `logCompletedRegistration` — the app has a signup flow.
- `setPushNotificationsDeviceToken` — the app already uses FCM, so push
  attribution is nearly free.

**Fixed 2026-08-26.** Added all four as guarded methods on
`FacebookEventsService` and wired them at the points that actually have the
relevant data:

- `setUserId`/`setUserData` (email, phone, external id) — `AuthViewModel.login()`
  success, right after `SessionManager.saveUserSession()`. Not name-splitting
  into first/last: the API only has one `name` field and guessing at a
  first/last split is more likely to feed Meta wrong data than none.
- `logCompletedRegistration` — `AuthViewModel.verifyOtp()` success, not
  `signup()`. The account can't log in until OTP/email verification succeeds,
  so that's the actual completion of registration, not the form submit.
- `clearUser()` — `ProfilePage._logout()`, alongside the existing
  `FcmService.unlinkUser()` call, so a device doesn't keep reporting events
  under the previous user's identity after logout.
- `setPushNotificationsDeviceToken` — `FcmService.initialize()`'s initial
  token fetch and its `onTokenRefresh` listener, alongside the existing
  backend sync (separate system; this doesn't replace it).

---

## Verification

- `test/facebook_events_service_test.dart` — 15 tests, all passing (re-verified
  2026-08-26 after the #1/#9/#10/#11 fixes, including the two tests updated to
  assert the corrected `initialize()` behaviour).
- `flutter analyze lib/core/services/facebook_events_service.dart` — no issues
  (2026-08-26). Previously reported the #9 deprecation warning.
- `flutter analyze` project-wide — 219 issues (2026-08-26), all pre-existing
  and unrelated (deprecated `withOpacity`, unused imports/params elsewhere);
  down from 221 at the start of this audit, accounted for by the #9 fix.
- `ios/Runner/Info.plist`, `android/.../strings.xml`,
  `android/.../AndroidManifest.xml` — checked well-formed after editing.

## Not covered

These tests assert what reaches the native MethodChannel. They do **not** prove
delivery to Meta. Confirming that requires a physical device plus Events Manager
→ Test Events, because a payload can be perfectly formed and still be discarded
by the ATT and AD_ID problems in #2 and #3.
