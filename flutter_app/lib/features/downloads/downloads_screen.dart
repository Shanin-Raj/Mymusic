import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import '../../providers/download_provider.dart';
import '../../services/offline_service.dart';
import '../../services/api_service.dart';
import '../../widgets/mini_player.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.surfaceDark : MyColors.offWhite;
    final textColor = isDark ? Colors.white : MyColors.darkText;
    final subColor = isDark ? MyColors.lightGrey : MyColors.mutedGrey;

    final downloadedSongs = downloadProvider.getAllDownloaded();
    final storageUsed = downloadProvider.getStorageUsed();
    final storageFormatted = downloadProvider.formatStorageSize(storageUsed);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [MiniPlayer()],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Downloads', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (downloadedSongs.isNotEmpty)
            TextButton(
              onPressed: () => _showClearAllDialog(context, downloadProvider, storageFormatted),
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: downloadedSongs.isEmpty
          ? _buildEmptyState(context, isDark, subColor)
          : Column(
              children: [
                _buildStorageHeader(storageFormatted, downloadedSongs.length, isDark, subColor),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: downloadedSongs.length,
                    itemBuilder: (context, index) {
                      final song = downloadedSongs[index];
                      return _buildDownloadTile(context, song, audioProvider, isDark, subColor);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageHeader(String storageFormatted, int count, bool isDark, Color subColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.storage, size: 18, color: subColor),
          const SizedBox(width: 8),
          Text(
            '$storageFormatted used',
            style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 14, color: subColor.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Text(
            '$count song${count == 1 ? "" : "s"}',
            style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(BuildContext context, OfflineSongMetadata song, AudioProvider audioProvider, bool isDark, Color subColor) {
    return Dismissible(
      key: Key(song.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.redAccent.withValues(alpha: 0.2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.redAccent),
      ),
      onDismissed: (_) {
        final downloadProvider = context.read<DownloadProvider>();
        downloadProvider.removeDownload(song.id);
      },
      child: InkWell(
        onTap: () {
          final downloadProvider = context.read<DownloadProvider>();
          final songMap = {
            'id': song.id,
            'name': song.name,
            'artist': song.artist,
            'album': song.album,
            'image': song.image,
            'duration_ms': song.durationMs,
          };
          final allSongs = downloadProvider.getAllDownloaded().map((s) => {
            'id': s.id,
            'name': s.name,
            'artist': s.artist,
            'album': s.album,
            'image': s.image,
            'duration_ms': s.durationMs,
          }).toList();
          audioProvider.playSong(songMap, allSongs);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 47,
                  width: 47,
                  child: Image.network(
                    ApiService.getImageUrl(song.image),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: MyColors.cardColor,
                      child: const Icon(Icons.music_note, color: MyColors.mutedGrey, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : MyColors.darkText,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      song.artist,
                      style: TextStyle(color: subColor, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: subColor, size: 20),
                onPressed: () => _showDeleteDialog(context, song),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, Color subColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: subColor.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              color: isDark ? Colors.white : MyColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download songs to listen offline',
            style: TextStyle(color: subColor, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.greenColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Explore Songs'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, OfflineSongMetadata song) {
    final downloadProvider = context.read<DownloadProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyColors.cardColor,
        title: const Text('Remove Download', style: TextStyle(color: Colors.white)),
        content: Text('Remove "${song.name}" from downloads?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              downloadProvider.removeDownload(song.id);
              Navigator.pop(ctx);
            },
            child: const Text('Remove', style: TextStyle(color: MyColors.greenColor)),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, DownloadProvider downloadProvider, String storageFormatted) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MyColors.cardColor,
        title: const Text('Clear All Downloads', style: TextStyle(color: Colors.white)),
        content: Text('Remove all downloaded songs? This will free $storageFormatted.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              downloadProvider.clearAllDownloads();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
