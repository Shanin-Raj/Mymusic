import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'lyrics_service.dart';

class OfflineSongMetadata {
  final String id;
  final String name;
  final String artist;
  final String? album;
  final String? image;
  final int durationMs;
  final String filePath;
  final int fileSize;
  final DateTime downloadedAt;

  OfflineSongMetadata({
    required this.id,
    required this.name,
    required this.artist,
    this.album,
    this.image,
    required this.durationMs,
    required this.filePath,
    required this.fileSize,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'artist': artist,
    'album': album,
    'image': image,
    'duration_ms': durationMs,
    'file_path': filePath,
    'file_size': fileSize,
    'downloaded_at': downloadedAt.toIso8601String(),
  };

  factory OfflineSongMetadata.fromJson(Map<String, dynamic> json) {
    return OfflineSongMetadata(
      id: json['id'] as String,
      name: json['name'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String?,
      image: json['image'] as String?,
      durationMs: json['duration_ms'] as int,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int,
      downloadedAt: DateTime.parse(json['downloaded_at'] as String),
    );
  }
}

class OfflineService {
  static OfflineService? _instance;
  static OfflineService get instance {
    _instance ??= OfflineService._();
    return _instance!;
  }

  OfflineService._();

  Box get _box => Hive.box('offline_songs');

  Future<Directory> _getDownloadsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/offline_downloads');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> downloadSong(
    String songId,
    Map<String, dynamic> metadata, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _getDownloadsDir();
    final tempFile = File('${dir.path}/$songId.tmp');
    final finalFile = File('${dir.path}/$songId.m4a');

    final client = http.Client();
    try {
      debugPrint('Downloading song $songId for offline...');
      final request = http.Request('GET', Uri.parse(ApiService.getStreamUrl(songId)));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to download song $songId: ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = tempFile.openWrite();

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      });

      await sink.flush();
      await sink.close();

      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(finalFile.path);

      final fileSize = await finalFile.length();

      final songMetadata = OfflineSongMetadata(
        id: songId,
        name: metadata['name']?.toString() ?? 'Unknown',
        artist: metadata['artist']?.toString() ?? 'Unknown',
        album: metadata['album']?.toString(),
        image: metadata['image']?.toString(),
        durationMs: _parseDuration(metadata['duration_ms']),
        filePath: finalFile.path,
        fileSize: fileSize,
        downloadedAt: DateTime.now(),
      );

      _box.put(songId, jsonEncode(songMetadata.toJson()));
      debugPrint('Downloaded song $songId to ${finalFile.path} ($fileSize bytes)');

      // Also cache lyrics for offline usage
      try {
        await LyricsService.instance.getLyrics(
          songId,
          name: metadata['name']?.toString(),
          artist: metadata['artist']?.toString(),
          durationMs: _parseDuration(metadata['duration_ms']),
          album: metadata['album']?.toString(),
        );
      } catch (lyricsErr) {
        debugPrint('Non-critical: Failed to cache lyrics for offline song $songId: $lyricsErr');
      }

      return finalFile.path;
    } catch (e) {
      debugPrint('Download failed for $songId: $e');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> removeSong(String songId) async {
    try {
      final dir = await _getDownloadsDir();
      final file = File('${dir.path}/$songId.m4a');
      if (await file.exists()) {
        await file.delete();
      }
      _box.delete(songId);
      await LyricsService.instance.removeLocalLyrics(songId);
      debugPrint('Removed offline song and lyrics for $songId');
    } catch (e) {
      debugPrint('Failed to remove offline song $songId: $e');
    }
  }

  bool isDownloaded(String songId) {
    final data = _box.get(songId);
    if (data == null) return false;
    try {
      final metadata = OfflineSongMetadata.fromJson(jsonDecode(data as String));
      final file = File(metadata.filePath);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  String? getOfflinePath(String songId) {
    final data = _box.get(songId);
    if (data == null) return null;
    try {
      final metadata = OfflineSongMetadata.fromJson(jsonDecode(data as String));
      final file = File(metadata.filePath);
      
      // Fallback check for migrated file names
      final migratedFile = File('${metadata.filePath}.m4a');
      
      if (file.existsSync()) {
        return file.path;
      } else if (migratedFile.existsSync()) {
        return migratedFile.path;
      }
      
      _box.delete(songId);
      return null;
    } catch (_) {
      return null;
    }
  }

  List<OfflineSongMetadata> getAllDownloaded() {
    final List<OfflineSongMetadata> songs = [];
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        try {
          final metadata = OfflineSongMetadata.fromJson(jsonDecode(data as String));
          final file = File(metadata.filePath);
          if (file.existsSync()) {
            songs.add(metadata);
          } else {
            _box.delete(key);
          }
        } catch (_) {
          _box.delete(key);
        }
      }
    }
    return songs;
  }

  int getDownloadedCount() {
    return getAllDownloaded().length;
  }

  int getStorageUsed() {
    int total = 0;
    for (final key in _box.keys) {
      final data = _box.get(key);
      if (data != null) {
        try {
          final metadata = OfflineSongMetadata.fromJson(jsonDecode(data as String));
          final file = File(metadata.filePath);
          if (file.existsSync()) {
            total += metadata.fileSize;
          } else {
            _box.delete(key);
          }
        } catch (_) {
          _box.delete(key);
        }
      }
    }
    return total;
  }

  Future<void> clearAll() async {
    final songs = getAllDownloaded();
    for (final song in songs) {
      await removeSong(song.id);
    }
  }

  void cleanupStale() {
    getAllDownloaded();
  }

  String formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  int _parseDuration(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? (double.tryParse(val)?.toInt() ?? 0);
    }
    return 0;
  }
}
