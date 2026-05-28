import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL - will be configurable later for Render migration
  static String baseUrl = 'https://music-vault-767870933282.asia-south1.run.app'; // Default for local testing

  // Cache variables to prevent lagging and redundant network requests
  static List<dynamic>? _cachedSongs;
  static List<dynamic>? _cachedPlaylists;

  static Future<List<dynamic>> fetchSongs({bool forceRefresh = false}) async {
    if (_cachedSongs != null && !forceRefresh) {
      return _cachedSongs!;
    }
    final response = await http.get(Uri.parse('$baseUrl/api/songs'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _cachedSongs = data['songs'] ?? [];
      return _cachedSongs!;
    } else {
      throw Exception('Failed to load songs');
    }
  }

  static Future<List<dynamic>> fetchPlaylists({bool forceRefresh = false}) async {
    if (_cachedPlaylists != null && !forceRefresh) {
      return _cachedPlaylists!;
    }
    final response = await http.get(Uri.parse('$baseUrl/api/playlists'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _cachedPlaylists = data['playlists'] ?? [];
      return _cachedPlaylists!;
    } else {
      throw Exception('Failed to load playlists');
    }
  }

  static String getStreamUrl(String songId) {
    return '$baseUrl/api/stream/$songId';
  }

  static Future<void> preCache(String songId) async {
    try {
      await http.get(Uri.parse('$baseUrl/api/precache/$songId'));
    } catch (e) {
      print('Precache failed: $e');
    }
  }

  static Future<Map<String, dynamic>> addSong(String? url, String? name, String? artist) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/add-song'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'url': url, 'name': name, 'artist': artist}),
    );
    // Invalidate songs cache on modification
    _cachedSongs = null;
    return json.decode(response.body);
  }

  static Future<bool> deleteSong(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/songs/$id'));
    if (response.statusCode == 200) {
      // Invalidate songs cache on modification
      _cachedSongs = null;
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> createPlaylist(String name, {String? image}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/playlists'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        if (image != null) 'image': image,
      }),
    );
    // Invalidate playlists cache on modification
    _cachedPlaylists = null;
    return json.decode(response.body);
  }

  static Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/playlists/$playlistId/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'songId': songId}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> fetchPlaylistDetail(String playlistId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/playlists/$playlistId'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load playlist detail');
    }
  }

  static Future<List<String>> fetchAvailableImages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/images'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['images'] as List? ?? [];
        return list.map((img) => img.toString()).toList();
      }
    } catch (e) {
      print('Failed to fetch available images: $e');
    }
    return [];
  }

  static Future<bool> deletePlaylist(String playlistId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/playlists/$playlistId'));
    if (response.statusCode == 200) {
      _cachedPlaylists = null;
      return true;
    }
    return false;
  }

  static Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/playlists/$playlistId/songs/$songId'));
    return response.statusCode == 200;
  }
}
