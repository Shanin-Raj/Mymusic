const io = require('socket.io-client');

const socket = io('https://shanin-05-mixtape.hf.space', {
    transports: ['polling', 'websocket'],
    auth: { token: 'test-token' } // Note: This will fail auth, but we should get an auth error!
});

console.log('Connecting...');

socket.on('connect', () => {
    console.log('Connected! ID:', socket.id);
    socket.emit('create_room', null, (response) => {
        console.log('Create room response:', response);
        socket.disconnect();
    });
});

socket.on('connect_error', (err) => {
    console.log('Connect error:', err.message);
    socket.disconnect();
});
