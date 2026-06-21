import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';

class SyncClient {
  static final SyncClient instance = SyncClient._internal();
  IO.Socket? _socket;
  
  int _clockOffset = 0; // Local time + offset = Server time
  bool _isConnected = false;
  String? _currentRoomId;
  Map<String, dynamic>? _roomState;
  
  final _stateController = StreamController<Map<String, dynamic>?>.broadcast();
  final _executeController = StreamController<Map<String, dynamic>>.broadcast();

  SyncClient._internal();

  Stream<Map<String, dynamic>?> get roomStateStream => _stateController.stream;
  Stream<Map<String, dynamic>> get executeStream => _executeController.stream;
  Map<String, dynamic>? get roomState => _roomState;
  bool get isConnected => _isConnected;

  Future<void> connect(String baseUrl) async {
    if (_isConnected) return;

    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : null;
    
    if (token == null) {
      debugPrint('SyncClient: Cannot connect without auth token');
      throw Exception('Not authenticated');
    }

    final connectCompleter = Completer<void>();

    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .disableAutoConnect()
      .setAuth({'token': token})
      .build());

    _socket!.onConnect((_) {
      debugPrint('SyncClient: Connected to server');
      _isConnected = true;
      _performClockSync();
      if (!connectCompleter.isCompleted) {
        connectCompleter.complete();
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('SyncClient: Disconnected from server');
      _isConnected = false;
    });

    _socket!.onConnectError((data) {
      debugPrint('SyncClient: Connection error: $data');
      if (!connectCompleter.isCompleted) {
        connectCompleter.completeError(Exception('Connection failed'));
      }
    });

    _socket!.on('sync_execute', (data) {
      _executeController.add(data);
    });

    _socket!.on('user_joined', (data) {
      if (_roomState != null) {
        _roomState!['totalUsers'] = data['totalUsers'];
        _stateController.add(_roomState);
      }
    });

    _socket!.on('user_left', (data) {
      if (_roomState != null) {
        _roomState!['totalUsers'] = data['totalUsers'];
        _stateController.add(_roomState);
      }
    });

    _socket!.on('room_ended', (_) {
      leaveRoom();
    });

    _socket!.connect();

    // Wait for connection with timeout
    return connectCompleter.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Connection timeout');
      },
    );
  }

  void _performClockSync() async {
    List<int> offsets = [];
    for (int i = 0; i < 5; i++) {
      final t0 = DateTime.now().millisecondsSinceEpoch;
      final serverTime = await _pingServer();
      final t1 = DateTime.now().millisecondsSinceEpoch;
      final latency = (t1 - t0) / 2;
      final offset = serverTime - (t0 + latency);
      offsets.add(offset.round());
      await Future.delayed(const Duration(milliseconds: 100));
    }
    offsets.sort();
    // take median
    _clockOffset = offsets[2];
    debugPrint('SyncClient: Clock synchronized. Offset: $_clockOffset ms');
  }

  Future<int> _pingServer() {
    final completer = Completer<int>();
    _socket!.emitWithAck('ping', DateTime.now().millisecondsSinceEpoch, ack: (data) {
      completer.complete(data as int);
    });
    return completer.future;
  }

  int getServerTime() {
    return DateTime.now().millisecondsSinceEpoch + _clockOffset;
  }

  Future<void> createRoom() async {
    if (!_isConnected) return Future.error('Not connected to server');
    final completer = Completer<void>();
    
    // Add timeout to prevent hanging
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.completeError('Connection timeout');
    });

    _socket!.emitWithAck('create_room', null, ack: (data) {
      if (completer.isCompleted) return;
      if (data['success']) {
        _currentRoomId = data['roomId'];
        _roomState = data['state'];
        _stateController.add(_roomState);
        completer.complete();
      } else {
        completer.completeError('Failed to create room');
      }
    });
    return completer.future;
  }

  Future<void> joinRoom(String roomId) async {
    if (!_isConnected) return Future.error('Not connected to server');
    final completer = Completer<void>();
    
    // Add timeout to prevent hanging
    Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) completer.completeError('Connection timeout');
    });

    _socket!.emitWithAck('join_room', roomId, ack: (data) {
      if (completer.isCompleted) return;
      if (data['success']) {
        _currentRoomId = roomId;
        _roomState = data['state'];
        _stateController.add(_roomState);
        completer.complete();
      } else {
        completer.completeError(data['error'] ?? 'Failed to join room');
      }
    });
    return completer.future;
  }

  void leaveRoom() {
    if (_currentRoomId != null) {
      _socket!.emit('leave_room', _currentRoomId);
      _currentRoomId = null;
      _roomState = null;
      _stateController.add(null);
    }
  }

  void sendIntent(String type, Map<String, dynamic> payload) {
    if (_currentRoomId == null || !_isConnected) return;
    _socket!.emit('sync_intent', {
      'roomId': _currentRoomId,
      'type': type,
      'payload': payload
    });
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}
