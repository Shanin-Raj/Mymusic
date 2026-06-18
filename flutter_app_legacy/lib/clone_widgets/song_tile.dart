import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';
import 'package:sonic_vault_flutter/providers/playlist_provider.dart';

/// Figma-style song tile: 47×47 artwork, title + "Song • artist" subtitle,
/// dot separator, three-dot menu icon. Light/dark aware.
class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.image,
    required this.title,
    required this.artist,
    this.onTap,
    this.isCurrent = false,
    this.isPlaying = false,
    this.song,
    this.showHeart = false,
  });

  final String title;
  final String artist;
  final String image;
  final VoidCallback? onTap;
  final bool isCurrent;
  final bool isPlaying;
  final Map<String, dynamic>? song;
  final bool showHeart;

  void _showAddToPlaylistSheet(BuildContext context, Map<String, dynamic> targetSong) {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Consumer<PlaylistProvider>(
          builder: (context, playlistProvider, _) {
            final playlists = playlistProvider.playlists;
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Add to Playlist',
                      style: AppTextStyles.bodyBold(color: Colors.white).copyWith(fontSize: 18),
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: playlists.isEmpty
                        ? const Center(
                            child: Text(
                              'No playlists available',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        : ListView.builder(
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final pl = playlists[index];
                              final currentSongs = pl['songs'] as List? ?? [];
                              final isAlreadyIn = currentSongs.any(
                                (s) => s['id'].toString() == targetSong['id'].toString(),
                              );

                              return ListTile(
                                leading: const Icon(Icons.playlist_play, color: Colors.white70),
                                title: Text(pl['name'] ?? 'Playlist', style: const TextStyle(color: Colors.white)),
                                trailing: isAlreadyIn
                                    ? const Icon(Icons.check_circle, color: MyColors.greenColor)
                                    : const Icon(Icons.add_circle_outline, color: Colors.white54),
                                onTap: isAlreadyIn
                                    ? null
                                    : () async {
                                        await playlistProvider.addSongToPlaylist(pl['id'].toString(), targetSong);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Added to "${pl['name']}"'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        }
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isCurrent ? MyColors.greenColor : (isDark ? Colors.white : MyColors.darkText);
    final subColor   = isDark ? MyColors.lightGrey : MyColors.mutedGrey;

    final player = context.watch<PlayerProvider>();
    final isLiked = song != null ? player.isLiked(song!['id'].toString()) : false;

    return InkWell(
      onTap: onTap,
      splashColor: MyColors.greenColor.withValues(alpha: 0.08),
      highlightColor: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 47,
                width: 47,
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: image,
                      height: 47,
                      width: 47,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: MyColors.cardColor),
                      errorWidget: (_, __, ___) => Container(
                        color: MyColors.cardColor,
                        child: const Icon(Icons.music_note, color: MyColors.mutedGrey, size: 18),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        height: 47,
                        width: 47,
                        color: Colors.black54,
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyBold(color: titleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Song',
                        style: AppTextStyles.cardSubtitle(color: subColor),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: subColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          artist,
                          style: AppTextStyles.cardSubtitle(color: subColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Optional Heart Toggle
            if (showHeart)
              IconButton(
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? MyColors.greenColor : subColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  if (song != null) {
                    await player.toggleLike(song!['id'].toString());
                  }
                },
              ),
            if (showHeart) const SizedBox(width: 8),
            // More options Popup Menu
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: subColor, size: 20),
              color: MyColors.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) async {
                if (song == null) return;
                
                if (value == 'like') {
                  await player.toggleLike(song!['id'].toString());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          player.isLiked(song!['id'].toString())
                              ? 'Added to Liked Songs'
                              : 'Removed from Liked Songs',
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                } else if (value == 'playlist') {
                  _showAddToPlaylistSheet(context, song!);
                } else if (value == 'queue') {
                  await player.addToQueue(song!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${song!['name']}" to Queue'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) {
                if (song == null) return [];
                final isSongLiked = player.isLiked(song!['id'].toString());
                return [
                  PopupMenuItem<String>(
                    value: 'like',
                    child: Row(
                      children: [
                        Icon(
                          isSongLiked ? Icons.favorite : Icons.favorite_border,
                          color: isSongLiked ? MyColors.greenColor : Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isSongLiked ? 'Liked' : 'Add to Liked Songs',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'playlist',
                    child: Row(
                      children: [
                        Icon(Icons.playlist_add, color: Colors.white70, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Add to Playlist',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'queue',
                    child: Row(
                      children: [
                        Icon(Icons.queue_music, color: Colors.white70, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Add to Queue',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
