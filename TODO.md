# Wallet Security Hardening TODO

## Previous Firebase Setup
- [x] Step 1: Create/update web/index.html with Firebase JS SDK and config
- [x] Step 2: Update lib/main.dart to include Firestore instance  
- [x] Step 3: Run `flutter pub get`
- [x] Step 4: Test with `flutter run -d chrome`
- [x] Step 5: Mark complete

## Security Improvements (Minimal - Add only)
- [ ] 1. Add security deps to backend/package.json → `cd backend && npm install`
- [ ] 2. Update .gitignore + delete exposed Firebase JSON (`../../ewallet-12201-firebase-adminsdk-fbsvc-262a42dfab.json`)
- [ ] 3. Secure backend/server.js (helmet, rate-limit, auth middleware, joi validation, strict CORS)
- [ ] 4. Update lib/services/api_service.dart (dart-define comments)
- [ ] 5. Firebase Console: Rotate service account/API key, set Firestore rules (snippet below)
- [ ] 6. Test: Unauthorized topup fails, authorized succeeds
- [ ] 7. Deploy: Use --dart-define for secrets

## Firestore Rules (paste to console):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /user/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /processed_topups/{id} { allow read, write: if false; }
    match /topups/{id} { allow read: if request.auth != null; }
    match /history/{id} { allow read: if request.auth != null; }
  }
}
```

