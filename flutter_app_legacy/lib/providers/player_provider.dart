import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:sonic_vault_flutter/audio_handler.dart';

import 'package:sonic_vault_flutter/services/storage_service.dart';

class PlayerProvider with ChangeNotifier {
  final MyAudioHandler _audioHandler;
  
  MediaItem? _currentSong;
  PlaybackState _playbackState = PlaybackState();
  Duration _position = Duration.zero;
  List<String> _likedSongIds = [];
  
  PlayerProvider(this._audioHandler) {
    _init();
    _loadFavorites();
  }

  MediaItem? get currentSong => _currentSong;
  PlaybackState get playbackState => _playbackState;
  bool get isPlaying => _playbackState.playing;
  Duration get position => _position;
  List<MediaItem> get queue => _audioHandler.queue.value;
  List<String> get likedSongIds => _likedSongIds;

  Stream<Duration> get positionStream => _audioHandler.appPositionStream;

  Future<void> _loadFavorites() async {
    _likedSongIds = await StorageService.getLikedSongs();
    notifyListeners();
  }

  bool isLiked(String id) => _likedSongIds.contains(id);

  Future<void> toggleLike(String id) async {
    await StorageService.toggleLiked(id);
    await _loadFavorites();
  }

  void _init() {
    _audioHandler.appMediaItemStream.listen((item) {
      // Only rebuild the UI tree when the song actually changes
      if (_currentSong?.id != item?.id) {
        _currentSong = item;
        notifyListeners();
      } else {
        _currentSong = item;
      }
    });

    _audioHandler.appPlaybackStateStream.listen((state) {
      // Only rebuild when play/pause state or processing state changes,
      // NOT on every position/buffer update which fires many times per second
      final oldPlaying = _playbackState.playing;
      final oldProcessing = _playbackState.processingState;
      final oldShuffle = _playbackState.shuffleMode;
      final oldRepeat = _playbackState.repeatMode;
      _playbackState = state;
      if (state.playing != oldPlaying ||
          state.processingState != oldProcessing ||
          state.shuffleMode != oldShuffle ||
          state.repeatMode != oldRepeat) {
        notifyListeners();
      }
    });

    // Update position periodically using the internal position stream
    _audioHandler.appPositionStream.listen((pos) {
      _position = pos;
    });
  }

  Future<void> playSong(Map<String, dynamic> song, List<dynamic> playlist) async {
    final systemItem = MediaItem(
      id: song['id'].toString(),
      album: 'MixTape',
      title: song['name'] ?? 'Unknown',
      artist: song['artist'] ?? 'Unknown',
      artUri: Uri.parse(song['image'] ?? 'https://via.placeholder.com/300'),
      duration: Duration(milliseconds: song['duration_ms'] ?? 0),
    );

    // Optimistically update system streams immediately inside the click handler to satisfy Android 12+ FGS launch window
    _audioHandler.mediaItem.add(systemItem);
    _audioHandler.playbackState.add(PlaybackState(
      playing: true,
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.buffering,
      updatePosition: Duration.zero,
    ));

    // Optimistically update UI state immediately
    _currentSong = systemItem;
    _playbackState = PlaybackState(
      playing: true,
      processingState: AudioProcessingState.buffering,
      updatePosition: Duration.zero,
    );
    notifyListeners();

    try {
      // Disable shuffle mode when playing a specific song from a list
      await _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);

      final mediaItems = playlist.map((s) => MediaItem(
        id: s['id'].toString(),
        album: 'MixTape',
        title: s['name'] ?? 'Unknown',
        artist: s['artist'] ?? 'Unknown',
        artUri: Uri.parse(s['image'] ?? 'https://via.placeholder.com/300'),
        duration: Duration(milliseconds: s['duration_ms'] ?? 0),
      )).toList();

      // Find index before updating queue to ensure we have the right context
      final index = playlist.indexWhere((s) => s['id'].toString() == song['id'].toString());
      
      if (index != -1) {
        await _audioHandler.updateQueueAndPlay(mediaItems, index);
      }
    } catch (e) {
      _playbackState = PlaybackState(
        playing: false,
        processingState: AudioProcessingState.error,
        updatePosition: Duration.zero,
      );
      notifyListeners();
    }
  }

  Future<void> addToQueue(Map<String, dynamic> song) async {
    try {
      final mediaItem = MediaItem(
        id: song['id'].toString(),
        album: 'MixTape',
        title: song['name'] ?? 'Unknown',
        artist: song['artist'] ?? 'Unknown',
        artUri: Uri.parse(song['image'] ?? 'https://via.placeholder.com/300'),
        duration: Duration(milliseconds: song['duration_ms'] ?? 0),
      );
      await _audioHandler.addQueueItems([mediaItem]);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Error in addToQueue(): $e');
    }
  }

  Future<void> shufflePlay(List<dynamic> playlist) async {
    if (playlist.isEmpty) return;

    final shuffledList = List.from(playlist)..shuffle();
    final firstSong = shuffledList.first;

    final systemItem = MediaItem(
      id: firstSong['id'].toString(),
      album: 'MixTape',
      title: firstSong['name'] ?? 'Unknown',
      artist: firstSong['artist'] ?? 'Unknown',
      artUri: Uri.parse(firstSong['image'] ?? 'https://via.placeholder.com/300'),
      duration: Duration(milliseconds: firstSong['duration_ms'] ?? 0),
    );

    // Optimistically update system streams immediately inside the click handler to satisfy Android 12+ FGS launch window
    _audioHandler.mediaItem.add(systemItem);
    _audioHandler.playbackState.add(PlaybackState(
      playing: true,
      controls: const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: AudioProcessingState.buffering,
      updatePosition: Duration.zero,
    ));

    // Optimistically update UI state immediately
    _currentSong = systemItem;
    _playbackState = PlaybackState(
      playing: true,
      processingState: AudioProcessingState.buffering,
      updatePosition: Duration.zero,
    );
    notifyListeners();

    try {
      final mediaItems = shuffledList.map((s) => MediaItem(
        id: s['id'].toString(),
        album: 'MixTape',
        title: s['name'] ?? 'Unknown',
        artist: s['artist'] ?? 'Unknown',
        artUri: Uri.parse(s['image'] ?? 'https://via.placeholder.com/300'),
        duration: Duration(milliseconds: s['duration_ms'] ?? 0),
      )).toList();

      // Keep shuffle mode OFF because we already manually shuffled the list.
      // Enabling just_audio's shuffle on top would cause a double-shuffle mismatch.
      await _audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
      
      // Update queue with shuffled items and start playing the first song atomically
      await _audioHandler.updateQueueAndPlay(mediaItems, 0);
    } catch (e) {
      _playbackState = PlaybackState(
        playing: false,
        processingState: AudioProcessingState.error,
        updatePosition: Duration.zero,
      );
      notifyListeners();
    }
  }

  Future<void> toggleShuffle() async {
    final isShuffle = _playbackState.shuffleMode == AudioServiceShuffleMode.all;
    await _audioHandler.setShuffleMode(isShuffle ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all);
  }

  Future<void> toggleRepeat() async {
    final repeatMode = _playbackState.repeatMode;
    if (repeatMode == AudioServiceRepeatMode.none) {
      await _audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
    } else if (repeatMode == AudioServiceRepeatMode.all) {
      await _audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
    } else {
      await _audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
    }
  }

  Future<void> togglePlay() async {
    if (isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> skipToNext() => _audioHandler.skipToNext();
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;
  int get sleepTimerMinutes => _sleepTimerMinutes;

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        _audioHandler.pause();
        _sleepTimerMinutes = 0;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> removeFromQueueAt(int index) async {
    try {
      if (index < 0 || index >= queue.length) return;
      await _audioHandler.removeQueueItemAt(index);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Error in removeFromQueueAt(): $e');
    }
  }
}
