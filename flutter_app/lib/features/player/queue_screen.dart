import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/now_playing_animation.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      appBar: AppBar(
        title: const Text('Queue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: audioProvider.queue.length,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80, // Space for miniplayer
        ),
        itemBuilder: (context, index) {
          final item = audioProvider.queue[index];
          final isCurrent = audioProvider.currentSong?.id == item.id;
          Widget tile = ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Image.network(
                    item.artUri?.toString() ?? 'https://via.placeholder.com/300',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 48,
                      height: 48,
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      width: 48,
                      height: 48,
                      color: Colors.black45,
                      child: Center(
                        child: NowPlayingAnimation(isPlaying: audioProvider.isPlaying, size: 20),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              item.title, 
              style: TextStyle(
                color: isCurrent ? theme.primaryColor : (isDark ? Colors.white : Colors.black),
                fontWeight: isCurrent ? FontWeight.bold : null,
              )
            ),
            subtitle: Text(item.artist ?? '', style: const TextStyle(color: Colors.grey)),
            trailing: isCurrent 
                ? const Icon(Icons.bar_chart, color: Colors.green)
                : null,
          );
          
          if (!isCurrent) {
            return Dismissible(
              key: Key(item.id + index.toString()),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (direction) {
                audioProvider.removeFromQueueAt(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${item.title}" from queue'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: tile,
            );
          }
          return tile;
        },
      ),
    );
  }
}

class AppColors {
  static Color mutedIconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54;
}
