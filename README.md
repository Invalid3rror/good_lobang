# GoodLobang

GoodLobang helps users find and sell near-expiry deals with voice search, Stripe checkout, and Firebase-backed auth, data, and storage.

## Highlights

- Listings: browse, filter, and search near-expiry products
- Voice search: speech-to-text mic in the Home search bar
- Auth: Google sign-in via Firebase Auth (email/password compatible)
- Payments: Stripe checkout with test cards
- Media: upload listing images/files to Firebase Storage
- Notifications: in-app/push for orders and app events
- Navigation: bottom bar for Home, Sell, Notifications, Profile

## Quick start

1) Install Flutter and run `flutter pub get`.
2) Add Firebase configs: google-services.json (Android), GoogleService-Info.plist (iOS/macOS), firebase_options.dart (all).
3) Set up environment variables (see below).
4) Run `flutter run` on your target (emulator/device/web/desktop).

## Environment setup

Create a `.env` file in the project root (it's already in `.gitignore` for security).

Add these variables:

- `STRIPE_PUBLISHABLE_KEY`: Your Stripe publishable key.
  - Get it: Sign up at [stripe.com](https://stripe.com), go to Dashboard > Developers > API keys. Use the "Publishable key" (starts with `pk_test_` for testing).

Example `.env`:
```
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
```

Keep this file local—never commit it to git.

## Configure auth

- Enable Google Sign-In in Firebase Auth and download updated platform config files.
- Make sure OAuth client IDs are present in the Google Services files for each platform.
- Sessions persist via Firebase; Google and email/password can both be used.

## Payments

- Test checkout with `4242 4242 4242 4242`, any future expiry, any CVC, any ZIP.
- Keep secret keys on server-side; app should only use the publishable key.

## Voice search

- Uses `speech_to_text` with `permission_handler` for mic access; tap the mic in the Home search bar.

## Uploads

- Listing images/files are uploaded to Firebase Storage; ensure storage rules are set for your environment.

## Navigation

- Bottom navigation drives Home, Sell, Notifications, and Profile. Search (text or voice) sits in the Home AppBar.

## Notifications

- In-app and push notifications surface order status and app events (ensure FCM is configured per platform).

## Notifications

- In-app and push notifications surface order status and app events (ensure FCM is configured per platform).
