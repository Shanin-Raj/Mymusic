import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';

class AudioCacheService {
  static AudioCacheService? _instance;
  static final Set<String> _downloading = {};
  static final Set<String> _downloaded = {};
  static final Map<String, Completer<String?>> _downloadCompleters = {};

  Timer? _inactivityTimer;
  static const _inactivityTimeout = Duration(minutes: 15);

  static AudioCacheService get instance {
    _instance ??= AudioCacheService._();
    return _instance!;
  }

  AudioCacheService._();

  void touch() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      debugPrint('15min inactivity reached, clearing audio cache');
      clearCache();
    });
  }

  Future<Directory> _getCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/audio_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String?> getCachedPath(String songId) async {
    if (!_downloaded.contains(songId)) return null;
    final dir = await _getCacheDir();
    final file = File('${dir.path}/$songId');
    if (await file.exists()) {
      return file.path;
    }
    _downloaded.remove(songId);
    return null;
  }

  Future<bool> isCached(String songId) async {
    final path = await getCachedPath(songId);
    return path != null;
  }

  Future<String> downloadSong(String songId) async {
    if (_downloading.contains(songId)) {
      final completer = _downloadCompleters[songId];
      if (completer != null) {
        final path = await completer.future;
        if (path != null) return path;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      final path = await getCachedPath(songId);
      if (path != null) return path;
      throw Exception('Song is already downloading but cache path was not found.');
    }

    _downloading.add(songId);
    final completer = Completer<String?>();
    _downloadCompleters[songId] = completer;

    final client = http.Client();
    try {
      debugPrint('Downloading song $songId...');
      final request = http.Request('GET', Uri.parse(ApiService.getStreamUrl(songId)));
      final response = await client.send(request);

      if (response.statusCode == 200) {
        final dir = await _getCacheDir();
        final file = File('${dir.path}/$songId');
        final sink = file.openWrite();
        await response.stream.pipe(sink);

        _downloaded.add(songId);
        debugPrint('Downloaded song $songId to ${file.path}');
        completer.complete(file.path);
        return file.path;
      } else {
        throw Exception('Failed to download song $songId: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Download failed for $songId: $e');
      completer.complete(null);
      rethrow;
    } finally {
      client.close();
      _downloading.remove(songId);
      _downloadCompleters.remove(songId);
    }
  }

  Future<void> removeSong(String songId) async {
    try {
      _downloaded.remove(songId);
      _downloading.remove(songId);
      final dir = await _getCacheDir();
      final file = File('${dir.path}/$songId');
      if (await file.exists()) {
        await file.delete();
        debugPrint('Deleted cached audio for song $songId');
      }
    } catch (e) {
      debugPrint('Failed to delete cached song $songId: $e');
    }
  }

  Future<void> clearCache() async {
    _inactivityTimer?.cancel();
    final dir = await _getCacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _downloaded.clear();
    debugPrint('Audio cache cleared');
  }

  void dispose() {
    _inactivityTimer?.cancel();
  }
}
