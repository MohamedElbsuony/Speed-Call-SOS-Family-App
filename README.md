# 📞 Speed Call Widget (الاتصال السريع)

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Android-Native-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/Architecture-Clean--Bloc-FF6F00?style=for-the-badge" alt="Architecture" />
  <img src="https://img.shields.io/badge/Offline-100%25-00C853?style=for-the-badge" alt="Offline Ready" />
</p>

---

## 🌟 Overview

**Speed Call Widget** is a state-of-the-art, feature-rich Android mobile application built with **Flutter** and **Kotlin Native Channels**. Designed for maximum accessibility, speed, and emergency readiness, Speed Call enables users to place **1-tap direct calls**, pin **custom home screen app widgets**, trigger **Family SOS emergency alerts**, manage **Favorites**, and dial seamlessly using a **Dual-SIM gradient dock** with **authentic DTMF keypad audio feedback**.

---

## 🔥 Key Features

### 1. 📞 Instant 1-Tap Direct Calling
- Bypass standard dialer screens and place direct calls from keypad, favorites grid, or home screen widgets.
- Native Android `TelecomManager` & `Intent.ACTION_CALL` integration for instant execution.

### 2. 📶 Dynamic Dual-SIM Dock & Hardware Detection
- Automatic hardware modem detection (`TelephonyManager` & `SubscriptionManager`).
- Renders **2 dedicated Dual-SIM Gradient Call Buttons** (**SIM 1** & **SIM 2**) on the dialer keypad for 1-tap line selection.
- Per-contact & per-key SIM preferences (Always SIM 1, Always SIM 2, Ask Every Time).

### 3. 🆘 Family Emergency SOS & 1x1 Compact Home Widget
- **Compact 1x1 Circular SOS AppWidget** for home screens.
- **3 Dedicated Action Modes**:
  1. **Voice Call Only**: Directly dials primary emergency target without modal delays.
  2. **WhatsApp Only**: Dispatches emergency crisis text and GPS location via WhatsApp.
  3. **Direct Offline SMS Only**: Sends direct SMS alerts from phone SIM without needing internet connection.
- Stores contact names alongside phone numbers for clear identification.

### 4. 🎵 Native DTMF Keypad Tones & Haptic Audio
- Real-time audio tone feedback using Android's native `ToneGenerator(STREAM_SYSTEM)` for digits `0-9`, `*`, and `#`.
- Haptic vibration feedback on key presses and long-press actions.

### 5. ⚡ Sub-50ms Contact Performance & Favorites Grid
- Optimized contact fetching (`withPhoto: false`) cutting load times by 100x (<50ms).
- In-memory contact caching for 0ms tab navigation latency.
- Dedicated **Favorites Screen Grid (المفضلة)** backed by persistent **Hive Storage**.
- Keypad T9 smart search filtering.

### 6. 🌐 100% Offline & Dual Language (Arabic / English)
- Uses **Native Material System Fonts** for zero-network font dependencies and 100% offline stability.
- Full RTL and LTR support with complete English & Arabic localizations.

---

## 🏗 System Architecture & Tech Stack

```
lib/
├── core/
│   ├── di/               # Service Locator (GetIt)
│   ├── local_storage/    # Persistent Hive Storage
│   ├── localization/     # AppLocalizations (AR/EN)
│   ├── native/           # DirectCallPlatform & SimInfoPlatform MethodChannels
│   ├── router/           # GoRouter navigation
│   └── theme/            # Material 3 Light, Dark & AMOLED Themes
├── features/
│   ├── calling/          # Keypad, Call History, Speed Dial & Family SOS
│   ├── contacts/         # Contacts list & Favorites Grid
│   ├── settings/         # Categorized Material 3 Settings
│   └── widgets/          # AppWidget Configuration & Preview
└── main.dart
```

- **Framework**: Flutter & Dart
- **State Management**: BLoC Pattern (`flutter_bloc`)
- **Local Storage**: Hive (`hive_flutter`)
- **Native Android**: Kotlin (AppWidgets `FamilySosWidgetProvider`, `ToneGenerator`, `SmsManager`, `SubscriptionManager`)
- **Dependency Injection**: GetIt

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK `3.x` or later
- Android SDK API 24+ (Android 7.0+)
- Java / Kotlin environment

### Installation & Run

```bash
# 1. Clone the repository
git clone https://github.com/mohamedsabry/speed_call_app.git

# 2. Navigate into project directory
cd speed_call_app

# 3. Install Flutter dependencies
flutter pub get

# 4. Run static analysis & unit tests
flutter analyze
flutter test

# 5. Build Release APK (Split ABI)
flutter build apk --release --split-per-abi --no-tree-shake-icons
```

---

## 📱 Screenshots & Previews

| Keypad & Dual-SIM Dock | Favorites Grid | Settings Screen |
| :---: | :---: | :---: |
| *Fullscreen T9 Dialer with Emerald & Royal Blue SIM Buttons* | *1-Tap Direct Call Contact Cards* | *5 Categorized Material 3 Theme & Language Cards* |

---

## 👨‍💻 Developer & Author

**Mohamed Sabry**  
*Lead Mobile Architect & Software Engineer*

- 📧 **Email**: [mo1hamed1.sa1bry@gmail.com](mailto:mo1hamed1.sa1bry@gmail.com)
- 💬 **WhatsApp**: [+201507366570](https://wa.me/201507366570)
- 💼 **LinkedIn**: [linkedin.com/in/mohamed-sabry-49080923b](https://www.linkedin.com/in/mohamed-sabry-49080923b)

---

<p align="center">
  Developed with ❤️ for speed, emergency safety, and accessibility.
</p>
