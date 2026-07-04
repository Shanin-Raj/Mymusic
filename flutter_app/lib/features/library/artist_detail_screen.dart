import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/mini_player.dart';

class ArtistDetailScreen extends StatelessWidget {
  final String artistName;
  const ArtistDetailScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    return Scaffold(
      bottomNavigationBar: const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(),
          ],
        ),
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
            return parts.any((part) => part.trim().toLowerCase() == artistName.trim().toLowerCase());
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
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    pinned: true,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          ClipOval(
                            child: Image.network(
                              ApiService.getImageUrl(artistImage),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 200,
                                height: 200,
                                color: Colors.white10,
                                child: const Icon(Icons.person, size: 80, color: Colors.white54),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          ElevatedButton.icon(
                            onPressed: () => audioProvider.shufflePlay(artistSongs),
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
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = artistSongs[index];
                          final isCurrent = audioProvider.currentSong?.id == (song['id'] ?? song['_id'] ?? '').toString();

                          return SongTile(
                            image: song['image'] ?? '',
                            title: song['name'] ?? 'Unknown',
                            artist: song['artist'] ?? 'Unknown',
                            isCurrent: isCurrent,
                            isPlaying: audioProvider.isPlaying,
                            song: song,
                            onTap: () => audioProvider.playSong(song, artistSongs),
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
