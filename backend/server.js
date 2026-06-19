const express = require('express');
const http = require('http');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const { db, admin } = require('./firebase');
const { addSong } = require('./adder');
const { getPresignedUrl, deleteFromB2 } = require('./s3');
const { initSyncEngine } = require('./sync_engine');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

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

// Authentication Middleware
async function authenticateToken(req, res, next) {
    if (req.method === 'OPTIONS') return next();

    // If it's a GET request, bypass token requirement but parse it if available
    if (req.method === 'GET') {
        const authHeader = req.headers['authorization'];
        const token = authHeader && authHeader.split(' ')[1];
        if (token) {
            try {
                const decodedToken = await admin.auth().verifyIdToken(token);
                req.user = decodedToken;
            } catch (error) {
                console.error('Firebase Auth Optional Error (GET):', error.message);
            }
        }
        return next();
    }

    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Authentication token is missing.' });
    }

    try {
        const decodedToken = await admin.auth().verifyIdToken(token);
        req.user = decodedToken;
        next();
    } catch (error) {
        console.error('Firebase Auth Error:', error.message);
        return res.status(403).json({ error: 'Invalid or expired authentication token.' });
    }
}

app.use('/api', authenticateToken);

let songsCache = [];
let playlistsCache = [];

function listenToLibrary() {
    console.log('🔄 [Firestore] Setting up real-time library listeners...');
    
    db.collection('songs').onSnapshot(snapshot => {
        const songs = [];
        snapshot.forEach(doc => songs.push(doc.data()));
        songsCache = songs.sort((a, b) => (b.added_at?.toDate ? b.added_at.toDate() : new Date(b.added_at || 0)) - (a.added_at?.toDate ? a.added_at.toDate() : new Date(a.added_at || 0)));
        console.log(`⚡ [Firestore] Library cache updated: ${songsCache.length} songs`);
    }, err => {
        console.error('❌ [Firestore] Library listener error:', err);
    });

    db.collection('playlists').onSnapshot(snapshot => {
        const playlists = [];
        snapshot.forEach(doc => playlists.push({ id: doc.id, ...doc.data() }));
        playlistsCache = playlists;
        console.log(`⚡ [Firestore] Playlists cache updated: ${playlistsCache.length} playlists`);
    }, err => {
        console.error('❌ [Firestore] Playlists listener error:', err);
    });
}

async function getLibrary() {
    return songsCache;
}

async function getSongById(id) {
    const cached = songsCache.find(s => s.id === id);
    if (cached) return cached;
    
    console.log(`🔥 [Firestore] Fetching song detail for ${id} from DB...`);
    const doc = await db.collection('songs').doc(id).get();
    return doc.exists ? doc.data() : null;
}

async function getPlaylists() {
    return playlistsCache;
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

        // 1. Delete from Backblaze B2 (optional/best-effort)
        const fileKey = song.fileKey || `${song.id}.m4a`;
        try {
            await deleteFromB2(fileKey);
            console.log(`Deleted B2 object ${fileKey} for ${song.name}`);
        } catch (err) {
            console.warn(`B2 Delete Failed for ${id}:`, err.message);
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
        if (!song) return res.status(404).json({ error: true, message: 'Not found' });

        const key = song.fileKey || `${song.id}.m4a`;
        const presignedUrl = await getPresignedUrl(key, 3600);
        res.redirect(302, presignedUrl);
    } catch (err) {
        console.error('Stream failed:', err);
        res.status(500).json({ error: true, message: 'Stream failed: ' + err.message });
    }
});


app.get('/api/stats', async (req, res) => {
    try {
        const songs = await getLibrary();
        res.json({ totalSongs: songs.length, totalArtists: new Set(songs.map(s => s.artist.split(',')[0])).size });
    } catch (e) { res.status(500).send(); }
});

app.get('/api/precache/:id', async (req, res) => {
    // Pre-caching is obsolete under B2 architecture; return success immediately
    res.json({ status: 'ok', message: 'Pre-caching not required' });
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
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/playlists/:id', async (req, res) => {
    try {
        await db.collection('playlists').doc(req.params.id).delete();
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



// Final catch-all middleware for SPA
app.use((req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

async function start() { 
    listenToLibrary();
    const server = http.createServer(app);
    initSyncEngine(server, admin);
    server.listen(PORT, () => {
        console.log(`🎵 Server listening on port ${PORT}`);
    });
}
start();
