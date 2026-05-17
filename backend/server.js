const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { Api } = require('telegram');
const { db } = require('./firebase');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// ── Telegram MTProto Client ──
const apiId = parseInt(process.env.TELEGRAM_API_ID);
const apiHash = process.env.TELEGRAM_API_HASH;
const botToken = process.env.TELEGRAM_BOT_TOKEN;
const channelId = (process.env.TELEGRAM_CHANNEL_ID || "").trim().replace(/['"]/g, "");
const stringSession = new StringSession(process.env.TELEGRAM_SESSION || "");
let tgClient = null;
let tgReady = false;

// ── Audio Cache ──
const CACHE_DIR = '/tmp/music-cache';
if (!fs.existsSync(CACHE_DIR)) fs.mkdirSync(CACHE_DIR, { recursive: true });

async function initTelegram() {
    console.log('🔄 Initializing Telegram...');
    console.log('Config:', { 
        apiId: apiId ? 'Present' : 'Missing', 
        apiHash: apiHash ? 'Present' : 'Missing', 
        botToken: botToken ? 'Present' : 'Missing',
        channelId: channelId ? 'Present' : 'Missing'
    });

    try {
        tgClient = new TelegramClient(stringSession, apiId, apiHash, {
            connectionRetries: 5,
            useWSS: false, // Cloud Run supports TCP
        });
        
        console.log('🔄 Connecting to Telegram...');
        await tgClient.start({
            botAuthToken: botToken,
        });
        
        tgReady = true;
        console.log('✅ Telegram client connected');
        
        // Test connection
        const me = await tgClient.getMe();
        console.log(`🤖 Logged in as: ${me.username}`);
    } catch (err) {
        console.error('❌ Telegram client failed:', err);
    }
}

app.use(cors());
app.use(express.json());

// Serve static frontend files & cached audio
app.use(express.static(path.join(__dirname, 'public')));
app.use('/cache', express.static(CACHE_DIR));

// Helper to read library from Firebase
async function getLibrary() {
    const snapshot = await db.collection('songs').get();
    const songs = [];
    snapshot.forEach(doc => {
        songs.push(doc.data());
    });
    // Sort by added_at (descending) so new songs appear at the top
    return songs.sort((a, b) => {
        const dateA = a.added_at?.toDate ? a.added_at.toDate() : new Date(a.added_at || 0);
        const dateB = b.added_at?.toDate ? b.added_at.toDate() : new Date(b.added_at || 0);
        return dateB - dateA;
    });
}

async function getSongById(id) {
    const doc = await db.collection('songs').doc(id).get();
    return doc.exists ? doc.data() : null;
}

// API: Get all songs
app.get('/api/songs', async (req, res) => {
    try {
        const songs = await getLibrary();
        res.json({ songs, total: songs.length });
    } catch (err) {
        console.error('Library fetch error:', err);
        res.status(500).json({ error: 'Failed to read library from cloud' });
    }
});

// API: Search songs
app.get('/api/search', async (req, res) => {
    try {
        const query = (req.query.q || '').toLowerCase();
        const songs = await getLibrary();
        const results = songs.filter(s =>
            s.name.toLowerCase().includes(query) ||
            s.artist.toLowerCase().includes(query)
        );
        res.json({ results, total: results.length });
    } catch (err) {
        res.status(500).json({ error: 'Search failed' });
    }
});

// API: Get single song
app.get('/api/songs/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song) return res.status(404).json({ error: 'Song not found' });
        res.json(song);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch song' });
    }
});

// API: Library stats
app.get('/api/stats', async (req, res) => {
    try {
        const songs = await getLibrary();
        const totalDuration = songs.reduce((acc, s) => acc + (s.duration_ms || 0), 0);
        const artists = [...new Set(songs.map(s => s.artist.split(',')[0].trim()))];
        res.json({
            totalSongs: songs.length,
            totalDurationMs: totalDuration,
            totalArtists: artists.length,
            lastSynced: songs.length > 0 ? (songs[0].added_at?.toDate ? songs[0].added_at.toDate() : songs[0].added_at) : null
        });
    } catch (err) {
        res.status(500).json({ error: 'Failed to get stats' });
    }
});

// API: Cache stats
app.get('/api/cache-stats', async (req, res) => {
    try {
        const files = fs.readdirSync(CACHE_DIR).filter(f => f.endsWith('.m4a'));
        let totalSize = 0;
        files.forEach(f => { totalSize += fs.statSync(path.join(CACHE_DIR, f)).size; });
        const songs = await getLibrary();
        res.json({
            cachedCount: files.length,
            totalSongs: songs.length,
            cachedIds: files.map(f => f.replace('.m4a', '')),
            totalSizeMB: +(totalSize / 1024 / 1024).toFixed(1)
        });
    } catch (e) {
        res.json({ cachedCount: 0, totalSongs: 0, cachedIds: [], totalSizeMB: 0 });
    }
});

// API: Download all songs (SSE progress stream)
app.get('/api/download-all', async (req, res) => {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders();

    if (!tgReady) {
        res.write(`data: ${JSON.stringify({ error: 'Telegram not connected' })}\n\n`);
        res.end();
        return;
    }

    const songs = getLibrary().filter(s => s.tg_message_id);
    const total = songs.length;
    let done = 0;
    let failed = 0;

    for (const song of songs) {
        const cacheFile = path.join(CACHE_DIR, `${song.id}.m4a`);
        if (fs.existsSync(cacheFile)) {
            done++;
            res.write(`data: ${JSON.stringify({ done, total, failed, song: song.name, status: 'cached' })}\n\n`);
            continue;
        }

        try {
            const peer = await tgClient.getInputEntity(channelId);
            const messages = await tgClient.invoke(
                new Api.channels.GetMessages({
                    channel: peer,
                    id: [new Api.InputMessageID({ id: song.tg_message_id })]
                })
            );
            const message = messages.messages[0];
            if (message && message.media) {
                const buffer = await tgClient.downloadMedia(message.media, {});
                fs.writeFileSync(cacheFile, buffer);
                console.log(`✅ Bulk cached: ${song.name} (${(buffer.length / 1024 / 1024).toFixed(1)} MB)`);
            }
            done++;
            res.write(`data: ${JSON.stringify({ done, total, failed, song: song.name, status: 'downloaded' })}\n\n`);
        } catch (err) {
            failed++;
            done++;
            console.error(`❌ Failed: ${song.name} - ${err.message}`);
            res.write(`data: ${JSON.stringify({ done, total, failed, song: song.name, status: 'failed' })}\n\n`);
        }
    }

    res.write(`data: ${JSON.stringify({ done: total, total, failed, status: 'complete' })}\n\n`);
    res.end();
});

// API: Precache audio from Telegram
app.get('/api/precache/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song || !song.tg_message_id) {
            return res.status(404).json({ error: 'Song not found or no Telegram message ID' });
        }

        const cacheFile = path.join(CACHE_DIR, `${song.id}.m4a`);

        // If cached, return success
        if (fs.existsSync(cacheFile)) {
            return res.json({ status: 'ok', cached: true });
        }

        // Download from Telegram
        if (!tgReady) {
            return res.status(503).json({ error: 'Telegram not connected yet' });
        }

        console.log(`⬇️  Precaching: ${song.name} (msg: ${song.tg_message_id})`);

        const peer = await tgClient.getInputEntity(channelId);
        const messages = await tgClient.invoke(
            new Api.channels.GetMessages({
                channel: peer,
                id: [new Api.InputMessageID({ id: song.tg_message_id })]
            })
        );

        const message = messages.messages[0];
        if (!message || !message.media) {
            return res.status(404).json({ error: 'No media found in Telegram message' });
        }

        // Download file to cache
        const buffer = await tgClient.downloadMedia(message.media, {});
        fs.writeFileSync(cacheFile, buffer);
        console.log(`✅ Precached: ${song.name} (${(buffer.length / 1024 / 1024).toFixed(1)} MB)`);

        return res.json({ status: 'ok', cached: true });

    } catch (err) {
        console.error('Precache error:', err.message);
        res.status(500).json({ error: 'Failed to precache audio' });
    }
});

// API: Stream audio from Telegram
app.get('/api/stream/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song || !song.tg_message_id) {
            return res.status(404).json({ error: 'Song not found or no Telegram message ID' });
        }

        const cacheFile = path.join(CACHE_DIR, `${song.id}.m4a`);

        // If cached, serve from disk
        if (fs.existsSync(cacheFile)) {
            return streamFile(cacheFile, req, res);
        }

        // Download from Telegram
        if (!tgReady) {
            return res.status(503).json({ error: 'Telegram not connected yet' });
        }

        console.log(`⬇️  Downloading: ${song.name} (msg: ${song.tg_message_id})`);

        const peer = await tgClient.getInputEntity(channelId);
        const messages = await tgClient.invoke(
            new Api.channels.GetMessages({
                channel: peer,
                id: [new Api.InputMessageID({ id: song.tg_message_id })]
            })
        );

        const message = messages.messages[0];
        if (!message || !message.media) {
            return res.status(404).json({ error: 'No media found in Telegram message' });
        }

        // Download file to cache
        const buffer = await tgClient.downloadMedia(message.media, {});
        fs.writeFileSync(cacheFile, buffer);
        console.log(`✅ Cached: ${song.name} (${(buffer.length / 1024 / 1024).toFixed(1)} MB)`);

        return streamFile(cacheFile, req, res);

    } catch (err) {
        console.error('Stream error:', err.message);
        res.status(500).json({ error: 'Failed to stream audio' });
    }
});

// Helper: stream file with Range support
function streamFile(filePath, req, res) {
    const stat = fs.statSync(filePath);
    const fileSize = stat.size;
    const range = req.headers.range;

    if (range) {
        const parts = range.replace(/bytes=/, "").split("-");
        const start = parseInt(parts[0], 10);
        const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
        const chunkSize = (end - start) + 1;
        const stream = fs.createReadStream(filePath, { start, end });
        res.writeHead(206, {
            'Content-Range': `bytes ${start}-${end}/${fileSize}`,
            'Accept-Ranges': 'bytes',
            'Content-Length': chunkSize,
            'Content-Type': 'audio/mp4',
        });
        stream.pipe(res);
    } else {
        res.writeHead(200, {
            'Content-Length': fileSize,
            'Content-Type': 'audio/mp4',
            'Accept-Ranges': 'bytes',
        });
        fs.createReadStream(filePath).pipe(res);
    }
}

// SPA fallback — MUST be last
app.get('{*path}', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ── Start Server ──
async function start() {
    await initTelegram();
    app.listen(PORT, () => {
        console.log(`🎵 Sonic Vault server running at http://localhost:${PORT}`);
    });
}
start();

