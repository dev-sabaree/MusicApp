import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Song {
  final String title;
  final String artist;
  final String coverUrl;
  final Duration duration;

  Song({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.duration,
  });
}

class PlayerState {
  final bool isPlaying;
  final Duration position;
  final Song? currentSong;
  final List<Song> queue;
  final String lastActionSource;
  final String dedicationNote;
  final int yourHearts;
  final int partnerHearts;

  PlayerState({
    this.isPlaying = false,
    this.position = Duration.zero,
    this.currentSong,
    this.queue = const [],
    this.lastActionSource = '',
    this.dedicationNote = 'For us, forever 🎶',
    this.yourHearts = 0,
    this.partnerHearts = 0,
  });

  PlayerState copyWith({
    bool? isPlaying,
    Duration? position,
    Song? currentSong,
    List<Song>? queue,
    String? lastActionSource,
    String? dedicationNote,
    int? yourHearts,
    int? partnerHearts,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      lastActionSource: lastActionSource ?? this.lastActionSource,
      dedicationNote: dedicationNote ?? this.dedicationNote,
      yourHearts: yourHearts ?? this.yourHearts,
      partnerHearts: partnerHearts ?? this.partnerHearts,
    );
  }
}

class PlayerController extends Notifier<PlayerState> {
  Timer? _ticker;

  @override
  PlayerState build() {
    final songs = [
      Song(
        title: 'Midnight City',
        artist: 'M83',
        coverUrl: 'https://placeholder.com/cover.jpg',
        duration: const Duration(minutes: 4, seconds: 3),
      ),
      Song(
        title: 'Sunset Lover',
        artist: 'Petit Biscuit',
        coverUrl: 'https://placeholder.com/cover2.jpg',
        duration: const Duration(minutes: 3, seconds: 58),
      ),
      Song(
        title: 'Electric Love',
        artist: 'BØRNS',
        coverUrl: 'https://placeholder.com/cover3.jpg',
        duration: const Duration(minutes: 3, seconds: 38),
      ),
    ];

    return PlayerState(
      currentSong: songs.first,
      queue: songs.skip(1).toList(),
    );
  }

  void play() {
    state = state.copyWith(isPlaying: true, lastActionSource: 'You');
    _startTicker();
  }

  void pause() {
    state = state.copyWith(isPlaying: false, lastActionSource: 'You');
    _stopTicker();
  }

  void seek(Duration position) {
    final duration = state.currentSong?.duration ?? Duration.zero;
    final clamped = position > duration ? duration : position;
    state = state.copyWith(position: clamped, lastActionSource: 'You');
  }

  void nextSong({String source = 'You'}) {
    if (state.queue.isEmpty) {
      state = state.copyWith(isPlaying: false, position: Duration.zero, lastActionSource: source);
      _stopTicker();
      return;
    }

    final next = state.queue.first;
    final updatedQueue = [...state.queue.skip(1), if (state.currentSong != null) state.currentSong!];
    state = state.copyWith(
      currentSong: next,
      queue: updatedQueue,
      position: Duration.zero,
      isPlaying: true,
      lastActionSource: source,
    );
    _startTicker();
  }

  void previousSong() {
    if (state.queue.isEmpty) return;
    final previous = state.queue.last;
    final updatedQueue = [if (state.currentSong != null) state.currentSong!, ...state.queue.take(state.queue.length - 1)];
    state = state.copyWith(
      currentSong: previous,
      queue: updatedQueue,
      position: Duration.zero,
      isPlaying: true,
      lastActionSource: 'You',
    );
    _startTicker();
  }

  void reactWithHeart({bool fromPartner = false}) {
    if (fromPartner) {
      state = state.copyWith(partnerHearts: state.partnerHearts + 1, lastActionSource: 'Partner');
      return;
    }
    state = state.copyWith(yourHearts: state.yourHearts + 1, lastActionSource: 'You');
  }

  void setDedicationNote(String note) {
    if (note.trim().isEmpty) return;
    state = state.copyWith(dedicationNote: note.trim(), lastActionSource: 'You');
  }

  void mockPartnerAction(String action) {
    if (action == 'pause') {
      state = state.copyWith(isPlaying: false, lastActionSource: 'Partner');
      _stopTicker();
    } else if (action == 'play') {
      state = state.copyWith(isPlaying: true, lastActionSource: 'Partner');
      _startTicker();
    } else if (action == 'seek') {
      state = state.copyWith(
        position: state.position + const Duration(seconds: 30),
        lastActionSource: 'Partner',
      );
    } else if (action == 'heart') {
      reactWithHeart(fromPartner: true);
    } else if (action == 'next') {
      nextSong(source: 'Partner');
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final newPos = state.position + const Duration(seconds: 1);
      if (state.currentSong != null && newPos >= state.currentSong!.duration) {
        nextSong();
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
