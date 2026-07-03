const { getPlaylistTracks } = require('./spotify');
const { downloadSong } = require('./downloader');
const { uploadToB2 } = require('./s3');
const { db } = require('./firebase');
const admin = require('firebase-admin');
const crypto = require('crypto');
const { spawnSync } = require('child_process');
const fs = require('fs');

// Helper to get metadata from YT link using yt-dlp
function getYTMetadata(url) {
    console.log('📡 Extracting metadata from YouTube...');
    
    // Attempt 1: Run yt-dlp directly
    let result = spawnSync('yt-dlp', ['--print', '%(title)s|%(uploader)s|%(thumbnail)s', '--no-playlist', '--js-runtimes', 'node', '--', url], { encoding: 'utf8' });
    
    // Fallback: If direct execution failed, run python -m yt_dlp
    if (result.error || result.status !== 0) {
        console.log('⚠️ yt-dlp direct execution failed, trying python fallback...');
        const pythonCmd = process.platform === 'win32' ? 'python' : 'python3';
        const args = [ '-m', 'yt_dlp', '--print', '%(title)s|%(uploader)s|%(thumbnail)s', '--no-playlist', '--js-runtimes', 'node', '--', url ];
        result = spawnSync(pythonCmd, args, { encoding: 'utf8' });
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
        // BRANCH 1: Link-based addition
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
                const meta = getYTMetadata(directUrl);
                if (meta) {
                    name = meta.name;
                    artist = meta.artist;
                    image = meta.image;
                } else {
                    throw new Error('Could not extract metadata from YouTube link');
                }
            }
        }

        // BRANCH 2: Manual Metadata entry (or fallback)
        if (!name || !artist) {
            throw new Error('Song Name and Artist are required if no direct link is provided.');
        }

        const trackId = spotifyId || ('manual-' + crypto.randomBytes(6).toString('hex'));
        
        // Check for duplicates in Firestore
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

        // 1. Download (uses directUrl if available, otherwise search)
        const filePath = await downloadSong(track.name, track.artist, directUrl);

        // 2. Upload to Backblaze B2
        console.log(`⏳ Syncing to private Backblaze B2 vault...`);
        const fileKey = `${track.id}.m4a`;
        const fileBuffer = fs.readFileSync(filePath);
        await uploadToB2(fileBuffer, fileKey, 'audio/mp4');

        // Clean up local downloaded file
        try {
            fs.unlinkSync(filePath);
            console.log(`🧹 Cleaned up local file: ${filePath}`);
        } catch (unlinkErr) {
            console.warn(`⚠️ Failed to delete local temp file ${filePath}:`, unlinkErr.message);
        }

        // 3. Save to Firestore
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
        throw err; // Propagate to API handler
    }
}

module.exports = { addSong };
