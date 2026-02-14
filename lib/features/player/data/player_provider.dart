import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Song {
  final String title;
  final String artist;
  final String coverUrl;
  final Duration duration;

  Song({required this.title, required this.artist, required this.coverUrl, required this.duration});
}

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Song? currentSong;
  final String lastActionSource; // "You" or "Partner"

  PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.currentSong,
    this.lastActionSource = "",
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Song? currentSong,
    String? lastActionSource,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      currentSong: currentSong ?? this.currentSong,
      lastActionSource: lastActionSource ?? this.lastActionSource,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  Timer? _ticker;

  @override
  PlayerState build() {
    return PlayerState(
      currentSong: Song(
        title: "Midnight City",
        artist: "M83",
        coverUrl: "https://placeholder.com/cover.jpg",
        duration: const Duration(minutes: 4, seconds: 3),
      ),
    );
  }

  void play() {
    state = state.copyWith(isPlaying: true, lastActionSource: "You");
    _startTicker();
  }

  void pause() {
    state = state.copyWith(isPlaying: false, lastActionSource: "You");
    _stopTicker();
  }

  void seek(Duration position) {
    state = state.copyWith(position: position, lastActionSource: "You");
  }

  // Simulate Partner Action
  void mockPartnerAction(String action) {
    if (action == "pause") {
      state = state.copyWith(isPlaying: false, lastActionSource: "Partner");
      _stopTicker();
    } else if (action == "play") {
      state = state.copyWith(isPlaying: true, lastActionSource: "Partner");
      _startTicker();
    } else if (action == "seek") {
      state = state.copyWith(
        position: state.position + const Duration(seconds: 30), 
        lastActionSource: "Partner"
      );
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final newPos = state.position + const Duration(seconds: 1);
      if (state.currentSong != null && newPos >= state.currentSong!.duration) {
        _stopTicker();
        state = state.copyWith(isPlaying: false, position: Duration.zero);
      } else {
        state = state.copyWith(position: newPos);
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
  }
}

final playerControllerProvider = NotifierProvider<PlayerController, PlayerState>(() {
  return PlayerController();
});
