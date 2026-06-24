# ChugLi

A modern Flutter application designed with seamless location services, responsive UI, and secure Firebase integration.

## 🚀 Features

- **Anonymous Authentication**: Secure out-of-the-box user sessions using Firebase Auth.
- **Real-time Data**: Powered by Cloud Firestore for instant, reliable data synchronization.
- **Location Services**: Integrated `geolocator` and `permission_handler` for precise location-aware features.
- **Dynamic Theming**: Built-in, system-aware support for Light and Dark modes.
- **Modern UI**: Utilizing `google_fonts` and `cupertino_icons` for a polished, highly-responsive aesthetic.
- **Local Storage**: Leveraging `shared_preferences` for fast local data caching and state persistence.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **Backend/BaaS**: [Firebase](https://firebase.google.com/) (Auth, Cloud Firestore)
- **Key Packages**:
  - `geolocator` & `permission_handler`
  - `shared_preferences`
  - `google_fonts`
  - `intl`

## 📋 Prerequisites

Before you begin, ensure you have met the following requirements:
- **Flutter SDK**: `^3.12.2` or higher.
- **Dart SDK**: Compatible with the Flutter version.
- **IDE**: Android Studio, VS Code, or Xcode.
- **Platform**: Emulators or physical devices set up for iOS, Android, macOS, Windows, or Web.
- **Firebase**: A configured Firebase project.

## ⚙️ Getting Started

Follow these steps to set up the project locally:

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ChugLi_Project65
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Ensure you have the [Firebase CLI](https://firebase.google.com/docs/cli) installed and are logged in.
   - Run `flutterfire configure` to connect the app to your Firebase project. This will generate/update the `lib/firebase_options.dart` file.
   - **Important**: The app relies on Anonymous Authentication. Make sure to enable it in your Firebase Console under **Authentication > Sign-in method**.

4. **Run the App**
   ```bash
   flutter run
   ```

## 📁 Project Structure

The project follows a structured, modular architecture for scalability:

```text
lib/
├── core/                 # Shared utilities, theming, and constants
│   └── theme/            # Light/Dark mode configurations
├── features/             # App features segregated by domain
│   └── onboarding/       # Splash screen and initial setups
├── main.dart             # Application entry point
└── firebase_options.dart # Generated Firebase configuration
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to submit a Pull Request or open an issue if you encounter any bugs or have feature suggestions.
