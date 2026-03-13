# Swipe 💕 — Flutter Dating App

A full-featured, premium dating app built entirely with **Flutter**, **Firebase**, and **Cloudinary**. Swipe delivers a polished, dark-mode-first experience with real-time matching, rich user profiles, and a gated premium tier — all powered by a clean Riverpod + GoRouter architecture.

---

## ✨ Features

### 🃏 Discovery
- Stackable swipe cards powered by `appinio_swiper`
- Cards display high-quality photos, name/age, bio snippets, active status, astrology chips, and a "Super Liked You" indicator
- Action buttons (like, super like, dislike) float atop the card stack
- Expand any card to a full scrollable **Profile Detail** view

### ❤️ Matching & Likes
- Mutual-like detection triggers an instant **Match** overlay animation
- **Received Likes** grid (blurred behind a premium paywall)
- **Super Likes** with dedicated received-super-likes collection
- Real-time like / super-like writes with Firestore

### 💬 Live Chat
- Real-time messaging powered by Firestore streams
- Tap the profile avatar in chat to navigate directly to the sender's profile detail view
- Messages batched in sub-collections for scalability
- Unread badge counts via `badges`

### 🔔 Push Notifications
- Firebase Cloud Messaging integration via `notification_service.dart`
- Local notifications for in-app alerts using `flutter_local_notifications`

### 👤 Profile & Onboarding
- Multi-step onboarding flow
- Full profile editor with **Edit / Preview** tabs
- Multi-image upload with dotted-border pickers (up to 6 photos via Cloudinary)
- `image_cropper` for square crop before upload
- Bottom-sheet pickers for interests, pronouns, height, looking-for, and astrology sign
- `smooth_page_indicator` for photo gallery navigation

### 💎 Premium Tier
- Gated "Who Liked You" screen (blurred unless subscribed)
- Subscription paywall with sleek dark UI
- Super Like button locked for free users

### 🎨 UI / Design
- Fully custom **glassmorphic** bottom navigation bar
- Gradient buttons, pill-shaped tags, and emoji-decorated attribute chips
- Google Fonts typography (`google_fonts`)
- Lottie animations for match overlays and empty states
- `shimmer` loading skeletons throughout
- Native splash screen via `flutter_native_splash` (background `#111118`)

---

## 🏗️ Architecture

Built on **feature-first** folder structure with **Riverpod** for state management and **GoRouter** for type-safe, auth-guarded navigation.

```
lib/
├── main.dart                   # Entry point, Firebase init, splash handling
├── app.dart                    # MaterialApp + GoRouter bootstrap
├── firebase_options.dart        # Auto-generated FlutterFire config
│
├── core/
│   ├── constants/              # AppConstants (Cloudinary keys, etc.)
│   ├── theme/                  # AppTheme, AppColors, text styles
│   └── router/                 # GoRouter config & auth redirect guards
│
├── models/                     # AppUser, Match, Message data models
│
├── services/
│   ├── auth_service.dart        # Firebase Auth (email + Google Sign-In)
│   ├── firestore_service.dart   # All Firestore reads/writes
│   ├── cloudinary_service.dart  # Image upload via Cloudinary REST API
│   ├── notification_service.dart# FCM + local notifications
│   └── seed_demo_users.dart     # Demo data seeder
│
├── providers/                   # Global Riverpod providers
│
└── features/
    ├── auth/                    # Login & registration screens
    ├── onboarding/              # Multi-step profile setup flow
    ├── splash/                  # Animated splash / auth gate
    ├── discovery/               # Swipe card stack & user detail view
    ├── matches/                 # Mutual matches grid
    ├── chat/                    # Real-time messaging interface
    ├── premium/                 # Paywall & "Likes You" grid
    ├── profile/                 # Profile editor with tabs & pickers
    ├── home/                    # Shell scaffold & bottom nav
    └── shared/                  # Reusable widgets (cards, chips, etc.)
```

---

## 🛠 Tech Stack

| Category | Technology | Version |
|---|---|---|
| Framework | Flutter | 3.x |
| State Management | flutter_riverpod | ^2.5.1 |
| Navigation | go_router | ^14.2.7 |
| Database | Cloud Firestore | ^5.4.4 |
| Authentication | Firebase Auth | ^5.3.1 |
| Cloud Storage | Firebase Storage | ^12.3.2 |
| Media Hosting | Cloudinary API | — |
| Push Notifications | Firebase Messaging | ^15.1.3 |
| Swipe Cards | appinio_swiper | ^2.0.0 |
| Image Handling | image_picker + image_cropper | ^1.1.2 / ^8.0.2 |
| Animations | flutter_animate + lottie | ^4.5.0 / ^3.1.2 |
| HTTP Client | dio + http | ^5.7.0 / ^1.2.2 |
| Location | geolocator + geocoding | ^12.0.0 / ^3.0.0 |
| Fonts | google_fonts | ^6.2.1 |

---

## 🚀 Setup & Run

### 1. Firebase Configuration

Sensitive config files are `.gitignore`'d — you must supply your own:

1. Go to [console.firebase.google.com](https://console.firebase.google.com/) and create a project.
2. Enable **Authentication** (Email/Password & Google Sign-In) and **Cloud Firestore**.
3. Enable **Firebase Storage** for profile photos.
4. Enable **Firebase Cloud Messaging** for push notifications.
5. Register your **Android** app (`com.swipeapp.swipe`):
   - Download `google-services.json` → place in `android/app/`
6. Register your **iOS** app (`com.swipeapp.swipe`):
   - Download `GoogleService-Info.plist` → place in `ios/Runner/`
7. Generate `lib/firebase_options.dart` using the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

### 2. Cloudinary Setup (Image Uploads)

1. Create a free account at [cloudinary.com](https://cloudinary.com).
2. Go to **Settings → Upload → Upload Presets** and create an **unsigned** preset.
3. Update `lib/core/constants/app_constants.dart`:
   ```dart
   class AppConstants {
     static const String cloudinaryCloudName = 'your-cloud-name';
     static const String cloudinaryUploadPreset = 'your-unsigned-preset';
   }
   ```

### 3. Deploy Firestore Security Rules

```bash
firebase deploy --only firestore:rules
```

### 4. Run the App

```bash
flutter pub get
flutter run
```

To run on a specific device:
```bash
flutter run -d <device-id>
```

---

## 🔐 Firestore Security Rules

The rules in `firestore.rules` enforce:

| Collection | Read | Write |
|---|---|---|
| `users/{userId}` | Any authenticated user | Owner only |
| `likes/{userId}` | Any authenticated user | Any authenticated user |
| `matches/{matchId}` | Any authenticated user | Any authenticated user |
| `matches/{matchId}/messageBatches` | Any authenticated user | Any authenticated user |
| `received_likes/{userId}` | Recipient only | Any authenticated user (swiper writes) |
| `received_super_likes/{userId}` | Recipient only | Any authenticated user (swiper writes) |

> **Note:** `demo_user_*` documents bypass auth restrictions to support seeded demo data.

---

## 📋 Development Notes

- **Code generation**: Run `build_runner` after modifying Riverpod annotated providers:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- **Linting**: Project uses `riverpod_lint` + `custom_lint` for provider-level lint rules.
- **Geolocator override**: `geolocator_android` is pinned to `4.6.1` via `dependency_overrides` to resolve a build compatibility issue.
