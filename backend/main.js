const { getPlaylistTracks } = require('./spotify');
const { downloadSong } = require('./downloader');
const { uploadToTelegram } = require('./telegram');
const { db } = require('./firebase');
const admin = require('firebase-admin');
const input = require('input'); // For user input

async function run() {
    const spotifyUrl = await input.text('Enter Spotify Link (Playlist or Track URL):');
    
    if (!spotifyUrl.includes('spotify.com/')) {
        console.error('Invalid Spotify URL. Must contain spotify.com/');
        return;
    }

    console.log(`📡 Fetching metadata from Spotify...`);
    const tracks = await getPlaylistTracks(spotifyUrl);
    console.log(`📊 Found ${tracks.length} track(s).`);

    for (const track of tracks) {
        try {
            console.log(`--- Processing: ${track.name} ---`);
            
            // 1. Check if already in DB
            const doc = await db.collection('songs').doc(track.id).get();
            if (doc.exists) {
                console.log('Track already exists in library. Skipping...');
                continue;
            }

            // 2. Download
            const filePath = await downloadSong(track.name, track.artist);

            // 3. Upload to Telegram
            const messageId = await uploadToTelegram(filePath, track);

            // 4. Save to Firestore
            await db.collection('songs').doc(track.id).set({
                ...track,
                tg_message_id: messageId,
                added_at: admin.firestore.FieldValue.serverTimestamp()
            });

            console.log('Track saved to database.');
        } catch (err) {
            console.error(`Failed to process ${track.name}:`, err);
        }
    }

    console.log('Playlist processing complete!');
    process.exit(0);
}

run();
