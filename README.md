<div align="center">
  <h1>🎙️ ChugLi</h1>
  <p><strong>Hyper-local, ephemeral, anonymous conversations.</strong></p>

  [![Flutter Version](https://img.shields.io/badge/Flutter-%5E3.12.2-02569B?logo=flutter)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase)](https://firebase.google.com/)
  [![Dart](https://img.shields.io/badge/Dart-%5E3.0.0-0175C2?logo=dart)](https://dart.dev/)
</div>

---

## 📖 About ChugLi

**ChugLi** is a privacy-first, location-based social platform built with Flutter and Firebase. It enables users to discover and participate in anonymous, ephemeral chat rooms within a specific physical radius (0.5km to 5km). Whether you're looking for recommendations, networking at an event, or just sharing a funny observation on a college campus, ChugLi connects you with the people immediately around you.

No profiles, no histories, no followers. Just the present moment.

## ✨ Key Features

*   📍 **Hyper-Local Discovery:** Filter active rooms based on your GPS location with customizable radiuses (0.5km, 1km, 2km, and 5km).
*   🎭 **True Anonymity:** Powered by Firebase Anonymous Auth. Users are assigned fun, randomized pseudo-handles (e.g., *Anonymous Panda*, *Silent Reader*).
*   ⏳ **Ephemeral Rooms:** Conversations don't last forever. Rooms automatically expire and disappear after a set duration (30 mins, 2 hours, 24 hours).
*   ⚡ **Real-Time Messaging:** Instant message delivery and live activity indicators via Firestore streams.
*   🎉 **Interactive Reactions:** React to individual messages or entire rooms with emojis.
*   🔔 **Push Notifications:** Stay updated on high-activity rooms and replies using Firebase Cloud Messaging (FCM).
*   🛡️ **Community Moderation:** Built-in reporting system and the ability to mute users locally to maintain a safe environment.

## 🛠️ Tech Stack

### Core
*   [Flutter](https://flutter.dev/) (UI Toolkit)
*   [Dart](https://dart.dev/) (Language)

### Backend & Infrastructure
*   **Firebase Authentication:** Anonymous sign-in.
*   **Cloud Firestore:** Real-time NoSQL database for rooms, messages, and user activity.
*   **Firebase Cloud Messaging (FCM):** Push notification delivery.

### Key Packages
*   `geolocator`: GPS coordinate fetching and Haversine distance calculations.
*   `dart_geohash`: Encoding lat/lon for optimized bounding box queries.
*   `shared_preferences`: Local caching of user preferences (theme, radius).
*   `flutter_local_notifications`: Foreground push notification handling.

## 🚀 Getting Started

### Prerequisites

*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.2 or higher)
*   [Firebase CLI](https://firebase.google.com/docs/cli) (if modifying backend configurations)
*   An active Firebase project with Firestore, Authentication (Anonymous), and FCM enabled.

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/your-username/chugli_project65.git
    cd chugli_project65
    ```

2.  **Install dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase**
    Make sure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in the respective directories. If using FlutterFire CLI:
    ```bash
    flutterfire configure
    ```

4.  **Run the app**
    ```bash
    flutter run
    ```

## 📂 Project Structure

```text
lib/
├── core/
│   ├── routing/       # Navigation and route definitions
│   ├── theme/         # Light/Dark mode configurations
│   └── widgets/       # Reusable UI components (Drawer, Buttons)
├── data/
│   └── services/      # Business logic (Firestore, Location, FCM)
├── features/
│   ├── home/          # Main feed and radius filtering logic
│   ├── onboarding/    # Splash screens and permissions
│   ├── profile/       # Radius settings and activity history
│   └── rooms/         # Room creation and live chat UI
├── main.dart          # Application entry point
└── firebase_options.dart # Auto-generated Firebase config
```

## 🔐 Security & Privacy

*   **Location Data:** Exact coordinates are only used temporarily for distance calculations and geohashing.
*   **Data Retention:** Expired rooms are purged to minimize data footprint.
*   **Firestore Rules:** Ensure you have deployed secure Firebase Security rules to restrict document reads/writes to participants.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! 
Feel free to check the [issues page](https://github.com/your-username/chugli_project65/issues).

1. Fork the project.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
