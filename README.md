# New Balan Medical — Customer App

Flutter mobile app for New Balan Medical pharmacy. Customers can browse medicines, place orders, track delivery, book clinic appointments, and manage their account.

**Platforms:** Android · iOS

---

## Features

- **Pharmacy** — Browse medicines by category, search, add to cart, filter by brand
- **Checkout** — Apply coupons, select saved address, pay via Razorpay (UPI/Card/Netbanking)
- **Orders** — Track order status in real time, view invoice, cancel & refund, reorder
- **Clinic** — Browse specialist doctors, view profiles
- **Polyclinic** — Polyclinic listings
- **Appointments** — View booked appointments
- **Insurance** — Submit insurance enquiries
- **Account** — Edit profile, change password, manage saved addresses
- **Notifications** — Push notifications for order status updates (Firebase FCM)
- **Legal** — Terms & Conditions, Privacy Policy, Refund Policy

---

## Tech Stack

| Layer | Library |
|---|---|
| UI Framework | Flutter 3.x |
| State Management | Riverpod 2 |
| Navigation | go_router 14 |
| HTTP Client | Dio 5 + PrettyDioLogger |
| Auth Storage | flutter_secure_storage |
| Cart Persistence | Hive |
| Push Notifications | Firebase Messaging + flutter_local_notifications |
| Payments | razorpay_flutter |
| PDF Invoice | pdf + printing |
| Image Cache | cached_network_image |
| Environment | flutter_dotenv |

---

## Project Structure

```
lib/
├── main.dart               # Entry point, Firebase init
├── app.dart                # Root widget, notification wiring
├── core/
│   ├── api/                # Dio client with auth interceptor
│   ├── config/             # AppConfig (API URL, shop details)
│   ├── router/             # GoRouter with auth redirect
│   ├── shell/              # Bottom navigation shell
│   ├── storage/            # Secure token storage
│   ├── theme/              # Colors, typography, Material 3 theme
│   ├── utils/              # Order date/status helpers
│   └── widgets/            # Shared widgets
└── features/
    ├── auth/               # Login, register, token refresh
    ├── home/               # Dashboard
    ├── pharmacy/           # Medicine catalog
    ├── cart/               # Cart state (Hive-backed)
    ├── checkout/           # Order creation + Razorpay
    ├── orders/             # Order history + detail
    ├── addresses/          # Saved addresses CRUD
    ├── clinic/             # Doctors listing + detail
    ├── polyclinic/         # Polyclinic listings
    ├── appointments/       # Appointments list
    ├── insurance/          # Insurance enquiry form
    ├── profile/            # Edit profile, change password
    ├── account/            # Account screen + menu
    ├── settings/           # App settings
    ├── notifications/      # FCM token + notification handling
    ├── legal/              # Terms, Privacy, Refund Policy
    └── about/              # About screen
```

---

## Setup

### Prerequisites

- Flutter SDK `>=3.3.0`
- Android Studio / Xcode
- Firebase project with Android & iOS apps registered

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Configure environment

Create a `.env` file in the project root:

```env
API_ORIGIN=https://devapi.newbalanpharmacy.com
API_PREFIX=/api/v1
SHOP_CITY=Palakkad
SHOP_STATE=Kerala
SHOP_PINCODE=678001
```

If `.env` is absent the app falls back to the defaults above.

### 3. Firebase setup

Place the config files in the correct locations:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

---

## Build

### Android (Release APK)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android (Debug APK — for development)

```bash
flutter build apk --debug
```

### iOS

Requires macOS + Xcode. Open `ios/Runner.xcworkspace` in Xcode, set your Team, then:

```bash
flutter build ios --release
```

---

## Backend

| Service | Repo |
|---|---|
| API (FastAPI) | `new_balan_be` |
| Web Admin Panel | `new_balan_fe` |
| Delivery Agent App | `new_balan_delivery` |
