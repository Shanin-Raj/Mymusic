import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sync_client.dart';
import 'api_service.dart';
import '../providers/audio_provider.dart';

/// AudioController bridges room sync events into the main AudioProvider,
/// ensuring room playback shows in mini-player, notifications, and lock screen.
class AudioController {
  static final AudioController instance = AudioController._internal();
  
  StreamSubscription? _syncSubscription;
  Timer? _driftTimer;
  AudioProvider? _audioProvider;

  // Track the room playback state for drift correction (currently unused)
  // int? _playStartServerTime;
  // int? _playStartPositionMs;

  AudioController._internal() {
    _syncSubscription = SyncClient.instance.executeStream.listen(_handleSyncExecute);
    SyncClient.instance.roomStateStream.listen((roomState) {
      if (roomState != null && _audioProvider != null) {
        _startDriftCorrection(_audioProvider!);
      } else if (roomState == null) {
        _driftTimer?.cancel();
      }
    });
  }

  /// Must be called after AudioProvider is initialized (e.g., in main.dart)
  void setAudioProvider(AudioProvider provider) {
    _audioProvider = provider;
    if (SyncClient.instance.roomState != null) {
      _startDriftCorrection(provider);
    }
  }

  void dispose() {
    _syncSubscription?.cancel();
    _driftTimer?.cancel();
  }

  Future<void> _handleSyncExecute(Map<String, dynamic> event) async {
    final type = event['type'] as String;
    final provider = _audioProvider;
    if (provider == null) {
      debugPrint('AudioController: No AudioProvider set, ignoring sync event');
      return;
    }
    
    if (type == 'TRACK_CHANGE_EXECUTE') {
      final songId = event['songId'] as String?;
      final targetTimestamp = event['targetTimestamp'] as int?;
      final position = event['position'] as int? ?? 0;
      
      if (songId != null) {
        try {
          // Fetch the song details from the API to build a proper MediaItem
          final songData = await ApiService.fetchSongDetail(songId);
          // Play the song through AudioProvider so it shows in mini-player etc
          provider.isSyncing = true;
          await provider.playSong(songData, [songData]);
          provider.isSyncing = false;
          
          // Schedule playback to sync with other devices
          if (targetTimestamp != null) {
            _schedulePlayback(provider, targetTimestamp, position);
          }
        } catch (e) {
          debugPrint('AudioController: Failed to load track - $e');
        }
      }
    } else if (type == 'PLAY_EXECUTE') {
      final targetTimestamp = event['targetTimestamp'] as int?;
      final position = event['position'] as int? ?? 0;
      final songId = event['songId'] as String? ?? SyncClient.instance.roomState?['currentSongId'] as String?;

      if (songId != null && provider.currentSong?.id != songId) {
        try {
          final songData = await ApiService.fetchSongDetail(songId);
          provider.isSyncing = true;
          await provider.playSong(songData, [songData]);
          provider.isSyncing = false;
        } catch (e) {
          debugPrint('AudioController: Failed to load track for play - $e');
        }
      }

      if (targetTimestamp != null) {
        _schedulePlayback(provider, targetTimestamp, position);
      }
    } else if (type == 'PAUSE_EXECUTE') {
      _driftTimer?.cancel();
      provider.isSyncing = true;
      await provider.pause();
      final position = event['position'] as int?;
      if (position != null) {
        await provider.seek(Duration(milliseconds: position));
      }
      provider.isSyncing = false;
    } else if (type == 'SEEK_EXECUTE') {
      final position = event['position'] as int?;
      if (position != null) {
        provider.isSyncing = true;
        await provider.seek(Duration(milliseconds: position));
        provider.isSyncing = false;
      }
    }
  }

  void _schedulePlayback(AudioProvider provider, int targetServerTime, int positionMs) {
    _driftTimer?.cancel();
    
    provider.isSyncing = true;
    provider.seek(Duration(milliseconds: positionMs)).then((_) {
      provider.isSyncing = false;
      final currentServerTime = SyncClient.instance.getServerTime();
      final delayMs = targetServerTime - currentServerTime;

      if (delayMs > 0) {
        debugPrint('AudioController: Scheduling play in $delayMs ms');
        Timer(Duration(milliseconds: delayMs), () {
          provider.isSyncing = true;
          provider.play();
          provider.isSyncing = false;
          // _playStartServerTime = targetServerTime;
          // _playStartPositionMs = positionMs;
          _startDriftCorrection(provider);
        });
      } else {
        // We missed the target timestamp, skip ahead
        debugPrint('AudioController: Missed schedule by ${-delayMs} ms. Catching up.');
        final adjustedPositionMs = positionMs + (-delayMs);
        provider.isSyncing = true;
        provider.seek(Duration(milliseconds: adjustedPositionMs)).then((_) {
          provider.play();
          provider.isSyncing = false;
          // _playStartServerTime = targetServerTime;
          // _playStartPositionMs = positionMs;
          _startDriftCorrection(provider);
        });
      }
    });
  }

  void _startDriftCorrection(AudioProvider provider) {
    _driftTimer?.cancel();
    _driftTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      final roomState = SyncClient.instance.roomState;
      if (roomState == null || !SyncClient.instance.isConnected) {
        timer.cancel();
        return;
      }

      final playbackState = roomState['playbackState'] as String?;
      final targetTimestamp = roomState['targetTimestamp'] as int?;
      final startPosition = roomState['position'] as int? ?? 0;
      final currentSongId = roomState['currentSongId'] as String?;

      if (playbackState == 'PLAYING' && targetTimestamp != null) {
        final currentServerTime = SyncClient.instance.getServerTime();
        final expectedPosMs = startPosition + (currentServerTime - targetTimestamp);

        // 1. Ensure current track is loaded into provider
        if (currentSongId != null && provider.currentSong?.id != currentSongId && !provider.isSyncing) {
          debugPrint('🔄 Room Sync Watchdog: Loading missing track $currentSongId');
          try {
            final songData = await ApiService.fetchSongDetail(currentSongId);
            provider.isSyncing = true;
            await provider.playSong(songData, [songData]);
            provider.isSyncing = false;
          } catch (e) {
            debugPrint('Error loading track in watchdog: $e');
            return;
          }
        }

        final localPosMs = provider.playbackState?.position.inMilliseconds ?? 0;
        final isPlayingLocal = provider.isPlaying;
        final diff = (localPosMs - expectedPosMs).abs();

        // 2. Re-sync if local player was interrupted (e.g. WhatsApp voice note) or desynced > 2000ms
        if ((!isPlayingLocal || diff > 2000) && !provider.isSyncing) {
          debugPrint('🔄 Room Sync Watchdog: Re-syncing local player to expected position: ${expectedPosMs}ms');
          provider.isSyncing = true;
          await provider.seek(Duration(milliseconds: expectedPosMs > 0 ? expectedPosMs : 0));
          await provider.play();
          provider.isSyncing = false;
        }
      } else if (playbackState == 'PAUSED') {
        if (provider.isPlaying && !provider.isSyncing) {
          debugPrint('🔄 Room Sync Watchdog: Server is PAUSED, pausing local player.');
          provider.isSyncing = true;
          await provider.pause();
          final pos = roomState['position'] as int? ?? 0;
          await provider.seek(Duration(milliseconds: pos));
          provider.isSyncing = false;
        }
      }
    });
  }

  // --- Methods for the UI to trigger actions ---

  void togglePlayPause(AudioProvider provider) {
    final roomState = SyncClient.instance.roomState;
    final currentSongId = roomState?['currentSongId'] as String?;
    final queue = roomState?['queue'] as List?;
    final currentIndex = roomState?['currentIndex'] as int? ?? 0;

    // If no song is loaded in provider but room has a currentSongId
    if (!provider.isPlaying && currentSongId != null && provider.currentSong?.id != currentSongId) {
      final trackUrl = (queue != null && currentIndex < queue.length)
          ? (queue[currentIndex]['trackUrl'] ?? ApiService.getStreamUrl(currentSongId))
          : ApiService.getStreamUrl(currentSongId);
      
      changeTrack(currentSongId, trackUrl, currentIndex: currentIndex);
      return;
    }

    final currentPositionMs = provider.playbackState?.position.inMilliseconds ?? 0;
    if (provider.isPlaying) {
      SyncClient.instance.sendIntent('PAUSE_INTENT', {
        'position': currentPositionMs
      });
    } else {
      SyncClient.instance.sendIntent('PLAY_INTENT', {
        'position': currentPositionMs
      });
    }
  }

  void seekInRoom(Duration position) {
    SyncClient.instance.sendIntent('SEEK_INTENT', {
      'position': position.inMilliseconds
    });
  }

  void changeTrack(String songId, String trackUrl, {int? currentIndex}) {
    SyncClient.instance.sendIntent('CHANGE_TRACK_INTENT', {
      'songId': songId,
      'trackUrl': trackUrl,
      if (currentIndex case final index?) 'currentIndex': index,
    });
  }

  void nextTrack() {
    SyncClient.instance.nextTrack();
  }

  void prevTrack() {
    SyncClient.instance.prevTrack();
  }

  void addToQueue(Map<String, dynamic> song) {
    SyncClient.instance.addToQueue(song);
  }

  void removeFromQueue(int index) {
    SyncClient.instance.removeFromQueue(index);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    SyncClient.instance.reorderQueue(oldIndex, newIndex);
  }
}
