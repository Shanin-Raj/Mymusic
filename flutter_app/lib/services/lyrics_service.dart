import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/lyrics_model.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

class LyricsService {
  static LyricsService? _instance;
  static LyricsService get instance {
    _instance ??= LyricsService._();
    return _instance!;
  }

  LyricsService._();

  Box get _box => Hive.box('song_lyrics');

  /// Retrieves lyrics for a song from local cache or API.
  Future<LyricsData?> getLyrics(
    String songId, {
    String? name,
    String? artist,
    int? durationMs,
    String? album,
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Check local Hive cache if not forcing refresh
      if (!forceRefresh && _box.containsKey(songId)) {
        final raw = _box.get(songId);
        if (raw != null) {
          if (raw is Map) {
            return LyricsData.fromJson(Map<String, dynamic>.from(raw));
          } else if (raw is String) {
            return LyricsData.fromJson(json.decode(raw) as Map<String, dynamic>);
          }
        }
      }

      // If offline and not in cache, we cannot fetch
      if (!ConnectivityService.instance.isOnline) {
        return null;
      }

      // 2. Fetch from backend API
      final lyricsMap = await ApiService.fetchLyrics(
        songId,
        name: name,
        artist: artist,
        durationMs: durationMs,
        album: album,
      );

      if (lyricsMap != null) {
        // Cache to Hive
        await _box.put(songId, lyricsMap);
        return LyricsData.fromJson(lyricsMap);
      }
    } catch (e) {
      debugPrint('LyricsService error for song $songId: $e');
    }
    return null;
  }

  /// Saves lyrics directly into Hive (e.g. during offline download sync).
  Future<void> saveLocalLyrics(String songId, Map<String, dynamic> lyricsData) async {
    try {
      await _box.put(songId, lyricsData);
    } catch (e) {
      debugPrint('Failed to save local lyrics for $songId: $e');
    }
  }

  /// Removes cached lyrics for a song.
  Future<void> removeLocalLyrics(String songId) async {
    try {
      await _box.delete(songId);
    } catch (e) {
      debugPrint('Failed to delete local lyrics for $songId: $e');
    }
  }
}
