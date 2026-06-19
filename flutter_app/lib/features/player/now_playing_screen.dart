import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/now_playing_animation.dart';
import 'queue_screen.dart';
import '../../services/api_service.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context);
    final song = audioProvider.currentSong;

    if (song == null) {
      return const Scaffold(
        body: Center(child: Text('Nothing playing')),
      );
    }

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

    final isPlaying = audioProvider.isPlaying;
    final shuffleMode = audioProvider.playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeatMode = audioProvider.playbackState?.repeatMode;

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
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_down, size: 32, color: iconColor),
                      onPressed: () => Navigator.pop(context),
                    ),
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
                    const SizedBox(width: 48), // To balance the back button
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
                              color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
                              blurRadius: 48,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ApiService.getImageUrl(song.artUri?.toString()),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: MyColors.cardColor,
                              child: const Icon(Icons.music_note, size: 100, color: Colors.white24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isPlaying)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: NowPlayingAnimation(
                          isPlaying: isPlaying,
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
                            song.artist ?? 'Unknown Artist',
                            style: AppTextStyles.nowPlayingArtist(color: secondaryTextColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        audioProvider.isLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                        size: 26,
                        color: audioProvider.isLiked(song.id) ? MyColors.greenColor : iconColor,
                      ),
                      onPressed: () => audioProvider.toggleLike(song.id),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Seek Bar ───────────────────────────────────────────
                StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
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
                            overlayColor: isDark ? Colors.white24 : MyColors.greenColor.withOpacity(0.12),
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                            max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
                            onChanged: (val) => audioProvider.seek(Duration(seconds: val.toInt())),
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
                        color: shuffleMode ? MyColors.greenBright : iconMutedColor,
                      ),
                      onPressed: () {
                        audioProvider.setShuffleMode(shuffleMode ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all);
                      },
                    ),
                    // Previous
                    IconButton(
                      icon: Icon(Icons.skip_previous, size: 38, color: iconColor),
                      onPressed: () => audioProvider.skipToPrevious(),
                    ),
                    // Play / Pause — large circle
                    GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          audioProvider.pause();
                        } else {
                          audioProvider.play();
                        }
                      },
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: playBtnBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: playBtnIconColor,
                          size: 34,
                        ),
                      ),
                    ),
                    // Next
                    IconButton(
                      icon: Icon(Icons.skip_next, size: 38, color: iconColor),
                      onPressed: () => audioProvider.skipToNext(),
                    ),
                    // Repeat
                    IconButton(
                      icon: Icon(
                        repeatMode == AudioServiceRepeatMode.one ? Icons.repeat_one : Icons.repeat,
                        size: 22,
                        color: repeatMode == AudioServiceRepeatMode.none || repeatMode == null
                            ? iconMutedColor
                            : MyColors.greenBright,
                      ),
                      onPressed: () {
                        final newMode = repeatMode == AudioServiceRepeatMode.none
                            ? AudioServiceRepeatMode.all
                            : repeatMode == AudioServiceRepeatMode.all
                                ? AudioServiceRepeatMode.one
                                : AudioServiceRepeatMode.none;
                        audioProvider.setRepeatMode(newMode);
                      },
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
                      onPressed: () => _showSleepTimerPicker(context, audioProvider),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSleepTimerPicker(BuildContext context, AudioProvider audioProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final minutesList = [5, 15, 30, 60, 0];
        final labels = ['5 minutes', '15 minutes', '30 minutes', '1 hour', 'Off'];
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'Stop audio in...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            ...List.generate(minutesList.length, (index) {
              final minutes = minutesList[index];
              final label = labels[index];
              final isSelected = audioProvider.sleepTimerMinutes == minutes;
              
              return ListTile(
                title: Text(label, style: const TextStyle(color: Colors.white)),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  audioProvider.setSleepTimer(minutes);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(minutes > 0 ? 'Sleep timer set for $label' : 'Sleep timer turned off'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
