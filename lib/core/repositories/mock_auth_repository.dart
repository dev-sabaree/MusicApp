import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  final String id;
  final String email;
  final String name;

  User({required this.id, required this.email, required this.name});
}

abstract class AuthRepository {
  Future<User?> getCurrentUser();
  Future<User> login(String email, String password);
  Future<User> register(String name, String email, String password);
  Future<void> logout();
}

class MockAuthRepository implements AuthRepository {
  User? _currentUser;

  @override
  Future<User?> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }

  @override
  Future<User> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'test@test.com' && password == 'password') {
      _currentUser = User(id: '1', email: email, name: 'Test User');
      return _currentUser!;
    }
    throw Exception('Invalid credentials');
  }

  @override
  Future<User> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(id: '2', email: email, name: name);
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});
