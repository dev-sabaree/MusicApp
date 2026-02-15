import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_app/core/repositories/mock_pairing_repository.dart';
import 'package:music_app/features/auth/data/auth_provider.dart';
import 'package:music_app/features/pairing/data/pairing_provider.dart';
import 'package:music_app/features/player/data/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final pairingState = ref.watch(pairingControllerProvider);
    final playerState = ref.watch(playerControllerProvider);
    final theme = Theme.of(context);

    final isPaired = pairingState.status == PairingStatus.paired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Couples Dashboard'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.surface,
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.06),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.favorite_rounded, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${authState.user?.name ?? 'User'}',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text('Ready for your next couple session?'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isPaired ? Colors.green.withOpacity(0.18) : Colors.orange.withOpacity(0.16),
                border: Border.all(color: isPaired ? Colors.greenAccent : Colors.orangeAccent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(isPaired ? Icons.link : Icons.link_off),
                      const SizedBox(width: 10),
                      Text(
                        isPaired ? 'Connected with Partner' : 'Not Connected Yet',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(isPaired
                      ? 'Realtime controls, hearts, and queue are active.'
                      : 'Pair now to unlock synced controls and reactions.'),
                  if (!isPaired)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context.go('/pairing'),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Start pairing'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickMetric(
                    title: 'Now Playing',
                    value: playerState.currentSong?.title ?? '-',
                    icon: Icons.music_note_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickMetric(
                    title: 'Queue',
                    value: '${playerState.queue.length} songs',
                    icon: Icons.queue_music_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            ElevatedButton.icon(
              onPressed: isPaired ? () => context.push('/player') : null,
              icon: const Icon(Icons.play_circle_fill_rounded, size: 30),
              label: const Text('Open Couple Player'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickMetric extends StatelessWidget {
  const _QuickMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
