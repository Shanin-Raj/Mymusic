require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const { downloadSong } = require('./downloader');
const { uploadToTelegram } = require('./telegram');
const { db } = require('./firebase');
const admin = require('firebase-admin');
const input = require('input');
const crypto = require('crypto');

const { spawnSync } = require('child_process');

// Helper to get metadata from YT Music link using yt-dlp
function getYTMetadata(url) {
    console.log('📡 Extracting metadata from YouTube...');
    const args = [
        '-m', 'yt_dlp',
        '--print', '%(title)s|%(uploader)s|%(thumbnail)s',
        '--no-playlist',
        url
    ];
    const result = spawnSync('python', args, { encoding: 'utf8' });
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

async function run() {
    console.log('🎵 Universal Song Adder — Spotify, YT Music, or Manual');
    
    const inputStr = await input.text('Enter YouTube Music Link (or Song Name):');

    if (!inputStr) {
        console.error('Input is required!');
        return;
    }

    let name, artist, image = null, directUrl = null;

    if (inputStr.includes('youtube.com/') || inputStr.includes('youtu.be/')) {
        directUrl = inputStr.trim();
        const meta = getYTMetadata(directUrl);
        if (meta) {
            name = meta.name;
            artist = meta.artist;
            image = meta.image;
            console.log(`✅ Found: ${name} by ${artist}`);
        } else {
            console.error('❌ Failed to extract metadata from link.');
            return;
        }
    } else {
        name = inputStr;
        artist = await input.text('Enter Artist Name:');
    }

    if (!name || !artist) {
        console.error('Name and Artist are required!');
        return;
    }

    // Generate a unique ID for manual tracks
    const manualId = 'manual-' + crypto.randomBytes(6).toString('hex');
    const track = {
        id: manualId,
        name: name.trim(),
        artist: artist.trim(),
        album: 'Manual Addition',
        image: image || null
    };

    try {
        console.log(`--- Processing: ${track.name} ---`);
        
        // 1. Download (uses directUrl if provided, otherwise search)
        const filePath = await downloadSong(track.name, track.artist, directUrl);

        // 2. Upload to Telegram
        const messageId = await uploadToTelegram(filePath, track);

        // 3. Save to Firestore
        await db.collection('songs').doc(track.id).set({
            ...track,
            tg_message_id: messageId,
            added_at: admin.firestore.FieldValue.serverTimestamp()
        });

        console.log('\n✨ Success! Song added to library and cloud database.');
        console.log('It will appear in your app instantly.');

    } catch (err) {
        console.error('\n❌ Failed to add song:', err.message);
    }

    process.exit(0);
}

run();
