import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';
import 'package:sonic_vault_flutter/widgets/now_playing_animation.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
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
        itemCount: player.queue.length,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 80, // Space for miniplayer if needed
        ),
        itemBuilder: (context, index) {
          final item = player.queue[index];
          final isCurrent = player.playbackState.queueIndex == index;
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item.artUri?.toString() ?? '',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                  if (isCurrent)
                    Container(
                      width: 48,
                      height: 48,
                      color: Colors.black45,
                      child: Center(
                        child: NowPlayingAnimation(isPlaying: player.isPlaying, size: 20),
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
            trailing: isCurrent ? const Icon(Icons.bar_chart, color: Colors.green) : null,
          );
        },
      ),
    );
  }
}
