import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/download_provider.dart';

class DownloadButton extends StatelessWidget {
  const DownloadButton({
    super.key,
    required this.song,
    this.size = 20,
    this.padding = EdgeInsets.zero,
  });

  final Map<String, dynamic> song;
  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final songId = (song['id'] ?? song['_id'] ?? '').toString();
    final isDownloading = downloadProvider.isDownloading(songId);
    final isDownloaded = downloadProvider.isDownloaded(songId);
    final progress = downloadProvider.getProgress(songId);

    if (isDownloading) {
      return Padding(
        padding: padding,
        child: SizedBox(
          width: size + 4,
          height: size + 4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size + 4,
                height: size + 4,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  color: MyColors.greenColor,
                ),
              ),
              Icon(
                Icons.download,
                size: size * 0.6,
                color: MyColors.greenColor,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: padding,
      child: IconButton(
        icon: Icon(
          isDownloaded ? Icons.download_done : Icons.download_outlined,
          color: isDownloaded ? MyColors.greenColor : null,
          size: size,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () async {
          if (isDownloaded) {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: MyColors.cardColor,
                title: const Text('Remove Download', style: TextStyle(color: Colors.white)),
                content: const Text('Remove this song from downloads?', style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove', style: TextStyle(color: MyColors.greenColor)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await downloadProvider.removeDownload(songId);
            }
          } else {
            await downloadProvider.startDownload(song);
          }
        },
      ),
    );
  }
}
