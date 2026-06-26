# Swappit — Skill Trading Platform

> Trade skills, not money. Connect, collaborate, and swap expertise with your local community.

## Overview
Swappit is a full-stack skill trading platform featuring:
- A Node.js + Express backend API
- MySQL for user, skill, trade, chat, and notification data
- A Flutter mobile app with authentication, onboarding, search, chat, and trade flows
- Email OTP verification and Google sign-in support
- Real-time interactions via Socket.io
- Cloudinary image uploads and Firebase notification integration

## Repository Layout
```
Swappit/
├── backend/                    # Backend API service
│   ├── config/                 # Database, Cloudinary, and socket setup
│   ├── controllers/            # Request handlers and business logic
│   ├── database/               # SQL schema and database scripts
│   ├── middlewares/            # JWT auth middleware
│   ├── routes/                 # Express route definitions
│   ├── utils/                  # Helpers (mailer, OTP utils)
│   ├── server.js               # API entry point
│   ├── .env.example            # Environment variables template
│   └── package.json            # Backend dependencies and scripts
├── preview/                    # UI preview assets
└── swappit_flutter/            # Flutter mobile application
    ├── lib/
    │   ├── core/               # Theme, constants, and utilities
    │   ├── models/             # App data models
    │   ├── screens/            # UI screens and flows
    │   ├── services/           # API client and auth provider
    │   └── widgets/            # Reusable UI components
    ├── pubspec.yaml            # Flutter dependencies
    └── README.md               # Flutter project placeholder
```

## Demo setup
A seed script is included so you can populate the database with five demo users and launch the full stack without opening multiple terminals.

### One-command startup
From the repository root:
```bash
python run_project.py
```

That script will:
- install the backend dependencies if needed
- install Flutter dependencies if needed
- start the backend on port 5000
- launch the Flutter web app on port 3000
- seed five demo accounts into MySQL

### Demo accounts
Use any of these credentials on the login screen:
- alicia@example.com / demo1234
- mateo@example.com / demo1234
- nadia@example.com / demo1234
- jordan@example.com / demo1234
- sofia@example.com / demo1234

You can also tap the new Demo accounts section on the login screen for quick sign-in.

## Backend

### What it does
- Supports email/password sign up with OTP verification
- Supports Google OAuth sign-in
- Manages user profiles, photos, and skill selections
- Enables trade request creation, acceptance/rejection, completion, and rating
- Supports chat and notification record keeping
- Exposes protected routes using JWT authentication
- Includes a health check endpoint for deployment readiness

### Requirements
- Node.js 18+
- npm
- MySQL

### Install & configure
```bash
cd backend
npm install
cp .env.example .env
```

### Environment variables
Update `backend/.env` values:
```env
PORT=5000
NODE_ENV=development
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=swappit
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d
GOOGLE_CLIENT_ID=your_google_client_id
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
FIREBASE_PROJECT_ID=your_firebase_project_id
FIREBASE_PRIVATE_KEY=your_firebase_private_key
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=465
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### Database setup
Import the schema into your MySQL database:
```sql
source database/schema.sql
```

### Run the backend
```bash
npm run dev
```

### API Endpoints
| Method | Route | Description |
|---|---|---|
| POST | `/auth/signup` | Register new user and send OTP |
| POST | `/auth/login` | Authenticate using email/password |
| POST | `/auth/verify-otp` | Verify OTP and issue JWT |
| POST | `/auth/resend-otp` | Resend OTP email |
| POST | `/auth/google` | Sign in with Google |
| GET | `/profile` | Get authenticated user profile |
| PUT | `/profile` | Update user profile |
| POST | `/profile/photo` | Upload profile image |
| POST | `/profile/skills` | Save offered/requested skills |
| GET | `/profile/:userId` | View another user profile |
| GET | `/skills/search?q=` | Search available skills |
| GET | `/skills/users?q=` | Search users by skill |
| GET | `/home/dashboard` | Retrieve dashboard data |
| POST | `/trade/request` | Send trade request |
| GET | `/trade` | List user trade requests |
| PUT | `/trade/:id/respond` | Accept or reject trade request |
| PUT | `/trade/:id/complete` | Mark trade as completed |
| PUT | `/trade/:id/rate` | Rate a completed trade |
| GET | `/chats` | Fetch chat conversations |
| GET | `/chats/:userId/messages` | Fetch messages with a user |
| POST | `/chats/messages` | Send a chat message |
| GET | `/notifications` | Fetch notifications |
| PUT | `/notifications/read-all` | Mark notifications as read |

## Flutter App

### What it includes
- Login, signup, and OTP verification screens
- Google authentication support placeholder
- Onboarding flow for profile completion
- Home feed, search, chat, notifications, and profile screens
- Persistent authentication using SharedPreferences
- API integration through `ApiService`
- State management via `Provider`

### Requirements
- Flutter SDK 3+
- Emulator, simulator, or connected device

### Install & run
```bash
cd swappit_flutter
flutter pub get
flutter run
```

For the quickest local workflow, you can also run the repository root launcher:
```bash
python run_project.py
```

### API configuration
Update `swappit_flutter/lib/core/constants/api_constants.dart` to point to your backend:
```dart
static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
// static const String baseUrl = 'http://localhost:5000'; // iOS simulator
// static const String baseUrl = 'https://your-api.onrender.com'; // Production
```

## App architecture

### Backend files
- `backend/server.js` — Express app and Socket.io setup
- `backend/config/db.js` — MySQL pool + startup connection test
- `backend/config/socket.js` — Socket.io event configuration
- `backend/routes/` — Route modules for auth, profile, skills, trade, chat, notifications, home
- `backend/controllers/` — Implementation of request handlers and business logic
- `backend/middlewares/auth.middleware.js` — JWT protection for secured routes
- `backend/utils/mailer.js` — OTP email sending
- `backend/database/schema.sql` — Database structure and initial data

### Flutter files
- `swappit_flutter/lib/main.dart` — App entry point and auth gate
- `swappit_flutter/lib/core/` — Theme, constants, and utility helpers
- `swappit_flutter/lib/models/` — JSON serializable models for app data
- `swappit_flutter/lib/services/api_service.dart` — HTTP client wrapper
- `swappit_flutter/lib/services/auth_provider.dart` — Auth state management and persistence
- `swappit_flutter/lib/screens/` — UI screens, onboarding, navigation flows
- `swappit_flutter/lib/widgets/` — Reusable components like buttons, cards, and form fields

## Full run sequence
1. Ensure MySQL is running and create the `swappit` database.
2. Configure backend environment in `backend/.env`.
3. Install backend dependencies and run `python run_project.py` for the full-stack experience.
4. If you prefer step-by-step startup, run the backend manually with `npm start` or `npm run dev` and then launch the Flutter app with `flutter run`.
5. Seed the demo accounts with `python seed_demo.py` whenever you want to reset the test dataset.

## Notes
- The backend uses an in-memory OTP store for signup verification. Replace this with Redis or a database-backed cache for production.
- Google sign-in requires a valid OAuth client ID and matching frontend/backend config.
- Email OTP delivery relies on SMTP credentials configured in `.env`.
- Set correct emulator localhost mapping: Android emulator uses `10.0.2.2`.

## Troubleshooting
- `ECONNREFUSED` from Flutter: backend is not running or `baseUrl` is incorrect.
- OTP emails fail: verify SMTP credentials and allow app passwords.
- Google auth fails: confirm `GOOGLE_CLIENT_ID` and OAuth app setup.
- MySQL connection fails: check credentials and database access.

## Tech stack summary
- Backend: Node.js, Express, MySQL, JWT, bcrypt, Cloudinary, Socket.io
- Mobile: Flutter, Provider, SharedPreferences, socket_io_client
- Auth: OTP email verification, Google OAuth
- Notifications: Firebase / FCM support
- Deployment-ready: backend can be hosted on Render/Railway/Heroku

## Contact
For questions or configuration help, inspect the backend controllers and Flutter services, or run the app locally to trace requests between `swappit_flutter` and `backend`.

```bash
cd swappit_app
flutter pub get
```

### 3. Configure Google Sign-In
- Create a project in [Google Cloud Console](https://console.cloud.google.com)
- Enable Google Sign-In API
- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Add your `GOOGLE_CLIENT_ID` to backend `.env`

### 4. Set API base URL
Edit `lib/core/constants/api_constants.dart`:
```dart
// Android emulator
static const String baseUrl = 'http://10.0.2.2:5000';

// iOS simulator
static const String baseUrl = 'http://localhost:5000';

// Production
static const String baseUrl = 'https://your-api.onrender.com';
```

### 5. Run the app
```bash
flutter run
```

---

## Onboarding Flow
```
WelcomeScreen
    └── SignUpScreen / LoginScreen
            └── VerificationScreen (OTP)
                    └── OnboardingFlow (4 steps)
                            ├── Step 1: Profile Photo
                            ├── Step 2: Bio & Location
                            ├── Step 3: Skills I Offer
                            └── Step 4: Skills I Want
                                    └── OnboardingSuccessScreen
                                            └── HomeScreen (MainShell)
```

---

## Tech Stack
| Layer | Technology |
|-------|------------|
| Mobile | Flutter |
| Backend | Node.js + Express |
| Database | MySQL |
| Auth | JWT + bcrypt + Google OAuth |
| Real-time | Socket.io |
| Images | Cloudinary |
| Push Notif | Firebase Cloud Messaging |
| Hosting | Render / Railway |
