import 'package:flutter/material.dart';
import 'package:sonic_vault_flutter/services/api_service.dart';

class PlaylistProvider with ChangeNotifier {
  List<dynamic> _playlists = [];
  bool _isLoading = false;
  // Cache of fully resolved playlist details (with song objects)
  final Map<String, Map<String, dynamic>> _playlistDetails = {};

  List<dynamic> get playlists => _playlists;
  bool get isLoading => _isLoading;

  PlaylistProvider() {
    loadPlaylists();
  }

  /// Get a fully resolved playlist (with song objects) by ID
  Map<String, dynamic>? getPlaylistDetail(String id) => _playlistDetails[id];

  Future<void> loadPlaylists() async {
    _isLoading = true;
    notifyListeners();
    try {
      _playlists = await ApiService.fetchPlaylists();
    } catch (e) {
      debugPrint('Error loading playlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single playlist with fully resolved song objects
  Future<void> loadPlaylistDetail(String playlistId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final detail = await ApiService.fetchPlaylistDetail(playlistId);
      _playlistDetails[playlistId] = detail;
    } catch (e) {
      debugPrint('Error loading playlist detail: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSongToPlaylist(String playlistId, dynamic song) async {
    try {
      final success = await ApiService.addSongToPlaylist(playlistId, song['id'].toString());
      if (success) {
        // Reload the full playlist detail to get the resolved song objects
        await loadPlaylistDetail(playlistId);
        await loadPlaylists();
      }
    } catch (e) {
      debugPrint('Error adding song to playlist: $e');
    }
  }

  Future<void> createPlaylist(String name, {String? image}) async {
    try {
      await ApiService.createPlaylist(name, image: image);
      await loadPlaylists();
    } catch (e) {
      debugPrint('Error creating playlist: $e');
    }
  }

  Future<bool> deletePlaylist(String playlistId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final success = await ApiService.deletePlaylist(playlistId);
      if (success) {
        _playlists.removeWhere((p) => p['id'].toString() == playlistId);
        _playlistDetails.remove(playlistId);
        await loadPlaylists();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting playlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final success = await ApiService.removeSongFromPlaylist(playlistId, songId);
      if (success) {
        await loadPlaylistDetail(playlistId);
        await loadPlaylists();
      }
    } catch (e) {
      debugPrint('Error removing song from playlist: $e');
    }
  }
}
