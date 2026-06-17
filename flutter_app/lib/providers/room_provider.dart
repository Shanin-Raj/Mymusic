import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sonic_vault_flutter/audio_handler.dart';
import 'package:sonic_vault_flutter/services/api_service.dart';

class RoomProvider with ChangeNotifier {
  final MyAudioHandler _audioHandler;
  
  String? _roomId;
  bool _isJoined = false;
  Map<String, dynamic>? _roomState;
  
  bool _isSyncing = false;
  int _clockOffset = 0; // ServerTime - ClientTime
  
  HttpClient? _httpClient;
  HttpClientRequest? _sseRequest;
  StreamSubscription? _sseSubscription;
  
  StreamSubscription? _playbackStateSubscription;
  StreamSubscription? _mediaItemSubscription;
  
  // Track previous local states to detect actual changes
  bool? _prevPlaying;
  String? _prevSongId;
  Duration? _prevPosition;
  
  RoomProvider(this._audioHandler) {
    _loadSavedRoom();
    _setupAudioHandlerListeners();
  }

  String? get roomId => _roomId;
  bool get isJoined => _isJoined;
  Map<String, dynamic>? get roomState => _roomState;

  Future<void> _loadSavedRoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoomId = prefs.getString('sv_room_id');
      if (savedRoomId != null && savedRoomId.isNotEmpty) {
        debugPrint('📡 Auto-connecting to saved Room: $savedRoomId');
        await joinRoom(savedRoomId);
      }
    } catch (e) {
      debugPrint('🚨 Error loading saved room: $e');
    }
  }

  void _setupAudioHandlerListeners() {
    // Listen to media item (song) changes
    _mediaItemSubscription = _audioHandler.appMediaItemStream.listen((item) {
      if (item == null || _roomId == null || _isSyncing) return;
      
      if (_prevSongId != item.id) {
        _prevSongId = item.id;
        debugPrint('📡 Song changed locally to: ${item.id}. Syncing...');
        _sendRoomStateUpdate();
      }
    });

    // Listen to playback state (play/pause/seek) changes
    _playbackStateSubscription = _audioHandler.appPlaybackStateStream.listen((state) {
      if (_roomId == null || _isSyncing) return;
      
      bool playingChanged = _prevPlaying != state.playing;
      
      // Detect seek: if the position changed significantly without a song change
      bool seekDetected = false;
      if (_prevPosition != null) {
        final diff = (state.position - _prevPosition!).inMilliseconds.abs();
        // If it jumped by more than 1.5 seconds in a single state update, it's likely a seek
        if (diff > 1500) {
          seekDetected = true;
        }
      }
      
      _prevPlaying = state.playing;
      _prevPosition = state.position;
      
      if (playingChanged || seekDetected) {
        debugPrint('📡 Playback state changed (playingChanged=$playingChanged, seekDetected=$seekDetected). Syncing...');
        _sendRoomStateUpdate();
      }
    });
  }

  Future<void> _sendRoomStateUpdate() async {
    if (_roomId == null || _isSyncing) return;
    
    final currentItem = _audioHandler.currentAppMediaItem;
    final state = _audioHandler.currentAppPlaybackState;
    
    final songId = currentItem?.id ?? '';
    final isPlaying = state.playing;
    final position = state.position.inMilliseconds;
    
    try {
      await ApiService.updateRoomState(
        roomId: _roomId!,
        songId: songId,
        isPlaying: isPlaying,
        position: position,
      );
    } catch (e) {
      debugPrint('🚨 Failed to send room update: $e');
    }
  }

  Future<void> createRoom() async {
    try {
      final data = await ApiService.createRoom();
      _roomId = data['roomId'];
      _isJoined = true;
      _roomState = data;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sv_room_id', _roomId!);
      
      notifyListeners();
      _connectSse();
      _sendRoomStateUpdate();
    } catch (e) {
      debugPrint('🚨 Create room failed: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String code) async {
    final cleanCode = code.trim().toUpperCase();
    try {
      final data = await ApiService.getRoomState(cleanCode);
      _roomId = data['roomId'];
      _isJoined = true;
      _roomState = data;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sv_room_id', _roomId!);
      
      notifyListeners();
      _connectSse();
    } catch (e) {
      debugPrint('🚨 Join room failed: $e');
      rethrow;
    }
  }

  Future<void> leaveRoom() async {
    _disconnectSse();
    _roomId = null;
    _isJoined = false;
    _roomState = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sv_room_id');
    
    notifyListeners();
  }

  Future<void> _connectSse() async {
    _disconnectSse();
    if (_roomId == null) return;
    
    debugPrint('📡 Syncing clock and connecting SSE...');
    
    try {
      final start = DateTime.now().millisecondsSinceEpoch;
      final serverTime = await ApiService.fetchServerTime();
      final end = DateTime.now().millisecondsSinceEpoch;
      final rtt = end - start;
      final estimatedServerTime = serverTime + (rtt ~/ 2);
      _clockOffset = estimatedServerTime - end;
      debugPrint('⏰ Clock synced. Offset: $_clockOffset ms');
    } catch (e) {
      debugPrint('⚠️ Clock sync failed: $e');
    }

    try {
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
        
      final url = '${ApiService.baseUrl}/api/rooms/$_roomId/stream';
      _sseRequest = await _httpClient!.getUrl(Uri.parse(url));
      _sseRequest!.headers.set('Accept', 'text/event-stream');
      _sseRequest!.headers.set('Cache-Control', 'no-cache');
      
      final response = await _sseRequest!.close();
      if (response.statusCode == 200) {
        debugPrint('📡 SSE stream connected for room: $_roomId');
        _sseSubscription = response
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              if (line.startsWith('data: ')) {
                final dataStr = line.substring(6).trim();
                try {
                  final data = json.decode(dataStr) as Map<String, dynamic>;
                  _handleRoomStateUpdate(data);
                } catch (e) {
                  debugPrint('🚨 Error decoding SSE line: $e');
                }
              }
            }, onError: (err) {
              debugPrint('🚨 SSE stream error: $err');
              _reconnectDelayed();
            }, onDone: () {
              debugPrint('📡 SSE stream closed by server');
              _reconnectDelayed();
            });
      } else {
        debugPrint('🚨 SSE failed with status code: ${response.statusCode}');
        _reconnectDelayed();
      }
    } catch (e) {
      debugPrint('🚨 Failed to initiate SSE: $e');
      _reconnectDelayed();
    }
  }

  void _reconnectDelayed() {
    if (_roomId == null) return;
    
    Future.delayed(const Duration(seconds: 3), () {
      if (_roomId != null) {
        debugPrint('📡 Reconnecting SSE stream...');
        _connectSse();
      }
    });
  }

  void _disconnectSse() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseRequest?.abort();
    _sseRequest = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    debugPrint('📡 SSE stream disconnected');
  }

  Future<void> _handleRoomStateUpdate(Map<String, dynamic> data) async {
    if (data.containsKey('error')) {
      debugPrint('⚠️ Room State Update Error: ${data['error']}');
      return;
    }
    
    final String? updateRoomId = data['roomId'];
    final String? currentSongId = data['currentSongId'];
    final bool targetPlaying = data['isPlaying'] ?? false;
    final int targetPos = data['position'] ?? 0;
    final int updatedAt = data['updatedAt'] ?? 0;
    
    if (updateRoomId != _roomId) return;
    
    _roomState = data;
    notifyListeners();
    
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final currentLocalSongId = _audioHandler.currentAppMediaItem?.id;
      
      // 1. Sync song ID
      if (currentSongId != null && currentSongId.isNotEmpty && currentSongId != currentLocalSongId) {
        debugPrint('📡 SSE: Loading song: $currentSongId');
        final songDetails = await ApiService.fetchSongDetail(currentSongId);
        
        final mediaItem = MediaItem(
          id: songDetails['id'].toString(),
          album: 'MixTape',
          title: songDetails['name'] ?? 'Unknown',
          artist: songDetails['artist'] ?? 'Unknown',
          artUri: Uri.parse(songDetails['image'] ?? 'https://via.placeholder.com/300'),
          duration: Duration(milliseconds: songDetails['duration_ms'] ?? 0),
        );
        
        await _audioHandler.updateQueue([mediaItem]);
        await _audioHandler.skipToQueueItem(0);
      }
      
      // 2. Calculate latency compensated position
      final localNow = DateTime.now().millisecondsSinceEpoch;
      final serverNow = localNow + _clockOffset;
      final elapsed = targetPlaying ? (serverNow - updatedAt) : 0;
      final targetPosMs = targetPos + elapsed;
      final targetDuration = Duration(milliseconds: targetPosMs);
      
      final currentLocalPlaying = _audioHandler.currentAppPlaybackState.playing;
      final currentLocalPos = _audioHandler.currentAppPlaybackState.position;
      
      // 3. Sync play/pause & seek
      if (targetPlaying) {
        if (!currentLocalPlaying) {
          debugPrint('📡 SSE: Playing');
          await _audioHandler.play();
        }
        
        final diff = (currentLocalPos.inMilliseconds - targetPosMs).abs();
        if (diff > 1500) {
          debugPrint('📡 SSE: Seeking to $targetDuration (diff: $diff ms)');
          await _audioHandler.seek(targetDuration);
        }
      } else {
        if (currentLocalPlaying) {
          debugPrint('📡 SSE: Pausing');
          await _audioHandler.pause();
        }
        
        final diff = (currentLocalPos.inMilliseconds - targetPosMs).abs();
        if (diff > 500) {
          debugPrint('📡 SSE: Seeking while paused to $targetDuration (diff: $diff ms)');
          await _audioHandler.seek(targetDuration);
        }
      }
      
      // Update local baseline trackers to match new synchronized target
      _prevPlaying = targetPlaying;
      _prevSongId = currentSongId;
      _prevPosition = targetDuration;
      
    } catch (e) {
      debugPrint('🚨 Error applying SSE room state: $e');
    } finally {
      // Release sync lock after player events settle
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSyncing = false;
      });
    }
  }

  @override
  void dispose() {
    _disconnectSse();
    _playbackStateSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    super.dispose();
  }
}
