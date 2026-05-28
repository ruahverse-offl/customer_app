# Play Store Readiness — New Balan Medical (Customer)

This is the checklist that takes the customer app from "runs on emulator" to "Google approves the upload." Items are grouped by who has to do them.

---

## 1. Done in this branch ✅

- **App label** — manifest now says `New Balan Medical` (was `NewBalan-Medicines`).
- **Internet permission** — `INTERNET` and `ACCESS_NETWORK_STATE` added (the API would not have worked on a fresh install without these).
- **`POST_NOTIFICATIONS`** added for Android 13+ FCM permission.
- **Removed `MANAGE_EXTERNAL_STORAGE`** — Google heavily restricts this scope. Submissions are rejected unless you fill out a special permission form, and pharmacy apps almost never qualify. We use scoped storage (`READ_MEDIA_IMAGES`) instead.
- **Removed `requestLegacyExternalStorage`** — defunct on Android 11+.
- **Scoped legacy permissions** — `READ_EXTERNAL_STORAGE` capped at SDK 32, `WRITE_EXTERNAL_STORAGE` capped at SDK 29 so Play Console doesn't flag them on newer devices.
- **Backup hardening** — `android:allowBackup="false"` and `fullBackupContent="false"` so cleartext user data isn't auto-backed up. Required for apps that handle medical/PII data.
- **Round icon + RTL support** declared in the manifest.
- **FCM default notification channel** wired to `orders`.
- **`<queries>` declarations** for `tel:`, `mailto:`, and `https:` so `url_launcher` works under package-visibility restrictions on Android 11+.
- **Release signing infrastructure** — `build.gradle.kts` now loads `android/key.properties` when present and falls back to debug keys only for local `flutter run --release`. ProGuard / R8 minify + shrinkResources enabled with rules for Firebase, Razorpay, PDF, and Flutter.
- **Branded splash** — `launch_background.xml` shows the launcher icon on a brand-coloured surface (dark-mode aware via `values-night/colors.xml`).
- **Theme parity with new_balan_fe** — colours, fonts, gradients, easing curves now match the marketing site exactly.

---

## 2. You must do these before uploading 🔴

### 2.1 Generate the upload keystore

```bash
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks ^
        -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (already gitignored):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/you/upload-keystore.jks
```

**Back this file up.** Lose it and you can never push an update to the same listing.

### 2.2 Bump versionCode/versionName

Every release needs a higher `versionCode`. Edit `pubspec.yaml`:

```yaml
version: 1.0.0+1   # versionName+versionCode
```

Increment `+1` to `+2`, `+3`, … for each upload.

### 2.3 Build the release artifact

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

The AAB lands at `build/app/outputs/bundle/release/app-release.aab`. Upload that to the Play Console — **don't upload an APK** for production.

### 2.4 Privacy policy URL

Play Console requires a publicly hosted privacy policy URL. Reuse the one already at the web app: confirm `https://newbalan.in/privacy` (or equivalent) is reachable and contains the disclosures listed in §4 below.

### 2.5 Data safety form (Play Console → App content)

Declare every category of data the app touches. For New Balan Medical, at minimum:

| Category | Collected | Shared | Purpose |
|---|---|---|---|
| Personal info (name, email, phone) | ✅ | ❌ | Account, fulfilment, communications |
| Address | ✅ | ❌ | Order delivery |
| Health info (prescriptions) | ✅ | ❌ | Order fulfilment (encrypted at rest) |
| Financial info | Razorpay-handled | ✅ (to Razorpay) | Payment processing |
| Photos (prescription upload) | ✅ | ❌ | Order fulfilment |
| App activity / crashes | ✅ | ❌ | Diagnostics |
| Device/other IDs (FCM token) | ✅ | ❌ | Push notifications |

### 2.6 Store listing assets

- **App icon** — 512×512 PNG, no alpha, no rounded corners (Play adds them).
- **Feature graphic** — 1024×500 PNG/JPG.
- **Screenshots** — at least 2, ideally 8. Use Pixel-class device frames at 1080×1920 or higher.
- **Short description** — 80 chars max.
- **Full description** — 4000 chars max. Mention Thoothukudi, established 1997, CDSCO-certified medicines, delivery radius.

### 2.7 Content rating questionnaire

Run through Play Console's IARC questionnaire. Pharmacy apps usually land at "Everyone" or "Everyone 10+" — answer the medical/health questions truthfully.

### 2.8 Categorise as "Medical"

App category should be **Medical**, not Shopping. This affects discovery and the policy bar.

---

## 3. App polish recommendations 🟡

These aren't outright blockers but failing them often triggers manual review or low ratings.

- [ ] **Test on a real low-end Android (Android 8 / 2 GB RAM).** Flutter apps can be janky on low memory; verify list scrolling, image caching, and cold start time.
- [ ] **Crash-free rate** — wire up Firebase Crashlytics (you already have `firebase_core`). One line in `main.dart`: `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;`.
- [ ] **Verify deep links** — if you advertise links like `https://newbalan.in/order/123`, add an `<intent-filter>` with `android:autoVerify="true"` and host `.well-known/assetlinks.json`.
- [ ] **Localise the launcher label** — only matters if you ship in Malayalam, but `values-ml/strings.xml` is the path.
- [ ] **Adaptive icon** — `assets/images/adaptive-icon.png` is present. Re-run `flutter pub run flutter_launcher_icons` after any icon change.
- [ ] **Splash screen** — consider `flutter_native_splash` for a smoother brand-coloured splash with the logo centred (the current `launch_background.xml` approach is acceptable but basic).
- [ ] **Accessibility** — all icon-only buttons in the home screen now have `tooltip`s. Audit the rest with `flutter analyze --watch` and the Accessibility Scanner from Google.
- [ ] **Dark mode** — `buildDarkTheme()` exists and is wired up. Verify every screen reads well in dark mode (check pharmacy cards, hero gradient, checkout).
- [ ] **Empty/error states** — use the new `EmptyStateView` / `ErrorStateView` widgets in `lib/core/widgets/status_views.dart`. Search for raw `CircularProgressIndicator()` and replace with `LoadingView` for consistency.

---

## 4. Privacy policy content checklist

Whatever URL you submit must spell out:

- Identity of data controller (New Balan Medical, address, contact).
- Categories of personal data collected (mirror §2.5 above).
- Lawful basis (consent, contract — under DPDP Act 2023 if India-only).
- Third parties (Razorpay for payments, Firebase for push/analytics).
- Data retention period.
- User rights: access, correction, deletion, withdrawal of consent.
- Children's data (the app is not directed at <13).
- Contact email for privacy requests.
- Effective date and last-updated date.

Reuse the policy hosted in `new_balan_fe` (the React site already has `PrivacyPolicy.jsx`). Make sure the URL you give Play Console matches.

---

## 5. Pre-upload smoke test

Run all of these on a real device before hitting "Roll out":

- [ ] Cold start <3s on mid-range device.
- [ ] Sign-up flow ends with the user landing on /home with a session.
- [ ] Sign-in survives app kill.
- [ ] Notification permission prompt fires on Android 13+.
- [ ] A test order completes through Razorpay (sandbox key OK for testing, switch to live key before publishing).
- [ ] Prescription upload works for photos AND PDFs.
- [ ] Order status push notification opens the correct order detail.
- [ ] Back-button doesn't escape the auth gate.
- [ ] App label says "New Balan Medical" on the home screen.
- [ ] Force-killing and reopening doesn't lose cart contents.

---

## 6. Common reasons Google rejects pharmacy apps

Lifted from Play policy + community reports — review before submitting:

1. **Unrestricted medical claims** — never claim the app diagnoses, cures, or treats. The clinic feature should say "consultation," not "treatment."
2. **Prescription drug sales without authorisation** — store listing must state that prescription medicines are dispensed only against a valid prescription, by a licensed pharmacy.
3. **Missing pharmacy license/registration info** — include the New Balan retail license number somewhere in the listing or in About.
4. **`MANAGE_EXTERNAL_STORAGE`** — covered above, already removed.
5. **Cleartext HTTP** — verify no API endpoint is `http://`. `network_security_config.xml` defaults are fine since we don't override them.
6. **Account deletion path** — Play Console now requires apps with accounts to support deletion *from inside the app or via a public web URL*. Make sure `/account` has a working "Delete account" option, or document the URL where users can request deletion.
