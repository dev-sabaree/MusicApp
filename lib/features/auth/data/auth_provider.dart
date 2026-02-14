import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/repositories/mock_auth_repository.dart';

// The state of the authentication
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(AuthState()) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    state = AuthState(isLoading: true);
    final user = await _repository.getCurrentUser();
    state = AuthState(user: user, isLoading: false);
  }

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _repository.login(email, password);
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = AuthState(isLoading: true);
    try {
      final user = await _repository.register(name, email, password);
      state = AuthState(user: user, isLoading: false);
    } catch (e) {
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = AuthState(user: null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
