import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sonic_vault_flutter/providers/room_provider.dart';
import 'package:sonic_vault_flutter/clone_widgets/constants.dart';

class ShareRoomScreen extends StatefulWidget {
  const ShareRoomScreen({super.key});

  @override
  State<ShareRoomScreen> createState() => _ShareRoomScreenState();
}

class _ShareRoomScreenState extends State<ShareRoomScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom() async {
    setState(() => _isLoading = true);
    try {
      await context.read<RoomProvider>().createRoom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create room: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleJoinRoom() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<RoomProvider>().joinRoom(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined room successfully!')),
        );
        _codeController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join room: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLeaveRoom() async {
    setState(() => _isLoading = true);
    try {
      await context.read<RoomProvider>().leaveRoom();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left room successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave room: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomProvider = context.watch<RoomProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    final bg = isDark ? MyColors.blackColor : MyColors.offWhite;
    final cardBg = isDark ? MyColors.cardColor : Colors.white;
    final textColor = isDark ? Colors.white : MyColors.darkText;
    final subTextColor = isDark ? MyColors.lightGrey : MyColors.mutedGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Listening Room',
          style: AppTextStyles.bodyBold(color: textColor).copyWith(fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  if (!roomProvider.isJoined)
                    _buildDisconnectedView(cardBg, textColor, subTextColor, theme)
                  else
                    _buildConnectedView(roomProvider, cardBg, textColor, subTextColor, theme),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(MyColors.greenColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView(
    Color cardBg,
    Color textColor,
    Color subTextColor,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.group_outlined,
                size: 80,
                color: MyColors.greenColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Sync Music Playback',
                style: AppTextStyles.sectionHeader(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Listen to songs simultaneously with your friends in real-time. Make host changes, seek, play or pause and have everyone sync instantly.',
                style: AppTextStyles.cardSubtitle(color: subTextColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons / Fields
        ElevatedButton(
          onPressed: _isLoading ? null : _handleCreateRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.greenColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 2,
          ),
          child: Text(
            'Create New Room',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(child: Divider(color: subTextColor.withValues(alpha: 0.3))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'OR JOIN EXISTING',
                style: AppTextStyles.tagLabel(color: subTextColor),
              ),
            ),
            Expanded(child: Divider(color: subTextColor.withValues(alpha: 0.3))),
          ],
        ),
        const SizedBox(height: 24),

        // Join Code Entry
        TextField(
          controller: _codeController,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          style: AppTextStyles.bodyBold(color: textColor).copyWith(
            fontSize: 18,
            letterSpacing: 2.0,
          ),
          decoration: InputDecoration(
            hintText: 'ENTER ROOM CODE',
            hintStyle: AppTextStyles.searchHint(color: subTextColor).copyWith(
              fontSize: 14,
              letterSpacing: 1.0,
            ),
            filled: true,
            fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: subTextColor.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(color: MyColors.greenColor, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleJoinRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: MyColors.greenColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: MyColors.greenColor, width: 2),
            ),
          ),
          child: Text(
            'Join Room',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedView(
    RoomProvider provider,
    Color cardBg,
    Color textColor,
    Color subTextColor,
    ThemeData theme,
  ) {
    final roomState = provider.roomState;
    final currentSongId = roomState?['currentSongId'];
    final isPlaying = roomState?['isPlaying'] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pulse & Status Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const PulseIndicator(),
              const SizedBox(height: 16),
              Text(
                'Connected to Room',
                style: AppTextStyles.cardSubtitle(color: subTextColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    provider.roomId ?? '',
                    style: AppTextStyles.greeting(color: textColor).copyWith(
                      fontSize: 32,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.copy, color: MyColors.greenColor, size: 24),
                    onPressed: () {
                      if (provider.roomId != null) {
                        Clipboard.setData(ClipboardData(text: provider.roomId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Room code copied to clipboard!')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Room Status Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROOM STATUS',
                style: AppTextStyles.tagLabel(color: subTextColor),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isPlaying ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: MyColors.greenColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isPlaying ? 'Music is Synchronized & Playing' : 'Playback is Paused',
                      style: AppTextStyles.bodyBold(color: textColor).copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
              if (currentSongId != null && currentSongId.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),
                Text(
                  'SYNCED SONG ID',
                  style: AppTextStyles.tagLabel(color: subTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  currentSongId,
                  style: AppTextStyles.caption(color: textColor),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Leave Room Button
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLeaveRoom,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91429),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Text(
            'Disconnect & Leave Room',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class PulseIndicator extends StatefulWidget {
  const PulseIndicator({super.key});

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: MyColors.greenColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: MyColors.greenColor.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
