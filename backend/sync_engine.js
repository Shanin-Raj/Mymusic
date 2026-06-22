const { Server } = require('socket.io');

const activeRooms = new Map();

function initSyncEngine(server, admin) {
    const io = new Server(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    // Authentication middleware
    io.use(async (socket, next) => {
        const token = socket.handshake.auth.token;
        if (!token) {
            return next(new Error('Authentication error'));
        }
        try {
            const decodedToken = await admin.auth().verifyIdToken(token);
            socket.user = decodedToken;
            next();
        } catch (err) {
            next(new Error('Authentication error'));
        }
    });

    io.on('connection', (socket) => {
        console.log(`🔌 WebSocket client connected: ${socket.user.uid}`);

        // Ping-Pong Clock Sync
        socket.on('ping', (clientTime, callback) => {
            if (typeof callback === 'function') {
                callback(Date.now());
            }
        });

        // Create Room
        socket.on('create_room', (...args) => {
            const callback = args.length > 0 && typeof args[args.length - 1] === 'function' ? args.pop() : null;
            
            const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
            let roomId = '';
            for (let i = 0; i < 5; i++) {
                roomId += chars.charAt(Math.floor(Math.random() * chars.length));
            }
            
            activeRooms.set(roomId, {
                roomId,
                hostId: socket.user.uid,
                users: new Set([socket.user.uid]),
                currentTrackUrl: null,
                currentSongId: null,
                playbackState: 'PAUSED', // PAUSED or PLAYING
                targetTimestamp: null,
                position: 0,
                eventLog: []
            });

            socket.join(roomId);
            if (typeof callback === 'function') {
                callback({ success: true, roomId, state: getRoomState(roomId) });
            }
            console.log(`🏠 Room created: ${roomId} by ${socket.user.uid}`);
        });

        // Join Room
        socket.on('join_room', (roomId, callback) => {
            roomId = roomId.toUpperCase();
            if (!activeRooms.has(roomId)) {
                if (typeof callback === 'function') callback({ success: false, error: 'Room not found' });
                return;
            }
            
            const room = activeRooms.get(roomId);
            room.users.add(socket.user.uid);
            socket.join(roomId);
            
            if (typeof callback === 'function') {
                callback({ success: true, state: getRoomState(roomId) });
            }
            
            socket.to(roomId).emit('user_joined', { userId: socket.user.uid, totalUsers: room.users.size });
            console.log(`👤 User ${socket.user.uid} joined room ${roomId}`);
        });

        // Leave Room
        socket.on('leave_room', (roomId) => {
            roomId = roomId.toUpperCase();
            socket.leave(roomId);
            if (activeRooms.has(roomId)) {
                const room = activeRooms.get(roomId);
                room.users.delete(socket.user.uid);
                socket.to(roomId).emit('user_left', { userId: socket.user.uid, totalUsers: room.users.size });
            }
        });

        // Event Sourcing
        socket.on('sync_intent', (data) => {
            const { roomId, type, payload } = data;
            if (!activeRooms.has(roomId)) return;
            
            const room = activeRooms.get(roomId);
            
            // Any user in the room can control playback

            const timestamp = Date.now();
            
            if (type === 'PLAY_INTENT') {
                room.playbackState = 'PLAYING';
                room.position = payload.position || room.position;
                room.targetTimestamp = timestamp + 500; // 500ms latency comp
                
                const event = {
                    type: 'PLAY_EXECUTE',
                    targetTimestamp: room.targetTimestamp,
                    position: room.position,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);
                
            } else if (type === 'PAUSE_INTENT') {
                room.playbackState = 'PAUSED';
                room.position = payload.position || room.position;
                room.targetTimestamp = null;
                
                const event = {
                    type: 'PAUSE_EXECUTE',
                    position: room.position,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);
                
            } else if (type === 'SEEK_INTENT') {
                room.position = payload.position;
                if (room.playbackState === 'PLAYING') {
                    room.targetTimestamp = timestamp + 500;
                    const event = {
                        type: 'PLAY_EXECUTE',
                        targetTimestamp: room.targetTimestamp,
                        position: room.position,
                        serverTime: timestamp
                    };
                    room.eventLog.push(event);
                    io.to(roomId).emit('sync_execute', event);
                } else {
                    const event = {
                        type: 'SEEK_EXECUTE',
                        position: room.position,
                        serverTime: timestamp
                    };
                    room.eventLog.push(event);
                    io.to(roomId).emit('sync_execute', event);
                }
            } else if (type === 'CHANGE_TRACK_INTENT') {
                room.currentSongId = payload.songId;
                room.currentTrackUrl = payload.trackUrl;
                room.position = 0;
                room.playbackState = 'PLAYING';
                room.targetTimestamp = timestamp + 1000; // 1s buffer for track change
                
                const event = {
                    type: 'TRACK_CHANGE_EXECUTE',
                    songId: room.currentSongId,
                    trackUrl: room.currentTrackUrl,
                    targetTimestamp: room.targetTimestamp,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);
            }
        });

        socket.on('disconnecting', () => {
            for (const roomId of socket.rooms) {
                if (activeRooms.has(roomId)) {
                    const room = activeRooms.get(roomId);
                    room.users.delete(socket.user.uid);
                    if (room.users.size === 0) {
                        activeRooms.delete(roomId);
                        console.log(`🗑️ Room deleted: ${roomId}`);
                    } else {
                        io.to(roomId).emit('user_left', { userId: socket.user.uid, totalUsers: room.users.size });
                        if (room.hostId === socket.user.uid) {
                            io.to(roomId).emit('room_ended');
                            activeRooms.delete(roomId);
                        }
                    }
                }
            }
        });
    });

    function getRoomState(roomId) {
        const room = activeRooms.get(roomId);
        if (!room) return null;
        return {
            roomId: room.roomId,
            hostId: room.hostId,
            currentSongId: room.currentSongId,
            currentTrackUrl: room.currentTrackUrl,
            playbackState: room.playbackState,
            targetTimestamp: room.targetTimestamp,
            position: room.position,
            totalUsers: room.users.size
        };
    }
}

module.exports = { initSyncEngine, activeRooms };
