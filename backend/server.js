const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { Api } = require('telegram');
const { db } = require('./firebase');
const { addSong } = require('./adder');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

const apiId = parseInt(process.env.TELEGRAM_API_ID);
const apiHash = process.env.TELEGRAM_API_HASH;
const botToken = process.env.TELEGRAM_BOT_TOKEN;
const channelId = (process.env.TELEGRAM_CHANNEL_ID || "").trim().replace(/['"]/g, "");
const stringSession = new StringSession(process.env.TELEGRAM_SESSION || "");
let tgClient = null;
let tgReady = false;

const CACHE_DIR = '/tmp/music-cache';
if (!fs.existsSync(CACHE_DIR)) fs.mkdirSync(CACHE_DIR, { recursive: true });

async function initTelegram() {
    console.log('🔄 Initializing Telegram...');
    try {
        await ensureTgConnected();
        console.log('✅ Telegram initialized and ready');
    } catch (err) { console.error('❌ Telegram failed:', err); }
}

async function ensureTgConnected() {
    if (!apiId || !apiHash) {
        throw new Error('Telegram credentials not configured');
    }
    if (!tgClient) {
        tgClient = new TelegramClient(stringSession, apiId, apiHash, { 
            connectionRetries: 10, 
            useWSS: false,
            autoReconnect: true,
            connectionTimeout: 10000 
        });
    }
    if (!tgClient.connected) {
        console.log('📡 [Server] Connecting/Reconnecting global Telegram client...');
        await tgClient.start({ botAuthToken: botToken });
        tgReady = true;
    }
}

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/cache', express.static(CACHE_DIR));

// Resolve the images directory robustly (look for sibling folder first, then internal backend folder)
let IMAGES_DIR = path.join(__dirname, '../images');
try {
    if (!fs.existsSync(IMAGES_DIR) || fs.readdirSync(IMAGES_DIR).filter(file => ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(path.extname(file).toLowerCase())).length === 0) {
        IMAGES_DIR = path.join(__dirname, 'images');
    }
} catch (e) {
    IMAGES_DIR = path.join(__dirname, 'images');
}
if (!fs.existsSync(IMAGES_DIR)) {
    fs.mkdirSync(IMAGES_DIR, { recursive: true });
}
app.use('/images', express.static(IMAGES_DIR));

app.get('/api/images', (req, res) => {
    try {
        if (fs.existsSync(IMAGES_DIR)) {
            const files = fs.readdirSync(IMAGES_DIR).filter(file => {
                const ext = path.extname(file).toLowerCase();
                return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
            });
            const imageUrls = files.map(file => getAbsoluteImageUrl(req, `/images/${file}`));
            return res.json({ images: imageUrls });
        }
        res.json({ images: [] });
    } catch (err) {
        res.status(500).json({ error: 'Failed to list images: ' + err.message });
    }
});



// Helper function to resolve a stable random cover image from files in d:/music/images
function getRandomCoverImage(idSeed) {
    try {
        if (fs.existsSync(IMAGES_DIR)) {
            const files = fs.readdirSync(IMAGES_DIR).filter(file => {
                const ext = path.extname(file).toLowerCase();
                return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
            });
            if (files.length > 0) {
                // Stable index based on input string hash code
                let hash = 0;
                const seedStr = String(idSeed || '');
                for (let i = 0; i < seedStr.length; i++) {
                    hash = seedStr.charCodeAt(i) + ((hash << 5) - hash);
                }
                const index = Math.abs(hash) % files.length;
                return `/images/${files[index]}`;
            }
        }
    } catch (err) {
        console.error('Failed to read images directory:', err);
    }
    return null;
}

// Helper to make a relative path absolute
function getAbsoluteImageUrl(req, relativePath) {
    if (!relativePath) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
        return relativePath;
    }
    const host = req.get('host');
    const protocol = req.protocol;
    return `${protocol}://${host}${relativePath}`;
}

// Android TWA Trust Handshake
app.get('/.well-known/assetlinks.json', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', '.well-known', 'assetlinks.json'));
});
let songsCache = null;
let playlistsCache = null;

async function getLibrary() {
    if (songsCache) {
        return songsCache;
    }
    console.log('🔥 [Firestore] Fetching all songs from DB (updating cache)...');
    const snapshot = await db.collection('songs').get();
    const songs = [];
    snapshot.forEach(doc => songs.push(doc.data()));
    songsCache = songs.sort((a, b) => (b.added_at?.toDate ? b.added_at.toDate() : new Date(b.added_at || 0)) - (a.added_at?.toDate ? a.added_at.toDate() : new Date(a.added_at || 0)));
    return songsCache;
}

async function getSongById(id) {
    if (songsCache) {
        const cached = songsCache.find(s => s.id === id);
        if (cached) return cached;
    }
    console.log(`🔥 [Firestore] Fetching song detail for ${id} from DB...`);
    const doc = await db.collection('songs').doc(id).get();
    return doc.exists ? doc.data() : null;
}

async function getPlaylists() {
    if (playlistsCache) {
        return playlistsCache;
    }
    console.log('🔥 [Firestore] Fetching all playlists from DB (updating cache)...');
    const snapshot = await db.collection('playlists').get();
    const playlists = [];
    snapshot.forEach(doc => playlists.push({ id: doc.id, ...doc.data() }));
    playlistsCache = playlists;
    return playlistsCache;
}


app.post('/api/add-song', async (req, res) => {
    try {
        const track = await addSong(req.body);
        songsCache = null; // Invalidate memory cache
        res.json({ status: 'ok', track });
    } catch (err) { 
        console.error('API add-song error:', err);
        const errorType = err.message.includes('TIMEOUT') ? 'TIMEOUT' : 'GENERAL';
        res.status(500).json({ 
            error: true, 
            type: errorType, 
            message: err.message,
            details: 'Failed to process song addition. Please try again.'
        }); 
    }
});

app.delete('/api/songs/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const song = await getSongById(id);
        if (!song) return res.status(404).json({ error: 'Not found' });

        // 1. Delete from Telegram (optional/best-effort)
        if (song.tg_message_id) {
            try {
                if (!tgReady) await initTelegram();
                await tgClient.deleteMessages(channelId, [song.tg_message_id], { revoke: true });
                console.log(`Deleted TG message ${song.tg_message_id} for ${song.name}`);
            } catch (err) {
                console.warn(`TG Delete Failed for ${id}:`, err.message);
            }
        }

        // 2. Delete from Firestore
        await db.collection('songs').doc(id).delete();
        
        // 3. Remove from all playlists
        const playlists = await db.collection('playlists').get();
        const batch = db.batch();
        playlists.forEach(doc => {
            const plData = doc.data();
            if (plData.songs.includes(id)) {
                const updatedSongs = plData.songs.filter(sid => sid !== id);
                batch.update(doc.ref, { songs: updatedSongs });
            }
        });
        await batch.commit();

        songsCache = null; // Invalidate memory cache
        playlistsCache = null; // Invalidate memory cache

        res.json({ status: 'ok' });
    } catch (err) {
        console.error('Delete song failed:', err);
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/songs', async (req, res) => {
    try {
        const songs = await getLibrary();
        const updatedSongs = songs.map(song => {
            let img = song.image;
            if (!img || img === '') {
                img = getRandomCoverImage(song.id || song.name);
            }
            return {
                ...song,
                image: getAbsoluteImageUrl(req, img)
            };
        });
        res.json({ songs: updatedSongs, total: songs.length });
    }
    catch (err) { res.status(500).json({ error: true, message: 'Library failed' }); }
});

app.get('/api/stream/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song || !song.tg_message_id) return res.status(404).json({ error: true, message: 'Not found' });
        const cacheFile = path.join(CACHE_DIR, `${song.id}.m4a`);
        if (fs.existsSync(cacheFile)) return streamFile(cacheFile, req, res);
        
        await ensureTgConnected();

        const downloadPromise = (async () => {
            const peer = await tgClient.getInputEntity(channelId);
            const messages = await tgClient.invoke(new Api.channels.GetMessages({ channel: peer, id: [new Api.InputMessageID({ id: song.tg_message_id })] }));
            if (!messages.messages[0] || !messages.messages[0].media) throw new Error('Media not found in Telegram');
            
            const buffer = await tgClient.downloadMedia(messages.messages[0].media, {});
            fs.writeFileSync(cacheFile, buffer);
            return cacheFile;
        })();

        const timeoutPromise = new Promise((_, reject) => 
            setTimeout(() => reject(new Error('TIMEOUT')), 25000)
        );

        try {
            await Promise.race([downloadPromise, timeoutPromise]);
            return streamFile(cacheFile, req, res);
        } catch (err) {
            if (err.message === 'TIMEOUT') {
                return res.status(503).json({ error: true, type: 'TIMEOUT', message: 'Telegram download timed out. Try again.' });
            }
            throw err;
        }
    } catch (err) { 
        console.error('Stream failed:', err);
        res.status(500).json({ error: true, message: 'Stream failed: ' + err.message }); 
    }
});

function streamFile(filePath, req, res) {
    const stat = fs.statSync(filePath);
    const range = req.headers.range;
    if (range) {
        const parts = range.replace(/bytes=/, "").split("-");
        const start = parseInt(parts[0], 10);
        const end = parts[1] ? parseInt(parts[1], 10) : stat.size - 1;
        res.writeHead(206, { 'Content-Range': `bytes ${start}-${end}/${stat.size}`, 'Accept-Ranges': 'bytes', 'Content-Length': (end - start) + 1, 'Content-Type': 'audio/mp4' });
        fs.createReadStream(filePath, { start, end }).pipe(res);
    } else {
        res.writeHead(200, { 'Content-Length': stat.size, 'Content-Type': 'audio/mp4', 'Accept-Ranges': 'bytes' });
        fs.createReadStream(filePath).pipe(res);
    }
}

app.get('/api/stats', async (req, res) => {
    try {
        const songs = await getLibrary();
        res.json({ totalSongs: songs.length, totalArtists: new Set(songs.map(s => s.artist.split(',')[0])).size });
    } catch (e) { res.status(500).send(); }
});

app.get('/api/precache/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        const cacheFile = path.join(CACHE_DIR, `${song.id}.m4a`);
        if (fs.existsSync(cacheFile)) return res.json({ status: 'ok' });
        await ensureTgConnected();
        const peer = await tgClient.getInputEntity(channelId);
        const messages = await tgClient.invoke(new Api.channels.GetMessages({ channel: peer, id: [new Api.InputMessageID({ id: song.tg_message_id })] }));
        const buffer = await tgClient.downloadMedia(messages.messages[0].media, {});
        fs.writeFileSync(cacheFile, buffer);
        res.json({ status: 'ok' });
    } catch (e) { res.status(500).send(); }
});

app.get('/api/playlists', async (req, res) => {
    try {
        const playlists = await getPlaylists();
        
        const updatedPlaylists = playlists.map(pl => {
            let img = pl.image;
            if (!img || img === '') {
                img = getRandomCoverImage(pl.id || pl.name);
            }
            return {
                ...pl,
                image: getAbsoluteImageUrl(req, img)
            };
        });
        res.json({ playlists: updatedPlaylists });
    } catch (err) { res.status(500).json({ error: 'Failed to fetch playlists' }); }
});

app.post('/api/playlists', async (req, res) => {
    try {
        const { name, image } = req.body;
        if (!name) throw new Error('Name is required');
        const id = 'pl-' + Date.now();
        
        let storedImage = image || '';
        if (storedImage.includes('/images/')) {
            const parts = storedImage.split('/images/');
            storedImage = `/images/${parts[parts.length - 1]}`;
        }

        const playlist = { 
            id, 
            name, 
            songs: [], 
            image: storedImage,
            created_at: new Date().toISOString() 
        };
        await db.collection('playlists').doc(id).set(playlist);
        playlistsCache = null; // Invalidate memory cache
        
        let plImg = playlist.image;
        if (!plImg || plImg === '') {
            plImg = getRandomCoverImage(id || name);
        }
        
        res.json({
            status: 'ok',
            playlist: {
                ...playlist,
                image: getAbsoluteImageUrl(req, plImg)
            }
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/playlists/:id/add', async (req, res) => {
    try {
        const { songId } = req.body;
        const plRef = db.collection('playlists').doc(req.params.id);
        const doc = await plRef.get();
        if (!doc.exists) throw new Error('Playlist not found');
        const data = doc.data();
        if (!data.songs.includes(songId)) {
            data.songs.push(songId);
            await plRef.update({ songs: data.songs });
            playlistsCache = null; // Invalidate memory cache
        }
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/playlists/:id', async (req, res) => {
    try {
        let playlist = null;
        if (playlistsCache) {
            playlist = playlistsCache.find(p => p.id === req.params.id);
        }
        if (!playlist) {
            console.log(`🔥 [Firestore] Fetching playlist detail for ${req.params.id} from DB...`);
            const doc = await db.collection('playlists').doc(req.params.id).get();
            if (!doc.exists) return res.status(404).json({ error: 'Not found' });
            playlist = doc.data();
        }
        const songs = [];
        if (playlist.songs && playlist.songs.length > 0) {
            const missingIds = [];
            for (const sid of playlist.songs) {
                let found = false;
                if (songsCache) {
                    const cached = songsCache.find(s => s.id === sid);
                    if (cached) {
                        let img = cached.image;
                        if (!img || img === '') {
                            img = getRandomCoverImage(cached.id || cached.name);
                        }
                        songs.push({
                            ...cached,
                            image: getAbsoluteImageUrl(req, img)
                        });
                        found = true;
                    }
                }
                if (!found) {
                    missingIds.push(sid);
                }
            }
            
            if (missingIds.length > 0) {
                console.log(`🔥 [Firestore] Fetching ${missingIds.length} missing songs for playlist from DB...`);
                const docRefs = missingIds.map(sid => db.collection('songs').doc(sid));
                const sdocs = await db.getAll(...docRefs);
                for (const sdoc of sdocs) {
                    if (sdoc.exists) {
                        let song = sdoc.data();
                        let img = song.image;
                        if (!img || img === '') {
                            img = getRandomCoverImage(song.id || song.name);
                        }
                        songs.push({
                            ...song,
                            image: getAbsoluteImageUrl(req, img)
                        });
                    }
                }
            }
        }
        
        let plImg = playlist.image;
        if (!plImg || plImg === '') {
            plImg = getRandomCoverImage(playlist.id || playlist.name);
        }
        
        res.json({
            ...playlist,
            image: getAbsoluteImageUrl(req, plImg),
            songs
        });
    } catch (err) { res.status(500).json({ error: 'Failed to fetch playlist: ' + err.message }); }
});

app.delete('/api/playlists/:id/songs/:songId', async (req, res) => {
    try {
        const { id, songId } = req.params;
        const plRef = db.collection('playlists').doc(id);
        const doc = await plRef.get();
        if (!doc.exists) throw new Error('Playlist not found');
        const data = doc.data();
        const updatedSongs = data.songs.filter(sid => sid !== songId);
        await plRef.update({ songs: updatedSongs });
        playlistsCache = null; // Invalidate memory cache
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/playlists/:id', async (req, res) => {
    try {
        await db.collection('playlists').doc(req.params.id).delete();
        playlistsCache = null; // Invalidate memory cache
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// GET single song details
app.get('/api/songs/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song) return res.status(404).json({ error: 'Song not found' });
        let img = song.image;
        if (!img || img === '') {
            img = getRandomCoverImage(song.id || song.name);
        }
        res.json({
            ...song,
            image: getAbsoluteImageUrl(req, img)
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// GET server time for sync compensation
app.get('/api/time', (req, res) => {
    res.json({ time: Date.now() });
});

// Helper: Generate a unique short Room ID
function generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let result = '';
    for (let i = 0; i < 5; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

// POST create a room
app.post('/api/rooms', async (req, res) => {
    try {
        let roomId;
        let docRef;
        let doc;
        let attempts = 0;
        
        do {
            roomId = generateRoomId();
            docRef = db.collection('rooms').doc(roomId);
            doc = await docRef.get();
            attempts++;
        } while (doc.exists && attempts < 10);

        if (doc.exists) {
            return res.status(500).json({ error: 'Failed to generate a unique room ID' });
        }

        const roomState = {
            roomId,
            currentSongId: '',
            isPlaying: false,
            position: 0,
            updatedAt: Date.now()
        };

        await docRef.set(roomState);
        res.json(roomState);
    } catch (err) {
        console.error('Create Room Failed:', err);
        res.status(500).json({ error: 'Failed to create room: ' + err.message });
    }
});

// GET room state
app.get('/api/rooms/:roomId', async (req, res) => {
    try {
        const roomId = req.params.roomId.toUpperCase();
        const doc = await db.collection('rooms').doc(roomId).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Room not found' });
        }
        res.json(doc.data());
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch room: ' + err.message });
    }
});

// POST update room state
app.post('/api/rooms/:roomId/update', async (req, res) => {
    try {
        const roomId = req.params.roomId.toUpperCase();
        const { currentSongId, isPlaying, position } = req.body;
        
        const docRef = db.collection('rooms').doc(roomId);
        const doc = await docRef.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Room not found' });
        }

        const updates = {
            updatedAt: Date.now()
        };
        if (currentSongId !== undefined) updates.currentSongId = currentSongId;
        if (isPlaying !== undefined) updates.isPlaying = isPlaying;
        if (position !== undefined) updates.position = parseFloat(position);

        await docRef.update(updates);
        
        const updatedDoc = await docRef.get();
        res.json(updatedDoc.data());
    } catch (err) {
        res.status(500).json({ error: 'Failed to update room: ' + err.message });
    }
});

// GET room stream via Server-Sent Events (SSE)
app.get('/api/rooms/:roomId/stream', async (req, res) => {
    const roomId = req.params.roomId.toUpperCase();
    
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    if (res.flushHeaders) res.flushHeaders();
    
    console.log(`📡 SSE client connected to room: ${roomId}`);

    const docRef = db.collection('rooms').doc(roomId);
    
    const unsubscribe = docRef.onSnapshot(doc => {
        if (doc.exists) {
            res.write(`data: ${JSON.stringify(doc.data())}\n\n`);
        } else {
            res.write(`data: ${JSON.stringify({ error: 'Room deleted' })}\n\n`);
        }
    }, err => {
        console.error(`SSE onSnapshot error for room ${roomId}:`, err);
        res.write(`data: ${JSON.stringify({ error: err.message })}\n\n`);
    });
    
    req.on('close', () => {
        console.log(`📡 SSE client disconnected from room: ${roomId}`);
        unsubscribe();
    });
});

// Final catch-all middleware for SPA
app.use((req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

async function start() { 
    await initTelegram();
    app.listen(PORT, () => {
        console.log(`🎵 Server listening on port ${PORT}`);
    });
}
start();
