import 'package:flutter/material.dart';
import '../../services/sync_client.dart';
import '../../services/audio_controller.dart';
import '../../services/api_service.dart';

class RoomScreen extends StatefulWidget {
  const RoomScreen({super.key});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _joinController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (!SyncClient.instance.isConnected) {
      SyncClient.instance.connect(ApiService.baseUrl);
    }
  }

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listening Room')),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  await SyncClient.instance.createRoom();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Create New Room'),
            ),
            const SizedBox(height: 32),
            const Text('OR'),
            const SizedBox(height: 32),
            TextField(
              controller: _joinController,
              decoration: const InputDecoration(
                labelText: 'Room ID',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
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
              child: const Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomActive(Map<String, dynamic> roomState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Room ID: ${roomState['roomId']}', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text('Users connected: ${roomState['totalUsers']}'),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () async {
            try {
              final songs = await ApiService.fetchSongs();
              if (songs.isNotEmpty) {
                final song = songs.first;
                final songId = song['id']?.toString() ?? song['_id']?.toString() ?? '';
                AudioController.instance.changeTrack(
                  songId, 
                  ApiService.getStreamUrl(songId)
                );
              }
            } catch (e) {
              debugPrint('Error changing track: $e');
            }
          },
          child: const Text('Play First Song in Library (Host Only)'),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.pause, size: 48),
              onPressed: () {
                SyncClient.instance.sendIntent('PAUSE_INTENT', {
                  'position': AudioController.instance.player.position.inMilliseconds
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow, size: 48),
              onPressed: () {
                SyncClient.instance.sendIntent('PLAY_INTENT', {
                  'position': AudioController.instance.player.position.inMilliseconds
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () {
            SyncClient.instance.leaveRoom();
            AudioController.instance.player.stop();
          },
          child: const Text('Leave Room'),
        ),
      ],
    );
  }
}
