import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import '../core/audio_handler.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/room_service.dart';

class AudioProvider with ChangeNotifier {
  late MyAudioHandler audioHandler;
  
  MediaItem? _currentAppMediaItem;
  PlaybackState? _currentAppPlaybackState;

  final RoomService _roomService = RoomService();
  String? _activeRoomId;
  bool _isSyncingFromServer = false;

  List<String> _likedSongIds = [];
  List<String> get likedSongIds => _likedSongIds;
  bool isLiked(String id) => _likedSongIds.contains(id);

  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;
  int get sleepTimerMinutes => _sleepTimerMinutes;

  String? get activeRoomId => _activeRoomId;
  bool get isSyncingFromServer => _isSyncingFromServer;

  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimerMinutes = minutes;
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), () {
        pause();
        _sleepTimerMinutes = 0;
        notifyListeners();
      });
    }
    notifyListeners();
  }
  
  MediaItem? get currentSong => _currentAppMediaItem;
  PlaybackState? get playbackState => _currentAppPlaybackState;

  List<MediaItem> get queue => audioHandler.queue.value;

  bool get isPlaying => _currentAppPlaybackState?.playing ?? false;

  Future<void> removeFromQueueAt(int index) async {
    await audioHandler.removeQueueItemAt(index);
    notifyListeners();
  }

  Future<void> toggleLike(String id) async {
    await StorageService.toggleLiked(id);
    _likedSongIds = await StorageService.getLikedSongs();
    notifyListeners();
  }

  Stream<Duration> get positionStream => audioHandler.appPositionStream;
  Stream<MediaItem?> get mediaItemStream => audioHandler.appMediaItemStream;
  Stream<PlaybackState> get playbackStateStream => audioHandler.appPlaybackStateStream;

  Future<void> init() async {
    _likedSongIds = await StorageService.getLikedSongs();
    
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.sonic_vault_flutter.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );

    // Listen to custom application streams that bypass Android Notification bugs
    audioHandler.appMediaItemStream.listen((item) {
      _currentAppMediaItem = item;
      notifyListeners();
    });

    audioHandler.appPlaybackStateStream.listen((state) {
      _currentAppPlaybackState = state;
      notifyListeners();
    });

    _roomService.roomStream.listen(_handleRoomUpdate);
  }

  Future<void> createRoom() async {
    final state = await _roomService.createRoom();
    _activeRoomId = state.roomId;
    notifyListeners();
    await _roomService.connectToStream(state.roomId);
  }

  Future<void> joinRoom(String roomId) async {
    final state = await _roomService.joinRoom(roomId);
    _activeRoomId = state.roomId;
    notifyListeners();
    await _roomService.connectToStream(state.roomId);
  }

  void leaveRoom() {
    _activeRoomId = null;
    _roomService.disconnectStream();
    notifyListeners();
  }

  Future<void> _handleRoomUpdate(RoomState state) async {
    if (_activeRoomId != state.roomId) return;
    
    _isSyncingFromServer = true;

    try {
      // 1. Sync current song
      if (_currentAppMediaItem?.id != state.currentSongId && state.currentSongId.isNotEmpty) {
        final songs = await ApiService.fetchSongs();
        final song = songs.firstWhere((s) => (s['id'] ?? s['_id']).toString() == state.currentSongId, orElse: () => null);
        if (song != null) {
          await playSong(song, songs);
        }
      }

      // 2. Sync play/pause
      if (state.isPlaying && !(isPlaying)) {
        await audioHandler.play();
      } else if (!state.isPlaying && isPlaying) {
        await audioHandler.pause();
      }

      // 3. Soft Sync position
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - state.updatedAt;
      final expectedPosition = state.position + (state.isPlaying && elapsed > 0 ? (elapsed / 1000.0) : 0);
      
      final currentPosStreamValue = await audioHandler.appPositionStream.first;
      final currentPosSec = currentPosStreamValue.inMilliseconds / 1000.0;
      
      if ((currentPosSec - expectedPosition).abs() > 2.0) {
        await audioHandler.seek(Duration(milliseconds: (expectedPosition * 1000).toInt()));
      }
    } catch (e) {
      debugPrint('Error handling room update: $e');
    } finally {
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSyncingFromServer = false;
      });
    }
  }

  Future<void> _broadcastState({String? songId, bool? playing, Duration? position}) async {
    if (_activeRoomId != null && !_isSyncingFromServer) {
      final currentSong = songId ?? _currentAppMediaItem?.id ?? '';
      final isNowPlaying = playing ?? isPlaying;
      final posSec = (position ?? await audioHandler.appPositionStream.first).inMilliseconds / 1000.0;
      
      await _roomService.updateState(_activeRoomId!, currentSong, isNowPlaying, posSec);
    }
  }

  Future<void> play() async {
    await audioHandler.play();
    await _broadcastState(playing: true);
  }
  
  Future<void> pause() async {
    await audioHandler.pause();
    await _broadcastState(playing: false);
  }

  Future<void> skipToNext() async {
    await audioHandler.skipToNext();
    Future.delayed(const Duration(milliseconds: 300), () async {
      await _broadcastState();
    });
  }

  Future<void> skipToPrevious() async {
    await audioHandler.skipToPrevious();
    Future.delayed(const Duration(milliseconds: 300), () async {
      await _broadcastState();
    });
  }

  Future<void> seek(Duration position) async {
    await audioHandler.seek(position);
    await _broadcastState(position: position);
  }

  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async => await audioHandler.setShuffleMode(mode);
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async => await audioHandler.setRepeatMode(mode);

  int _parseDuration(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
    }
    return 0;
  }

  Uri _parseUri(String? url) {
    if (url == null || url.isEmpty) {
      return Uri.parse('https://via.placeholder.com/300');
    }
    try {
      return Uri.parse(url);
    } catch (_) {
      return Uri.parse('https://via.placeholder.com/300');
    }
  }

  Future<void> playSong(Map<String, dynamic> song, List<dynamic> allSongs) async {
    try {
      final mediaItems = allSongs.map((s) {
        final songId = (s['id'] ?? s['_id'] ?? '').toString();
        final imageUrl = s['image']?.toString();
        return MediaItem(
          id: songId,
          album: 'MixTape',
          title: s['name']?.toString() ?? 'Unknown',
          artist: s['artist']?.toString() ?? 'Unknown',
          artUri: _parseUri(ApiService.getImageUrl(imageUrl)),
          duration: Duration(milliseconds: _parseDuration(s['duration_ms'])),
        );
      }).toList();

      final targetId = (song['id'] ?? song['_id'] ?? '').toString();
      final startIndex = mediaItems.indexWhere((item) => item.id == targetId);
      
      if (startIndex != -1) {
        // Disable shuffle mode when playing a specific song
        await setShuffleMode(AudioServiceShuffleMode.none);
        await audioHandler.updateQueueAndPlay(mediaItems, startIndex);
      }
      
      if (!_isSyncingFromServer) {
         await _broadcastState(songId: targetId, playing: true, position: Duration.zero);
      }
    } catch (e) {
      debugPrint('Error in playSong: $e');
    }
  }

  Future<void> shufflePlay(List<dynamic> playlist) async {
    if (playlist.isEmpty) return;

    try {
      final shuffledList = List.from(playlist)..shuffle();
      final mediaItems = shuffledList.map((s) {
        final songId = (s['id'] ?? s['_id'] ?? '').toString();
        final imageUrl = s['image']?.toString();
        return MediaItem(
          id: songId,
          album: 'MixTape',
          title: s['name']?.toString() ?? 'Unknown',
          artist: s['artist']?.toString() ?? 'Unknown',
          artUri: _parseUri(ApiService.getImageUrl(imageUrl)),
          duration: Duration(milliseconds: _parseDuration(s['duration_ms'])),
        );
      }).toList();

      // Keep shuffle mode OFF to avoid double shuffle
      await setShuffleMode(AudioServiceShuffleMode.none);
      await audioHandler.updateQueueAndPlay(mediaItems, 0);
      
      if (!_isSyncingFromServer && mediaItems.isNotEmpty) {
         await _broadcastState(songId: mediaItems[0].id, playing: true, position: Duration.zero);
      }
    } catch (e) {
      debugPrint('Error in shufflePlay: $e');
    }
  }

  Future<void> addToQueue(Map<String, dynamic> song) async {
    try {
      final mediaItem = MediaItem(
        id: (song['id'] ?? song['_id'] ?? '').toString(),
        album: 'MixTape',
        title: song['name']?.toString() ?? 'Unknown',
        artist: song['artist']?.toString() ?? 'Unknown',
        artUri: _parseUri(ApiService.getImageUrl(song['image']?.toString())),
        duration: Duration(milliseconds: _parseDuration(song['duration_ms'])),
      );
      await audioHandler.addQueueItems([mediaItem]);
      notifyListeners();
    } catch (e) {
      debugPrint('🚨 Error in addToQueue(): $e');
    }
  }
}
