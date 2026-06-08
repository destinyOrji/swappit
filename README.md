# Swappit — Skill Trading Platform

> Trade skills, not money. Barter your expertise with people around you.

## Color Palette
| Role | Color | Hex |
|------|-------|-----|
| Primary | Teal | `#00BFA6` |
| Accent | Coral | `#FF6B6B` |
| Background | Soft White | `#F5F7FA` |
| Text Primary | Dark Navy | `#1A1A2E` |

---

## Project Structure
```
Swappit/
├── backend/                    # Node.js + Express API
│   ├── config/
│   │   ├── db.js               # MySQL pool
│   │   ├── socket.js           # Socket.io handler
│   │   └── cloudinary.js       # Image upload config
│   ├── controllers/            # Business logic
│   ├── middlewares/            # JWT auth guard
│   ├── routes/                 # API routes
│   ├── utils/
│   │   └── mailer.js           # OTP email sender
│   ├── database/
│   │   └── schema.sql          # Full MySQL schema + seed skills
│   ├── server.js               # App entry point
│   ├── .env.example            # Environment variables template
│   └── package.json
│
└── swappit_app/                # Flutter mobile app
    └── lib/
        ├── main.dart           # Entry point + auth gate
        ├── core/
        │   ├── theme/          # Colors, typography, theme
        │   ├── constants/      # API endpoints
        │   └── utils/          # Validators
        ├── models/             # UserModel, TradeModel, etc.
        ├── services/
        │   ├── api_service.dart    # All HTTP calls
        │   └── auth_provider.dart  # Auth state (Provider)
        ├── screens/
        │   ├── auth/           # Welcome, Login, Signup, Verification
        │   ├── onboarding/     # 4-step profile setup
        │   ├── home/           # Dashboard + recommendations
        │   ├── search/         # Search users by skill
        │   ├── chats/          # Conversations list
        │   ├── notifications/  # Notifications feed
        │   └── profile/        # User profile
        └── widgets/            # Reusable UI components
```

---

## Backend Setup

### 1. Install dependencies
```bash
cd backend
npm install
```

### 2. Configure environment
```bash
cp .env.example .env
# Fill in your MySQL, JWT, Cloudinary, Google OAuth credentials
```

### 3. Set up database
```sql
-- Run in MySQL client or workbench
source database/schema.sql
```

### 4. Start server
```bash
npm run dev    # development (nodemon)
npm start      # production
```

### API Endpoints
| Method | Route | Description |
|--------|-------|-------------|
| POST | `/auth/signup` | Register with email |
| POST | `/auth/login` | Login |
| POST | `/auth/verify-otp` | Verify email OTP |
| POST | `/auth/resend-otp` | Resend OTP |
| POST | `/auth/google` | Google Sign-In |
| GET | `/profile` | Get my profile |
| PUT | `/profile` | Update profile |
| POST | `/profile/photo` | Upload photo |
| POST | `/profile/skills` | Update skills |
| GET | `/skills/search?q=` | Search skills |
| GET | `/skills/users?q=` | Search users by skill |
| GET | `/home/dashboard` | Home feed data |
| POST | `/trade/request` | Send trade request |
| GET | `/trade` | My trades |
| PUT | `/trade/:id/respond` | Accept/reject trade |
| PUT | `/trade/:id/complete` | Mark trade complete |
| POST | `/trade/:id/rate` | Rate a trade |
| GET | `/chats` | Conversations |
| GET | `/chats/:userId/messages` | Messages |
| POST | `/chats/messages` | Send message (REST) |
| GET | `/notifications` | Notifications |
| PUT | `/notifications/read-all` | Mark all read |

---

## Flutter App Setup

### 1. Create project (if not done)
```bash
flutter create swappit_app
# Then copy the lib/ folder from this repo
```

### 2. Install packages
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
