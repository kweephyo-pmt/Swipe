# Swipe 💕 — Flutter Dating App

A full-featured dating app with a premium, sleek dark-mode UI inspired by the best modern mobile apps. Built entirely with Flutter, Firebase, and Cloudinary.

## ✨ Key Features
- **Sleek Aesthetic**: Fully custom glassmorphic bottom navigation, gorgeous gradient buttons, custom SVG icons, and a premium dark mode design.
- **Discovery**: Custom stackable swipe cards featuring high-quality images, clean gradient overlays, active indicators, and bio snippets.
- **Premium Tier**: Gated "Super Like" functionality and a blurred "Who Liked You" screen, driving users to a sleek subscription paywall.
- **Robust Profile Editing**: A heavily customized profile editor with tabs for 'Edit' and 'Preview', multi-image uploading via dotted-borders, and beautifully designed bottom sheet pickers for attributes like interests, pronouns, and height. 
- **Real-time Match & Chat**: Immediate "Match" overlays on mutual likes, leading to real-time chat powered by Firestore streams.
- **Rich User Profiles**: Scrollable detailed profiles with extensive photo galleries, emoji-decorated "Looking For" tags, pill-shaped tags for interests, and detailed attributes (height, pronouns).

---

## 🚀 Setup & Execution

### 1. Firebase Project Configuration
Since sensitive keys are `.gitignore`'d, you must supply your own Firebase configuration:
1. Go to [console.firebase.google.com](https://console.firebase.google.com/)
2. Create a project and enable **Authentication** (Email/Password) & **Cloud Firestore**
3. Register your Android app `com.swipeapp.swipe` → Download `google-services.json` → Place in `android/app/`
4. Register your iOS app `com.swipeapp.swipe` → Download `GoogleService-Info.plist` → Place in `ios/Runner/`
5. Generate `lib/firebase_options.dart` using the Flutterfire CLI.

### 2. Cloudinary Setup (For Image Uploads)
1. Create a free account at [cloudinary.com](https://cloudinary.com)
2. Go to **Settings → Upload → Upload presets** and add an unsigned preset.
3. Update `lib/core/constants/app_constants.dart` with your keys:
   ```dart
   class AppConstants {
     static const String cloudinaryCloudName = 'your-cloud-name';
     static const String cloudinaryUploadPreset = 'your-preset-name';
   }
   ```

### 3. Run the Application
```bash
flutter pub get
flutter run
```

---

## 📁 Architecture Overview
Built cleanly using **Riverpod** for robust state management and **GoRouter** for seamless, type-safe navigation and auth guarding.

```
lib/
├── main.dart               # Entry point
├── app.dart                # MaterialApp + AppRouter
├── core/
│   ├── theme/              # Custom AppTheme, AppColors, and typography
│   └── router/             # GoRouter configuration
├── models/                 # AppUser, Match, Message
├── services/               # AuthService, FirestoreService, CloudinaryService
├── providers/              # Global Riverpod state providers
└── features/
    ├── auth/               # Beautiful full-screen login / registration
    ├── discovery/          # The main swipe card stack & User Details view
    ├── premium/            # Subscription paywalls & "Likes You" grids
    ├── matches/            # Grid of mutual matches
    ├── chat/               # Live Messaging interfaces
    └── profile/            # Advanced profile editing with dynamic pickers
```

---

## 🛠 Tech Stack
| Category | Technology |
|---|---|
| Framework | Flutter 3.x |
| Architecture | Riverpod |
| Navigation | GoRouter |
| Database | Cloud Firestore |
| User Auth | Firebase Auth |
| Media Hosting | Cloudinary API |
| Gestures | appinio_swiper |
