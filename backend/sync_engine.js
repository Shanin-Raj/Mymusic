const { Server } = require('socket.io');

const activeRooms = new Map();

function cancelCleanupTimer(room) {
    if (room.cleanupTimer) {
        clearTimeout(room.cleanupTimer);
        room.cleanupTimer = null;
        console.log(`⏱️ Cleanup timer cancelled for room: ${room.roomId}`);
    }
}

function startCleanupTimer(room) {
    if (!room.cleanupTimer) {
        console.log(`⏱️ Room ${room.roomId} empty. Starting 3 min cleanup timer.`);
        room.cleanupTimer = setTimeout(() => {
            activeRooms.delete(room.roomId);
            console.log(`🗑️ Room deleted due to inactivity: ${room.roomId}`);
        }, 3 * 60 * 1000);
    }
}

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
            const payload = args.length > 0 ? args[0] : null;

            const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
            let roomId = '';
            for (let i = 0; i < 5; i++) {
                roomId += chars.charAt(Math.floor(Math.random() * chars.length));
            }

            const initialQueue = (payload && Array.isArray(payload.queue)) ? payload.queue : (payload && Array.isArray(payload)) ? payload : [];
            const firstTrack = initialQueue.length > 0 ? initialQueue[0] : null;
            const currentSongId = firstTrack ? (firstTrack.id || firstTrack._id || null) : null;
            const currentTrackUrl = firstTrack ? (firstTrack.trackUrl || null) : null;

            activeRooms.set(roomId, {
                roomId,
                hostId: socket.user.uid,
                users: new Set([socket.user.uid]),
                queue: initialQueue,
                currentIndex: 0,
                currentTrackUrl,
                currentSongId,
                playbackState: 'PAUSED', // PAUSED or PLAYING
                targetTimestamp: null,
                position: 0,
                eventLog: [],
                cleanupTimer: null
            });

            socket.join(roomId);
            if (typeof callback === 'function') {
                callback({ success: true, roomId, state: getRoomState(roomId) });
            }
            console.log(`🏠 Room created: ${roomId} by ${socket.user.uid} with ${initialQueue.length} songs in queue`);
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
            cancelCleanupTimer(room);

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
                if (room.users.size === 0) {
                    startCleanupTimer(room);
                } else {
                    socket.to(roomId).emit('user_left', { userId: socket.user.uid, totalUsers: room.users.size });
                }
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
                room.position = payload?.position || room.position;
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
                room.position = payload?.position || room.position;
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

                // If song index is specified in payload, update currentIndex
                if (typeof payload.currentIndex === 'number') {
                    room.currentIndex = payload.currentIndex;
                } else if (room.queue && room.queue.length > 0) {
                    const idx = room.queue.findIndex(s => (s.id || s._id) === payload.songId);
                    if (idx !== -1) room.currentIndex = idx;
                }

                const event = {
                    type: 'TRACK_CHANGE_EXECUTE',
                    songId: room.currentSongId,
                    trackUrl: room.currentTrackUrl,
                    currentIndex: room.currentIndex,
                    queue: room.queue,
                    targetTimestamp: room.targetTimestamp,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);

            } else if (type === 'UPDATE_QUEUE_INTENT') {
                if (payload && Array.isArray(payload.queue)) {
                    room.queue = payload.queue;
                }
                if (payload && typeof payload.currentIndex === 'number') {
                    room.currentIndex = payload.currentIndex;
                }
                if (room.queue.length > 0 && room.currentIndex < room.queue.length) {
                    const currentSong = room.queue[room.currentIndex];
                    room.currentSongId = currentSong.id || currentSong._id;
                    room.currentTrackUrl = currentSong.trackUrl || room.currentTrackUrl;
                }
                const event = {
                    type: 'QUEUE_UPDATE_EXECUTE',
                    queue: room.queue,
                    currentIndex: room.currentIndex,
                    currentSongId: room.currentSongId,
                    currentTrackUrl: room.currentTrackUrl,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);

            } else if (type === 'ADD_TO_QUEUE_INTENT') {
                const newItems = payload && Array.isArray(payload.songs) ? payload.songs : (payload && payload.song ? [payload.song] : []);
                room.queue.push(...newItems);
                if (room.queue.length > 0 && (room.currentSongId == null || room.currentTrackUrl == null)) {
                    room.currentIndex = 0;
                    const first = room.queue[0];
                    room.currentSongId = first.id || first._id;
                    room.currentTrackUrl = first.trackUrl;
                }
                const event = {
                    type: 'QUEUE_UPDATE_EXECUTE',
                    queue: room.queue,
                    currentIndex: room.currentIndex,
                    currentSongId: room.currentSongId,
                    currentTrackUrl: room.currentTrackUrl,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);

            } else if (type === 'REMOVE_FROM_QUEUE_INTENT') {
                const removeIdx = payload ? payload.index : -1;
                if (typeof removeIdx === 'number' && removeIdx >= 0 && removeIdx < room.queue.length) {
                    room.queue.splice(removeIdx, 1);
                    if (room.currentIndex >= room.queue.length) {
                        room.currentIndex = Math.max(0, room.queue.length - 1);
                    }
                    if (room.queue.length > 0) {
                        const current = room.queue[room.currentIndex];
                        room.currentSongId = current.id || current._id;
                        room.currentTrackUrl = current.trackUrl;
                    } else {
                        room.currentSongId = null;
                        room.currentTrackUrl = null;
                        room.playbackState = 'PAUSED';
                    }
                }
                const event = {
                    type: 'QUEUE_UPDATE_EXECUTE',
                    queue: room.queue,
                    currentIndex: room.currentIndex,
                    currentSongId: room.currentSongId,
                    currentTrackUrl: room.currentTrackUrl,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);

            } else if (type === 'REORDER_QUEUE_INTENT') {
                if (payload && Array.isArray(payload.queue)) {
                    room.queue = payload.queue;
                } else if (payload && typeof payload.oldIndex === 'number' && typeof payload.newIndex === 'number') {
                    const oldIndex = payload.oldIndex;
                    let newIndex = payload.newIndex;
                    if (oldIndex >= 0 && oldIndex < room.queue.length && newIndex >= 0 && newIndex <= room.queue.length) {
                        if (oldIndex < newIndex) {
                            newIndex -= 1;
                        }
                        const [item] = room.queue.splice(oldIndex, 1);
                        room.queue.splice(newIndex, 0, item);
                    }
                }
                if (payload && typeof payload.currentIndex === 'number') {
                    room.currentIndex = payload.currentIndex;
                }
                if (room.queue.length > 0 && room.currentIndex < room.queue.length) {
                    const current = room.queue[room.currentIndex];
                    room.currentSongId = current.id || current._id;
                    room.currentTrackUrl = current.trackUrl;
                }
                const event = {
                    type: 'QUEUE_UPDATE_EXECUTE',
                    queue: room.queue,
                    currentIndex: room.currentIndex,
                    currentSongId: room.currentSongId,
                    currentTrackUrl: room.currentTrackUrl,
                    serverTime: timestamp
                };
                room.eventLog.push(event);
                io.to(roomId).emit('sync_execute', event);

            } else if (type === 'NEXT_TRACK_INTENT') {
                if (room.queue && room.queue.length > 0) {
                    const nextIndex = room.currentIndex + 1;
                    if (nextIndex < room.queue.length) {
                        room.currentIndex = nextIndex;
                        const nextSong = room.queue[nextIndex];
                        room.currentSongId = nextSong.id || nextSong._id;
                        room.currentTrackUrl = nextSong.trackUrl || payload?.trackUrl;
                        room.position = 0;
                        room.playbackState = 'PLAYING';
                        room.targetTimestamp = timestamp + 1000;

                        const event = {
                            type: 'TRACK_CHANGE_EXECUTE',
                            songId: room.currentSongId,
                            trackUrl: room.currentTrackUrl,
                            currentIndex: room.currentIndex,
                            queue: room.queue,
                            targetTimestamp: room.targetTimestamp,
                            serverTime: timestamp
                        };
                        room.eventLog.push(event);
                        io.to(roomId).emit('sync_execute', event);
                    } else {
                        // End of queue reached
                        room.playbackState = 'PAUSED';
                        room.position = 0;
                        const event = {
                            type: 'PAUSE_EXECUTE',
                            position: 0,
                            serverTime: timestamp
                        };
                        room.eventLog.push(event);
                        io.to(roomId).emit('sync_execute', event);
                    }
                }

            } else if (type === 'PREV_TRACK_INTENT') {
                if (room.queue && room.queue.length > 0) {
                    const prevIndex = Math.max(0, room.currentIndex - 1);
                    room.currentIndex = prevIndex;
                    const prevSong = room.queue[prevIndex];
                    room.currentSongId = prevSong.id || prevSong._id;
                    room.currentTrackUrl = prevSong.trackUrl || payload?.trackUrl;
                    room.position = 0;
                    room.playbackState = 'PLAYING';
                    room.targetTimestamp = timestamp + 1000;

                    const event = {
                        type: 'TRACK_CHANGE_EXECUTE',
                        songId: room.currentSongId,
                        trackUrl: room.currentTrackUrl,
                        currentIndex: room.currentIndex,
                        queue: room.queue,
                        targetTimestamp: room.targetTimestamp,
                        serverTime: timestamp
                    };
                    room.eventLog.push(event);
                    io.to(roomId).emit('sync_execute', event);
                }
            }
        });

        socket.on('disconnecting', () => {
            for (const roomId of socket.rooms) {
                if (activeRooms.has(roomId)) {
                    const room = activeRooms.get(roomId);
                    room.users.delete(socket.user.uid);
                    if (room.users.size === 0) {
                        startCleanupTimer(room);
                    } else {
                        io.to(roomId).emit('user_left', { userId: socket.user.uid, totalUsers: room.users.size });
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
            queue: room.queue || [],
            currentIndex: room.currentIndex || 0,
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
