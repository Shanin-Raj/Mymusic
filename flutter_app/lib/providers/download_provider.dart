import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../services/offline_service.dart';

class DownloadProvider with ChangeNotifier {
  final OfflineService _offlineService = OfflineService.instance;

  final Map<String, double> _activeDownloads = {};
  final Queue<Map<String, dynamic>> _downloadQueue = Queue();
  int _activeDownloadCount = 0;
  static const int maxConcurrentDownloads = 3;

  Future<void> init() async {
    _offlineService.cleanupStale();
    notifyListeners();
  }

  bool isDownloading(String songId) => _activeDownloads.containsKey(songId);

  double getProgress(String songId) => _activeDownloads[songId] ?? 0.0;

  bool isDownloaded(String songId) => _offlineService.isDownloaded(songId);

  List<OfflineSongMetadata> getAllDownloaded() => _offlineService.getAllDownloaded();

  int getDownloadedCount() => _offlineService.getDownloadedCount();

  int getStorageUsed() => _offlineService.getStorageUsed();

  String formatStorageSize(int bytes) => _offlineService.formatStorageSize(bytes);

  Future<void> startDownload(Map<String, dynamic> song) async {
    final songId = (song['id'] ?? song['_id'] ?? '').toString();

    if (isDownloaded(songId) || isDownloading(songId)) return;

    if (_activeDownloadCount >= maxConcurrentDownloads) {
      _downloadQueue.add(song);
      notifyListeners();
      return;
    }

    _activeDownloadCount++;
    _activeDownloads[songId] = 0.0;
    notifyListeners();

    try {
      await _offlineService.downloadSong(
        songId,
        song,
        onProgress: (progress) {
          _activeDownloads[songId] = progress;
          notifyListeners();
        },
      );

      _activeDownloads.remove(songId);
      notifyListeners();
    } catch (e) {
      debugPrint('Download failed for $songId: $e');
      _activeDownloads.remove(songId);
      notifyListeners();
    } finally {
      _activeDownloadCount--;
      _processNextInQueue();
    }
  }

  void _processNextInQueue() {
    if (_downloadQueue.isEmpty) return;
    if (_activeDownloadCount >= maxConcurrentDownloads) return;

    final nextSong = _downloadQueue.removeFirst();
    startDownload(nextSong);
  }

  Future<void> removeDownload(String songId) async {
    await _offlineService.removeSong(songId);
    notifyListeners();
  }

  Future<void> clearAllDownloads() async {
    await _offlineService.clearAll();
    notifyListeners();
  }

  void cancelDownload(String songId) {
    _activeDownloads.remove(songId);
    _downloadQueue.removeWhere((s) {
      final id = (s['id'] ?? s['_id'] ?? '').toString();
      return id == songId;
    });
    notifyListeners();
  }
}
