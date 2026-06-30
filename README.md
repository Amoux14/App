# CareSaathi

A simple Flutter app for senior citizen support with a local Node.js backend.

## What this project does

This repo contains:

- A Flutter mobile app (`lib/main.dart`) with a login flow using mobile OTP.
- A home screen that lists support services like hospital visits, airport pickup, personal care, and emergency assistance.
- A booking form that collects name, address, emergency contact, date, time slot, and helper gender preference.
- A confirmation screen with booking details and a fake helper assignment.
- A tracking screen showing a simulated helper on a map using `flutter_map`.
- A backend server in `backend/server.js` that handles OTP send/verify using Express and MongoDB.

## Main app flow

1. Enter a 10-digit mobile number.
2. Send OTP to the backend.
3. Enter the 4-digit OTP and verify.
4. Browse service cards and choose a service.
5. Fill in booking details and confirm.
6. View booking confirmation.
7. Track the helper on a map simulation.

## Tech stack

- Flutter for the mobile app
- `flutter_map` + `latlong2` for the map screen
- `http` for REST calls to backend
- Node.js + Express for API gateway and backend server
- MongoDB for OTP and user verification data

## How to run

### Backend & Gateway

1. Open a terminal and go to `backend`.
2. Run `npm install`.
3. Create `.env` from `.env.example` if needed.
4. Start MongoDB locally or use a MongoDB URI.
5. Run `npm start` to start both the backend server and the gateway.
   - Backend listens on `http://127.0.0.1:3000` (internal).
   - Gateway listens on `http://127.0.0.1:4000` (public).

### Flutter app

1. Open the project in your editor.
2. Run `flutter pub get`.
3. Launch the app on a device or emulator.

> The Flutter app communicates through the gateway at `http://127.0.0.1:4000`.

## Architecture

The system uses an **API Gateway** pattern:
- **Gateway** (`backend/gateway.js`) — Express proxy that listens on port 4000 and forwards all `/health` and `/api/*` requests to the backend.
- **Backend** (`backend/server.js`) — Handles authentication, bookings, and business logic on port 3000.
- **Flutter App** — Communicates through the gateway instead of directly hitting the backend.

This decouples the app from the backend and allows for request routing, logging, and other middleware at the gateway level.

## Backend endpoints

- `POST /api/auth/send-otp` — send OTP for a mobile number
- `POST /api/auth/verify-otp` — verify OTP and mark user verified
- `POST /api/bookings` — create a booking and generate an admin-only ticket
- `GET /api/admin/tickets` — view admin-visible tickets with an admin key
- `GET /health` — health check

## Notes

- OTP is generated and logged in the backend console for debugging.
- The tracking screen is simulated, not live GPS.
- The app is a prototype/demo, so some data is hardcoded for presentation.

## Files to check

- `lib/main.dart` — main Flutter UI and flow
- `pubspec.yaml` — Flutter dependencies
- `backend/server.js` — backend auth server
- `backend/gateway.js` — API gateway proxy
- `backend/package.json` — backend scripts and packages
