import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class RoomState {
  final String roomId;
  final String currentSongId;
  final bool isPlaying;
  final double position;
  final int updatedAt;

  RoomState({
    required this.roomId,
    required this.currentSongId,
    required this.isPlaying,
    required this.position,
    required this.updatedAt,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      roomId: json['roomId'] ?? '',
      currentSongId: json['currentSongId'] ?? '',
      isPlaying: json['isPlaying'] ?? false,
      position: (json['position'] ?? 0).toDouble(),
      updatedAt: json['updatedAt'] ?? 0,
    );
  }
}

class RoomService {
  http.Client? _client;
  StreamSubscription? _streamSubscription;
  final _roomStateController = StreamController<RoomState>.broadcast();

  Stream<RoomState> get roomStream => _roomStateController.stream;

  Future<RoomState> createRoom() async {
    final response = await http.post(Uri.parse('${ApiService.baseUrl}/api/rooms'));
    if (response.statusCode == 200) {
      return RoomState.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create room');
    }
  }

  Future<RoomState> joinRoom(String roomId) async {
    final response = await http.get(Uri.parse('${ApiService.baseUrl}/api/rooms/$roomId'));
    if (response.statusCode == 200) {
      return RoomState.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to join room');
    }
  }

  Future<void> updateState(String roomId, String currentSongId, bool isPlaying, double position) async {
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/api/rooms/$roomId/update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'currentSongId': currentSongId,
          'isPlaying': isPlaying,
          'position': position,
        }),
      );
    } catch (e) {
      debugPrint('Error updating room state: $e');
    }
  }

  Future<void> connectToStream(String roomId) async {
    disconnectStream(); // Ensure any existing connection is closed
    
    _client = http.Client();
    final request = http.Request('GET', Uri.parse('${ApiService.baseUrl}/api/rooms/$roomId/stream'));
    request.headers['Accept'] = 'text/event-stream';
    
    try {
      final response = await _client!.send(request);
      
      if (response.statusCode == 200) {
        _streamSubscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr.isNotEmpty) {
              try {
                final data = json.decode(dataStr);
                if (data['error'] != null) {
                  debugPrint('SSE Error: ${data['error']}');
                  if (data['error'] == 'Room deleted') {
                    disconnectStream();
                  }
                  return;
                }
                _roomStateController.add(RoomState.fromJson(data));
              } catch (e) {
                debugPrint('Error parsing SSE data: $e');
              }
            }
          }
        }, onError: (error) {
          debugPrint('SSE Stream Error: $error');
          // Reconnect logic could be added here
        }, cancelOnError: true);
      } else {
        debugPrint('Failed to connect to SSE stream, status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error connecting to SSE stream: $e');
    }
  }

  void disconnectStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _client?.close();
    _client = null;
  }
  
  void dispose() {
    disconnectStream();
    _roomStateController.close();
  }
}
