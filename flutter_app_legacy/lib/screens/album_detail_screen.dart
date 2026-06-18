import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:sonic_vault_flutter/services/api_service.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';
import 'package:sonic_vault_flutter/clone_widgets/song_tile.dart';
import 'package:sonic_vault_flutter/screens/main_screen.dart';

class AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final String imageUrl;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return Scaffold(
      // MiniPlayer lives in bottomNavigationBar — Scaffold automatically
      // insets the body above it AND above the system nav bar.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          AppBottomNav(
            selectedIndex: 2,
            onTap: (i) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => MainScreen(initialIndex: i)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.fetchSongs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFF121212),
              child: const Center(
                  child: CircularProgressIndicator(color: MyColors.greenColor)),
            );
          }
          if (snapshot.hasError) {
            return Container(
              color: const Color(0xFF121212),
              child: const Center(
                  child: Text('Error loading album',
                      style: TextStyle(color: Colors.white))),
            );
          }

          final allSongs = snapshot.data ?? [];
          final albumSongs = allSongs
              .where(
                (song) {
                  final sAlbum = song['album']?.toString().trim();
                  if (albumName.trim() == 'Spotify Songs') {
                    return sAlbum == null ||
                        sAlbum.isEmpty ||
                        sAlbum == 'Spotify Songs' ||
                        sAlbum == 'Unknown Album' ||
                        sAlbum == 'Synced Addition';
                  } else {
                    return sAlbum == albumName.trim();
                  }
                },
              )
              .toList();

          if (albumSongs.isEmpty) {
            return Container(
              color: const Color(0xFF121212),
              child: const Center(
                  child: Text('No songs in this album',
                      style: TextStyle(color: Colors.white))),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFC63224),
                  Color(0xFF641D17),
                  Color(0xFF271513),
                  Color(0xFF121212),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false, // bottom handled by Scaffold.bottomNavigationBar
              child: CustomScrollView(
                slivers: [
                  // Back button app bar
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    pinned: true,
                  ),
                  // Album Artwork & Header Info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Artwork (Dynamic Cover image)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 240,
                                    height: 240,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      width: 240,
                                      height: 240,
                                      color: MyColors.cardColor,
                                    ),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      'assets/vinyl.jpg',
                                      width: 240,
                                      height: 240,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    'assets/vinyl.jpg',
                                    width: 240,
                                    height: 240,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          Text(
                            albumName,
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Album Subtitle
                          const Text(
                            'Album',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB3B3B3),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Shuffle Play Button
                          ElevatedButton.icon(
                            onPressed: () => context
                                .read<PlayerProvider>()
                                .shufflePlay(albumSongs),
                            icon: const Icon(Icons.shuffle, size: 20),
                            label: Text(
                              'SHUFFLE PLAY',
                              style: GoogleFonts.montserrat(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.greenColor,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(200, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)),
                              elevation: 4,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // Songs List
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = albumSongs[index];
                          final isCurrent =
                              player.currentSong?.id == song['id'].toString();

                          return SongTile(
                            image: song['image'] ?? '',
                            title: song['name'] ?? 'Unknown',
                            artist: song['artist'] ?? 'Unknown',
                            isCurrent: isCurrent,
                            isPlaying: player.isPlaying,
                            song: song,
                            onTap: () => context
                                .read<PlayerProvider>()
                                .playSong(song, albumSongs),
                          );
                        },
                        childCount: albumSongs.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
