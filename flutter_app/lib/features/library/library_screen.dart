import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/song_tile.dart';
import 'playlist_detail_screen.dart';
import 'artist_detail_screen.dart';
import 'album_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _selectedFilter; // null = All Songs, or 'Playlists', 'Artists', 'Albums', 'Liked Songs'
  List<dynamic> _playlists = [];
  List<dynamic> _songs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    List<dynamic> playlists = [];
    List<dynamic> songs = [];

    try {
      playlists = await ApiService.fetchPlaylists(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Failed to load playlists: $e');
    }

    try {
      songs = await ApiService.fetchSongs(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Failed to load songs: $e');
    }

    if (mounted) {
      setState(() {
        _playlists = playlists;
        _songs = songs;
        _isLoading = false;
      });
    }
  }

  void _showCreatePlaylistDialog() {
    final TextEditingController controller = TextEditingController();
    String? selectedImage;
    List<String> availableImages = [];
    bool imagesLoaded = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!imagesLoaded) {
            imagesLoaded = true;
            ApiService.fetchAvailableImages().then((images) {
              if (context.mounted) {
                setDialogState(() {
                  availableImages = images;
                });
              }
            });
          }

          return AlertDialog(
            backgroundColor: MyColors.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: const Text('New Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter playlist name',
                      hintStyle: TextStyle(color: Colors.white30),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: MyColors.greenColor)),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 20),
                  const Text('Select Image (Optional)', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 10),
                  if (availableImages.isNotEmpty)
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableImages.length,
                        itemBuilder: (context, index) {
                          final img = availableImages[index];
                          final isSelected = selectedImage == img;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedImage = isSelected ? null : img;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected ? MyColors.greenColor : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  ApiService.getImageUrl(img),
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 76, height: 76, color: Colors.grey[800],
                                    child: const Icon(Icons.music_note, color: Colors.white30),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(color: MyColors.greenColor, strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.pop(context);
                    try {
                      await ApiService.createPlaylist(name, image: selectedImage);
                      _loadData(forceRefresh: true);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Playlist "$name" created')),
                        );
                      }
                    } catch (e) {
                      debugPrint('Failed to create playlist: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.greenColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLibraryAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add to Library',
                style: AppTextStyles.bodyBold(color: Colors.white).copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.playlist_add, color: MyColors.greenColor),
                title: const Text('Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Create a new playlist or view existing playlists', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: MyColors.greenColor),
                title: const Text('Artist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View and navigate your artists list', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedFilter = 'Artists');
                },
              ),
              ListTile(
                leading: const Icon(Icons.album, color: MyColors.greenColor),
                title: const Text('Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View and navigate your albums list', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedFilter = 'Albums');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.surfaceDark : MyColors.offWhite;
    final titleColor = isDark ? Colors.white : MyColors.darkText;
    final audioProvider = Provider.of<AudioProvider>(context);
    final hasMiniPlayer = audioProvider.currentSong != null;

    String appBarTitle = 'Your Library';
    if (_selectedFilter == 'Playlists') appBarTitle = 'Your Playlists';
    if (_selectedFilter == 'Artists') appBarTitle = 'Your Artists';
    if (_selectedFilter == 'Albums') appBarTitle = 'Your Albums';
    if (_selectedFilter == 'Liked Songs') appBarTitle = 'Liked Songs';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: MyColors.greenColor))
            : Padding(
                padding: EdgeInsets.only(bottom: hasMiniPlayer ? 80.0 : 16.0), // Padding for mini player
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      backgroundColor: bg,
                      elevation: 0,
                      expandedHeight: 80,
                      flexibleSpace: FlexibleSpaceBar(
                        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
                        title: Text(
                          appBarTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: titleColor),
                          onPressed: () => _loadData(forceRefresh: true),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: titleColor),
                          onPressed: _showLibraryAddBottomSheet,
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: _buildFilterChips(),
                      ),
                    ),
                    _buildContentSliver(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Playlists', 'Artists', 'Albums', 'Liked Songs'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = isSelected ? null : filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? MyColors.greenColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? MyColors.greenColor
                        : (isDark ? const Color(0xFF535353) : const Color(0xFFCCCCCC)),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.black
                            : (isDark ? Colors.white : MyColors.darkText),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentSliver(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);

    if (_selectedFilter == 'Playlists') {
      return _buildPlaylistsSliver();
    } else if (_selectedFilter == 'Artists') {
      return _buildArtistsSliver();
    } else if (_selectedFilter == 'Albums') {
      return _buildAlbumsSliver();
    } else if (_selectedFilter == 'Liked Songs') {
      return _buildLikedSongsSliver(audioProvider);
    } else {
      return _buildAllSongsSliver(audioProvider);
    }
  }

  Widget _buildAllSongsSliver(AudioProvider audioProvider) {
    if (_songs.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No songs found.')),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ElevatedButton.icon(
              onPressed: () => audioProvider.shufflePlay(_songs),
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
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = _songs[index];
              final songId = (song['id'] ?? song['_id'] ?? '').toString();
              final isCurrent = audioProvider.currentSong?.id == songId;

              return SongTile(
                image: song['image'] ?? '',
                title: song['name'] ?? 'Unknown',
                artist: song['artist'] ?? 'Unknown Artist',
                isCurrent: isCurrent,
                isPlaying: audioProvider.isPlaying,
                song: song,
                onTap: () => audioProvider.playSong(song, _songs),
              );
            },
            childCount: _songs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildLikedSongsSliver(AudioProvider audioProvider) {
    final likedSongs = _songs.where((song) {
      final songId = (song['id'] ?? song['_id'] ?? '').toString();
      return audioProvider.isLiked(songId);
    }).toList();

    if (likedSongs.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 64, color: Colors.white24),
              SizedBox(height: 12),
              Text(
                'No liked songs yet.',
                style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ElevatedButton.icon(
              onPressed: () => audioProvider.shufflePlay(likedSongs),
              icon: const Icon(Icons.shuffle, size: 20),
              label: Text(
                'SHUFFLE PLAY LIKED',
                style: GoogleFonts.montserrat(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.greenColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final song = likedSongs[index];
              final songId = (song['id'] ?? song['_id'] ?? '').toString();
              final isCurrent = audioProvider.currentSong?.id == songId;

              return SongTile(
                image: song['image'] ?? '',
                title: song['name'] ?? 'Unknown',
                artist: song['artist'] ?? 'Unknown Artist',
                isCurrent: isCurrent,
                isPlaying: audioProvider.isPlaying,
                song: song,
                showHeart: true,
                onTap: () => audioProvider.playSong(song, likedSongs),
              );
            },
            childCount: likedSongs.length,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaylistsSliver() {
    if (_playlists.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No playlists found.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final playlist = _playlists[index];
            final plId = (playlist['id'] ?? playlist['_id'] ?? '').toString();
            final image = playlist['image'] as String? ?? '';
            final count = playlist['songs']?.length ?? 0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistId: plId)),
                ).then((_) => _loadData());
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: MyColors.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: image.isNotEmpty
                            ? Image.network(
                                ApiService.getImageUrl(image),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.playlist_play, size: 56, color: Colors.white24),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.playlist_play, size: 56, color: Colors.white24),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playlist['name'] ?? 'Playlist',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Playlist • $count tracks',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          },
          childCount: _playlists.length,
        ),
      ),
    );
  }

  Widget _buildArtistsSliver() {
    final Set<String> artistSet = {};
    final Map<String, String> artistImages = {};

    for (var song in _songs) {
      final artistStr = song['artist'] as String?;
      if (artistStr != null) {
        final parts = artistStr.split(',');
        for (var part in parts) {
          final clean = part.trim();
          if (clean.isNotEmpty) {
            artistSet.add(clean);
            if (!artistImages.containsKey(clean)) {
              artistImages[clean] = song['image'] ?? '';
            }
          }
        }
      }
    }
    final sortedArtists = artistSet.toList()..sort();

    if (sortedArtists.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No artists found.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final artistName = sortedArtists[index];
            final image = artistImages[artistName] ?? '';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: ClipOval(
                child: Image.network(
                  ApiService.getImageUrl(image),
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: MyColors.cardColor,
                    child: const Icon(Icons.person, color: Colors.white54),
                  ),
                ),
              ),
              title: Text(
                artistName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Artist',
                style: TextStyle(color: Colors.grey[500]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArtistDetailScreen(artistName: artistName)),
                );
              },
            );
          },
          childCount: sortedArtists.length,
        ),
      ),
    );
  }

  Widget _buildAlbumsSliver() {
    final Set<String> albumSet = {};
    final Map<String, String> albumImages = {};

    for (var song in _songs) {
      var albumStr = song['album'] as String?;
      if (albumStr == null ||
          albumStr.trim().isEmpty ||
          albumStr.trim() == 'Unknown Album' ||
          albumStr.trim() == 'Synced Addition') {
        albumStr = 'Spotify Songs';
      }
      final cleanAlbum = albumStr.trim();
      albumSet.add(cleanAlbum);
      if (!albumImages.containsKey(cleanAlbum) || albumImages[cleanAlbum]!.isEmpty) {
        albumImages[cleanAlbum] = song['image'] ?? '';
      }
    }
    final sortedAlbums = albumSet.toList()..sort();

    if (sortedAlbums.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No albums found.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.82,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final albumName = sortedAlbums[index];
            final albumImage = albumImages[albumName] ?? '';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AlbumDetailScreen(
                      albumName: albumName,
                      imageUrl: albumImage,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: MyColors.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: albumImage.isNotEmpty
                            ? Image.network(
                                ApiService.getImageUrl(albumImage),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Icon(Icons.album, size: 56, color: Colors.white24),
                                ),
                              )
                            : const Center(
                                child: Icon(Icons.album, size: 56, color: Colors.white24),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Album',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          },
          childCount: sortedAlbums.length,
        ),
      ),
    );
  }
}
