# Static Application Security Testing (SAST) & Architectural Review
**Target Project:** Sonic Vault Node.js/Express Backend  
**Date:** June 18, 2026  
**Status:** DRAFT (Ready for Audit & Integration)

---

## 1. Executive Summary
This report details the findings of a Static Application Security Testing (SAST) and architectural review conducted on the **Sonic Vault** backend codebase. 

Sonic Vault is a Node.js/Express-based audio processing gateway interfacing with **Backblaze B2** (storage) and **Cloud Firestore** (database). It handles metadata extraction and audio stream downloading/transcoding via `yt-dlp` and `ffmpeg`.

Due to AI-assisted generation ("vibe coding"), the current codebase prioritizes functionality and speed over security constraints. This has left the application exposed to severe security flaws including **Command/Argument Injection (Remote Code Execution)**, **Broken API Access Control**, **Resource Exhaustion (Denial of Service)**, and **Insecure Direct Object Reference (IDOR)**.

---

## 2. Architectural Threat Model Summary

Sonic Vault operates as an API Gateway connecting mobile client applications with external media services and cloud infrastructure.

### Data Flow & Trust Boundaries
```
[ Untrusted Web/Mobile Client ] 
             |
             |  (Internet Boundary - Wildcard CORS, Unauthenticated HTTP REST)
             v
    [ Express API Gateway ]
       /     |     \
      /      |      \   (Internal Subprocess Execution)
     /       |       v
    /        |    [ yt-dlp / ffmpeg ]  <---> [ YouTube Platform ]
   /         v
  /     [ Firebase Admin SDK ] <---> [ Cloud Firestore DB ]
 v
[ AWS S3 SDK ] <---> [ Backblaze B2 Vault ]
```

### Key Trust Vectors & Critical Threat Scenarios:
1. **Unauthenticated Boundary Input:** The API Gateway accepts arbitrary text inputs (URLs, queries, Room IDs) and directly executes or stores them without verification or authorization.
2. **Subprocess Sanitization Leakage:** Standard subprocess calls to `yt-dlp` omit critical CLI option delimiters (`--`), allowing query or URL strings that start with `-` to act as flags (Argument Injection).
3. **Privileged Backend Context:** The Express backend holds high-privilege credentials (`B2_APPLICATION_KEY` and firebase service key) capable of reading/writing all user media. Compromise of the server process via RCE implies complete compromise of these cloud environments.
4. **Denial of Service (DoS):** Media download processes are highly CPU- and RAM-intensive. The lack of rate limiters or queue processing permits malicious clients to run multiple download requests in parallel, exhausting host resources.

---

## 3. Vulnerability Report Table

| Severity | Category | File Path | Description | Remediation |
| :--- | :--- | :--- | :--- | :--- |
| **CRITICAL** | Command / Argument Injection | [downloader.js](file:///d:/music/backend/downloader.js)<br>[adder.js](file:///d:/music/backend/adder.js) | YouTube URLs are passed directly to `yt-dlp` subprocesses without validation. An attacker can pass options like `--exec` or configuration flags, executing arbitrary code in the server's context. | Validate inputs against a strict YouTube URL pattern and utilize the `--` option separator before passing values to `spawn`/`spawnSync`. |
| **CRITICAL** | Broken Access Control | [server.js](file:///d:/music/backend/server.js) | All write, delete, and streaming API endpoints (`/api/add-song`, `/api/songs/:id`, `/api/playlists`) are completely unauthenticated. | Introduce a token-based authentication middleware (e.g., matching a shared secret key or JWT). |
| **HIGH** | Resource Exhaustion (DoS) | [server.js](file:///d:/music/backend/server.js) | The `/api/add-song` endpoint starts a heavy transcoding and download subprocess. There are no rate limits, queues, or concurrent limit rules. | Enforce rate limiting via `express-rate-limit` and configure a queue limit. |
| **MEDIUM** | Insecure Direct Object Reference (IDOR) | [server.js](file:///d:/music/backend/server.js) | The listening room update API endpoint (`/api/rooms/:roomId/update`) allows anyone guessing the 5-character short room ID to modify active playback details. | Generate a unique `roomSecret` during creation. Require this secret in the update payload for state modifications. |
| **MEDIUM** | Weak CORS Configuration | [server.js](file:///d:/music/backend/server.js) | Enforces wildcard CORS (`*`), allowing untrusted sites to issue cross-origin requests and read non-opaque responses. | Configure restrictive CORS rules to accept requests only from designated origins or mobile clients. |
| **LOW** | Verbose Error Leakage | [server.js](file:///d:/music/backend/server.js) | Error handlers respond with internal system trace statements (`err.message`), exposing package names, file paths, and database fields. | Log verbose errors internally and return sanitized, consumer-safe error strings to the client. |

---

## 4. Secure Code Patches

Below are the complete secure code replacements to mitigate the vulnerabilities.

### 4.1. Secure `backend/downloader.js`
This patch restricts download URLs to verified YouTube domains, sanitizes track search names, and uses the `--` argument delimiter to block CLI argument injection.

```javascript
const { spawn, spawnSync } = require('child_process');
const path = require('path');
const fs = require('fs');

/**
 * Validates whether a given URL is a legitimate YouTube endpoint.
 */
function isValidYoutubeUrl(url) {
  if (!url) return false;
  try {
    const parsed = new URL(url);
    const validHosts = ['youtube.com', 'www.youtube.com', 'youtu.be', 'www.youtu.be', 'music.youtube.com'];
    return (parsed.protocol === 'http:' || parsed.protocol === 'https:') && 
           validHosts.some(host => parsed.hostname.endsWith(host));
  } catch (e) {
    return false;
  }
}

async function downloadSong(songName, artistName, directUrl = null) {
  if (directUrl && !isValidYoutubeUrl(directUrl)) {
    throw new Error('Invalid or unauthorized download URL provided.');
  }

  // Prevent file path traversal and sanitize track names
  const sanitizedSong = songName.replace(/[/\\?%*:|"<>]/g, '-');
  const sanitizedArtist = artistName.replace(/[/\\?%*:|"<>]/g, '-');
  const query = `${sanitizedSong} ${sanitizedArtist} lyrics`;
  
  const outputDir = path.join(__dirname, 'downloads');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const fileName = `${sanitizedSong}.m4a`;
  const outputPath = path.join(outputDir, fileName);

  const baseArgs = [
    '--extract-audio',
    '--audio-format', 'm4a',
    '--no-playlist',
    '--js-runtimes', 'nodejs'
  ];

  const ffmpegLocation = process.env.FFMPEG_LOCATION;
  if (ffmpegLocation) {
    baseArgs.push('--ffmpeg-location', ffmpegLocation);
  }

  baseArgs.push('-o', outputPath);

  // CRITICAL: Double dash forces yt-dlp to stop option parsing.
  // Any following value (even if starting with a dash) will be treated as positional arguments (URLs/Queries).
  baseArgs.push('--'); 
  baseArgs.push(directUrl ? directUrl : `ytsearch1:${query}`);

  let cmd = 'yt-dlp';
  let args = [...baseArgs];

  try {
    const check = spawnSync('yt-dlp', ['--version']);
    if (check.status !== 0) {
      throw new Error('yt-dlp returned non-zero status');
    }
  } catch (err) {
    console.log('⚠️ yt-dlp direct command not available, falling back to python module...');
    cmd = process.platform === 'win32' ? 'python' : 'python3';
    args = ['-m', 'yt_dlp', ...baseArgs];
  }

  return new Promise((resolve, reject) => {
    console.log(`🚀 Spawning: ${cmd} ${args.join(' ')}`);
    const child = spawn(cmd, args);

    child.stdout.on('data', (data) => {
      const output = data.toString();
      if (output.includes('%')) {
        process.stdout.write(`\rProgress: ${output.trim().split(' ').filter(x => x.includes('%'))[0] || ''}    `);
      }
    });

    child.stderr.on('data', (data) => {
      const output = data.toString().trim();
      if (output) {
        console.error(`stderr: ${output}`);
      }
    });

    child.on('close', (code) => {
      if (code === 0) {
        console.log(`\n✅ Successfully downloaded: ${fileName}`);
        resolve(outputPath);
      } else {
        console.error(`\n❌ Failed to download with exit code ${code}`);
        reject(new Error(`Exit code ${code}`));
      }
    });
  });
}

module.exports = { downloadSong };
```

---

### 4.2. Secure `backend/adder.js`
This patch enforces strict URL filters and secure positional formatting during yt-dlp metadata inquiries.

```javascript
const { getPlaylistTracks } = require('./spotify');
const { downloadSong } = require('./downloader');
const { uploadToB2 } = require('./s3');
const { db } = require('./firebase');
const admin = require('firebase-admin');
const crypto = require('crypto');
const { spawnSync } = require('child_process');
const fs = require('fs');

/**
 * Validates whether a given URL is a legitimate YouTube endpoint.
 */
function isValidYoutubeUrl(url) {
    if (!url) return false;
    try {
        const parsed = new URL(url);
        const validHosts = ['youtube.com', 'www.youtube.com', 'youtu.be', 'www.youtu.be', 'music.youtube.com'];
        return (parsed.protocol === 'http:' || parsed.protocol === 'https:') && 
               validHosts.some(host => parsed.hostname.endsWith(host));
    } catch (e) {
        return false;
    }
}

function getYTMetadata(url) {
    if (!isValidYoutubeUrl(url)) {
        console.error('❌ Aborted metadata pull: Invalid YouTube URL');
        return null;
    }
    
    console.log('📡 Extracting metadata from YouTube...');
    
    // Command args using double-dash to prevent argument injection
    const args = ['--print', '%(title)s\|%(uploader)s\|%(thumbnail)s', '--no-playlist', '--', url];
    
    let result = spawnSync('yt-dlp', args, { encoding: 'utf8' });
    
    if (result.error || result.status !== 0) {
        console.log('⚠️ yt-dlp direct execution failed, trying python fallback...');
        const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';
        const pythonArgs = [ '-m', 'yt_dlp', '--print', '%(title)s\|%(uploader)s\|%(thumbnail)s', '--no-playlist', '--', url ];
        result = spawnSync(pythonCmd, pythonArgs, { encoding: 'utf8' });
    }

    if (result.status === 0 && result.stdout) {
        const lines = result.stdout.split('\n');
        const metaLine = lines.find(l => l.includes('|'));
        if (metaLine) {
            const [name, artist, image] = metaLine.trim().split('|');
            return { name, artist, image };
        }
    }
    return null;
}

async function addSong(data) {
    let { name, artist, url } = data;
    let image = null;
    let directUrl = null;
    let spotifyId = null;

    console.log(`📡 Processing addition request:`, data);

    try {
        if (url && url.trim() !== '') {
            if (url.includes('spotify.com/')) {
                console.log('🟢 Detected Spotify Link');
                const tracks = await getPlaylistTracks(url);
                if (!tracks || tracks.length === 0) throw new Error('Failed to fetch Spotify metadata');
                const t = tracks[0];
                name = t.name;
                artist = t.artist;
                image = t.image;
                spotifyId = t.id;
            } 
            else if (url.includes('youtube.com/') || url.includes('youtu.be/')) {
                console.log('🔴 Detected YouTube Link');
                directUrl = url.trim();
                
                if (!isValidYoutubeUrl(directUrl)) {
                    throw new Error('Provided YouTube link is malformed or invalid');
                }
                
                const meta = getYTMetadata(directUrl);
                if (meta) {
                    name = meta.name;
                    artist = meta.artist;
                    image = meta.image;
                } else {
                    throw new Error('Could not extract metadata from YouTube link');
                }
            } else {
                throw new Error('Unsupported URL format. Only Spotify and YouTube URLs are allowed.');
            }
        }

        if (!name || !artist) {
            throw new Error('Song Name and Artist are required if no direct link is provided.');
        }

        const trackId = spotifyId || ('manual-' + crypto.randomBytes(6).toString('hex'));
        
        const doc = await db.collection('songs').doc(trackId).get();
        if (doc.exists) {
            console.log('⚠️ Track already exists in library');
            return doc.data();
        }

        const track = {
            id: trackId,
            name: name.trim(),
            artist: artist.trim(),
            album: 'Synced Addition',
            image: image || null
        };

        console.log(`⏳ Downloading: ${track.name} by ${track.artist}`);
        const filePath = await downloadSong(track.name, track.artist, directUrl);

        console.log(`⏳ Syncing to private Backblaze B2 vault...`);
        const fileKey = `${track.id}.m4a`;
        const fileBuffer = fs.readFileSync(filePath);
        await uploadToB2(fileBuffer, fileKey, 'audio/mp4');

        try {
            fs.unlinkSync(filePath);
            console.log(`🧹 Cleaned up local file: ${filePath}`);
        } catch (unlinkErr) {
            console.warn(`⚠️ Failed to delete local temp file ${filePath}:`, unlinkErr.message);
        }

        const finalData = {
            ...track,
            fileKey,
            added_at: admin.firestore.FieldValue.serverTimestamp()
        };
        await db.collection('songs').doc(track.id).set(finalData);

        console.log('✨ Successfully added to B2 vault!');
        return finalData;

    } catch (err) {
        console.error('❌ Add song error:', err.message);
        throw err;
    }
}

module.exports = { addSong };
```

---

### 4.3. Secure `backend/server.js`
This patch enforces Bearer Token authentication via environment variables, restrictive CORS settings, global and endpoint rate limiters, IDOR mitigation through room passcodes (`roomSecret`), and secure error response handlers.

To support this file, make sure to add `express-rate-limit` to `dependencies` in `package.json`.

```javascript
const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
const rateLimit = require('express-rate-limit');
const crypto = require('crypto');
const { db } = require('./firebase');
const { addSong } = require('./adder');
const { getPresignedUrl, deleteFromB2 } = require('./s3');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 8080;

// 1. SECURE CORS CONFIGURATION
const allowedOrigins = process.env.ALLOWED_ORIGINS ? process.env.ALLOWED_ORIGINS.split(',') : [];
const corsOptions = {
    origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps or curl)
        if (!origin || allowedOrigins.includes(origin)) {
            callback(null, true);
        } else {
            callback(new Error('Blocked by CORS policy'));
        }
    },
    methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
};
app.use(cors(corsOptions));
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// 2. RATE LIMITING MIDDLEWARES
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per window
    message: { error: 'Too many requests, please try again later.' }
});
app.use(globalLimiter);

// Strict rate limiting for the heavy transcoding/downloading endpoint
const downloadLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 hour
    max: 15, // Limit each IP to 15 audio transcoding downloads per hour
    message: { error: 'Transcode limit reached. Please wait a while before requesting another download.' }
});

// 3. SECURE AUTHENTICATION MIDDLEWARE
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Expecting "Bearer <TOKEN>"
    
    const configuredToken = process.env.API_KEY || process.env.JWT_SECRET;
    if (!configuredToken) {
        console.warn('⚠️ Warning: No backend API_KEY or JWT_SECRET configured in .env. Blocked request.');
        return res.status(501).json({ error: 'Server authentication configuration error.' });
    }

    if (!token) {
        return res.status(401).json({ error: 'Authentication token is missing.' });
    }

    if (token !== configuredToken) {
        return res.status(403).json({ error: 'Invalid authentication token.' });
    }
    next();
}

// Images resolving logic
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
        res.status(500).json({ error: 'Failed to retrieve image list.' });
    }
});

function getRandomCoverImage(idSeed) {
    try {
        if (fs.existsSync(IMAGES_DIR)) {
            const files = fs.readdirSync(IMAGES_DIR).filter(file => {
                const ext = path.extname(file).toLowerCase();
                return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);
            });
            if (files.length > 0) {
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

function getAbsoluteImageUrl(req, relativePath) {
    if (!relativePath) return '';
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
        return relativePath;
    }
    const host = req.get('host');
    const protocol = req.protocol;
    return `${protocol}://${host}${relativePath}`;
}

app.get('/.well-known/assetlinks.json', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', '.well-known', 'assetlinks.json'));
});

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

// 4. SECURING WRITE ENDPOINTS
app.post('/api/add-song', authenticateToken, downloadLimiter, async (req, res) => {
    try {
        const track = await addSong(req.body);
        res.json({ status: 'ok', track });
    } catch (err) { 
        console.error('API add-song error:', err);
        const errorType = err.message.includes('TIMEOUT') ? 'TIMEOUT' : 'GENERAL';
        res.status(500).json({ 
            error: true, 
            type: errorType, 
            message: 'Failed to transcode and add track'
        }); 
    }
});

app.delete('/api/songs/:id', authenticateToken, async (req, res) => {
    try {
        const id = req.params.id;
        const song = await getSongById(id);
        if (!song) return res.status(404).json({ error: 'Song not found' });

        const fileKey = song.fileKey || `${song.id}.m4a`;
        try {
            await deleteFromB2(fileKey);
            console.log(`Deleted B2 object ${fileKey} for ${song.name}`);
        } catch (err) {
            console.warn(`B2 Delete Failed for ${id}:`, err.message);
        }

        await db.collection('songs').doc(id).delete();
        
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
        res.status(500).json({ error: 'Failed to delete song' });
    }
});

// Read routes do not require auth in standard mobile streaming context, but can be locked if required
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
    catch (err) { res.status(500).json({ error: true, message: 'Failed to read library' }); }
});

app.get('/api/stream/:id', async (req, res) => {
    try {
        const song = await getSongById(req.params.id);
        if (!song) return res.status(404).json({ error: true, message: 'Song not found' });

        const key = song.fileKey || `${song.id}.m4a`;
        const presignedUrl = await getPresignedUrl(key, 3600);
        res.redirect(302, presignedUrl);
    } catch (err) {
        console.error('Stream failed:', err);
        res.status(500).json({ error: true, message: 'Stream generation failed' });
    }
});

app.get('/api/stats', async (req, res) => {
    try {
        const songs = await getLibrary();
        res.json({ totalSongs: songs.length, totalArtists: new Set(songs.map(s => s.artist.split(',')[0])).size });
    } catch (e) { res.status(500).send(); }
});

app.get('/api/precache/:id', async (req, res) => {
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

app.post('/api/playlists', authenticateToken, async (req, res) => {
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
    } catch (err) { res.status(500).json({ error: 'Failed to create playlist' }); }
});

app.post('/api/playlists/:id/add', authenticateToken, async (req, res) => {
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
    } catch (err) { res.status(500).json({ error: 'Failed to add song to playlist' }); }
});

app.get('/api/playlists/:id', async (req, res) => {
    try {
        let playlist = null;
        if (playlistsCache) {
            playlist = playlistsCache.find(p => p.id === req.params.id);
        }
        if (!playlist) {
            const doc = await db.collection('playlists').doc(req.params.id).get();
            if (!doc.exists) return res.status(404).json({ error: 'Playlist not found' });
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
    } catch (err) { res.status(500).json({ error: 'Failed to fetch playlist details' }); }
});

app.delete('/api/playlists/:id/songs/:songId', authenticateToken, async (req, res) => {
    try {
        const { id, songId } = req.params;
        const plRef = db.collection('playlists').doc(id);
        const doc = await plRef.get();
        if (!doc.exists) throw new Error('Playlist not found');
        const data = doc.data();
        const updatedSongs = data.songs.filter(sid => sid !== songId);
        await plRef.update({ songs: updatedSongs });
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: 'Failed to remove song from playlist' }); }
});

app.delete('/api/playlists/:id', authenticateToken, async (req, res) => {
    try {
        await db.collection('playlists').doc(req.params.id).delete();
        res.json({ status: 'ok' });
    } catch (err) { res.status(500).json({ error: 'Failed to delete playlist' }); }
});

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
        res.status(500).json({ error: 'Failed to fetch song metadata' });
    }
});

app.get('/api/time', (req, res) => {
    res.json({ time: Date.now() });
});

function generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let result = '';
    for (let i = 0; i < 5; i++) {
        result += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return result;
}

// 5. SECURITY FIX: GEN ROOM SECRET TO PREVENT ROOM IDOR
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

        // Generate a cryptographically secure 16-character room secret passcode
        const roomSecret = crypto.randomBytes(8).toString('hex');

        const roomState = {
            roomId,
            roomSecret, // Kept in database, sent to creator so they can authorize updates
            currentSongId: '',
            isPlaying: false,
            position: 0,
            updatedAt: Date.now()
        };

        await docRef.set(roomState);
        
        // Return full state (including secret) to creator
        res.json(roomState);
    } catch (err) {
        console.error('Create Room Failed:', err);
        res.status(500).json({ error: 'Failed to create room' });
    }
});

app.get('/api/rooms/:roomId', async (req, res) => {
    try {
        const roomId = req.params.roomId.toUpperCase();
        const doc = await db.collection('rooms').doc(roomId).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Room not found' });
        }
        
        const data = doc.data();
        // Redact the roomSecret from GET requests to prevent other listeners from hijacking
        const { roomSecret, ...safeData } = data;
        res.json(safeData);
    } catch (err) {
        res.status(500).json({ error: 'Failed to fetch room' });
    }
});

// 6. IDOR REMEDIATION FOR ROOM UPDATES
app.post('/api/rooms/:roomId/update', async (req, res) => {
    try {
        const roomId = req.params.roomId.toUpperCase();
        const { currentSongId, isPlaying, position, secret } = req.body;
        
        const docRef = db.collection('rooms').doc(roomId);
        const doc = await docRef.get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'Room not found' });
        }

        const currentData = doc.data();
        
        // Require roomSecret validation
        if (!secret || secret !== currentData.roomSecret) {
            return res.status(403).json({ error: 'Forbidden: Invalid or missing room passcode.' });
        }

        const updates = {
            updatedAt: Date.now()
        };
        if (currentSongId !== undefined) updates.currentSongId = currentSongId;
        if (isPlaying !== undefined) updates.isPlaying = isPlaying;
        if (position !== undefined) updates.position = parseFloat(position);

        await docRef.update(updates);
        
        const updatedDoc = await docRef.get();
        const { roomSecret, ...safeData } = updatedDoc.data();
        res.json(safeData);
    } catch (err) {
        res.status(500).json({ error: 'Failed to update room status' });
    }
});

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
            const data = doc.data();
            const { roomSecret, ...safeData } = data; // Redact secret from stream events
            res.write(`data: ${JSON.stringify(safeData)}\n\n`);
        } else {
            res.write(`data: ${JSON.stringify({ error: 'Room deleted' })}\n\n`);
        }
    }, err => {
        console.error(`SSE onSnapshot error for room ${roomId}:`, err);
        res.write(`data: ${JSON.stringify({ error: 'Stream interrupted' })}\n\n`);
    });
    
    req.on('close', () => {
        console.log(`📡 SSE client disconnected from room: ${roomId}`);
        unsubscribe();
    });
});

app.use((req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

async function start() { 
    listenToLibrary();
    app.listen(PORT, () => {
        console.log(`🎵 Server listening on port ${PORT}`);
    });
}
start();
```
