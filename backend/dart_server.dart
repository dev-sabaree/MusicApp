import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

final Map<String, Map<String, dynamic>> usersByEmail = {};
final Map<String, Map<String, dynamic>> usersById = {};
final Map<String, String> sessions = {}; // token -> userId
final Map<String, Map<String, dynamic>> roomsByCode = {};
final Map<String, Map<String, dynamic>> roomsById = {};

String newId() => DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(99999).toString();

Map<String, String> corsHeaders = {
  HttpHeaders.contentTypeHeader: 'application/json',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

Future<Map<String, dynamic>> readBody(HttpRequest req) async {
  final body = await utf8.decoder.bind(req).join();
  if (body.trim().isEmpty) return {};
  final decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('Body must be a JSON object');
}

void sendJson(HttpRequest req, int status, Object payload) {
  req.response.statusCode = status;
  corsHeaders.forEach(req.response.headers.set);
  req.response.write(jsonEncode(payload));
  req.response.close();
}

Map<String, dynamic>? getAuthUser(HttpRequest req) {
  final authHeader = req.headers.value(HttpHeaders.authorizationHeader);
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;
  final token = authHeader.substring('Bearer '.length).trim();
  final userId = sessions[token];
  if (userId == null) return null;
  return usersById[userId];
}

Map<String, dynamic> sanitizeUser(Map<String, dynamic> user) => {
      'id': user['id'],
      'email': user['email'],
      'name': user['name'],
    };

String generateRoomCode() {
  final random = Random();
  String code;
  do {
    code = (1000 + random.nextInt(9000)).toString();
  } while (roomsByCode.containsKey(code));
  return code;
}

Map<String, dynamic> getOrCreatePlayerState(Map<String, dynamic> room) {
  if (room['playerState'] == null) {
    room['playerState'] = {
      'isPlaying': false,
      'positionMs': 0,
      'currentSong': {
        'title': 'Midnight City',
        'artist': 'M83',
        'coverUrl': 'https://placeholder.com/cover.jpg',
        'durationMs': 243000,
      },
      'lastActionSource': '',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }
  return room['playerState'] as Map<String, dynamic>;
}

Future<void> handleRequest(HttpRequest req) async {
  if (req.method == 'OPTIONS') {
    sendJson(req, HttpStatus.noContent, {});
    return;
  }

  try {
    if (req.method == 'GET' && req.uri.path == '/health') {
      sendJson(req, HttpStatus.ok, {'ok': true});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/auth/register') {
      final body = await readBody(req);
      final name = body['name'] as String?;
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      if (name == null || email == null || password == null) {
        sendJson(req, HttpStatus.badRequest, {'error': 'name, email and password are required'});
        return;
      }
      if (usersByEmail.containsKey(email)) {
        sendJson(req, HttpStatus.conflict, {'error': 'Email already exists'});
        return;
      }

      final user = {
        'id': newId(),
        'name': name,
        'email': email,
        'password': password,
      };
      usersByEmail[email] = user;
      usersById[user['id'] as String] = user;

      final token = newId();
      sessions[token] = user['id'] as String;
      sendJson(req, HttpStatus.created, {'user': sanitizeUser(user), 'token': token});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/auth/login') {
      final body = await readBody(req);
      final email = body['email'] as String?;
      final password = body['password'] as String?;
      if (email == null || password == null) {
        sendJson(req, HttpStatus.badRequest, {'error': 'email and password are required'});
        return;
      }

      final user = usersByEmail[email];
      if (user == null || user['password'] != password) {
        sendJson(req, HttpStatus.unauthorized, {'error': 'Invalid credentials'});
        return;
      }

      final token = newId();
      sessions[token] = user['id'] as String;
      sendJson(req, HttpStatus.ok, {'user': sanitizeUser(user), 'token': token});
      return;
    }

    if (req.method == 'GET' && req.uri.path == '/auth/me') {
      final user = getAuthUser(req);
      if (user == null) {
        sendJson(req, HttpStatus.unauthorized, {'error': 'Unauthorized'});
        return;
      }
      sendJson(req, HttpStatus.ok, {'user': sanitizeUser(user)});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/auth/logout') {
      final authHeader = req.headers.value(HttpHeaders.authorizationHeader);
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        sessions.remove(authHeader.substring('Bearer '.length).trim());
      }
      sendJson(req, HttpStatus.ok, {'ok': true});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/pairing/code') {
      final user = getAuthUser(req);
      if (user == null) {
        sendJson(req, HttpStatus.unauthorized, {'error': 'Unauthorized'});
        return;
      }

      final code = generateRoomCode();
      final room = {
        'id': newId(),
        'code': code,
        'hostUserId': user['id'],
        'joinedUserId': null,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'playerState': null,
      };
      roomsByCode[code] = room;
      roomsById[room['id'] as String] = room;

      sendJson(req, HttpStatus.created, {'roomId': room['id'], 'code': code, 'status': 'waiting'});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/pairing/join') {
      final user = getAuthUser(req);
      if (user == null) {
        sendJson(req, HttpStatus.unauthorized, {'error': 'Unauthorized'});
        return;
      }

      final body = await readBody(req);
      final code = body['code'] as String?;
      if (code == null) {
        sendJson(req, HttpStatus.badRequest, {'error': 'code is required'});
        return;
      }

      final room = roomsByCode[code];
      if (room == null) {
        sendJson(req, HttpStatus.notFound, {'error': 'Invalid code'});
        return;
      }

      if (room['joinedUserId'] != null && room['joinedUserId'] != user['id']) {
        sendJson(req, HttpStatus.conflict, {'error': 'Room already full'});
        return;
      }

      room['joinedUserId'] = user['id'];
      sendJson(req, HttpStatus.ok, {'roomId': room['id'], 'status': 'paired'});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/player/state') {
      final user = getAuthUser(req);
      if (user == null) {
        sendJson(req, HttpStatus.unauthorized, {'error': 'Unauthorized'});
        return;
      }

      final body = await readBody(req);
      final roomId = body['roomId'] as String?;
      if (roomId == null) {
        sendJson(req, HttpStatus.badRequest, {'error': 'roomId is required'});
        return;
      }

      final room = roomsById[roomId];
      if (room == null) {
        sendJson(req, HttpStatus.notFound, {'error': 'Room not found'});
        return;
      }

      if (room['hostUserId'] != user['id'] && room['joinedUserId'] != user['id']) {
        sendJson(req, HttpStatus.forbidden, {'error': 'Forbidden'});
        return;
      }

      final playerState = getOrCreatePlayerState(room);
      sendJson(req, HttpStatus.ok, {'playerState': playerState});
      return;
    }

    if (req.method == 'POST' && req.uri.path == '/player/action') {
      final user = getAuthUser(req);
      if (user == null) {
        sendJson(req, HttpStatus.unauthorized, {'error': 'Unauthorized'});
        return;
      }

      final body = await readBody(req);
      final roomId = body['roomId'] as String?;
      final action = body['action'] as String?;
      final positionMs = body['positionMs'];
      if (roomId == null || action == null) {
        sendJson(req, HttpStatus.badRequest, {'error': 'roomId and action are required'});
        return;
      }

      final room = roomsById[roomId];
      if (room == null) {
        sendJson(req, HttpStatus.notFound, {'error': 'Room not found'});
        return;
      }

      if (room['hostUserId'] != user['id'] && room['joinedUserId'] != user['id']) {
        sendJson(req, HttpStatus.forbidden, {'error': 'Forbidden'});
        return;
      }

      final playerState = getOrCreatePlayerState(room);
      if (action == 'play') {
        playerState['isPlaying'] = true;
      } else if (action == 'pause') {
        playerState['isPlaying'] = false;
      } else if (action == 'seek') {
        if (positionMs is! num || positionMs < 0) {
          sendJson(req, HttpStatus.badRequest, {'error': 'Valid non-negative positionMs is required for seek action'});
          return;
        }
        playerState['positionMs'] = positionMs.toInt();
      } else {
        sendJson(req, HttpStatus.badRequest, {'error': 'Unsupported action'});
        return;
      }

      playerState['lastActionSource'] = user['name'];
      playerState['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      sendJson(req, HttpStatus.ok, {'playerState': playerState});
      return;
    }

    sendJson(req, HttpStatus.notFound, {'error': 'Not found'});
  } catch (e) {
    sendJson(req, HttpStatus.internalServerError, {'error': e.toString()});
  }
}

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('MusicApp Dart backend listening on http://0.0.0.0:$port');
  await for (final req in server) {
    unawaited(handleRequest(req));
  }
}
