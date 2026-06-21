import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_app/services/api_service.dart';
import 'package:flutter_app/services/audio_cache_service.dart';

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
  Duration _lastPosition = Duration.zero;
  int _stallCount = 0;

  // Synchronization lock for queue/playlist operations
  Future<void> _playlistLock = Future.value();

  // Version counter to cancel stale updateQueueAndPlay requests
  int _playRequestVersion = 0;

  Future<T> _synchronized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _playlistLock = _playlistLock.then((_) async {
      try {
        final result = await action();
        completer.complete(result);
      } catch (e, stackTrace) {
        completer.completeError(e, stackTrace);
      }
    }).catchError((e) {
      debugPrint('🚨 Error in _playlistLock chain: $e');
    });
    return completer.future;
  }

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

      // Pipe player playback events to update the state
      _player.playbackEventStream.listen(
        (_) => _updatePlaybackState(),
        onError: (Object e, StackTrace st) {
          debugPrint('🚨 playbackEventStream error: $e');
        },
      );
      
      // Sync appMediaItem and System mediaItem with current player index
      _player.currentIndexStream.listen((index) {
        if (index != null && index < queue.value.length) {
          final item = queue.value[index];
          _currentAppMediaItem = item;
          _appMediaItemController.add(item);
          mediaItem.add(item);

          // Reset inactivity timer on song change
          AudioCacheService.instance.touch();

          // Precache the next song immediately when the current song starts playing
          _checkPreCache(index);
        }
      }, onError: (Object e, StackTrace st) {
        debugPrint('🚨 currentIndexStream error: $e');
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
      }, onError: (Object e, StackTrace st) {
        debugPrint('🚨 durationStream error: $e');
      });

      // Handle track completion
      _player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          skipToNext();
        }
      }, onError: (Object e, StackTrace st) {
        debugPrint('🚨 processingStateStream error: $e');
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
      AudioCacheService.instance.touch();
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
      AudioCacheService.instance.touch();
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
      await _player.stop();
      await super.stop();
    } catch (e) {
      debugPrint('🚨 Error in stop(): $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      AudioCacheService.instance.touch();
      await _player.seekToNext();
    } catch (e) {
      debugPrint('🚨 Error in skipToNext(): $e');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      AudioCacheService.instance.touch();
      await _player.seekToPrevious();
    } catch (e) {
      debugPrint('🚨 Error in skipToPrevious(): $e');
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    try {
      AudioCacheService.instance.touch();
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
  Future<void> addQueueItems(List<MediaItem> mediaItems) {
    return _synchronized(() async {
      try {
        final sources = await _buildSources(mediaItems);

        await _playlist.addAll(sources);
        final currentQueue = List<MediaItem>.from(queue.value);
        currentQueue.addAll(mediaItems);
        queue.add(currentQueue);

        if (_player.audioSource == null) {
          await _player.setAudioSource(_playlist);
        }
      } catch (e) {
        debugPrint('Error in addQueueItems(): $e');
      }
    });
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) {
    return _synchronized(() async {
      try {
        // Check if the queue is identical
        if (this.queue.value.length == queue.length) {
          bool identical = true;
          for (int i = 0; i < queue.length; i++) {
            if (this.queue.value[i].id != queue[i].id) {
              identical = false;
              break;
            }
          }
          if (identical) return;
        }

        this.queue.add(queue);

        final wasPlaying = _player.playing;
        if (wasPlaying) {
          await _player.pause();
        }

        await _playlist.clear();
        final sources = await _buildSources(queue);
        await _playlist.addAll(sources);

        // Ensure source is set and reset to initial position/index
        await _player.setAudioSource(_playlist, initialIndex: 0, initialPosition: Duration.zero);

        if (wasPlaying) {
          await _player.play();
        }
      } catch (e) {
        debugPrint('Error in updateQueue(): $e');
      }
    });
  }

  Future<void> updateQueueAndPlay(List<MediaItem> newQueue, int startIndex) async {
    final myVersion = ++_playRequestVersion;

    final sources = await _buildSources(newQueue);

    return _synchronized(() async {
      try {
        if (_playRequestVersion != myVersion) {
          debugPrint('Skipping stale updateQueueAndPlay (version $myVersion, current $_playRequestVersion)');
          return;
        }

        // Check if the queue is identical
        bool identical = queue.value.length == newQueue.length;
        if (identical) {
          for (int i = 0; i < newQueue.length; i++) {
            if (queue.value[i].id != newQueue[i].id) {
              identical = false;
              break;
            }
          }
        }

        if (identical && _player.currentIndex == startIndex) {
          if (!_player.playing) {
            await play();
          }
          return;
        }

        queue.add(newQueue);

        await _playlist.clear();
        await _playlist.addAll(sources);

        // Atomically load playlist starting at target song index
        await _player.setAudioSource(
          _playlist,
          initialIndex: startIndex,
          initialPosition: Duration.zero,
        );

        // Don't await play() - _player.play() returns a Future that completes
        // when playback STOPS, not when it starts. Awaiting it would hold the
        // _synchronized lock for the entire song duration, blocking all
        // subsequent song changes.
        play();
      } catch (e) {
        debugPrint('Error in updateQueueAndPlay(): $e');
      }
    });
  }

  Future<List<AudioSource>> _buildSources(List<MediaItem> items) async {
    final sources = <AudioSource>[];
    for (final item in items) {
      final cachedPath = await AudioCacheService.instance.getCachedPath(item.id);
      if (cachedPath != null) {
        sources.add(AudioSource.file(cachedPath, tag: item));
      } else {
        sources.add(AudioSource.uri(
          Uri.parse(ApiService.getStreamUrl(item.id)),
          tag: item,
        ));
      }
    }
    return sources;
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) {
    return _synchronized(() async {
      try {
        final index = queue.value.indexWhere((item) => item.id == mediaItem.id);
        if (index != -1) {
          await _removeQueueItemAt(index);
        }
      } catch (e) {
        debugPrint('Error in removeQueueItem(): $e');
      }
    });
  }

  @override
  Future<void> removeQueueItemAt(int index) {
    return _synchronized(() async {
      try {
        await _removeQueueItemAt(index);
      } catch (e) {
        debugPrint('Error in removeQueueItemAt(): $e');
      }
    });
  }

  Future<void> _removeQueueItemAt(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    
    final currentQueue = List<MediaItem>.from(queue.value);
    currentQueue.removeAt(index);
    queue.add(currentQueue);
    
    await _playlist.removeAt(index);
    _updatePlaybackState();
  }

  void _checkPreCache(int currentIndex) {
    try {
      if (currentIndex < queue.value.length - 1) {
        final nextItem = queue.value[currentIndex + 1];
        if (_preCachedId != nextItem.id) {
          _preCachedId = nextItem.id;
          debugPrint('Pre-downloading next track: ${nextItem.title}');
          _downloadNextSong(nextItem);
        }
      }
    } catch (e) {
      debugPrint('Error in _checkPreCache(): $e');
    }
  }

  Future<void> _downloadNextSong(MediaItem item) async {
    try {
      final localPath = await AudioCacheService.instance.downloadSong(item.id);
      if (localPath.isNotEmpty) {
        final replaced = await _synchronized(() async {
          final currentIndex = queue.value.indexWhere((qItem) => qItem.id == item.id);
          if (currentIndex != -1) {
            return await _replaceSource(currentIndex, item, localPath);
          }
          return false;
        });

        if (replaced) {
          debugPrint('Replaced source with local file for ${item.title}');
        } else {
          debugPrint('Did not replace source for ${item.title} (already replaced, no longer in queue, or player error)');
        }
      }
    } catch (e) {
      debugPrint('Failed to download next song ${item.title}: $e');
    }
  }

  Future<bool> _replaceSource(int index, MediaItem item, String localPath) async {
    try {
      if (index >= 0 && index < queue.value.length && index < _playlist.length) {
        if (queue.value[index].id == item.id) {
          final currentSource = _playlist.children[index];
          if (currentSource is UriAudioSource && currentSource.uri.isScheme('file')) {
            return false;
          }
          final newSource = AudioSource.file(localPath, tag: item);
          await _playlist.removeAt(index);
          await _playlist.insert(index, newSource);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error replacing source at $index: $e');
      return false;
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
