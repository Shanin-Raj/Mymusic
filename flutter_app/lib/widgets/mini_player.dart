import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../features/player/now_playing_screen.dart';
import '../core/constants.dart';
import '../services/api_service.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;
    final isPlaying = audioProvider.isPlaying;

    if (song == null) {
      return const SizedBox.shrink(); // Hide if nothing is playing
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.cardColor : Colors.white;

    return SafeArea(
      bottom: true,
      child: GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NowPlayingScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Row(
                children: [
                  // Album art
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      ApiService.getImageUrl(song.artUri?.toString()),
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 40,
                        width: 40,
                        color: MyColors.cardColor,
                        child: const Icon(Icons.music_note, color: MyColors.mutedGrey, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title + artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          song.title,
                          style: AppTextStyles.miniPlayerTitle(
                            color: isDark ? Colors.white : MyColors.darkText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          song.artist ?? 'Unknown Artist',
                          style: AppTextStyles.miniPlayerArtist(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Like button
                  IconButton(
                    icon: Icon(
                      audioProvider.isLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                      color: audioProvider.isLiked(song.id) ? MyColors.greenColor : (isDark ? Colors.white : MyColors.darkText),
                      size: 22,
                    ),
                    onPressed: () => audioProvider.toggleLike(song.id),
                  ),
                  // Play/Pause button
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isDark ? Colors.white : MyColors.darkText,
                      size: 28,
                    ),
                    onPressed: () {
                      if (isPlaying) {
                        audioProvider.pause();
                      } else {
                        audioProvider.play();
                      }
                    },
                  ),
                ],
              ),
            ),
            // Progress bar
            StreamBuilder<Duration>(
              stream: audioProvider.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = song.duration ?? const Duration(seconds: 1);
                final durationMs = duration.inMilliseconds;
                final progress = durationMs > 0
                    ? (position.inMilliseconds / durationMs).clamp(0.0, 1.0)
                    : 0.0;

                return ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(MyColors.greenColor),
                    minHeight: 2.5,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
