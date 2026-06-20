import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme_provider.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/recent_plays_chip.dart';
import '../../core/constants.dart';
import '../../features/player/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final songs = await ApiService.fetchSongs();
      if (mounted) {
        setState(() {
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load songs: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final audioProvider = Provider.of<AudioProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final bg = isDark ? MyColors.blackColor : MyColors.offWhite;
    final titleColor = isDark ? Colors.white : MyColors.darkText;
    final hasMiniPlayer = audioProvider.currentSong != null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: MyColors.greenColor))
            : SingleChildScrollView(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: hasMiniPlayer ? 100.0 : 16.0), // Space for mini player
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Good evening',
                          style: AppTextStyles.greeting(color: titleColor),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: titleColor),
                              onPressed: themeProvider.toggleTheme,
                            ),
                            IconButton(
                              icon: Icon(Icons.settings_outlined, color: titleColor),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                );
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Recently Played Grid
                    Text(
                      'Recently played',
                      style: AppTextStyles.sectionHeader(color: titleColor),
                    ),
                    const SizedBox(height: 16),
                    _buildSongGrid(audioProvider),
                    const SizedBox(height: 28),

                    // Favourites horizontal scroll
                    if (_songs.isNotEmpty) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#LMWRAPPED',
                            style: AppTextStyles.tagLabel(color: isDark ? MyColors.lightGrey : MyColors.mutedGrey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Favourites',
                            style: AppTextStyles.sectionHeader(color: titleColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCarousel(
                        audioProvider,
                        _songs.where((s) => audioProvider.isLiked((s['id'] ?? s['_id'] ?? '').toString())).toList().isNotEmpty
                            ? _songs.where((s) => audioProvider.isLiked((s['id'] ?? s['_id'] ?? '').toString())).toList()
                            : _songs.take(5).toList(),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Editor's picks horizontal scroll
                    if (_songs.length > 5) ...[
                      Text(
                        "Editor's picks",
                        style: AppTextStyles.sectionHeader(color: titleColor),
                      ),
                      const SizedBox(height: 16),
                      _buildCarousel(audioProvider, _songs.skip(5).take(5).toList()),
                      const SizedBox(height: 28),
                    ],

                    // Chill Mix horizontal scroll
                    if (_songs.length > 3) ...[
                      Text(
                        'Chill Mix',
                        style: AppTextStyles.sectionHeader(color: titleColor),
                      ),
                      const SizedBox(height: 16),
                      _buildCarousel(audioProvider, _songs.skip(3).take(5).toList()),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSongGrid(AudioProvider audioProvider) {
    if (_songs.isEmpty) {
      return const Text('No songs found.', style: TextStyle(color: Colors.white54));
    }

    final gridCount = _songs.length > 6 ? 6 : _songs.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final song = _songs[index];
        final songId = (song['id'] ?? song['_id'] ?? '').toString();
        final isCurrent = audioProvider.currentSong?.id == songId;
        return RecentPlaysChip(
          image: song['image'] ?? '',
          title: song['name'] ?? '',
          isCurrent: isCurrent,
          onTap: () => audioProvider.playSong(song, _songs),
        );
      },
    );
  }

  Widget _buildCarousel(AudioProvider audioProvider, List<dynamic> songs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          
          return GestureDetector(
            onTap: () => audioProvider.playSong(song, _songs),
            child: Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      ApiService.getImageUrl(song['image']),
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 140,
                        height: 140,
                        color: MyColors.cardColor,
                        child: const Icon(Icons.music_note, size: 50, color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    song['name'] ?? 'Unknown',
                    style: AppTextStyles.cardTitle(color: isDark ? Colors.white : MyColors.darkText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song['artist'] ?? 'Unknown Artist',
                    style: AppTextStyles.cardSubtitle(color: isDark ? MyColors.lightGrey : MyColors.mutedGrey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
