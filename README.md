# Speed Call - One-Tap Direct Dial Widget for Android 🚀

A production-ready, high-quality Flutter Android application that enables users to create unlimited customizable **Home Screen AppWidgets** for direct one-tap calling.

![Flutter](https://img.shields.org/badge/Flutter-v3.22+-02569B?logo=flutter)
![Android](https://img.shields.org/badge/Android-SDK%2024+-3DDC84?logo=android)
![Architecture](https://img.shields.org/badge/Architecture-Clean%20%2B%20Feature--First-FF6F00)
![Language](https://img.shields.org/badge/Localization-English%20%7C%20Arabic%20(RTL)-blue)

---

## 🌟 Key Features

- **⚡ Real One-Tap Direct Dial**: Tapping any home screen widget instantly places a phone call (`Intent.ACTION_CALL`). Does NOT open dialer, contact card, or require extra taps.
- **🎨 Deep Widget Customization**:
  - **Sizes**: Small (1x1 / 2x2), Medium (2x1), Large (2x2).
  - **Shapes**: Circular avatar, Rounded corners, Square image.
  - **Colors**: Full ARGB background palette, text colors, transparency, opacity sliders.
  - **Labels**: Show/Hide contact name, phone number, and SIM slot badges.
- **📱 Dual SIM & Multi-SIM Management**:
  - Assign specific SIM card per widget (Always SIM 1, Always SIM 2, Ask every time, or System Default SIM).
- **📞 Contact Management & Picker**:
  - Select specific phone number (Mobile, Work, Home, Main, Other) for contacts with multiple numbers.
  - Search contacts, pin favorites, and organize contacts.
- **🕒 Call History Log**:
  - Tracks direct call attempts, timestamp, and used SIM card with fast re-dialing.
- **🌗 Theme Modes**:
  - Light, Dark, True AMOLED Black, and Material You Dynamic Colors.
- **🌍 Full RTL & Localization**:
  - English and Arabic (`ar`) localization with automatic layout mirroring.

---

## 🏗 Architecture & Tech Stack

This project follows **Clean Architecture** and a **Feature-First** structure:

```
lib/
├── core/
│   ├── di/               # Service Locator (GetIt)
│   ├── local_storage/    # Hive local persistence
│   ├── localization/     # English & Arabic (RTL) localizations
│   ├── native/           # Method Channels (DirectCall, SIMs, AppWidgets)
│   ├── router/           # GoRouter declarative routes
│   └── theme/            # Material 3 & AMOLED theme definitions
├── features/
│   ├── calling/          # Direct call logic, call history repository & BLoC
│   ├── contacts/         # Contacts search, pinning, phone number picker & BLoC
│   ├── settings/         # Theme, vibration, confirmation & language settings BLoC
│   └── widgets/          # Widget customizer, live preview, CRUD & BLoC
└── shared/
    └── widgets/          # Empty state, permission banners, dialogs
```

### Native Android Stack (Kotlin)
- **`DirectDialWidgetProvider.kt`**: Subclass of `AppWidgetProvider` rendering Kotlin `RemoteViews`.
- **`DirectCallManager.kt`**: Triggers native `ACTION_CALL` intent targeting specific SIM handles.
- **`SimManager.kt`**: Retrieves active SIM subscriptions using `SubscriptionManager` / `TelecomManager`.
- **`WidgetRenderUtils.kt`**: Generates custom Bitmaps and RemoteViews without waking Flutter engine.

---

## 🛠 Prerequisites & Setup

1. **Flutter SDK**: `>= 3.20.0`
2. **Android Studio**: Android SDK 24+ (Android 7.0 Nougat or higher).
3. **Target SDK**: Android SDK 34/35.

### Installation

```bash
# 1. Clone the project
git clone https://github.com/example/speed_call_app.git
cd speed_call_app

# 2. Get dependencies
flutter pub get

# 3. Run Unit Tests
flutter test

# 4. Launch on Android Device / Emulator
flutter run
```

---

## 🔒 Permissions & Security

- `android.permission.CALL_PHONE`: Required for placing direct calls without opening dialer.
- `android.permission.READ_CONTACTS`: Required to display contact list and photos.
- `android.permission.READ_PHONE_STATE`: Required to query active SIM card slots and Telecom handles.
- `android.permission.VIBRATE`: Optional haptic feedback before calling.

---

## 🧪 Unit Tests

Run automated unit tests:
```bash
flutter test
```

---

## 📄 License
This project is production-ready and structured for Google Play Store publication.
