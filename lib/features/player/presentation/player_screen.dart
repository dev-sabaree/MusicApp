import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    if (song == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Couple Player'),
        actions: [
          if (isPaired)
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
              onPressed: () {
                controller.reactWithHeart();
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: controller.mockPartnerAction,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'play', child: Text('Partner: Play')),
              PopupMenuItem(value: 'pause', child: Text('Partner: Pause')),
              PopupMenuItem(value: 'seek', child: Text('Partner: Seek +30s')),
              PopupMenuItem(value: 'heart', child: Text('Partner: Send ❤️')),
              PopupMenuItem(value: 'next', child: Text('Partner: Next Song')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.35),
              theme.colorScheme.secondary.withOpacity(0.2),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: Colors.greenAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPaired
                            ? 'Live synced with your partner'
                            : 'Solo mode: pair to unlock live reactions',
                      ),
                    ),
                    Text(
                      playerState.lastActionSource.isEmpty
                          ? 'Ready'
                          : 'Last: ${playerState.lastActionSource}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6A5AE0), Color(0xFFB07DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.album_rounded, size: 140, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                song.title,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                song.artist,
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(playerState.position)),
                  Text(_formatDuration(song.duration)),
                ],
              ),
              Slider(
                value: playerState.position.inSeconds.toDouble().clamp(0, song.duration.inSeconds.toDouble()),
                max: song.duration.inSeconds.toDouble(),
                onChanged: (value) => controller.seek(Duration(seconds: value.toInt())),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: controller.previousSong,
                    icon: const Icon(Icons.skip_previous_rounded, size: 38),
                  ),
                  const SizedBox(width: 18),
                  Ink(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => playerState.isPlaying ? controller.pause() : controller.play(),
                      icon: Icon(
                        playerState.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 42,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  IconButton(
                    onPressed: controller.nextSong,
                    icon: const Icon(Icons.skip_next_rounded, size: 38),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dedication note', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text(playerState.dedicationNote),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () => _showDedicationEditor(context, controller, playerState.dedicationNote),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('Edit note'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(label: 'Your ❤️', value: '${playerState.yourHearts}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatChip(label: 'Partner ❤️', value: '${playerState.partnerHearts}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.05),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Up next', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (playerState.queue.isEmpty)
                      const Text('Queue is empty')
                    else
                      ...playerState.queue.take(3).map(
                            (queuedSong) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.music_note_rounded, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text('${queuedSong.title} • ${queuedSong.artist}')),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDedicationEditor(
    BuildContext context,
    PlayerController controller,
    String currentNote,
  ) async {
    final inputController = TextEditingController(text: currentNote);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update dedication'),
          content: TextField(
            controller: inputController,
            maxLength: 80,
            decoration: const InputDecoration(hintText: 'A short sweet message...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                controller.setDedicationNote(inputController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
