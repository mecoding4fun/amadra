# 🚀 AMADRA — Community Social App (Flutter + Firebase + Supabase)

AMADRA is a community-focused social application built with **Flutter** for mobile, and powered by **Firebase** & **Supabase** for authentication, storage, and realtime-like features. It’s designed as a polished, performant mobile-first experience for posting images, interacting with communities, and sharing content.

> 💡 **Concept:** A simple social feed + communities app, optimized for smooth mobile UX and reliable media handling.

## 📌 Important Note Before Running

The app expects a backend (Firebase + Supabase) configuration. Replace the placeholder keys/config values in the app before running.

- Configure Firebase (Auth, Firestore/Realtime DB, Storage).
- Configure Supabase (optional: image uploads/metadata).
- Make sure your Google services JSON / plist are placed in the platform folders for Android/iOS.

## ✨ Features

* **🔐 Authentication:** Email / Google (via Firebase Auth)
* **🖼 Image Posting:** Upload, display and cache user images
* **⚡ Feed:** Scrolling feeds with cached images for smooth performance
* **💬 Interactions:** Likes, comments, and simple community tagging
* **📤 Uploads:** Multi-image picker + camera support
* **📥 Caching:** Image & data caching for offline-ish experience
* **🧩 Modular:** Clean folder structure for components and services

## 🏗 Tech Stack

| Layer | Technology |
| :--- | :--- |
| **Mobile Client** | Flutter (Dart) |
| **Auth & Storage** | Firebase Auth, Firebase Storage / Firestore |
| **Optional DB / Storage** | Supabase (Postgres & Storage) |
| **State Management** | Provider / Riverpod / (your choice) |
| **Image Caching** | cached_network_image or flutter_cache_manager |

## 📁 Project Structure

```text
amadra/
│── README.md
│── LICENSE
│── pubspec.yaml
│── pubspec.lock
│── .gitignore
│── firebase.json
│
├── assets/
│   ├── icons/
│   ├── images/
│   └── others/
│
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart    
│   ├── components/                  # UI building blocks
│   │   ├── PostCard.dart
│   │   ├── Comments.dart
│   │   ├── Likes.dart
│   │   ├── post_popup.dart
│   ├── splash_screen.dart
│   ├── login.dart
│   ├── signup.dart
│   ├── Home.dart
│   ├── launcher.dart
│   ├── NotificationsPage.dart
│   ├── profile.dart
│   ├── profileUpdate.dart
│   └── ViewProfile.dart
│   
├── android/
│── ios/
│── macos/
│── linux/
│── functions/       
│── build/
│── .dart_tool/
│── .idea/
```
## 🔧 Local Setup (Development)

### 1. Clone the Repository
```bash
git clone https://github.com/mecoding4fun/amadra.git
cd amadra
```


### 2. Install Dependencies
```
flutter pub get
```


### 3. Firebase Configuration (Required)

AMADRA uses Firebase Auth + Firebase Storage + Firestore.

Follow these steps:

1. Create a Firebase project
2. Enable:
    - Authentication (Email/Password or Google)
    - Firestore Database
    - Firebase Storage
3. Download configuration files:
    - google-services.json → place in android/app/
    - GoogleService-Info.plist → place in ios/Runner/
4. Add Firebase packages to the project (already included in pubspec)


### 4. Supabase Configuration (Optional / For Media & Metadata)

If you are using Supabase:


1. Create a new Supabase project
2. Copy:

    - SUPABASE_URL
    - SUPABASE_ANON_KEY


3. Add them inside your Flutter config file, for example:
```
const String supabaseUrl = "https://xxxxx.supabase.co";
const String supabaseKey = "YOUR_SUPABASE_KEY";
```


### 5. Environment Setup (App Constants)

In your Flutter app, update connection/config constants such as:
```
const String appTitle = "AMADRA";
const String firebaseApiKey = "YOUR_FIREBASE_API_KEY";
```


📱 Running the App



Android and ios :
```
flutter run
```


Building APK (Release)
```
flutter build apk
```


Building AppBundle (App Store)
```
flutter build appbundle
```


🔐 Security Notes

- Use Firebase Security Rules for Storage and Firestore.
- NEVER commit real API keys, Google files, or secrets.
- Use environment variables for CI/CD if you automate deployments.
- Validate and sanitize user-uploaded content.



🎯 Core Features (Implemented)

- 🔐 Firebase Authentication
- 🖼 Image Posting & Uploads
- ⚡ Smooth Cached Feed
- 💬 Community & Post Interaction
- 📤 Multi-image Picker Support
- 🧩 Clean Architecture & Modular Code
- 📥 Caching for smooth UX



🛠 Tech Used

- Flutter (Dart)
- Firebase (Auth, Firestore, Storage)
- Supabase (Optional media backend)
- State Management: Provider / Riverpod (depending on your setup)
- Caching: cached_network_image + Flutter cache manager



🧭 Roadmap / Future Enhancements

- Community moderation
- Video uploads & playback
- Real-time notifications
- Post drafts & scheduling
- Explore page algorithm
- User profiles redesign
- Web version (Next.js or Flutter Web)



👤 Author

Built by Ramachandran 
GitHub: https://github.com/mecoding4fun
Portfolio: https://mecoding4fun.com
