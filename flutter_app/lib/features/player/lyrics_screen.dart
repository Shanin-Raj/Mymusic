import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/lyrics_model.dart';
import '../../providers/audio_provider.dart';
import '../../services/api_service.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _userIsScrolling = false;
  Timer? _userScrollTimer;
  int _lastAutoScrolledIndex = -1;

  @override
  void initState() {
    super.initState();
    // Pre-fetch lyrics if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      if (audioProvider.currentLyrics == null && !audioProvider.isLoadingLyrics) {
        audioProvider.fetchLyricsForCurrentSong();
      }
    });
  }

  @override
  void dispose() {
    _userScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onUserScrollStart() {
    _userIsScrolling = true;
    _userScrollTimer?.cancel();
    _userScrollTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _userIsScrolling = false;
        });
        _scrollToActiveLine();
      }
    });
  }

  void _scrollToActiveLine() {
    if (_userIsScrolling || !mounted) return;
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final activeIndex = audioProvider.activeLyricIndex;
    final lyrics = audioProvider.currentLyrics;

    if (lyrics == null || !lyrics.hasSynced || activeIndex < 0 || activeIndex >= lyrics.lines.length) {
      return;
    }

    if (activeIndex == _lastAutoScrolledIndex) return;
    _lastAutoScrolledIndex = activeIndex;

    // Calculate approximate position or scroll smoothly
    if (_scrollController.hasClients) {
      final itemHeight = 70.0;
      final screenHeight = MediaQuery.of(context).size.height;
      final targetOffset = (activeIndex * itemHeight) - (screenHeight * 0.35);
      final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;
    final lyrics = audioProvider.currentLyrics;
    final isLoading = audioProvider.isLoadingLyrics;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (song == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('No song playing', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    // Auto-scroll when active index changes and user isn't actively scrolling
    if (lyrics != null && lyrics.hasSynced && !_userIsScrolling) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveLine());
    }

    final imageUrl = ApiService.getImageUrl(song.artUri?.toString());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F12),
        body: Stack(
          children: [
            // ── 1. Blurred Background Artwork Reflection ────────────────
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(color: const Color(0xFF141418)),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  color: Colors.black.withValues(alpha: isDark ? 0.78 : 0.70),
                ),
              ),
            ),

            // ── 2. Main Content ─────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                song.title,
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                song.artist ?? 'Unknown Artist',
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: Colors.white60,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (lyrics != null && lyrics.hasSynced)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MyColors.greenColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: MyColors.greenColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.sync, color: MyColors.greenBright, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'SYNCED',
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: MyColors.greenBright,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                          tooltip: 'Refresh Lyrics',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            audioProvider.fetchLyricsForCurrentSong(forceRefresh: true);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Divider
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),

                  // Body Area
                  Expanded(
                    child: _buildLyricsContent(context, audioProvider, lyrics, isLoading),
                  ),

                  // Mini Player Transport at bottom
                  _buildBottomControls(context, audioProvider, song),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsContent(
    BuildContext context,
    AudioProvider audioProvider,
    LyricsData? lyrics,
    bool isLoading,
  ) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(MyColors.greenBright),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Fetching lyrics...',
              style: GoogleFonts.nunito(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (lyrics == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lyrics_outlined, color: Colors.white38, size: 48),
              ),
              const SizedBox(height: 18),
              Text(
                'No lyrics available',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t find time-synced lyrics for this track.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.greenColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try Again'),
                onPressed: () => audioProvider.fetchLyricsForCurrentSong(forceRefresh: true),
              ),
            ],
          ),
        ),
      );
    }

    if (lyrics.isInstrumental) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note, color: MyColors.greenBright, size: 54),
            ),
            const SizedBox(height: 20),
            Text(
              'Instrumental Track',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This song does not contain any vocal lyrics.',
              style: GoogleFonts.nunito(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // ── CASE A: Synchronized Lyrics ─────────────────────────────────────
    if (lyrics.hasSynced && lyrics.lines.isNotEmpty) {
      final activeIndex = audioProvider.activeLyricIndex;

      return NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            _onUserScrollStart();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          physics: const BouncingScrollPhysics(),
          itemCount: lyrics.lines.length,
          itemBuilder: (context, index) {
            final line = lyrics.lines[index];
            final isActive = index == activeIndex;
            final isPast = index < activeIndex;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                audioProvider.seekToLyric(line.timestamp);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  style: GoogleFonts.nunito(
                    fontSize: isActive ? 26 : 21,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    color: isActive
                        ? Colors.white
                        : (isPast
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.45)),
                    shadows: isActive
                        ? [
                            Shadow(
                              color: MyColors.greenBright.withValues(alpha: 0.6),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    line.text.isEmpty ? '♪' : line.text,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // ── CASE B: Plain (Unsynced) Lyrics ──────────────────────────────────
    if (lyrics.plainLyrics != null && lyrics.plainLyrics!.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        physics: const BouncingScrollPhysics(),
        child: Text(
          lyrics.plainLyrics!,
          style: GoogleFonts.nunito(
            fontSize: 20,
            height: 1.8,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomControls(
    BuildContext context,
    AudioProvider audioProvider,
    dynamic song,
  ) {
    final isPlaying = audioProvider.isPlaying;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: StreamBuilder<Duration>(
        stream: audioProvider.positionStream,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = song.duration ?? const Duration(seconds: 1);
          final posMs = position.inMilliseconds.toDouble();
          final durMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1000.0;
          final clampedPos = posMs.clamp(0.0, durMs).toDouble();

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress Bar
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                  activeTrackColor: MyColors.greenBright,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  value: clampedPos,
                  max: durMs,
                  onChanged: (val) => audioProvider.seek(Duration(milliseconds: val.toInt())),
                ),
              ),
              // Transport Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.white60),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                        onPressed: () => audioProvider.skipToPrevious(),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (isPlaying) {
                            audioProvider.pause();
                          } else {
                            audioProvider.play();
                          }
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                        onPressed: () => audioProvider.skipToNext(),
                      ),
                    ],
                  ),
                  Text(
                    _formatDuration(duration),
                    style: GoogleFonts.nunito(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
