# CareSaathi Backend

This backend provides the auth endpoints used by the CareSaathi Flutter app.

## Setup

1. Install dependencies:
   ```bash
   cd backend
   npm install
   ```

2. Create an `.env` file from the example:
   ```bash
   cd backend
   copy .env.example .env
   ```

3. Start MongoDB locally or use a MongoDB Atlas URI in `.env`.

4. Run the backend server:
   ```bash
   npm start
   ```

5. Run the gateway server:
   ```bash
   npm run gateway
   ```

6. The backend listens on `http://127.0.0.1:3000` by default.
   The gateway listens on `http://127.0.0.1:4000` by default and forwards requests to the backend.

## Endpoints

- `POST /api/auth/send-otp`
- `POST /api/auth/verify-otp`
- `POST /api/bookings` — create a new booking and generate an admin ticket
- `GET /api/admin/tickets` — list admin-visible tickets (requires `x-admin-key` header)
- `GET /api/admin/tickets/:ticketNumber` — get a single ticket by number
- `GET /health`

The app expects the gateway at `http://127.0.0.1:4000` and the backend at `http://127.0.0.1:3000`.
