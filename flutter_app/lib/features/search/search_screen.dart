import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/category_card.dart';
import '../../widgets/search_box.dart';
import '../../core/constants.dart';
import '../../widgets/offline_banner.dart';
import '../library/playlist_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _allSongs = [];
  List<dynamic> _playlists = [];
  List<String> _recentSearchIds = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAllSongs();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadAllSongs() async {
    try {
      final songs = await ApiService.fetchSongs();
      final playlists = await ApiService.fetchPlaylists();
      final recents = await StorageService.getRecentSearches();
      if (mounted) {
        setState(() {
          _allSongs = songs;
          _playlists = playlists;
          _recentSearchIds = recents;
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load songs or playlists for search: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Color _getCategoryColor(String idSeed) {
    int hash = 0;
    final seedStr = idSeed.trim();
    for (int i = 0; i < seedStr.length; i++) {
      hash = seedStr.codeUnitAt(i) + ((hash << 5) - hash);
    }
    hash = hash.abs();

    final double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.4).toColor();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (query.isEmpty) {
        setState(() {
          _searchResults = [];
        });
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final results = _allSongs.where((song) {
        final name = song['name']?.toString().toLowerCase() ?? '';
        final artist = song['artist']?.toString().toLowerCase() ?? '';
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || artist.contains(searchLower);
      }).toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.blackColor : MyColors.offWhite;
    final titleColor = isDark ? Colors.white : MyColors.darkText;
    final hasQuery = _searchController.text.isNotEmpty;
    final hasMiniPlayer = audioProvider.currentSong != null;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: hasMiniPlayer ? 80.0 : 16.0), // Padding for mini player
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Search',
                style: AppTextStyles.greeting(color: titleColor),
              ),
              const SizedBox(height: 12),
              if (!audioProvider.isOnline) const OfflineBanner(),
              SearchBox(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onCancel: hasQuery
                    ? () {
                        _searchController.clear();
                        _onSearchChanged('');
                      }
                    : null,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: hasQuery
                    ? (_isLoading
                        ? Center(child: CircularProgressIndicator(color: MyColors.greenColor))
                        : _searchResults.isEmpty
                            ? const Center(child: Text('No results found', style: TextStyle(color: Colors.white54)))
                            : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  final song = _searchResults[index];
                                  final songId = (song['id'] ?? song['_id'] ?? '').toString();
                                  final isCurrent = audioProvider.currentSong?.id == songId;

                                  return SongTile(
                                    image: song['image'] ?? '',
                                    title: song['name'] ?? 'Unknown',
                                    artist: song['artist'] ?? 'Unknown Artist',
                                    isCurrent: isCurrent,
                                    isPlaying: audioProvider.isPlaying,
                                    song: song,
                                    onTap: () async {
                                      await StorageService.addRecentSearch(songId);
                                      final recents = await StorageService.getRecentSearches();
                                      if (mounted) {
                                        setState(() {
                                          _recentSearchIds = recents;
                                        });
                                      }
                                      audioProvider.playSong(song, _searchResults);
                                    },
                                  );
                                },
                              ))
                    : _buildDefaultBrowseView(context, isDark, audioProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultBrowseView(BuildContext context, bool isDark, AudioProvider audioProvider) {
    final titleColor = isDark ? Colors.white : MyColors.darkText;
    final subColor = isDark ? MyColors.lightGrey : MyColors.mutedGrey;

    // Filter _allSongs to find the songs that are in _recentSearchIds
    final recentSongs = _recentSearchIds.map((id) {
      return _allSongs.firstWhere(
        (song) => (song['id'] ?? song['_id'] ?? '').toString() == id,
        orElse: () => null,
      );
    }).where((song) => song != null).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (recentSongs.isNotEmpty) ...[
            Text(
              'Recent searches',
              style: AppTextStyles.sectionHeader(color: titleColor),
            ),
            const SizedBox(height: 12),
            ...recentSongs.map((song) {
              final songId = (song['id'] ?? song['_id'] ?? '').toString();
              final isCurrent = audioProvider.currentSong?.id == songId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    ApiService.getImageUrl(song['image']),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: MyColors.cardColor,
                      child: const Icon(Icons.music_note, color: MyColors.mutedGrey),
                    ),
                  ),
                ),
                title: Text(
                  song['name'] ?? '',
                  style: AppTextStyles.bodyBold(color: titleColor),
                ),
                subtitle: Text(
                  'Song • ${song['artist'] ?? ''}',
                  style: AppTextStyles.cardSubtitle(color: subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, color: subColor, size: 18),
                  onPressed: () async {
                    await StorageService.removeRecentSearch(songId);
                    final recents = await StorageService.getRecentSearches();
                    setState(() {
                      _recentSearchIds = recents;
                    });
                  },
                ),
                onTap: () => audioProvider.playSong(song, _allSongs),
              );
            }),
            const SizedBox(height: 24),
          ],
          Text(
            'Start browsing',
            style: AppTextStyles.sectionHeader(color: titleColor),
          ),
          const SizedBox(height: 16),
          if (_isInitialLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: MyColors.greenColor),
              ),
            )
          else if (_playlists.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No categories found', style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: _playlists.map((pl) {
                return CategoryCard(
                  title: pl['name'] ?? 'Playlist',
                  color: _getCategoryColor((pl['id'] ?? pl['name'] ?? '').toString()),
                  image: pl['image'] != null && pl['image'].toString().isNotEmpty
                      ? ApiService.getImageUrl(pl['image'])
                      : null,
                  onTap: () {
                    if (pl['id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailScreen(playlistId: pl['id']),
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
