# Swipe 💕 — Flutter Dating App

A full-featured Tinder-like dating app built with Flutter 3, Firebase, and Cloudinary.

## Features
- 🔐 Email/Password + Google Sign-In 
- 👤 5-step onboarding (name, birthday, gender/orientation, photos, bio)
- 🃏 Swipe left/right card stack with match detection
- 💕 "It's a Match!" overlay with celebration animation
- 💬 Real-time 1-1 chat with Firestore streams
- 🔍 Discovery filters (age range, distance)
- 📸 Photo upload via Cloudinary (up to 6 photos)
- 🌍 Auto-detected location

---

## 🚀 Setup

### 1. Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com/)
2. Create a new project called `swipe-app`
3. Enable **Authentication** → Email/Password & Google
4. Enable **Cloud Firestore** in production mode
5. Add Android app with package `com.swipeapp.swipe` → download `google-services.json` → place in `android/app/`
6. Add iOS app with bundle ID `com.swipeapp.swipe` → download `GoogleService-Info.plist` → place in `ios/Runner/`
7. Replace placeholder values in `lib/firebase_options.dart`

### 2. Cloudinary
1. Create a free account at [cloudinary.com](https://cloudinary.com)
2. Go to **Settings → Upload → Upload presets** → Add unsigned preset
3. Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String cloudinaryCloudName = 'your-cloud-name';
   static const String cloudinaryUploadPreset = 'your-preset-name';
   ```

### 3. Firestore Security Rules
In the Firebase Console → Firestore → Rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /likes/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /matches/{matchId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
    match /matches/{matchId}/messages/{msgId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 4. Android Permissions
`android/app/src/main/AndroidManifest.xml` already has internet. Add location:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 5. iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We use your location to show nearby profiles.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo access to let you add profile photos.</string>
```

### 6. Run the App
```bash
cd /Users/phyominthein/Desktop/Projects/Swipe
flutter pub get
flutter run
```

---

## 📁 Project Structure
```
lib/
├── main.dart               # Entry point + Firebase init
├── app.dart                # MaterialApp + GoRouter
├── firebase_options.dart   # ⚠️ Replace with your Firebase config
├── core/
│   ├── theme/app_theme.dart       # Dark rose/coral theme
│   ├── router/app_router.dart     # GoRouter with auth guard
│   └── constants/app_constants.dart
├── models/                 # AppUser, Match, Message
├── services/               # AuthService, FirestoreService, CloudinaryService
├── providers/              # Riverpod providers
└── features/
    ├── auth/               # Login, Register
    ├── onboarding/         # 5-step onboarding flow
    ├── discovery/          # Swipe cards + filters
    ├── matches/            # Matches grid
    ├── chat/               # Conversations + real-time chat
    └── profile/            # View + edit profile
```

---

## 🛠 Tech Stack
| | |
|---|---|
| Framework | Flutter 3.24 |
| Auth | Firebase Auth (Email + Google) |
| Database | Cloud Firestore |
| Media | Cloudinary (unsigned upload) |
| State | Riverpod |
| Navigation | GoRouter |
| Swipe | appinio_swiper |
