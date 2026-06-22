import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/song_tile.dart';
import '../../widgets/mini_player.dart';
import '../../providers/download_provider.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  Map<String, dynamic>? _playlistDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final detail = await ApiService.fetchPlaylistDetail(widget.playlistId);
      setState(() {
        _playlistDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load playlist detail: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddSongsSheet() async {
    final messenger = ScaffoldMessenger.of(context);
    List<dynamic> allSongs = [];
    try {
      allSongs = await ApiService.fetchSongs();
    } catch (e) {
      debugPrint('Failed to fetch songs for sheet: $e');
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: MyColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final currentSongs = _playlistDetail?['songs'] as List? ?? [];

              return Column(
                children: [
                  Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Add Songs', style: AppTextStyles.bodyBold(color: Colors.white)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) {
                        final song = allSongs[index];
                        final songId = (song['id'] ?? song['_id'] ?? '').toString();
                        final isAlreadyIn = currentSongs.any(
                          (s) => (s['id'] ?? s['_id'] ?? '').toString() == songId,
                        );

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              ApiService.getImageUrl(song['image']),
                              width: 40, height: 40, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 40, height: 40, color: Colors.grey[800],
                                child: const Icon(Icons.music_note, color: Colors.white70),
                              ),
                            ),
                          ),
                          title: Text(song['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                          subtitle: Text(song['artist'] ?? 'Unknown', style: const TextStyle(color: Colors.white60)),
                          trailing: isAlreadyIn
                              ? const Icon(Icons.check_circle, color: MyColors.greenColor)
                              : const Icon(Icons.add_circle_outline, color: Colors.white54),
                          onTap: isAlreadyIn
                              ? null
                              : () async {
                                  final success = await ApiService.addSongToPlaylist(widget.playlistId, songId);
                                  if (success) {
                                    await _loadDetails();
                                    setSheetState(() {});
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Added "${song['name']}" to playlist'),
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
              );
            },
          );
        },
      ),
    );
  }

  List<Color> _getPlaylistGradient(String idSeed, bool isDark) {
    int hash = 0;
    final seedStr = idSeed.trim();
    for (int i = 0; i < seedStr.length; i++) {
      hash = seedStr.codeUnitAt(i) + ((hash << 5) - hash);
    }
    hash = hash.abs();

    final double hue = (hash % 360).toDouble();
    
    if (isDark) {
      final double saturation = 0.35 + (hash % 20) / 100.0;
      final double lightness1 = 0.20 + (hash % 10) / 100.0;
      final double lightness2 = 0.10 + (hash % 8) / 100.0;
      
      final color1 = HSLColor.fromAHSL(1.0, hue, saturation, lightness1).toColor();
      final color2 = HSLColor.fromAHSL(1.0, (hue + 25) % 360, saturation - 0.05, lightness2).toColor();
      return [color1, color2, MyColors.surfaceDark];
    } else {
      final double saturation = 0.25 + (hash % 15) / 100.0;
      final double lightness1 = 0.75 + (hash % 10) / 100.0;
      final double lightness2 = 0.85 + (hash % 10) / 100.0;
      
      final color1 = HSLColor.fromAHSL(1.0, hue, saturation, lightness1).toColor();
      final color2 = HSLColor.fromAHSL(1.0, (hue + 20) % 360, saturation - 0.05, lightness2).toColor();
      return [color1, color2, MyColors.offWhite];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final audioProvider = context.watch<AudioProvider>();

    if (_isLoading && _playlistDetail == null) {
      return const Scaffold(
        backgroundColor: MyColors.surfaceDark,
        body: Center(
          child: CircularProgressIndicator(color: MyColors.greenColor),
        ),
      );
    }

    final playlistName = _playlistDetail?['name'] ?? 'Playlist';
    final playlistImage = _playlistDetail?['image'] ?? '';
    final songs = _playlistDetail?['songs'] as List? ?? [];

    return Scaffold(
      backgroundColor: isDark ? MyColors.surfaceDark : MyColors.offWhite,
      bottomNavigationBar: const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MiniPlayer(),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 390,
            pinned: true,
            backgroundColor: isDark ? MyColors.surfaceDark : MyColors.offWhite,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : MyColors.darkText),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: MyColors.cardColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      title: const Text('Delete Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      content: const Text('Are you sure you want to delete this playlist? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (confirm == true) {
                    final success = await ApiService.deletePlaylist(widget.playlistId);
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Playlist deleted successfully')),
                      );
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: isDark ? Colors.white : MyColors.darkText),
                onPressed: _loadDetails,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              centerTitle: true,
              title: LayoutBuilder(
                builder: (context, constraints) {
                  final top = constraints.biggest.height;
                  final double opacity = (1.0 - ((top - kToolbarHeight - MediaQuery.of(context).padding.top) / (390 - kToolbarHeight - MediaQuery.of(context).padding.top))).clamp(0.0, 1.0);
                  return Opacity(
                    opacity: opacity > 0.85 ? opacity : 0.0,
                    child: Text(
                      playlistName,
                      style: AppTextStyles.bodyBold(color: isDark ? Colors.white : MyColors.darkText),
                    ),
                  );
                },
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _getPlaylistGradient(widget.playlistId, isDark),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiService.getImageUrl(playlistImage),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: MyColors.cardColor,
                              child: const Icon(Icons.playlist_play, size: 80, color: Colors.white30),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        playlistName,
                        style: AppTextStyles.greeting(color: isDark ? Colors.white : MyColors.darkText).copyWith(fontSize: 24),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Playlist • ${songs.length} tracks',
                        style: AppTextStyles.caption(color: isDark ? MyColors.lightGrey : MyColors.mutedGrey),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => audioProvider.shufflePlay(songs),
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
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_for_offline),
                        color: isDark ? Colors.white : MyColors.darkText,
                        iconSize: 28,
                        onPressed: () {
                          final downloadProvider = context.read<DownloadProvider>();
                          int count = 0;
                          for (final song in songs) {
                            final songId = (song['id'] ?? song['_id'] ?? '').toString();
                            if (!downloadProvider.isDownloaded(songId) && !downloadProvider.isDownloading(songId)) {
                              downloadProvider.startDownload(song);
                              count++;
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(count > 0 ? 'Started downloading $count songs' : 'All songs are already downloaded'),
                              backgroundColor: count > 0 ? MyColors.greenColor : Colors.grey,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      OutlinedButton.icon(
                        onPressed: _showAddSongsSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : MyColors.darkText,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          minimumSize: const Size(80, 48),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final song = songs[index];
                final songId = (song['id'] ?? song['_id'] ?? '').toString();
                final isCurrent = audioProvider.currentSong?.id == songId;

                return SongTile(
                  image: song['image'] ?? '',
                  title: song['name'] ?? 'Unknown',
                  artist: song['artist'] ?? 'Unknown',
                  isCurrent: isCurrent,
                  isPlaying: audioProvider.isPlaying,
                  song: song,
                  showDownload: true,
                  onTap: () => audioProvider.playSong(song, songs),
                  onRemove: () async {
                    final success = await ApiService.removeSongFromPlaylist(widget.playlistId, songId);
                    if (success) {
                      await _loadDetails();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed "${song['name']}" from playlist'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    }
                  },
                );
              },
              childCount: songs.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
