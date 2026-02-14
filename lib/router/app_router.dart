import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/auth/presentation/login_screen.dart';
import 'package:music_app/features/auth/presentation/register_screen.dart';
import 'package:music_app/features/auth/presentation/splash_screen.dart';
import 'package:music_app/features/pairing/presentation/pairing_screen.dart';
import 'package:music_app/features/home/presentation/home_screen.dart';
import 'package:music_app/features/player/presentation/player_screen.dart';
import 'package:music_app/features/auth/data/auth_provider.dart';
import 'package:music_app/features/pairing/data/pairing_provider.dart';
import 'package:music_app/core/repositories/mock_pairing_repository.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider); // Watch auth state (User object)
  final pairingState = ref.watch(pairingControllerProvider); // Watch pairing state (PairingStatus)

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null; // Check if user object is present
      final isPaired = pairingState.status == PairingStatus.paired;
      final isGoingToLogin = state.uri.toString() == '/login';
      final isGoingToRegister = state.uri.toString() == '/register';
      final isGoingToSplash = state.uri.toString() == '/splash';

      // 1. If not logged in, force to Login (unless going to Register)
      if (!isLoggedIn) {
        if (state.uri.toString() == '/splash' && authState.isLoading) return null; // Stay on splash if loading
        if (isGoingToRegister) return null; // Allow access to register
        if (isGoingToLogin) return null; // Allow access to login
        return '/login';
      }

      // 2. If logged in but not paired, force to Pairing
      if (isLoggedIn && !isPaired) {
        if (state.uri.toString() == '/pairing') return null;
        return '/pairing';
      }

      // 3. If logged in and paired, force to Home (if trying to access auth/pairing)
      if (isLoggedIn && isPaired) {
        if (isGoingToLogin || isGoingToRegister || state.uri.toString() == '/pairing' || isGoingToSplash) {
          return '/home';
        }
      }

      return null; // No redirection needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) => const PlayerScreen(),
      ),
    ],
  );
});
