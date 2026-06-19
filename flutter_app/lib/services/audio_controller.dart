import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'sync_client.dart';
import 'api_service.dart';

class AudioController {
  static final AudioController instance = AudioController._internal();
  final AudioPlayer _player = AudioPlayer();
  
  StreamSubscription? _syncSubscription;
  Timer? _driftTimer;

  AudioController._internal() {
    _syncSubscription = SyncClient.instance.executeStream.listen(_handleSyncExecute);
  }

  AudioPlayer get player => _player;

  void dispose() {
    _syncSubscription?.cancel();
    _driftTimer?.cancel();
    _player.dispose();
  }

  Future<void> _handleSyncExecute(Map<String, dynamic> event) async {
    final type = event['type'] as String;
    
    if (type == 'TRACK_CHANGE_EXECUTE') {
      final trackUrl = event['trackUrl'] as String?;
      final targetTimestamp = event['targetTimestamp'] as int?;
      
      if (trackUrl != null) {
        // Prepare the audio buffer
        try {
          final headers = await ApiService.getHeaders();
          await _player.setAudioSource(
            AudioSource.uri(Uri.parse(trackUrl), headers: headers),
            preload: true
          );
          
          if (targetTimestamp != null) {
            _schedulePlayback(targetTimestamp, 0);
          }
        } catch (e) {
          debugPrint('AudioController: Failed to load track - $e');
        }
      }
    } else if (type == 'PLAY_EXECUTE') {
      final targetTimestamp = event['targetTimestamp'] as int?;
      final position = event['position'] as int?;
      
      if (targetTimestamp != null && position != null) {
        _schedulePlayback(targetTimestamp, position);
      }
    } else if (type == 'PAUSE_EXECUTE') {
      await _player.pause();
      final position = event['position'] as int?;
      if (position != null) {
        await _player.seek(Duration(milliseconds: position));
      }
    } else if (type == 'SEEK_EXECUTE') {
      final position = event['position'] as int?;
      if (position != null) {
        await _player.seek(Duration(milliseconds: position));
      }
    }
  }

  void _schedulePlayback(int targetServerTime, int positionMs) {
    _driftTimer?.cancel(); // Stop active drift correction while scheduling
    
    // Seek to the exact position first
    _player.seek(Duration(milliseconds: positionMs)).then((_) {
      final currentServerTime = SyncClient.instance.getServerTime();
      final delayMs = targetServerTime - currentServerTime;

      if (delayMs > 0) {
        debugPrint('AudioController: Scheduling play in $delayMs ms');
        Timer(Duration(milliseconds: delayMs), () {
          _player.play();
          _startDriftCorrection(targetServerTime, positionMs);
        });
      } else {
        // We missed the target timestamp, we need to skip ahead
        debugPrint('AudioController: Missed schedule by ${-delayMs} ms. Catching up.');
        final adjustedPositionMs = positionMs + (-delayMs);
        _player.seek(Duration(milliseconds: adjustedPositionMs)).then((_) {
          _player.play();
          _startDriftCorrection(targetServerTime, positionMs);
        });
      }
    });
  }

  void _startDriftCorrection(int startServerTime, int startPositionMs) {
    _driftTimer?.cancel();
    _driftTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!_player.playing) return;

      final currentServerTime = SyncClient.instance.getServerTime();
      final expectedPositionMs = startPositionMs + (currentServerTime - startServerTime);
      final actualPositionMs = _player.position.inMilliseconds;
      
      final driftMs = expectedPositionMs - actualPositionMs;
      
      if (driftMs.abs() > 50) {
        debugPrint('AudioController: Drift detected: $driftMs ms');
        if (driftMs > 0) {
          // Lagging behind
          if (driftMs > 500) {
            // Huge lag, hard seek
            _player.seek(Duration(milliseconds: expectedPositionMs));
          } else {
            // Minor lag, speed up temporarily
            _player.setSpeed(1.05);
            Future.delayed(const Duration(seconds: 2), () {
              if (_player.playing) _player.setSpeed(1.0);
            });
          }
        } else {
          // Too fast
          if (driftMs < -500) {
            _player.seek(Duration(milliseconds: expectedPositionMs));
          } else {
            // Minor lead, slow down temporarily
            _player.setSpeed(0.95);
            Future.delayed(const Duration(seconds: 2), () {
              if (_player.playing) _player.setSpeed(1.0);
            });
          }
        }
      }
    });
  }

  // --- Methods for the UI to trigger actions ---

  void togglePlayPause() {
    if (_player.playing) {
      SyncClient.instance.sendIntent('PAUSE_INTENT', {
        'position': _player.position.inMilliseconds
      });
    } else {
      SyncClient.instance.sendIntent('PLAY_INTENT', {
        'position': _player.position.inMilliseconds
      });
    }
  }

  void seek(Duration position) {
    SyncClient.instance.sendIntent('SEEK_INTENT', {
      'position': position.inMilliseconds
    });
  }

  void changeTrack(String songId, String trackUrl) {
    SyncClient.instance.sendIntent('CHANGE_TRACK_INTENT', {
      'songId': songId,
      'trackUrl': trackUrl,
    });
  }
}
