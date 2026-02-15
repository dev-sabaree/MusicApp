# MusicApp Backend

A lightweight in-memory backend for auth, pairing, and shared player state.

This backend is available in **both Node.js and Dart**. They expose the same API and are intended for local prototyping.

## Run

### Node.js

```bash
cd backend
npm start
# or: npm run start:node
```

### Dart

```bash
cd backend
dart run dart_server.dart
# or: npm run start:dart
```

The API runs on `http://localhost:8080` by default.

## Endpoints

### Health
- `GET /health`

### Auth
- `POST /auth/register` body: `{ "name": "...", "email": "...", "password": "..." }`
- `POST /auth/login` body: `{ "email": "...", "password": "..." }`
- `GET /auth/me` header: `Authorization: Bearer <token>`
- `POST /auth/logout` header: `Authorization: Bearer <token>`

### Pairing
- `POST /pairing/code` header: `Authorization: Bearer <token>`
- `POST /pairing/join` header: `Authorization: Bearer <token>`, body: `{ "code": "1234" }`

### Player
- `POST /player/state` header: `Authorization: Bearer <token>`, body: `{ "roomId": "..." }`
- `POST /player/action` header: `Authorization: Bearer <token>`, body:
  - play/pause: `{ "roomId": "...", "action": "play" }`
  - seek: `{ "roomId": "...", "action": "seek", "positionMs": 12345 }`

## Notes

- Data is stored in memory and resets on restart.
- This is intended for local development and prototyping.
