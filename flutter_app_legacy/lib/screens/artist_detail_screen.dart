import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sonic_vault_flutter/services/api_service.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';
import 'package:sonic_vault_flutter/clone_widgets/song_tile.dart';
import 'package:sonic_vault_flutter/screens/main_screen.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  const ArtistDetailScreen({super.key, required this.artistName});

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
              child: const Center(child: CircularProgressIndicator(color: MyColors.greenColor)),
            );
          }
          if (snapshot.hasError) {
            return Container(
              color: const Color(0xFF121212),
              child: const Center(child: Text('Error loading artist', style: TextStyle(color: Colors.white))),
            );
          }

          final allSongs = snapshot.data ?? [];

          // Match artist robustly by splitting composite artist strings
          final artistSongs = allSongs.where((song) {
            final artistStr = song['artist']?.toString() ?? '';
            final parts = artistStr.split(',');
            return parts.any((part) => part.replaceAll(' ', ' ').replaceAll(' ', ' ').trim().toLowerCase() == artistName.trim().toLowerCase());
          }).toList();

          if (artistSongs.isEmpty) {
            return Container(
              color: const Color(0xFF121212),
              child: const Center(child: Text('No songs for this artist', style: TextStyle(color: Colors.white))),
            );
          }

          final artistImage = artistSongs.first['image'] ?? '';

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1E3264),
                  Color(0xFF14142B),
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
                  // Artist Profile Header Info
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // circular avatar profile
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: artistImage,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.white10),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Title
                          Text(
                            artistName,
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            'Artist • ${artistSongs.length} tracks',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFB3B3B3),
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          // Shuffle Play Button
                          ElevatedButton.icon(
                            onPressed: () => context.read<PlayerProvider>().shufflePlay(artistSongs),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
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
                          final song = artistSongs[index];
                          final isCurrent = player.currentSong?.id == song['id'].toString();

                          return SongTile(
                            image: song['image'] ?? '',
                            title: song['name'] ?? 'Unknown',
                            artist: song['artist'] ?? 'Unknown',
                            isCurrent: isCurrent,
                            isPlaying: player.isPlaying,
                            song: song,
                            onTap: () => context.read<PlayerProvider>().playSong(song, artistSongs),
                          );
                        },
                        childCount: artistSongs.length,
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
