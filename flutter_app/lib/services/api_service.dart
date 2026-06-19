import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Base URL - will be configurable later for Render migration
  static String baseUrl = 'https://mymusic-ibgr.onrender.com'; // Default for local testing

  // Cache variables to prevent lagging and redundant network requests
  static List<dynamic>? _cachedSongs;
  static List<dynamic>? _cachedPlaylists;
  static Future<List<dynamic>>? _songsFuture;
  static Future<List<dynamic>>? _playlistsFuture;

  static Future<Map<String, String>> getHeaders({bool isJson = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    return {
      if (isJson) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> fetchSongs({bool forceRefresh = false}) async {
    if (_songsFuture != null && !forceRefresh) {
      return _songsFuture!;
    }
    
    _songsFuture = Future(() async {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/songs'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedSongs = data['songs'] ?? [];
        return _cachedSongs!;
      } else {
        _songsFuture = null; // Reset on failure so it can retry
        throw Exception('Failed to load songs');
      }
    });
    return _songsFuture!;
  }

  static Future<List<dynamic>> fetchPlaylists({bool forceRefresh = false}) async {
    if (_playlistsFuture != null && !forceRefresh) {
      return _playlistsFuture!;
    }
    
    _playlistsFuture = Future(() async {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/playlists'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedPlaylists = data['playlists'] ?? [];
        return _cachedPlaylists!;
      } else {
        _playlistsFuture = null; // Reset on failure so it can retry
        throw Exception('Failed to load playlists');
      }
    });
    return _playlistsFuture!;
  }

  static String getStreamUrl(String songId) {
    return '$baseUrl/api/stream/$songId';
  }

  static String getImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/300';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    // Prepend baseUrl for relative paths (ensuring leading slash if needed)
    final separator = path.startsWith('/') ? '' : '/';
    return '$baseUrl$separator$path';
  }


  static Future<void> preCache(String songId) async {
    try {
      final headers = await getHeaders();
      await http.get(Uri.parse('$baseUrl/api/precache/$songId'), headers: headers);
    } catch (e) {
      debugPrint('Precache failed: $e');
    }
  }

  static Future<Map<String, dynamic>> addSong(String? url, String? name, String? artist) async {
    final headers = await getHeaders(isJson: true);
    final response = await http.post(
      Uri.parse('$baseUrl/api/add-song'),
      headers: headers,
      body: json.encode({'url': url, 'name': name, 'artist': artist}),
    );
    // Invalidate songs cache on modification
    _cachedSongs = null;
    _songsFuture = null;
    return json.decode(response.body);
  }

  static Future<bool> deleteSong(String id) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/api/songs/$id'), headers: headers);
    if (response.statusCode == 200) {
      // Invalidate songs cache on modification
      _cachedSongs = null;
      _songsFuture = null;
      return true;
    }
    return false;
  }

  static Future<Map<String, dynamic>> createPlaylist(String name, {String? image}) async {
    final headers = await getHeaders(isJson: true);
    final response = await http.post(
      Uri.parse('$baseUrl/api/playlists'),
      headers: headers,
      body: json.encode({
        'name': name,
        if (image != null) 'image': image,
      }),
    );
    // Invalidate playlists cache on modification
    _cachedPlaylists = null;
    _playlistsFuture = null;
    return json.decode(response.body);
  }

  static Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    final headers = await getHeaders(isJson: true);
    final response = await http.post(
      Uri.parse('$baseUrl/api/playlists/$playlistId/add'),
      headers: headers,
      body: json.encode({'songId': songId}),
    );
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> fetchPlaylistDetail(String playlistId) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/playlists/$playlistId'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load playlist detail');
    }
  }

  static Future<List<String>> fetchAvailableImages() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/api/images'), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['images'] as List? ?? [];
        return list.map((img) => img.toString()).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch available images: $e');
    }
    return [];
  }

  static Future<bool> deletePlaylist(String playlistId) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/api/playlists/$playlistId'), headers: headers);
    if (response.statusCode == 200) {
      _cachedPlaylists = null;
      _playlistsFuture = null;
      return true;
    }
    return false;
  }

  static Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    final headers = await getHeaders();
    final response = await http.delete(Uri.parse('$baseUrl/api/playlists/$playlistId/songs/$songId'), headers: headers);
    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> fetchSongDetail(String id) async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/songs/$id'), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load song detail');
    }
  }

  static Future<int> fetchServerTime() async {
    final headers = await getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/api/time'), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['time'] as int;
    } else {
      throw Exception('Failed to fetch server time');
    }
  }
}
