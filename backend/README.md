# Stripe Backend (Dynamic Amount + Firebase Credit)

## 1) Install and run backend

```bash
cd backend
npm install
cp .env.example .env
# edit .env and set STRIPE_SECRET_KEY (+ STRIPE_WEBHOOK_SECRET recommended)
npm run dev
```

Server default: `http://localhost:4242`

## 2) Run Flutter app with backend URL

```bash
flutter run --dart-define=STRIPE_BACKEND_URL=http://localhost:4242
```

## 3) Firebase Admin credentials

This backend uses Firebase Admin SDK to credit wallet balance in Firestore.

Project options are aligned to Flutter `FirebaseOptions` by default:

- `FIREBASE_PROJECT_ID=ewallet-12201`
- `FIREBASE_STORAGE_BUCKET=ewallet-12201.firebasestorage.app`

For credentials, set one of these before starting backend:

- `GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/service-account.json`
- or `FIREBASE_CLIENT_EMAIL` + `FIREBASE_PRIVATE_KEY` in `.env`
- or run on an environment that already provides application default credentials.

## 4) Fee behavior for Stripe top-up

On successful Stripe payment, the backend applies a fixed fee plus a percentage fee before wallet credit:

- Default percentage fee: `5.5%` (`TOPUP_FEE_PERCENT=5.5`)
- Default fixed fee: `$0.30` (`TOPUP_FEE_FIXED=0.3`)
- Wallet credit = `gross_amount - (fixed_fee + percentage_fee)`
- Stored in Firestore (`topups`, `processed_topups`, `history`) with:
  - `grossAmount`
  - `feeAmount`
  - `amount` / `netAmount` (credited value)

## 5) Webhook (recommended for auto credit)

Expose local backend for Stripe webhook testing:

```bash
stripe listen --forward-to localhost:4242/stripe-webhook
```

Copy the webhook signing secret (`whsec_...`) to `STRIPE_WEBHOOK_SECRET` in `.env`.

Webhook events handled:

- `checkout.session.completed`
- `checkout.session.async_payment_succeeded`

## 6) Manual confirmation endpoint (app button)

If webhook is not available, app can call:

`POST /confirm-topup`

Body:

```json
{ "sessionId": "cs_test_..." }
```

The backend verifies payment status from Stripe, then credits Firestore if paid.
Idempotency is enforced with `processed_topups/{sessionId}`.

## Endpoints

- `GET /health`
- `POST /create-checkout-session`
- `POST /confirm-topup`
- `POST /stripe-webhook`

## Security

- Never put `sk_live...` in Flutter app files.
- Keep it only in `backend/.env` on server.
- If a secret key was leaked, rotate it immediately in Stripe dashboard.
- Set `STRIPE_SUCCESS_URL`, `STRIPE_CANCEL_URL`, and `PUBLIC_BASE_URL` to `https://` URLs in production.
- `POST /upload-profile-image` now requires a valid Firebase ID token.
- The backend rejects disallowed browser origins and non-JSON API requests.
