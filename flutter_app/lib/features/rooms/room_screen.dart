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

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: canPop
          ? const SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [MiniPlayer()],
              ),
            )
          : null,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Listening Room', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        leading: canPop
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () => Navigator.pop(context),
              )
            : null,
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
              Text(
                'Connection failed',
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
      child: SingleChildScrollView(
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
                onPressed: () {
                  if (!SyncClient.instance.isConnected) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Not connected to server')),
                    );
                    return;
                  }
                  _showCreateRoomSongPicker();
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
                      if (mounted) {
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
    final queue = roomState['queue'] != null ? List<dynamic>.from(roomState['queue']) : <dynamic>[];
    final currentIndex = roomState['currentIndex'] is int ? roomState['currentIndex'] as int : 0;

    final currentSong = audioProvider.currentSong;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: const TextStyle(
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
                      '${roomState['totalUsers'] ?? 1} connected',
                      style: TextStyle(color: subColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Currently Playing Track Card if playing in room
          if (currentSong != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      currentSong.artUri?.toString() ?? '',
                      width: 48, height: 48, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 48, height: 48, color: MyColors.cardColor,
                        child: const Icon(Icons.music_note, color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentSong.title,
                          style: TextStyle(
                            color: isDark ? Colors.white : MyColors.darkText,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentSong.artist ?? 'Unknown Artist',
                          style: TextStyle(color: subColor, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Playback controls (Prev, Play/Pause, Next)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 36),
                color: isDark ? Colors.white : MyColors.darkText,
                onPressed: queue.isNotEmpty ? () => AudioController.instance.prevTrack() : null,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  audioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 64,
                  color: MyColors.greenColor,
                ),
                onPressed: () {
                  AudioController.instance.togglePlayPause(audioProvider);
                },
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 36),
                color: isDark ? Colors.white : MyColors.darkText,
                onPressed: queue.isNotEmpty ? () => AudioController.instance.nextTrack() : null,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Room Queue Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room Queue',
                    style: TextStyle(
                      color: isDark ? Colors.white : MyColors.darkText,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${queue.length} songs',
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _showAddSongsPicker,
                icon: const Icon(Icons.add_circle_outline, size: 18, color: MyColors.greenColor),
                label: const Text('Add Music', style: TextStyle(color: MyColors.greenColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Queue List / Empty State
          if (queue.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: subColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.queue_music, size: 48, color: subColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'Queue is empty',
                    style: TextStyle(
                      color: isDark ? Colors.white : MyColors.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Add Music" to select songs for the room',
                    style: TextStyle(color: subColor, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: queue.length,
              onReorder: (oldIndex, newIndex) {
                AudioController.instance.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final song = queue[index];
                final songId = (song['id'] ?? song['_id'] ?? '').toString();
                final isCurrent = index == currentIndex;

                return Container(
                  key: ValueKey('queue_item_${index}_$songId'),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? MyColors.greenColor.withValues(alpha: 0.15)
                        : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent ? Border.all(color: MyColors.greenColor, width: 1.5) : null,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_handle, color: subColor, size: 20),
                        ),
                        const SizedBox(width: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            ApiService.getImageUrl(song['image'] ?? ''),
                            width: 40, height: 40, fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 40, height: 40,
                              color: MyColors.cardColor,
                              child: const Icon(Icons.music_note, color: Colors.white24, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      song['name'] ?? 'Unknown',
                      style: TextStyle(
                        color: isCurrent ? MyColors.greenColor : (isDark ? Colors.white : MyColors.darkText),
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['artist'] ?? 'Unknown',
                      style: TextStyle(color: subColor, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent && audioProvider.isPlaying)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.volume_up, size: 20, color: MyColors.greenColor),
                          ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                          onPressed: () {
                            AudioController.instance.removeFromQueue(index);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      final trackUrl = song['trackUrl'] ?? ApiService.getStreamUrl(songId);
                      AudioController.instance.changeTrack(songId, trackUrl, currentIndex: index);
                    },
                  ),
                );
              },
            ),

          const SizedBox(height: 32),

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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCreateRoomSongPicker() async {
    try {
      final songs = await ApiService.fetchSongs();
      if (!mounted) return;
      if (songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No songs available to select')),
        );
        return;
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final Set<String> selectedSongIds = {};

      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? MyColors.cardColor : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
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
                        child: Row(
                          children: [
                            Text(
                              'Select Songs for Room',
                              style: TextStyle(
                                color: isDark ? Colors.white : MyColors.darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${selectedSongIds.length} selected',
                              style: const TextStyle(color: MyColors.greenColor, fontWeight: FontWeight.w600),
                            ),
                          ],
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
                            final isSelected = selectedSongIds.contains(songId);

                            return CheckboxListTile(
                              activeColor: MyColors.greenColor,
                              checkColor: Colors.black,
                              value: isSelected,
                              onChanged: (bool? val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedSongIds.add(songId);
                                  } else {
                                    selectedSongIds.remove(songId);
                                  }
                                });
                              },
                              secondary: ClipRRect(
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
                                style: TextStyle(
                                  color: isDark ? Colors.white : MyColors.darkText,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song['artist'] ?? 'Unknown',
                                style: TextStyle(
                                  color: isDark ? MyColors.lightGrey : MyColors.mutedGrey,
                                  fontSize: 13,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: selectedSongIds.isEmpty
                                ? null
                                : () async {
                                    final initialQueue = songs.where((s) {
                                      final sId = (s['id'] ?? s['_id'] ?? '').toString();
                                      return selectedSongIds.contains(sId);
                                    }).map((s) {
                                      final sId = (s['id'] ?? s['_id'] ?? '').toString();
                                      return {
                                        'id': sId,
                                        '_id': sId,
                                        'name': s['name'] ?? 'Unknown',
                                        'artist': s['artist'] ?? 'Unknown',
                                        'image': s['image'] ?? '',
                                        'duration_ms': s['duration_ms'] ?? 0,
                                        'trackUrl': ApiService.getStreamUrl(sId),
                                      };
                                    }).toList();

                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(context);
                                    try {
                                      await SyncClient.instance.createRoom(initialQueue);
                                    } catch (e) {
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Error creating room: $e')),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.play_arrow),
                            label: Text('Create Room (${selectedSongIds.length} Songs)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.greenColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error fetching songs for create room: $e');
    }
  }

  void _showAddSongsPicker() async {
    try {
      final songs = await ApiService.fetchSongs();
      if (!mounted) return;
      if (songs.isEmpty) return;

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final Set<String> selectedSongIds = {};

      showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? MyColors.cardColor : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.75,
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
                        child: Row(
                          children: [
                            Text(
                              'Add Songs to Room Queue',
                              style: TextStyle(
                                color: isDark ? Colors.white : MyColors.darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${selectedSongIds.length} selected',
                              style: const TextStyle(color: MyColors.greenColor, fontWeight: FontWeight.w600),
                            ),
                          ],
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
                            final isSelected = selectedSongIds.contains(songId);

                            return CheckboxListTile(
                              activeColor: MyColors.greenColor,
                              checkColor: Colors.black,
                              value: isSelected,
                              onChanged: (bool? val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedSongIds.add(songId);
                                  } else {
                                    selectedSongIds.remove(songId);
                                  }
                                });
                              },
                              secondary: ClipRRect(
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
                                style: TextStyle(
                                  color: isDark ? Colors.white : MyColors.darkText,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song['artist'] ?? 'Unknown',
                                style: TextStyle(
                                  color: isDark ? MyColors.lightGrey : MyColors.mutedGrey,
                                  fontSize: 13,
                                ),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: selectedSongIds.isEmpty
                                ? null
                                : () {
                                    final newSongs = songs.where((s) {
                                      final sId = (s['id'] ?? s['_id'] ?? '').toString();
                                      return selectedSongIds.contains(sId);
                                    }).map((s) {
                                      final sId = (s['id'] ?? s['_id'] ?? '').toString();
                                      return {
                                        'id': sId,
                                        '_id': sId,
                                        'name': s['name'] ?? 'Unknown',
                                        'artist': s['artist'] ?? 'Unknown',
                                        'image': s['image'] ?? '',
                                        'duration_ms': s['duration_ms'] ?? 0,
                                        'trackUrl': ApiService.getStreamUrl(sId),
                                      };
                                    }).toList();

                                    Navigator.pop(context);
                                    AudioController.instance.addToQueue(newSongs.first);
                                    for (var i = 1; i < newSongs.length; i++) {
                                      AudioController.instance.addToQueue(newSongs[i]);
                                    }
                                  },
                            icon: const Icon(Icons.add),
                            label: Text('Add ${selectedSongIds.length} Songs to Queue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: MyColors.greenColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('Error fetching songs for add to queue: $e');
    }
  }
}
