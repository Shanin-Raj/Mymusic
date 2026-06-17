import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:sonic_vault_flutter/services/api_service.dart';
import 'package:sonic_vault_flutter/providers/player_provider.dart';
import 'package:sonic_vault_flutter/providers/playlist_provider.dart';
import 'package:sonic_vault_flutter/providers/theme_provider.dart';
import 'package:sonic_vault_flutter/screens/settings_screen.dart';
import 'package:sonic_vault_flutter/screens/share_room_screen.dart';
import 'package:sonic_vault_flutter/screens/queue_screen.dart';
import 'package:sonic_vault_flutter/screens/album_detail_screen.dart';
import 'package:sonic_vault_flutter/screens/artist_detail_screen.dart';
import 'package:sonic_vault_flutter/widgets/now_playing_animation.dart';
import 'package:sonic_vault_flutter/services/storage_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:sonic_vault_flutter/clone_widgets/constants.dart';
import 'package:sonic_vault_flutter/clone_widgets/recent_plays_chip.dart';
import 'package:sonic_vault_flutter/clone_widgets/mix_card.dart';
import 'package:sonic_vault_flutter/clone_widgets/search_box.dart';
import 'package:sonic_vault_flutter/clone_widgets/song_tile.dart';
import 'package:sonic_vault_flutter/clone_widgets/library_options_list.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SHELL
// ─────────────────────────────────────────────────────────────────────────────
class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  static const List<Widget> _screens = [
    HomeView(),
    SearchView(),
    LibraryView(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        debugPrint('🔔 Requesting notification permission...');
        await Permission.notification.request();
      }
    } catch (e) {
      debugPrint('🚨 Error requesting notification permission: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? MyColors.blackColor.withValues(alpha: 0.97) : MyColors.offWhite,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: isDark ? MyColors.blackColor : MyColors.offWhite,
        body: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _screens,
              ),
            ),
            // MiniPlayer sits just above the bottom nav
            const MiniPlayer(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          selectedIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAVIGATION — Figma style
// ─────────────────────────────────────────────────────────────────────────────
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.selectedIndex, required this.onTap});
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.blackColor : MyColors.offWhite;
    final selectedColor = isDark ? Colors.white : MyColors.darkText;
    final unselectedColor = isDark ? const Color(0xFF535353) : const Color(0xFFAAAAAA);

    final items = [
      (icon: Icons.home_filled,    label: 'Home'),
      (icon: Icons.search_rounded, label: 'Search'),
      (icon: Icons.library_music,  label: 'Your Library'),
    ];

    return Container(
      color: bg,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == selectedIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        items[i].icon,
                        size: 24,
                        color: selected ? selectedColor : unselectedColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].label,
                      style: AppTextStyles.navLabel(
                        color: selected ? selectedColor : unselectedColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME VIEW
// ─────────────────────────────────────────────────────────────────────────────
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final player = context.watch<PlayerProvider>();
    final bg = isDark ? MyColors.blackColor : MyColors.offWhite;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── App bar with greeting + settings / theme toggle ──────────────
          SliverAppBar(
            backgroundColor: bg,
            elevation: 0,
            floating: true,
            snap: true,
            titleSpacing: 16,
            toolbarHeight: 56,
            title: FutureBuilder<List<dynamic>>(
              future: ApiService.fetchSongs(),
              builder: (context, _) {
                final hour = DateTime.now().hour;
                String greeting = 'Good morning';
                if (hour >= 12 && hour < 17) greeting = 'Good afternoon';
                if (hour >= 17 || hour < 5)  greeting = 'Good evening';
                return Text(
                  greeting,
                  style: AppTextStyles.greeting(
                    color: isDark ? Colors.white : MyColors.darkText,
                  ),
                );
              },
            ),
            actions: [
              // Theme toggle
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: isDark ? Colors.white : MyColors.darkText,
                  size: 22,
                ),
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              ),
              IconButton(
                icon: Icon(
                  Icons.group_outlined,
                  color: isDark ? Colors.white : MyColors.darkText,
                  size: 22,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShareRoomScreen()),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDark ? Colors.white : MyColors.darkText,
                  size: 22,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          // ── Content ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<List<dynamic>>(
              future: ApiService.fetchSongs(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final allSongs = snapshot.data ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Recently Played — 2×3 chip grid ─────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Recently played',
                        style: AppTextStyles.sectionHeader(
                          color: isDark ? Colors.white : MyColors.darkText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3.0,
                        ),
                        itemCount: allSongs.length > 6 ? 6 : allSongs.length,
                        itemBuilder: (context, index) {
                          final song = allSongs[index];
                          final isCurrent = player.currentSong?.id == song['id'].toString();
                          return RecentPlaysChip(
                            image: song['image'] ?? '',
                            title: song['name'] ?? '',
                            isCurrent: isCurrent,
                            onTap: () => context.read<PlayerProvider>().playSong(song, allSongs),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Your 2021 in Review — horizontal scroll ──────────
                    _SectionCarousel(
                      title: 'Your Favourites',
                      tag: '#LMWRAPPED',
                      songs: allSongs.take(5).toList(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),

                    // ── Editor's Picks — horizontal scroll ───────────────
                    _SectionCarousel(
                      title: "Editor's picks",
                      songs: allSongs.skip(5).take(5).toList(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 28),

                    // ── Chill Mix ────────────────────────────────────────
                    _SectionCarousel(
                      title: 'Chill Mix',
                      songs: allSongs.skip(3).take(5).toList(),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Section header + horizontal MixCard carousel
class _SectionCarousel extends StatelessWidget {
  const _SectionCarousel({
    required this.title,
    required this.songs,
    required this.isDark,
    this.tag,
  });

  final String title;
  final String? tag;
  final List<dynamic> songs;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) return const SizedBox.shrink();
    final player = context.watch<PlayerProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tag != null)
                Text(
                  tag!,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: MyColors.mutedGrey,
                    letterSpacing: 1,
                  ),
                ),
              Text(
                title,
                style: AppTextStyles.sectionHeader(
                  color: isDark ? Colors.white : MyColors.darkText,
                ).copyWith(fontSize: tag != null ? 22 : 19),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isCurrent = player.currentSong?.id == song['id'].toString();
              return MixCard(
                image: song['image'] ?? '',
                title: song['name'] ?? '',
                subtitle: song['artist'],
                isCurrent: isCurrent,
                onTap: () => context.read<PlayerProvider>().playSong(song, songs),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH VIEW
// ─────────────────────────────────────────────────────────────────────────────
class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allSongs = [];
  List<dynamic> _filteredSongs = [];
  List<String> _recentSearchIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    try {
      final songs = await ApiService.fetchSongs();
      final recents = await StorageService.getRecentSearches();
      setState(() {
        _allSongs = songs;
        _filteredSongs = songs;
        _recentSearchIds = recents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredSongs = _allSongs.where((song) {
        final name   = (song['name'] ?? '').toString().toLowerCase();
        final artist = (song['artist'] ?? '').toString().toLowerCase();
        final q = query.toLowerCase();
        return name.contains(q) || artist.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final player  = context.watch<PlayerProvider>();
    final hasQuery = _searchController.text.isNotEmpty;
    final bg = isDark ? MyColors.surfaceDark : MyColors.offWhite;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Figma: title "Search" above search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                'Search',
                style: AppTextStyles.greeting(
                  color: isDark ? Colors.white : MyColors.darkText,
                ),
              ),
            ),
            // Search bar
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
            // Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasQuery
                      ? ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            final isCurrent = player.currentSong?.id == song['id'].toString();
                            return SongTile(
                              image: song['image'] ?? '',
                              title: song['name'] ?? 'Unknown',
                              artist: song['artist'] ?? 'Unknown',
                              isCurrent: isCurrent,
                              isPlaying: player.isPlaying,
                              song: song,
                              onTap: () async {
                                await StorageService.addRecentSearch(song['id'].toString());
                                final recents = await StorageService.getRecentSearches();
                                if (mounted) {
                                  setState(() {
                                    _recentSearchIds = recents;
                                  });
                                }
                                if (context.mounted) {
                                  context.read<PlayerProvider>().playSong(song, _filteredSongs);
                                }
                              },
                            );
                          },
                        )
                      : _buildRecentSearches(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(BuildContext context, bool isDark) {
    final titleColor = isDark ? Colors.white : MyColors.darkText;
    final subColor   = isDark ? MyColors.lightGrey : MyColors.mutedGrey;

    // Filter _allSongs to find the songs that are in _recentSearchIds
    final recentSongs = _recentSearchIds.map((id) {
      return _allSongs.firstWhere(
        (song) => song['id'].toString() == id,
        orElse: () => null,
      );
    }).where((song) => song != null).toList();

    // Browse categories from Figma
    final categories = [
      {'title': 'Music',        'color': const Color(0xFFE91429)},
      {'title': 'Live Events',  'color': const Color(0xFF8400E7)},
      {'title': 'Made For You', 'color': const Color(0xFF1E3264)},
      {'title': 'New Releases', 'color': const Color(0xFFE8115B)},
      {'title': 'Hindi',        'color': const Color(0xFFE13300)},
      {'title': 'Punjabi',      'color': const Color(0xFF1F883D)},
      {'title': 'Tamil',        'color': const Color(0xFFBA5D07)},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches header (only if there are recent searches!)
          if (recentSongs.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Recent searches',
                style: AppTextStyles.sectionHeader(color: titleColor),
              ),
            ),
            ...recentSongs.map((song) => ListTile(
              leading: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: song['image'] ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: MyColors.cardColor),
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
                  await StorageService.removeRecentSearch(song['id'].toString());
                  final recents = await StorageService.getRecentSearches();
                  setState(() {
                    _recentSearchIds = recents;
                  });
                },
              ),
              onTap: () => context.read<PlayerProvider>().playSong(song, _allSongs),
            )),
            const SizedBox(height: 24),
          ],
          // Browse grid
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              'Start browsing',
              style: AppTextStyles.sectionHeader(color: titleColor),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: cat['color'] as Color,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    cat['title'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIBRARY VIEW
// ─────────────────────────────────────────────────────────────────────────────
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  String? _selectedFilter;

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    String? selectedImageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: MyColors.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(
              'New Playlist',
              style: AppTextStyles.bodyBold(),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter playlist name',
                      hintStyle: AppTextStyles.cardSubtitle(),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: MyColors.greenColor)),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Select Cover Image (Optional)',
                    style: AppTextStyles.bodyBold().copyWith(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: FutureBuilder<List<String>>(
                      future: ApiService.fetchAvailableImages(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: MyColors.greenColor));
                        }
                        final images = snapshot.data ?? [];
                        if (images.isEmpty) {
                          return const Center(child: Text('No custom cover images', style: TextStyle(color: Colors.white54, fontSize: 12)));
                        }
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: images.length,
                          itemBuilder: (context, index) {
                            final imageUrl = images[index];
                            final isSelected = selectedImageUrl == imageUrl;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedImageUrl = null;
                                  } else {
                                    selectedImageUrl = imageUrl;
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? MyColors.greenColor : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.white12),
                                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white24),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.cardSubtitle(color: Colors.white70)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    final nav = Navigator.of(context);
                    await context.read<PlaylistProvider>().createPlaylist(
                      controller.text,
                      image: selectedImageUrl,
                    );
                    nav.pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.greenColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text('Create', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
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
                  _showPlaylistOptionDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: MyColors.greenColor),
                title: const Text('Artist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View and navigate your artists list', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showArtistsOptionDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.album, color: MyColors.greenColor),
                title: const Text('Album', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('View and navigate your albums list', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showAlbumsOptionDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }



  void _showPlaylistOptionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                    child: Text('Playlists', style: AppTextStyles.bodyBold(color: Colors.white).copyWith(fontSize: 18)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add, color: MyColors.greenColor),
                    title: const Text('Create New Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      _showCreatePlaylistDialog();
                    },
                  ),
                  const Divider(color: Colors.white10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final pl = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.playlist_play, color: Colors.white70),
                          title: Text(pl['name'] ?? 'Playlist', style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailScreen(playlistId: pl['id'].toString()),
                              ),
                            );
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

  void _showArtistsOptionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService.fetchSongs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final songs = snapshot.data ?? [];
            final Set<String> artistSet = {};
            for (var song in songs) {
              final artistStr = song['artist'] as String?;
              if (artistStr != null) {
                final parts = artistStr.split(',');
                for (var part in parts) {
                  final clean = part.trim();
                  if (clean.isNotEmpty) artistSet.add(clean);
                }
              }
            }
            final sortedArtists = artistSet.toList()..sort();

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
                    child: Text('Artists', style: AppTextStyles.bodyBold(color: Colors.white).copyWith(fontSize: 18)),
                  ),
                  Expanded(
                    child: sortedArtists.isEmpty
                        ? const Center(child: Text('No artists available', style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: sortedArtists.length,
                            itemBuilder: (context, index) {
                              final artist = sortedArtists[index];
                              return ListTile(
                                leading: const Icon(Icons.person, color: Colors.white70),
                                title: Text(artist, style: const TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ArtistDetailScreen(artistName: artist),
                                    ),
                                  );
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

  void _showAlbumsOptionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: MyColors.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: ApiService.fetchSongs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final songs = snapshot.data ?? [];
            final Set<String> albumSet = {};
            final Map<String, String> albumImages = {};
            for (var song in songs) {
              var albumStr = song['album'] as String?;
              if (albumStr == null ||
                  albumStr.trim().isEmpty ||
                  albumStr.trim() == 'Unknown Album' ||
                  albumStr.trim() == 'Synced Addition') {
                albumStr = 'Spotify Songs';
              }
              final clean = albumStr.trim();
              albumSet.add(clean);
              if (!albumImages.containsKey(clean) || albumImages[clean]!.isEmpty) {
                albumImages[clean] = song['image'] ?? '';
              }
            }
            final sortedAlbums = albumSet.toList()..sort();

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
                    child: Text('Albums', style: AppTextStyles.bodyBold(color: Colors.white).copyWith(fontSize: 18)),
                  ),
                  Expanded(
                    child: sortedAlbums.isEmpty
                        ? const Center(child: Text('No albums available', style: TextStyle(color: Colors.white70)))
                        : ListView.builder(
                            itemCount: sortedAlbums.length,
                            itemBuilder: (context, index) {
                              final album = sortedAlbums[index];
                              final imageUrl = albumImages[album] ?? '';
                              return ListTile(
                                leading: const Icon(Icons.album, color: Colors.white70),
                                title: Text(album, style: const TextStyle(color: Colors.white)),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AlbumDetailScreen(
                                        albumName: album,
                                        imageUrl: imageUrl,
                                      ),
                                    ),
                                  );
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
    final bg = isDark ? MyColors.surfaceDark : MyColors.offWhite;
    final titleColor = isDark ? Colors.white : MyColors.darkText;

    String appBarTitle = 'Your Library';
    if (_selectedFilter == 'Playlists') appBarTitle = 'Your Playlists';
    if (_selectedFilter == 'Artists') appBarTitle = 'Your Artists';
    if (_selectedFilter == 'Albums') appBarTitle = 'Your Albums';
    if (_selectedFilter == 'Liked Songs') appBarTitle = 'Liked Songs';

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Pinned app bar (Figma: "Your Library" bold)
          SliverAppBar(
            pinned: true,
            backgroundColor: bg,
            elevation: 0,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Text(
                appBarTitle,
                style: AppTextStyles.sectionHeader(color: titleColor).copyWith(fontSize: 22),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: titleColor),
                tooltip: 'Refresh Library',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final playlistProvider = context.read<PlaylistProvider>();
                  
                  await ApiService.fetchSongs(forceRefresh: true);
                  await playlistProvider.loadPlaylists();
                  
                  if (mounted) {
                    setState(() {});
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Vault cache refreshed successfully!'),
                        duration: Duration(seconds: 1),
                        backgroundColor: MyColors.cardColor,
                      ),
                    );
                  }
                },
              ),
              if (_selectedFilter == null)
                IconButton(
                  icon: Icon(Icons.add, color: titleColor),
                  onPressed: _showLibraryAddBottomSheet,
                )
              else if (_selectedFilter == 'Playlists')
                IconButton(
                  icon: Icon(Icons.add, color: titleColor),
                  onPressed: _showCreatePlaylistDialog,
                ),
            ],
          ),
          // Filter chips row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: LibraryOptionsList(
                selectedFilter: _selectedFilter,
                onFilterSelected: (val) => setState(() => _selectedFilter = val),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),
          if (_selectedFilter == 'Playlists')
            const PlaylistGridSliver()
          else if (_selectedFilter == 'Artists')
            const ArtistListSliver()
          else if (_selectedFilter == 'Albums')
            const AlbumListSliver()
          else if (_selectedFilter == 'Liked Songs')
            const LikedSongListSliver()
          else
            const SongListSliver(),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SONG LIST SLIVER (Library → Songs tab)
// ─────────────────────────────────────────────────────────────────────────────
class SongListSliver extends StatelessWidget {
  const SongListSliver({super.key});



  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return FutureBuilder<List<dynamic>>(
      future: ApiService.fetchSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SliverFillRemaining(
            child: Center(child: Text('Error loading songs')),
          );
        }
        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: Text('Your vault is empty.')),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            // Shuffle play button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ElevatedButton.icon(
                  onPressed: () => context.read<PlayerProvider>().shufflePlay(songs),
                  icon: const Icon(Icons.shuffle, size: 20),
                  label: Text(
                    'SHUFFLE PLAY',
                    style: GoogleFonts.nunito(
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
            // Song tiles
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  final isCurrent = player.currentSong?.id == song['id'].toString();

                  return Dismissible(
                    key: Key(song['id'].toString()),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: MyColors.cardColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          title: Text('Delete Track', style: AppTextStyles.bodyBold()),
                          content: Text(
                            'Delete "${song['name']}" from your vault?',
                            style: AppTextStyles.cardSubtitle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                            ),
                          ],
                        ),
                      );
                    },
                    background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      final success = await ApiService.deleteSong(song['id'].toString());
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Failed to delete song')),
                        );
                      }
                    },
                    child: SongTile(
                      image: song['image'] ?? '',
                      title: song['name'] ?? 'Unknown',
                      artist: song['artist'] ?? 'Unknown',
                      isCurrent: isCurrent,
                      isPlaying: player.isPlaying,
                      song: song,
                      onTap: () => context.read<PlayerProvider>().playSong(song, songs),
                    ),
                  );
                },
                childCount: songs.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIKED SONG LIST SLIVER (Library → Liked Songs tab)
// ─────────────────────────────────────────────────────────────────────────────
class LikedSongListSliver extends StatelessWidget {
  const LikedSongListSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return FutureBuilder<List<dynamic>>(
      future: ApiService.fetchSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: MyColors.greenColor)),
          );
        }
        if (snapshot.hasError) {
          return const SliverFillRemaining(
            child: Center(child: Text('Error loading liked songs', style: TextStyle(color: Colors.white))),
          );
        }
        
        final allSongs = snapshot.data ?? [];
        final likedSongs = allSongs.where((song) => player.isLiked(song['id'].toString())).toList();

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
            // Shuffle play button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ElevatedButton.icon(
                  onPressed: () => context.read<PlayerProvider>().shufflePlay(likedSongs),
                  icon: const Icon(Icons.shuffle, size: 20),
                  label: Text(
                    'SHUFFLE PLAY LIKED',
                    style: GoogleFonts.nunito(
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
            // Song tiles for liked songs
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = likedSongs[index];
                  final isCurrent = player.currentSong?.id == song['id'].toString();

                  return SongTile(
                    image: song['image'] ?? '',
                    title: song['name'] ?? 'Unknown',
                    artist: song['artist'] ?? 'Unknown',
                    isCurrent: isCurrent,
                    isPlaying: player.isPlaying,
                    song: song,
                    showHeart: true,
                    onTap: () => context.read<PlayerProvider>().playSong(song, likedSongs),
                  );
                },
                childCount: likedSongs.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST GRID SLIVER
// ─────────────────────────────────────────────────────────────────────────────
class PlaylistGridSliver extends StatelessWidget {
  const PlaylistGridSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        if (playlistProvider.isLoading && playlistProvider.playlists.isEmpty) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final playlists = playlistProvider.playlists;

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
                final playlist = playlists[index];
                final plImage = playlist['image'] as String? ?? '';
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailScreen(
                        playlistId: playlist['id'].toString(),
                      ),
                    ),
                  ),
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
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: plImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: plImage,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: MyColors.cardColor),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.playlist_play, size: 56, color: Colors.white24),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(Icons.playlist_play, size: 56, color: Colors.white24),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        playlist['name'] ?? 'Playlist',
                        style: AppTextStyles.cardTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Playlist • ${playlist['songs']?.length ?? 0} tracks',
                        style: AppTextStyles.cardSubtitle(),
                      ),
                    ],
                  ),
                );
              },
              childCount: playlists.length,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST DETAIL SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class PlaylistDetailScreen extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistProvider>().loadPlaylistDetail(widget.playlistId);
    });
  }

  void _showAddSongsSheet() async {
    final allSongs = await ApiService.fetchSongs();
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
          return Consumer<PlaylistProvider>(
            builder: (context, playlistProvider, _) {
              final detail = playlistProvider.getPlaylistDetail(widget.playlistId);
              final currentSongs = detail?['songs'] as List? ?? [];

              return Column(
                children: [
                  Container(
                    width: 36, height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Add Songs', style: AppTextStyles.bodyBold()),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: allSongs.length,
                      itemBuilder: (context, index) {
                        final song = allSongs[index];
                        final isAlreadyIn = currentSongs.any(
                          (s) => s['id'].toString() == song['id'].toString(),
                        );

                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: song['image'] ?? '',
                              width: 40, height: 40, fit: BoxFit.cover,
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
                                  await playlistProvider.addSongToPlaylist(widget.playlistId, song);
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
    final player = context.watch<PlayerProvider>();

    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, _) {
        final detail = playlistProvider.getPlaylistDetail(widget.playlistId);
        final listEntry = playlistProvider.playlists.firstWhere(
          (p) => p['id'].toString() == widget.playlistId,
          orElse: () => <String, dynamic>{},
        );
        final playlistName = detail?['name'] ?? listEntry['name'] ?? 'Playlist';
        final playlistImage = detail?['image'] ?? listEntry['image'] ?? '';
        final songs = detail?['songs'] as List? ?? [];

        // Loading spinner ONLY on initial load (i.e. no cache exists and provider is loading)
        if (playlistProvider.isLoading && detail == null) {
          return const Scaffold(
            backgroundColor: MyColors.surfaceDark,
            body: Center(
              child: CircularProgressIndicator(color: MyColors.greenColor),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDark ? MyColors.surfaceDark : MyColors.offWhite,
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
          body: CustomScrollView(
            slivers: [
              // ── Collapsing Premium Collapsed Figma Header ───────────────────
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
                    icon: Icon(Icons.delete_outline, color: isDark ? Colors.redAccent : Colors.red),
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
                        final success = await context.read<PlaylistProvider>().deletePlaylist(widget.playlistId);
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
                    onPressed: () => playlistProvider.loadPlaylistDetail(widget.playlistId),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  centerTitle: true,
                  title: LayoutBuilder(
                    builder: (context, constraints) {
                      final top = constraints.biggest.height;
                      // Show title only when mostly collapsed
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
                          // Large Artwork container
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: playlistImage.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: playlistImage,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(color: MyColors.cardColor),
                                      errorWidget: (_, __, ___) => Container(
                                        color: MyColors.cardColor,
                                        child: const Icon(Icons.playlist_play, size: 72, color: Colors.white24),
                                      ),
                                    )
                                  : Container(
                                      color: MyColors.cardColor,
                                      child: const Icon(Icons.playlist_play, size: 72, color: Colors.white24),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Playlist Name text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              playlistName,
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : MyColors.darkText,
                                letterSpacing: -0.6,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Caption info
                          Text(
                            'Playlist • ${songs.length} tracks',
                            style: AppTextStyles.cardSubtitle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Control Bar Sliver (Creator and Play button) ────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: MyColors.greenColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.playlist_play, size: 12, color: Colors.black),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vault Creator',
                                  style: AppTextStyles.bodyBold(
                                    color: isDark ? Colors.white : MyColors.darkText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${songs.length} songs • Dynamic Playlist Vault',
                              style: AppTextStyles.caption(
                                color: isDark ? MyColors.lightGrey : MyColors.mutedGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Large circular Play/Shuffle Action button
                      GestureDetector(
                        onTap: songs.isNotEmpty
                            ? () => context.read<PlayerProvider>().shufflePlay(songs)
                            : null,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: songs.isNotEmpty ? MyColors.greenColor : Colors.grey.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: MyColors.greenColor.withValues(alpha: isDark ? 0.3 : 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Find / Search & Sort bar simulation ────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? MyColors.cardColor : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Icon(Icons.search, size: 18, color: isDark ? Colors.white54 : Colors.black45),
                              const SizedBox(width: 8),
                              Text(
                                'Find in playlist',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.black45,
                                  fontSize: 14,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? MyColors.cardColor : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Sort',
                            style: AppTextStyles.cardTitle(
                              color: isDark ? Colors.white : MyColors.darkText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Background subtle loader when refreshing in background
              if (playlistProvider.isLoading)
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 2,
                    child: LinearProgressIndicator(color: MyColors.greenColor, backgroundColor: Colors.transparent),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Songs List ──────────────────────────────────────────────────
              if (songs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 90),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.playlist_add, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            'Your playlist is empty.',
                            style: AppTextStyles.bodyBold(color: isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddSongsSheet,
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: const Text('ADD SONGS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.greenColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = songs[index];
                      final isCurrent = player.currentSong?.id == song['id'].toString();

                      return Dismissible(
                        key: Key('pl-song-${widget.playlistId}-${song['id']}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: MyColors.cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              title: const Text('Remove Song', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              content: Text('Remove "${song['name']}" from this playlist? It will still exist in your library.', style: const TextStyle(color: Colors.white70)),
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
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await playlistProvider.removeSongFromPlaylist(widget.playlistId, song['id'].toString());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('"${song['name']}" removed from playlist')),
                            );
                          }
                        },
                        child: SongTile(
                          image: song['image'] ?? '',
                          title: song['name'] ?? 'Unknown',
                          artist: song['artist'] ?? 'Unknown',
                          isCurrent: isCurrent,
                          isPlaying: player.isPlaying,
                          song: song,
                          onTap: () => context.read<PlayerProvider>().playSong(song, songs),
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),

              // Add Songs trigger at bottom
              if (songs.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 90),
                    child: OutlinedButton.icon(
                      onPressed: _showAddSongsSheet,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Songs'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MyColors.greenColor,
                        side: const BorderSide(color: MyColors.greenColor),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINI PLAYER — Figma style
// ─────────────────────────────────────────────────────────────────────────────
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song   = player.currentSong;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (song == null) return const SizedBox.shrink();

    final bg = isDark ? MyColors.cardColor : Colors.white;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FullScreenPlayer()),
      ),
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
                    child: CachedNetworkImage(
                      imageUrl: song.artUri?.toString() ?? '',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: MyColors.cardColor),
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
                          song.artist ?? '',
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
                      player.isLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                      color: player.isLiked(song.id) ? MyColors.greenColor : (isDark ? Colors.white : MyColors.darkText),
                      size: 22,
                    ),
                    onPressed: () => player.toggleLike(song.id),
                  ),
                  // Play/Pause button
                  IconButton(
                    icon: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: isDark ? Colors.white : MyColors.darkText,
                      size: 28,
                    ),
                    onPressed: () => player.togglePlay(),
                  ),
                ],
              ),
            ),
            // Progress bar
            StreamBuilder<Duration>(
              stream: player.positionStream,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FULL SCREEN PLAYER — Figma "Now Playing" style
// ─────────────────────────────────────────────────────────────────────────────
class FullScreenPlayer extends StatelessWidget {
  const FullScreenPlayer({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    final song   = player.currentSong;

    if (song == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : MyColors.offWhite;
    final primaryTextColor = isDark ? Colors.white : MyColors.darkText;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black87;
    final tertiaryTextColor = isDark ? Colors.white38 : Colors.black45;
    final iconColor = isDark ? Colors.white : MyColors.darkText;
    final iconMutedColor = isDark ? Colors.white54 : Colors.black54;
    final iconDimmedColor = isDark ? Colors.white38 : Colors.black38;
    
    final playBtnBg = isDark ? Colors.white : MyColors.darkText;
    final playBtnIconColor = isDark ? Colors.black : Colors.white;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // ── Header row ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Drag down / close
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down, size: 32, color: iconColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // Centre — playing from context
                      Column(
                        children: [
                          Text(
                            'PLAYING FROM VAULT',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Discovery',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: iconColor),
                        onPressed: () {},
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── Album Artwork ──────────────────────────────────────
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                                blurRadius: 48,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: song.artUri?.toString() ?? '',
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: MyColors.cardColor),
                            ),
                          ),
                        ),
                      ),
                      if (player.isPlaying)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: NowPlayingAnimation(
                            isPlaying: player.isPlaying,
                            size: 36,
                            color: isDark ? Colors.white : MyColors.greenColor,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // ── Title + Artist + Like ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: AppTextStyles.nowPlayingTitle(color: primaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist ?? '',
                              style: AppTextStyles.nowPlayingArtist(color: secondaryTextColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          player.isLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                          size: 26,
                          color: player.isLiked(song.id) ? MyColors.greenColor : iconColor,
                        ),
                        onPressed: () => player.toggleLike(song.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Seek Bar ───────────────────────────────────────────
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? player.position;
                      final duration = song.duration ?? const Duration(seconds: 1);

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: isDark ? Colors.white : MyColors.greenColor,
                              inactiveTrackColor: isDark ? Colors.white24 : Colors.black12,
                              thumbColor: isDark ? Colors.white : MyColors.greenColor,
                              overlayColor: isDark ? Colors.white24 : MyColors.greenColor.withValues(alpha: 0.12),
                            ),
                            child: Slider(
                              value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                              max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                              onChanged: (val) => player.seek(Duration(seconds: val.toInt())),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: GoogleFonts.nunito(fontSize: 12, color: tertiaryTextColor),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: GoogleFonts.nunito(fontSize: 12, color: tertiaryTextColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Transport Controls ─────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          size: 22,
                          color: player.playbackState.shuffleMode == AudioServiceShuffleMode.all
                              ? MyColors.greenBright
                              : iconMutedColor,
                        ),
                        onPressed: () => player.toggleShuffle(),
                      ),
                      // Previous
                      IconButton(
                        icon: Icon(Icons.skip_previous, size: 38, color: iconColor),
                        onPressed: () => player.skipToPrevious(),
                      ),
                      // Play / Pause — large circle
                      GestureDetector(
                        onTap: () => player.togglePlay(),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: playBtnBg,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: playBtnIconColor,
                            size: 34,
                          ),
                        ),
                      ),
                      // Next
                      IconButton(
                        icon: Icon(Icons.skip_next, size: 38, color: iconColor),
                        onPressed: () => player.skipToNext(),
                      ),
                      // Repeat
                      IconButton(
                        icon: Icon(
                          player.playbackState.repeatMode == AudioServiceRepeatMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          size: 22,
                          color: player.playbackState.repeatMode == AudioServiceRepeatMode.none
                              ? iconMutedColor
                              : MyColors.greenBright,
                        ),
                        onPressed: () => player.toggleRepeat(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Bottom row — timer + queue ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.timer_outlined, color: iconDimmedColor, size: 22),
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.queue_music, color: iconDimmedColor, size: 22),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const QueueScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ARTIST LIST SLIVER
// ─────────────────────────────────────────────────────────────────────────────
class ArtistListSliver extends StatelessWidget {
  const ArtistListSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : MyColors.darkText;

    return FutureBuilder<List<dynamic>>(
      future: ApiService.fetchSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SliverFillRemaining(
            child: Center(child: Text('Error loading artists')),
          );
        }
        final songs = snapshot.data ?? [];
        
        // Extract unique cleaned artists
        final Set<String> artistSet = {};
        final Map<String, String> artistImages = {};

        for (var song in songs) {
          final artistStr = song['artist'] as String?;
          if (artistStr != null) {
            final parts = artistStr.split(',');
            for (var part in parts) {
              final clean = part.replaceAll('', '').trim();
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
                    child: CachedNetworkImage(
                      imageUrl: image,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: MyColors.cardColor),
                    ),
                  ),
                  title: Text(
                    artistName,
                    style: AppTextStyles.bodyBold(color: titleColor),
                  ),
                  subtitle: Text(
                    'Artist',
                    style: AppTextStyles.cardSubtitle(color: isDark ? MyColors.lightGrey : MyColors.mutedGrey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artistName: artistName),
                      ),
                    );
                  },
                );
              },
              childCount: sortedArtists.length,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALBUM LIST SLIVER
// ─────────────────────────────────────────────────────────────────────────────
class AlbumListSliver extends StatelessWidget {
  const AlbumListSliver({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : MyColors.darkText;

    return FutureBuilder<List<dynamic>>(
      future: ApiService.fetchSongs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const SliverFillRemaining(
            child: Center(child: Text('Error loading albums')),
          );
        }
        final songs = snapshot.data ?? [];

        // Extract unique albums
        final Set<String> albumSet = {};
        final Map<String, String> albumImages = {};
        final Map<String, String> albumArtists = {};

        for (var song in songs) {
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
          if (!albumArtists.containsKey(cleanAlbum)) {
            albumArtists[cleanAlbum] = (song['artist'] as String?)?.replaceAll('', '').trim() ?? 'Spotify Scrapes';
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
                final assetPath = (index % 2 == 0) ? 'assets/vinyl.jpg' : 'assets/cassette.jpg';

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
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: albumImage.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: albumImage,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: MyColors.cardColor),
                                    errorWidget: (_, __, ___) => Image.asset(
                                      assetPath,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    assetPath,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        albumName,
                        style: AppTextStyles.cardTitle(color: titleColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
              childCount: sortedAlbums.length,
            ),
          ),
        );
      },
    );
  }
}



