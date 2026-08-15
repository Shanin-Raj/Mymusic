import 'dart:async';
import 'package:audio_service/audio_service.dart';
import '../core/audio_handler.dart';
import '../models/lyrics_model.dart';
import '../services/api_service.dart';
import '../services/lyrics_service.dart';
import '../services/storage_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';
import '../main.dart';
import 'package:flutter/material.dart';
import '../services/sync_client.dart';
import '../services/audio_controller.dart';

class AudioProvider with ChangeNotifier {
  late MyAudioHandler audioHandler;
  
  MediaItem? _currentAppMediaItem;
  PlaybackState? _currentAppPlaybackState;

  List<String> _likedSongIds = [];
  List<String> get likedSongIds => _likedSongIds;
  bool isLiked(String id) => _likedSongIds.contains(id);

  Timer? _sleepTimer;
  int _sleepTimerMinutes = 0;
  int get sleepTimerMinutes => _sleepTimerMinutes;

  // Connectivity related
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  StreamSubscription<bool>? _connectivitySubscription;

  // Lyrics related
  LyricsData? _currentLyrics;
  LyricsData? get currentLyrics => _currentLyrics;
  bool _isLoadingLyrics = false;
  bool get isLoadingLyrics => _isLoadingLyrics;
  int _activeLyricIndex = -1;
  int get activeLyricIndex => _activeLyricIndex;
  StreamSubscription<Duration>? _positionSubscription;

  // Syncing state flag
  bool isSyncing = false;

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

  Future<void> init([ConnectivityService? connectivityService]) async {
    _likedSongIds = await StorageService.getLikedSongs();
    
    audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.sonic_vault_flutter.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidNotificationIcon: 'drawable/ic_notification',
      ),
    );

    // Listen to custom application streams that bypass Android Notification bugs
    audioHandler.appMediaItemStream.listen((item) {
      final previousId = _currentAppMediaItem?.id;
      _currentAppMediaItem = item;
      notifyListeners();

      if (item != null && item.id != previousId) {
        _activeLyricIndex = -1;
        fetchLyricsForCurrentSong();
      }
    });

    audioHandler.appPlaybackStateStream.listen((state) {
      _currentAppPlaybackState = state;
      notifyListeners();
    });

    // Track real-time playback position for active lyric line calculation
    _positionSubscription?.cancel();
    _positionSubscription = audioHandler.appPositionStream.listen((position) {
      _updateActiveLyricIndex(position);
    });

    // Subscribe to connectivity changes if provided
    if (connectivityService != null) {
      _isOnline = connectivityService.isOnline;
      _connectivitySubscription = connectivityService.onlineStream.listen((isOnline) {
        _isOnline = isOnline;
        notifyListeners();
      });
    }
  }

  void _updateActiveLyricIndex(Duration position) {
    if (_currentLyrics == null || !_currentLyrics!.hasSynced || _currentLyrics!.lines.isEmpty) {
      if (_activeLyricIndex != -1) {
        _activeLyricIndex = -1;
        notifyListeners();
      }
      return;
    }

    final lines = _currentLyrics!.lines;
    int index = -1;
    for (int i = 0; i < lines.length; i++) {
      if (position >= lines[i].timestamp) {
        index = i;
      } else {
        break;
      }
    }

    if (index != _activeLyricIndex) {
      _activeLyricIndex = index;
      notifyListeners();
    }
  }

  Future<void> fetchLyricsForCurrentSong({bool forceRefresh = false}) async {
    final song = _currentAppMediaItem;
    if (song == null) {
      _currentLyrics = null;
      _isLoadingLyrics = false;
      _activeLyricIndex = -1;
      notifyListeners();
      return;
    }

    _isLoadingLyrics = true;
    notifyListeners();

    try {
      final lyrics = await LyricsService.instance.getLyrics(
        song.id,
        name: song.title,
        artist: song.artist,
        durationMs: song.duration?.inMilliseconds,
        album: song.album,
        forceRefresh: forceRefresh,
      );

      if (_currentAppMediaItem?.id == song.id) {
        _currentLyrics = lyrics;
        _isLoadingLyrics = false;
        if (playbackState != null) {
          _updateActiveLyricIndex(playbackState!.position);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching lyrics in AudioProvider: $e');
      if (_currentAppMediaItem?.id == song.id) {
        _isLoadingLyrics = false;
        notifyListeners();
      }
    }
  }

  Future<void> seekToLyric(Duration timestamp) async {
    await seek(timestamp);
  }

  Future<void> play() async {
    if (SyncClient.instance.isConnected && SyncClient.instance.roomState != null && !isSyncing) {
      SyncClient.instance.sendIntent('PLAY_INTENT', {
        'position': playbackState?.position.inMilliseconds ?? 0
      });
      return;
    }
    await audioHandler.play();
  }
  
  Future<void> pause() async {
    if (SyncClient.instance.isConnected && SyncClient.instance.roomState != null && !isSyncing) {
      SyncClient.instance.sendIntent('PAUSE_INTENT', {
        'position': playbackState?.position.inMilliseconds ?? 0
      });
      return;
    }
    await audioHandler.pause();
  }

  Future<void> skipToNext() async {
    if (SyncClient.instance.isConnected && SyncClient.instance.roomState != null && !isSyncing) {
      AudioController.instance.nextTrack();
      return;
    }
    await audioHandler.skipToNext();
  }

  Future<void> skipToPrevious() async {
    if (SyncClient.instance.isConnected && SyncClient.instance.roomState != null && !isSyncing) {
      AudioController.instance.prevTrack();
      return;
    }
    await audioHandler.skipToPrevious();
  }

  Future<void> seek(Duration position) async {
    if (SyncClient.instance.isConnected && SyncClient.instance.roomState != null && !isSyncing) {
      AudioController.instance.seekInRoom(position);
      return;
    }
    await audioHandler.seek(position);
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
      if (!_isOnline) {
        // When offline, check if the song is downloaded
        final songId = (song['id'] ?? song['_id'] ?? '').toString();
        final isDownloaded = OfflineService.instance.isDownloaded(songId);
        
        if (!isDownloaded) {
          // Show error message to user
          debugPrint('Cannot play song "$songId" while offline - not downloaded');
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Cannot play this song while offline. Download it first!'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }
      }
      
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

  Future<bool> canPlaySong(Map<String, dynamic> song) async {
    return true;
  }

  List<Map<String, dynamic>> filterDownloadedSongs(List<Map<String, dynamic>> allSongs) {
    if (_isOnline) return allSongs;
    return allSongs.where((song) {
      final songId = (song['id'] ?? song['_id'] ?? '').toString();
      return OfflineService.instance.isDownloaded(songId);
    }).toList();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _connectivitySubscription?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }
}
