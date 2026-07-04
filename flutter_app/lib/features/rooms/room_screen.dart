import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/sync_client.dart';
import '../../services/audio_controller.dart';
import '../../services/api_service.dart';
import '../../providers/audio_provider.dart';
import '../../core/constants.dart';
import '../../widgets/mini_player.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _joinController = TextEditingController();
  bool _isConnecting = false;
  String? _connectionError;
  
  @override
  void initState() {
    super.initState();
    _ensureConnected();
  }

  Future<void> _ensureConnected() async {
    if (SyncClient.instance.isConnected) return;
    
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      await SyncClient.instance.connect(ApiService.baseUrl);
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? MyColors.surfaceDark : MyColors.offWhite;
    final textColor = isDark ? Colors.white : MyColors.darkText;

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [MiniPlayer()],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Listening Room', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: SyncClient.instance.roomStateStream,
        builder: (context, snapshot) {
          final roomState = snapshot.data ?? SyncClient.instance.roomState;
          
          if (roomState == null) {
            return _buildJoinCreate();
          }
          
          return _buildRoomActive(roomState);
        },
      ),
    );
  }

  Widget _buildJoinCreate() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark ? MyColors.lightGrey : MyColors.mutedGrey;

    if (_isConnecting) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: MyColors.greenColor),
            const SizedBox(height: 16),
            Text('Connecting to server...', style: TextStyle(color: subColor)),
          ],
        ),
      );
    }

    if (_connectionError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Connection failed',
                style: TextStyle(
                  color: isDark ? Colors.white : MyColors.darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_connectionError!, textAlign: TextAlign.center, style: TextStyle(color: subColor)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _ensureConnected,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.greenColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset, size: 64, color: MyColors.greenColor.withValues(alpha: 0.7)),
            const SizedBox(height: 24),
            Text(
              'Listen Together',
              style: TextStyle(
                color: isDark ? Colors.white : MyColors.darkText,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a room to listen with friends',
              style: TextStyle(color: subColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!SyncClient.instance.isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not connected to server')),
                    );
                    return;
                  }
                  try {
                    await SyncClient.instance.createRoom();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Create New Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.greenColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider(color: subColor.withValues(alpha: 0.3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: subColor, fontWeight: FontWeight.w500)),
                ),
                Expanded(child: Divider(color: subColor.withValues(alpha: 0.3))),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _joinController,
              style: TextStyle(color: isDark ? Colors.white : MyColors.darkText),
              decoration: InputDecoration(
                labelText: 'Room ID',
                labelStyle: TextStyle(color: subColor),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: subColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: MyColors.greenColor),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (!SyncClient.instance.isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not connected to server')),
                    );
                    return;
                  }
                  if (_joinController.text.isNotEmpty) {
                    try {
                      await SyncClient.instance.joinRoom(_joinController.text.trim());
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Join Room'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                  foregroundColor: isDark ? Colors.white : MyColors.darkText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomActive(Map<String, dynamic> roomState) {
    final audioProvider = context.watch<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subColor = isDark ? MyColors.lightGrey : MyColors.mutedGrey;
    final roomId = roomState['roomId']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Room ID card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('Room ID', style: TextStyle(color: subColor, fontSize: 13)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: roomId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room ID copied!'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        roomId,
                        style: TextStyle(
                          color: MyColors.greenColor,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.copy, size: 18, color: subColor),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people, size: 16, color: subColor),
                    const SizedBox(width: 6),
                    Text(
                      '${roomState['totalUsers']} connected',
                      style: TextStyle(color: subColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Play a song button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                try {
                  final songs = await ApiService.fetchSongs();
                  if (songs.isNotEmpty) {
                    _showSongPicker(songs);
                  }
                } catch (e) {
                  debugPrint('Error fetching songs: $e');
                }
              },
              icon: const Icon(Icons.queue_music),
              label: const Text('Choose a Song'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.greenColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Playback controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 56,
                  color: MyColors.greenColor,
                ),
                onPressed: () {
                  AudioController.instance.togglePlayPause(audioProvider);
                },
              ),
            ],
          ),
          const Spacer(),
          // Leave room button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                SyncClient.instance.leaveRoom();
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Leave Room'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSongPicker(List<dynamic> songs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? MyColors.cardColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Pick a Song',
                    style: TextStyle(
                      color: isDark ? Colors.white : MyColors.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white10),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final songId = (song['id'] ?? song['_id'] ?? '').toString();
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            ApiService.getImageUrl(song['image'] ?? ''),
                            width: 44, height: 44, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 44, height: 44,
                              color: MyColors.cardColor,
                              child: const Icon(Icons.music_note, color: Colors.white24),
                            ),
                          ),
                        ),
                        title: Text(
                          song['name'] ?? 'Unknown',
                          style: TextStyle(color: isDark ? Colors.white : MyColors.darkText, fontWeight: FontWeight.w600),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song['artist'] ?? 'Unknown',
                          style: TextStyle(color: isDark ? MyColors.lightGrey : MyColors.mutedGrey, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          AudioController.instance.changeTrack(
                            songId,
                            ApiService.getStreamUrl(songId),
                          );
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
    );
  }
}
