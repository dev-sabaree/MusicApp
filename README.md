# Music App

Flutter client with a lightweight local backend for auth, pairing, and synchronized player state.

## Frontend (Flutter)

```bash
flutter pub get
flutter run
```

## Backend (Node or Dart)

### Option 1: Node.js

```bash
cd backend
npm start
```

### Option 2: Dart

```bash
cd backend
dart run dart_server.dart
```

Both implementations expose the same API contract on `http://localhost:8080`.
See `backend/README.md` for endpoint details.
