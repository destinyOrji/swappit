# Swappit Setup and Run Steps

This document covers everything needed to run the Swappit application locally, including account setup for third-party services, required tools, environment configuration, and launch commands for both backend and Flutter app.

## 1. Prerequisites

### Local tools
- Node.js 18 or later
- npm (comes with Node.js)
- MySQL server
- Flutter SDK 3 or later
- A device, emulator, or simulator for Flutter development
- Git (optional but recommended)

### Required accounts
- Cloudinary account
- Google Cloud account for Google OAuth
- Firebase account for push notification credentials
- Email provider account for SMTP/OTP delivery (Gmail or similar)

## 2. Backend prerequisites

### Create MySQL database
1. Start your MySQL server.
2. Create a new database named `swappit`.
3. Import the schema from `backend/database/schema.sql`.

Example using MySQL CLI:
```sql
CREATE DATABASE swappit;
USE swappit;
SOURCE backend/database/schema.sql;
```

### Create Cloudinary account
1. Visit https://cloudinary.com and sign up for a free account.
2. Copy your Cloud Name, API Key, and API Secret.
3. Fill these values in `backend/.env`.

### Create Google OAuth credentials
1. Visit https://console.cloud.google.com.
2. Create or select a project.
3. Enable the Google Identity Services API.
4. Create OAuth 2.0 Client IDs for your platform(s):
   - Android (web app flow may also be used during development)
   - iOS (if needed)
   - Web (optional)
5. Copy the client ID value.
6. Add `GOOGLE_CLIENT_ID` to `backend/.env`.

### Create Firebase project (optional for notifications)
1. Visit https://console.firebase.google.com.
2. Create a new Firebase project.
3. Add a web or mobile app if needed.
4. Generate service account credentials.
5. Copy the following values into `backend/.env`:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY`

### Create email SMTP credentials
1. Use your email provider SMTP settings.
2. For Gmail, enable App Passwords or less secure app access if required.
3. Add SMTP values to `backend/.env`:
   - `EMAIL_HOST`
   - `EMAIL_PORT`
   - `EMAIL_USER`
   - `EMAIL_PASS`

## 3. Backend setup

### Install dependencies
```bash
cd backend
npm install
```

### Configure environment
1. Copy the example env file:
```bash
cd backend
copy .env.example .env
```
2. Update `backend/.env` with your values.

Example values:
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
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=your_firebase_client_email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=465
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### Validate database connection
Start the backend to confirm it can connect to MySQL:
```bash
cd backend
npm run dev
```
If the server logs `✅ MySQL connected successfully`, the connection is valid.

## 4. Flutter app setup

### Install Flutter dependencies
```bash
cd swappit_flutter
flutter pub get
```

### Configure API base URL
Open `swappit_flutter/lib/core/constants/api_constants.dart` and set the correct backend URL:

```dart
static const String baseUrl = 'http://10.0.2.2:5000'; // Android emulator
// static const String baseUrl = 'http://localhost:5000'; // iOS simulator
// static const String baseUrl = 'https://your-api.onrender.com'; // Production
```

### Configure Google Sign-In in Flutter
If you want Google sign-in to work, ensure you have a valid OAuth client ID.

For web:
- Add a `<meta name="google-signin-client_id" content="YOUR_CLIENT_ID">` tag to `web/index.html`.

For mobile:
- Configure Android and iOS OAuth client IDs in the Google Cloud Console.
- Add the appropriate credentials to your app configuration.

## 5. Run the full application

### Start backend
```bash
cd backend
npm run dev
```

### Start Flutter app
```bash
cd swappit_flutter
flutter run
```

## 6. Important notes
- Use `10.0.2.2` for Android emulators when connecting to a backend running on your machine.
- Use `localhost` for iOS simulators or desktop Flutter targets.
- If the app fails to log in, make sure the backend is running and `baseUrl` is correct.
- OTP is stored in-memory in this project. For production, replace it with Redis or database-backed storage.

## 7. Optional setup

### Deploying backend
- You can deploy the backend to Render, Railway, Heroku, or a similar service.
- Update the Flutter `baseUrl` to the deployed API endpoint.

### Running on a physical device
- Use your machine's local IP address instead of `10.0.2.2`.
- Ensure the device and backend host are on the same network.

## 8. Troubleshooting
- `npm install` fails: ensure Node.js is installed and PowerShell execution policy allows scripts.
- `flutter pub get` fails: ensure Flutter SDK is installed and added to PATH.
- Backend cannot connect to MySQL: review `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, and database existence.
- Email OTP not received: verify SMTP credentials and provider access settings.
- Google sign-in fails: verify `GOOGLE_CLIENT_ID` and OAuth consent settings.
- API request errors: look at backend terminal logs for route and payload details.
