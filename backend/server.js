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
        if (!apiId || !apiHash) {
            console.error('❌ Missing TELEGRAM_API_ID or TELEGRAM_API_HASH');
            return;
        }
        tgClient = new TelegramClient(stringSession, apiId, apiHash, { connectionRetries: 5, useWSS: false });
        await tgClient.start({ botAuthToken: botToken });
        tgReady = true;
        console.log('✅ Telegram connected');
    } catch (err) { console.error('❌ Telegram failed:', err); }
}

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));
app.use('/cache', express.static(CACHE_DIR));

// Android TWA Trust Handshake
app.get('/.well-known/assetlinks.json', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', '.well-known', 'assetlinks.json'));
});

async function getLibrary() {
    const snapshot = await db.collection('songs').get();
    const songs = [];
    snapshot.forEach(doc => songs.push(doc.data()));
    return songs.sort((a, b) => (b.added_at?.toDate ? b.added_at.toDate() : new Date(b.added_at || 0)) - (a.added_at?.toDate ? a.added_at.toDate() : new Date(a.added_at || 0)));
}

async function getSongById(id) {
    const doc = await db.collection('songs').doc(id).get();
    return doc.exists ? doc.data() : null;
}

app.post('/api/add-song', async (req, res) => {
    try {
        const track = await addSong(req.body);
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

        res.json({ status: 'ok' });
    } catch (err) {
        console.error('Delete song failed:', err);
        res.status(500).json({ error: err.message });
    }
});

app.get('/api/songs', async (req, res) => {
    try { const songs = await getLibrary(); res.json({ songs, total: songs.length }); }
    catch (err) { res.status(500).json({ error: true, message: 'Library failed' }); }
});

app.get('/api/stream/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song || !song.tg_message_id) return res.status(404).json({ error: true, message: 'Not found' });
        const cacheFile = path.join(CACHE_DIR, `${song.id}.m4a`);
        if (fs.existsSync(cacheFile)) return streamFile(cacheFile, req, res);
        
        if (!tgReady) {
            return res.status(503).json({ error: true, type: 'BUSY', message: 'Telegram client is not ready' });
        }

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
        if (!tgReady) return res.status(503).send();
        const peer = await tgClient.getInputEntity(channelId);
        const messages = await tgClient.invoke(new Api.channels.GetMessages({ channel: peer, id: [new Api.InputMessageID({ id: song.tg_message_id })] }));
        const buffer = await tgClient.downloadMedia(messages.messages[0].media, {});
        fs.writeFileSync(cacheFile, buffer);
        res.json({ status: 'ok' });
    } catch (e) { res.status(500).send(); }
});

app.get('/api/playlists', async (req, res) => {
    try {
        const snapshot = await db.collection('playlists').get();
        const playlists = [];
        snapshot.forEach(doc => playlists.push({ id: doc.id, ...doc.data() }));
        res.json({ playlists });
    } catch (err) { res.status(500).json({ error: 'Failed to fetch playlists' }); }
});

app.post('/api/playlists', async (req, res) => {
    try {
        const { name } = req.body;
        if (!name) throw new Error('Name is required');
        const id = 'pl-' + Date.now();
        const playlist = { id, name, songs: [], created_at: new Date().toISOString() };
        await db.collection('playlists').doc(id).set(playlist);
        res.json({ status: 'ok', playlist });
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
        }
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/playlists/:id', async (req, res) => {
    try {
        const doc = await db.collection('playlists').doc(req.params.id).get();
        if (!doc.exists) return res.status(404).json({ error: 'Not found' });
        const playlist = doc.data();
        const songs = [];
        for (const sid of playlist.songs) {
            const sdoc = await db.collection('songs').doc(sid).get();
            if (sdoc.exists) songs.push(sdoc.data());
        }
        res.json({ ...playlist, songs });
    } catch (err) { res.status(500).json({ error: 'Failed to fetch playlist' }); }
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
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/playlists/:id', async (req, res) => {
    try {
        await db.collection('playlists').doc(req.params.id).delete();
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
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
