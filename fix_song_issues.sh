#!/bin/bash

# Fix for Flutter Song Playing Issues
# 
# This script addresses the following issues:
# 1. URL change from old backend to new backend that doesn't support same API endpoints
# 2. Poor error handling in API calls
# 3. Network connectivity issues
# 4. Real-time synchronization problems

# Step 1: Fix the ApiService class with improved error handling
# (Already done in previous edits)

# Step 2: Add retry logic for failed API calls
cat > D:/music/flutter_app/lib/services/api_service_retry.dart << 'EOF'
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiServiceRetry {
  static String baseUrl = 'https://mymusic-ibgr.onrender.com';
  
  static Future<T> _makeRequest<T>(
    String url,
    Future<T> Function(http.Response response) parser,
    {int maxRetries = 3, Duration retryDelay = const Duration(seconds: 2)},
  ) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Request timed out'),
        );
        
        if (response.statusCode == 200) {
          return parser(response);
        } else if (response.statusCode >= 500) {
          // Server error, retry
          attempt++;
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          }
        }
        
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      } catch (e) {
        if (e is TimeoutException) {
          attempt++;
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          }
        }
        rethrow;
      }
    }
    throw Exception('Max retries exceeded');
  }
  
  static Future<List<dynamic>> fetchSongsWithRetry() async {
    return _makeRequest(
      '$baseUrl/api/songs',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          final data = json.decode(body);
          if (data is Map<String, dynamic> && data.containsKey('songs')) {
            return data['songs'] ?? [];
          } else {
            throw Exception('Invalid response format');
          }
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
    );
  }
  
  static Future<List<dynamic>> fetchPlaylistsWithRetry() async {
    return _makeRequest(
      '$baseUrl/api/playlists',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          final data = json.decode(body);
          if (data is Map<String, dynamic> && data.containsKey('playlists')) {
            return data['playlists'] ?? [];
          } else {
            throw Exception('Invalid response format');
          }
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
    );
  }
  
  static Future<Map<String, dynamic>> fetchSongDetailWithRetry(String id) async {
    return _makeRequest(
      '$baseUrl/api/songs/$id',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          return json.decode(body);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
    );
  }
  
  static Future<Map<String, dynamic>> createRoomWithRetry() async {
    return _makeRequest(
      '$baseUrl/api/rooms',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          return json.decode(body);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
    );
  }
  
  static Future<Map<String, dynamic>> getRoomStateWithRetry(String roomId) async {
    return _makeRequest(
      '$baseUrl/api/rooms/$roomId',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          return json.decode(body);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
    );
  }
  
  static Future<Map<String, dynamic>> updateRoomStateWithRetry({
    required String roomId,
    required String songId,
    required bool isPlaying,
    required int position,
  }) async {
    return _makeRequest(
      '$baseUrl/api/rooms/$roomId/update',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          return json.decode(body);
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'currentSongId': songId,
        'isPlaying': isPlaying,
        'position': position,
      }),
    );
  }
  
  static Future<int> fetchServerTimeWithRetry() async {
    return _makeRequest(
      '$baseUrl/api/time',
      (response) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response from server');
        }
        try {
          final data = json.decode(body);
          if (data is Map<String, dynamic> && data.containsKey('time')) {
            return data['time'] as int;
          } else {
            throw Exception('Invalid response format');
          }
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      },
    );
  }
}
EOF
