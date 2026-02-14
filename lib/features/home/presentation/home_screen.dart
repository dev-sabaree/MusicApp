import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/features/auth/data/auth_provider.dart';
import 'package:music_app/features/pairing/data/pairing_provider.dart';
import 'package:music_app/core/repositories/mock_pairing_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final pairingState = ref.watch(pairingControllerProvider);
    final theme = Theme.of(context);

    final isPaired = pairingState.status == PairingStatus.paired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(pairingControllerProvider.notifier).unpair();
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              'Hi, ${authState.user?.name ?? "User"}',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPaired ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isPaired ? Icons.link : Icons.link_off,
                    size: 40,
                    color: isPaired ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPaired ? 'Connected with Partner' : 'Not Connected',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isPaired)
                    const Text(
                      'Listening together ❤️',
                      style: TextStyle(color: Colors.pinkAccent),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: isPaired ? () => context.push('/player') : null,
              icon: const Icon(Icons.play_circle_fill, size: 32),
              label: const Text('Open Music Player'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: theme.textTheme.titleMedium,
              ),
            ),
            if (!isPaired)
               Padding(
                 padding: const EdgeInsets.only(top: 16.0),
                 child: TextButton(
                   onPressed: () => context.go('/pairing'),
                   child: const Text('Go to Pairing'),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
