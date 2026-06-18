import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _songsCacheKey = 'sv_songs_cache';
  static const String _likedSongsKey = 'sv_liked';

  static Future<void> cacheSongs(List<dynamic> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_songsCacheKey, json.encode(songs));
  }

  static Future<List<dynamic>> getCachedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_songsCacheKey);
    if (data != null) {
      return json.decode(data);
    }
    return [];
  }

  static Future<void> toggleLiked(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> liked = prefs.getStringList(_likedSongsKey) ?? [];
    if (liked.contains(songId)) {
      liked.remove(songId);
    } else {
      liked.add(songId);
    }
    await prefs.setStringList(_likedSongsKey, liked);
  }

  static Future<List<String>> getLikedSongs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_likedSongsKey) ?? [];
  }

  static const String _recentSearchesKey = 'sv_recent_searches';

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? [];
  }

  static Future<void> addRecentSearch(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = prefs.getStringList(_recentSearchesKey) ?? [];
    recents.remove(songId);
    recents.insert(0, songId);
    if (recents.length > 10) {
      recents = recents.sublist(0, 10);
    }
    await prefs.setStringList(_recentSearchesKey, recents);
  }

  static Future<void> removeRecentSearch(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> recents = prefs.getStringList(_recentSearchesKey) ?? [];
    recents.remove(songId);
    await prefs.setStringList(_recentSearchesKey, recents);
  }
}
