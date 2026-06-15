import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:sonic_vault_flutter/services/api_service.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  
  // App-level state streams (to bypass system notification)
  final _appMediaItemController = StreamController<MediaItem?>.broadcast();
  final _appPlaybackStateController = StreamController<PlaybackState>.broadcast();
  
  MediaItem? _currentAppMediaItem;
  PlaybackState _currentAppPlaybackState = PlaybackState();

  Stream<MediaItem?> get appMediaItemStream => _appMediaItemController.stream;
  Stream<PlaybackState> get appPlaybackStateStream => _appPlaybackStateController.stream;
  Stream<Duration> get appPositionStream => _player.positionStream;
  
  MediaItem? get currentAppMediaItem => _currentAppMediaItem;
  PlaybackState get currentAppPlaybackState => _currentAppPlaybackState;

  // Track pre-cached status
  String? _preCachedId;

  // Watchdog state
  Timer? _watchdogTimer;
  Timer? _preCacheTimer;
  Duration _lastPosition = Duration.zero;
  int _stallCount = 0;

  MyAudioHandler() {
    _init();
    _startWatchdog();
  }

  void _init() {
    try {
      // Emit initial idle playback state to system stream
      playbackState.add(PlaybackState(
        controls: const [],
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.playPause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.seek,
          MediaAction.stop,
        },
        processingState: AudioProcessingState.idle,
        playing: false,
      ));

      // Configure and activate the audio session for music playback.
      // This tells the OS to grant audio focus and keep the app alive in background.
      _activateAudioSession();

      // Pipe player state and event streams to unified state updates
      _player.playbackEventStream.listen((_) => _updatePlaybackState());
      _player.playerStateStream.listen((_) => _updatePlaybackState());
      
      // Sync appMediaItem and System mediaItem with current player index
      _player.currentIndexStream.listen((index) {
        if (index != null && index < queue.value.length) {
          final item = queue.value[index];
          _currentAppMediaItem = item;
          _appMediaItemController.add(item);
          mediaItem.add(item);
          
          // Precache the next song immediately when the current song starts playing
          _checkPreCache(index);
        }
      });

      // Update MediaItem duration when player discovers actual duration
      _player.durationStream.listen((duration) {
        if (duration != null && duration.inMilliseconds > 0) {
          final currentItem = _currentAppMediaItem;
          if (currentItem != null && (currentItem.duration == null || currentItem.duration!.inMilliseconds == 0)) {
            final updatedItem = currentItem.copyWith(duration: duration);
            _currentAppMediaItem = updatedItem;
            _appMediaItemController.add(updatedItem);
            mediaItem.add(updatedItem);
          }
        }
      });

      // Handle track completion
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          skipToNext();
        }
      });
    } catch (e) {
      debugPrint('🚨 Error in MyAudioHandler init: $e');
    }
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_player.playing && _player.processingState == ProcessingState.ready) {
        if (_player.position == _lastPosition && _player.position != Duration.zero) {
          _stallCount++;
          debugPrint('⚠️ Playback stall detected ($_stallCount/2). Position: ${_player.position}');
          if (_stallCount >= 2) {
            debugPrint('🚨 Watchdog: Triggering recovery seek...');
            _recoverPlayback();
            _stallCount = 0;
          }
        } else {
          _stallCount = 0;
        }
        _lastPosition = _player.position;
      } else {
        _stallCount = 0;
      }
    });
  }

  Future<void> _activateAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
      await session.setActive(true);
      debugPrint('🎵 AudioSession activated for music playback');
    } catch (e) {
      debugPrint('🚨 Error activating AudioSession: $e');
    }
  }

  Future<void> _recoverPlayback() async {
    try {
      final currentPos = _player.position;
      await _player.pause();
      await _player.seek(currentPos);
      await _player.play();
    } catch (e) {
      debugPrint('🚨 Playback recovery failed: $e');
    }
  }

  @override
  Future<void> play() async {
    try {
      // Synchronously emit playing state to guarantee immediate foreground service promotion inside the user click window
      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(
        playing: true,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
      ));
      await _player.play();
    } catch (e) {
      debugPrint('🚨 Error in play(): $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      // Synchronously emit paused state immediately
      final currentState = playbackState.value;
      playbackState.add(currentState.copyWith(
        playing: false,
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
      ));
      await _player.pause();
    } catch (e) {
      debugPrint('🚨 Error in pause(): $e');
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('🚨 Error in seek(): $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      _watchdogTimer?.cancel();
      _preCacheTimer?.cancel();
      await _player.stop();
      await super.stop();
    } catch (e) {
      debugPrint('🚨 Error in stop(): $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      await _player.seekToNext();
    } catch (e) {
      debugPrint('🚨 Error in skipToNext(): $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      await _player.seekToPrevious();
    } catch (e) {
      debugPrint('🚨 Error in skipToPrevious(): $e');
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      if (index < 0 || index >= queue.value.length) return;
      
      await _player.seek(Duration.zero, index: index);
      _updatePlaybackState();
    } catch (e) {
      debugPrint('🚨 Error in skipToQueueItem(): $e');
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      final enabled = shuffleMode == AudioServiceShuffleMode.all;
      await _player.setShuffleModeEnabled(enabled);
      if (enabled) {
        await _player.shuffle();
      }
      // Update app state
      final newState = _currentAppPlaybackState.copyWith(shuffleMode: shuffleMode);
      _currentAppPlaybackState = newState;
      _appPlaybackStateController.add(newState);
    } catch (e) {
      debugPrint('🚨 Error in setShuffleMode(): $e');
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          await _player.setLoopMode(LoopMode.off);
          break;
        case AudioServiceRepeatMode.one:
          await _player.setLoopMode(LoopMode.one);
          break;
        case AudioServiceRepeatMode.all:
        case AudioServiceRepeatMode.group:
          await _player.setLoopMode(LoopMode.all);
          break;
      }
      // Update app state
      final newState = _currentAppPlaybackState.copyWith(repeatMode: repeatMode);
      _currentAppPlaybackState = newState;
      _appPlaybackStateController.add(newState);
    } catch (e) {
      debugPrint('🚨 Error in setRepeatMode(): $e');
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> items) async {
    try {
      final sources = items.map((item) => AudioSource.uri(
        Uri.parse(ApiService.getStreamUrl(item.id)),
        tag: item,
      )).toList();
      
      await _playlist.addAll(sources);
      queue.add(queue.value..addAll(items));
      
      if (_player.audioSource == null) {
        await _player.setAudioSource(_playlist);
      }
    } catch (e) {
      debugPrint('🚨 Error in addQueueItems(): $e');
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> newQueue) async {
    try {
      // Check if the queue is identical
      if (queue.value.length == newQueue.length) {
        bool identical = true;
        for (int i = 0; i < newQueue.length; i++) {
          if (queue.value[i].id != newQueue[i].id) {
            identical = false;
            break;
          }
        }
        if (identical) return;
      }

      queue.add(newQueue);
      
      final wasPlaying = _player.playing;
      if (wasPlaying) {
        await _player.pause();
      }

      await _playlist.clear();
      final sources = newQueue.map((item) => AudioSource.uri(
        Uri.parse(ApiService.getStreamUrl(item.id)),
        tag: item,
      )).toList();
      await _playlist.addAll(sources);
      
      // Ensure source is set
      if (_player.audioSource != _playlist) {
        await _player.setAudioSource(_playlist);
      }
    } catch (e) {
      debugPrint('🚨 Error in updateQueue(): $e');
    }
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    try {
      final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
      if (index != -1) {
        await removeQueueItemAt(index);
      }
    } catch (e) {
      debugPrint('🚨 Error in removeQueueItem(): $e');
    }
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    try {
      if (index < 0 || index >= queue.value.length) return;
      await _playlist.removeAt(index);
      final currentQueue = List<MediaItem>.from(queue.value);
      currentQueue.removeAt(index);
      queue.add(currentQueue);
      _updatePlaybackState();
    } catch (e) {
      debugPrint('🚨 Error in removeQueueItemAt(): $e');
    }
  }

  void _checkPreCache(int currentIndex) {
    try {
      if (currentIndex < queue.value.length - 1) {
        final nextItem = queue.value[currentIndex + 1];
        if (_preCachedId != nextItem.id) {
          _preCachedId = nextItem.id;
          _preCacheTimer?.cancel();
          _preCacheTimer = Timer(const Duration(seconds: 4), () {
            print('📡 Pre-caching next native track: ${nextItem.title}');
            ApiService.preCache(nextItem.id);
          });
        }
      }
    } catch (e) {
      debugPrint('🚨 Error in _checkPreCache(): $e');
    }
  }

  PlaybackState _transformState() {
    final playing = _player.playing;
    final controls = [
      MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
    ];

    final rawState = _player.processingState;
    final mappedProcessingState = const {
      ProcessingState.idle: AudioProcessingState.idle,
      ProcessingState.loading: AudioProcessingState.loading,
      ProcessingState.buffering: AudioProcessingState.buffering,
      ProcessingState.ready: AudioProcessingState.ready,
      ProcessingState.completed: AudioProcessingState.completed,
    }[rawState] ?? AudioProcessingState.idle;

    return PlaybackState(
      controls: controls,
      systemActions: const {
        MediaAction.seek,
        MediaAction.playPause,
        MediaAction.play,
        MediaAction.pause,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: mappedProcessingState,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: _player.currentIndex,
      shuffleMode: _player.shuffleModeEnabled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode]!,
    );
  }

  void _updatePlaybackState() {
    try {
      final state = _transformState();
      _currentAppPlaybackState = state;
      _appPlaybackStateController.add(state);
      playbackState.add(state);
    } catch (e) {
      debugPrint('🚨 Error updating playback state: $e');
    }
  }
}
