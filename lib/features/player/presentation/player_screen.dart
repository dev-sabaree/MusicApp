import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/features/auth/data/auth_provider.dart';
import 'package:music_app/features/pairing/data/pairing_provider.dart';
import 'package:music_app/features/player/data/player_provider.dart';
import 'package:music_app/core/repositories/mock_pairing_repository.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final pairingState = ref.watch(pairingControllerProvider);
    final theme = Theme.of(context);

    final isPaired = pairingState.status == PairingStatus.paired;
    final song = playerState.currentSong;

    if (song == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          if (isPaired)
            IconButton(
              icon: const Icon(Icons.link, color: Colors.green),
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced with partner')),
                 );
              },
            ),
          // Demo button to simulate partner action (only if paired effectively, but kept for demo)
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Simulate Partner Action',
            onPressed: () => controller.mockPartnerAction(playerState.isPlaying ? 'pause' : 'play'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80), // For extended app bar
              // Cover Art
              Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(Icons.album, size: 120, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 40),
              
              // Song Info
              Text(
                song.title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                song.artist,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7)
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),

              // Seek Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(_formatDuration(playerState.position), style: theme.textTheme.bodySmall),
                   Text(_formatDuration(song.duration), style: theme.textTheme.bodySmall),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  value: playerState.position.inSeconds.toDouble().clamp(0, song.duration.inSeconds.toDouble()),
                  max: song.duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    controller.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: theme.colorScheme.onSurface.withOpacity(0.2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, size: 48),
                    color: theme.colorScheme.onSurface,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 32),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      boxShadow: [
                         BoxShadow(
                           color: theme.colorScheme.primary.withOpacity(0.4),
                           blurRadius: 10,
                           spreadRadius: 2,
                         )
                      ]
                    ),
                    child: IconButton(
                      iconSize: 48,
                      icon: Icon(playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      color: theme.colorScheme.onPrimary,
                      onPressed: playerState.isPlaying ? controller.pause : controller.play,
                    ),
                  ),
                  const SizedBox(width: 32),
                  IconButton(
                     icon: const Icon(Icons.skip_next_rounded, size: 48),
                     color: theme.colorScheme.onSurface,
                     onPressed: () {},
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Sync Indicator (Only if paired)
              if (isPaired && playerState.lastActionSource.isNotEmpty)
                Container(
                   margin: const EdgeInsets.only(bottom: 32),
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(
                     color: theme.colorScheme.surfaceVariant,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Icon(
                         playerState.lastActionSource == "You" ? Icons.person : Icons.group,
                         size: 16,
                         color: theme.colorScheme.primary,
                       ),
                       const SizedBox(width: 8),
                       Text(
                         playerState.lastActionSource == "You"
                            ? "Corrected by you"
                            : "Partner updated playback", // More generic for demo
                         style: theme.textTheme.labelMedium?.copyWith(
                           color: theme.colorScheme.onSurfaceVariant,
                         ),
                       ),
                     ],
                   ),
                ),
               if (!isPaired)
                 const SizedBox(height: 60), // Spacer placeholder to keep layout stable
            ],
          ),
        ),
      ),
    );
  }
}
