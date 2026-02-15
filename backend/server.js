const http = require('http');
const crypto = require('crypto');

const PORT = process.env.PORT || 8080;

const usersByEmail = new Map();
const usersById = new Map();
const sessions = new Map(); // token -> userId
const roomsByCode = new Map();
const roomsById = new Map();

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  });
  res.end(JSON.stringify(payload));
}

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
      if (data.length > 1e6) {
        req.connection.destroy();
        reject(new Error('Payload too large'));
      }
    });
    req.on('end', () => {
      if (!data) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(data));
      } catch {
        reject(new Error('Invalid JSON body'));
      }
    });
    req.on('error', reject);
  });
}

function getAuthUser(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) return null;

  const token = authHeader.slice('Bearer '.length).trim();
  const userId = sessions.get(token);
  if (!userId) return null;
  return usersById.get(userId) || null;
}

function sanitizeUser(user) {
  return { id: user.id, email: user.email, name: user.name };
}

function generateRoomCode() {
  let code;
  do {
    code = Math.floor(1000 + Math.random() * 9000).toString();
  } while (roomsByCode.has(code));
  return code;
}

function getOrCreatePlayerState(room) {
  if (!room.playerState) {
    room.playerState = {
      isPlaying: false,
      positionMs: 0,
      currentSong: {
        title: 'Midnight City',
        artist: 'M83',
        coverUrl: 'https://placeholder.com/cover.jpg',
        durationMs: 243000,
      },
      lastActionSource: '',
      updatedAt: Date.now(),
    };
  }
  return room.playerState;
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    sendJson(res, 204, {});
    return;
  }

  try {
    if (req.method === 'GET' && req.url === '/health') {
      sendJson(res, 200, { ok: true });
      return;
    }

    if (req.method === 'POST' && req.url === '/auth/register') {
      const body = await readJsonBody(req);
      const { name, email, password } = body;
      if (!name || !email || !password) {
        sendJson(res, 400, { error: 'name, email and password are required' });
        return;
      }
      if (usersByEmail.has(email)) {
        sendJson(res, 409, { error: 'Email already exists' });
        return;
      }

      const user = {
        id: crypto.randomUUID(),
        name,
        email,
        password,
      };
      usersByEmail.set(email, user);
      usersById.set(user.id, user);

      const token = crypto.randomUUID();
      sessions.set(token, user.id);

      sendJson(res, 201, { user: sanitizeUser(user), token });
      return;
    }

    if (req.method === 'POST' && req.url === '/auth/login') {
      const body = await readJsonBody(req);
      const { email, password } = body;
      if (!email || !password) {
        sendJson(res, 400, { error: 'email and password are required' });
        return;
      }

      const user = usersByEmail.get(email);
      if (!user || user.password !== password) {
        sendJson(res, 401, { error: 'Invalid credentials' });
        return;
      }

      const token = crypto.randomUUID();
      sessions.set(token, user.id);

      sendJson(res, 200, { user: sanitizeUser(user), token });
      return;
    }

    if (req.method === 'GET' && req.url === '/auth/me') {
      const user = getAuthUser(req);
      if (!user) {
        sendJson(res, 401, { error: 'Unauthorized' });
        return;
      }

      sendJson(res, 200, { user: sanitizeUser(user) });
      return;
    }

    if (req.method === 'POST' && req.url === '/auth/logout') {
      const authHeader = req.headers.authorization;
      if (authHeader?.startsWith('Bearer ')) {
        sessions.delete(authHeader.slice('Bearer '.length).trim());
      }
      sendJson(res, 200, { ok: true });
      return;
    }

    if (req.method === 'POST' && req.url === '/pairing/code') {
      const user = getAuthUser(req);
      if (!user) {
        sendJson(res, 401, { error: 'Unauthorized' });
        return;
      }

      const code = generateRoomCode();
      const room = {
        id: crypto.randomUUID(),
        code,
        hostUserId: user.id,
        joinedUserId: null,
        createdAt: Date.now(),
        playerState: null,
      };
      roomsByCode.set(code, room);
      roomsById.set(room.id, room);

      sendJson(res, 201, { roomId: room.id, code, status: 'waiting' });
      return;
    }

    if (req.method === 'POST' && req.url === '/pairing/join') {
      const user = getAuthUser(req);
      if (!user) {
        sendJson(res, 401, { error: 'Unauthorized' });
        return;
      }

      const body = await readJsonBody(req);
      const { code } = body;
      if (!code) {
        sendJson(res, 400, { error: 'code is required' });
        return;
      }

      const room = roomsByCode.get(code);
      if (!room) {
        sendJson(res, 404, { error: 'Invalid code' });
        return;
      }

      if (room.joinedUserId && room.joinedUserId !== user.id) {
        sendJson(res, 409, { error: 'Room already full' });
        return;
      }

      room.joinedUserId = user.id;
      sendJson(res, 200, { roomId: room.id, status: 'paired' });
      return;
    }

    if (req.method === 'POST' && req.url === '/player/state') {
      const user = getAuthUser(req);
      if (!user) {
        sendJson(res, 401, { error: 'Unauthorized' });
        return;
      }

      const body = await readJsonBody(req);
      const { roomId } = body;
      if (!roomId) {
        sendJson(res, 400, { error: 'roomId is required' });
        return;
      }

      const room = roomsById.get(roomId);
      if (!room) {
        sendJson(res, 404, { error: 'Room not found' });
        return;
      }

      if (room.hostUserId !== user.id && room.joinedUserId !== user.id) {
        sendJson(res, 403, { error: 'Forbidden' });
        return;
      }

      const playerState = getOrCreatePlayerState(room);
      sendJson(res, 200, { playerState });
      return;
    }

    if (req.method === 'POST' && req.url === '/player/action') {
      const user = getAuthUser(req);
      if (!user) {
        sendJson(res, 401, { error: 'Unauthorized' });
        return;
      }

      const body = await readJsonBody(req);
      const { roomId, action, positionMs } = body;
      if (!roomId || !action) {
        sendJson(res, 400, { error: 'roomId and action are required' });
        return;
      }

      const room = roomsById.get(roomId);
      if (!room) {
        sendJson(res, 404, { error: 'Room not found' });
        return;
      }

      if (room.hostUserId !== user.id && room.joinedUserId !== user.id) {
        sendJson(res, 403, { error: 'Forbidden' });
        return;
      }

      const playerState = getOrCreatePlayerState(room);
      if (action === 'play') {
        playerState.isPlaying = true;
      } else if (action === 'pause') {
        playerState.isPlaying = false;
      } else if (action === 'seek') {
        if (typeof positionMs !== 'number' || positionMs < 0) {
          sendJson(res, 400, { error: 'Valid non-negative positionMs is required for seek action' });
          return;
        }
        playerState.positionMs = positionMs;
      } else {
        sendJson(res, 400, { error: 'Unsupported action' });
        return;
      }

      playerState.lastActionSource = user.name;
      playerState.updatedAt = Date.now();

      sendJson(res, 200, { playerState });
      return;
    }

    sendJson(res, 404, { error: 'Not found' });
  } catch (error) {
    sendJson(res, 500, { error: error.message || 'Internal server error' });
  }
});

server.listen(PORT, '0.0.0.0', () => {
  // eslint-disable-next-line no-console
  console.log(`MusicApp backend listening on http://0.0.0.0:${PORT}`);
});
