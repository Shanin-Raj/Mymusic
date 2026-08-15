const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const { db } = require('./firebase');
const { fetchLyrics } = require('./lyrics');

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function main() {
    console.log('🎵 ===============================================');
    console.log('🎵  Mixtape Database Batch Lyrics Synchronizer  ');
    console.log('🎵 ===============================================\n');

    const forceRefresh = process.argv.includes('--force');
    if (forceRefresh) {
        console.log('⚡ Force refresh mode enabled: re-fetching lyrics for ALL songs.\n');
    }

    try {
        console.log('📡 Fetching all songs from Firestore database...');
        const snapshot = await db.collection('songs').get();

        if (snapshot.empty) {
            console.log('ℹ️ No songs found in the database.');
            process.exit(0);
        }

        const totalSongs = snapshot.size;
        console.log(`✅ Found ${totalSongs} total songs in your vault.\n`);

        let alreadyHadCount = 0;
        let newlyFetchedCount = 0;
        let syncedCount = 0;
        let plainCount = 0;
        let instrumentalCount = 0;
        let notFoundCount = 0;
        let failedCount = 0;

        let index = 0;
        for (const doc of snapshot.docs) {
            index++;
            const song = doc.data();
            const songId = doc.id;
            const songName = song.name || 'Unknown Song';
            const artistName = song.artist || 'Unknown Artist';
            const durationMs = song.duration_ms || 0;
            const albumName = song.album || '';

            const prefix = `[${index}/${totalSongs}]`;

            // Check if lyrics already exist
            if (!forceRefresh && song.lyrics && (song.lyrics.synced || song.lyrics.plain || song.lyrics.isInstrumental)) {
                const type = song.lyrics.synced ? 'SYNCED' : (song.lyrics.isInstrumental ? 'INSTRUMENTAL' : 'PLAIN');
                console.log(`${prefix} ⏩ Already has ${type} lyrics: "${songName}" by ${artistName}`);
                alreadyHadCount++;
                continue;
            }

            try {
                const lyricsData = await fetchLyrics(songName, artistName, durationMs, albumName);

                if (lyricsData) {
                    const updatePayload = {
                        lyrics: {
                            ...lyricsData,
                            updated_at: new Date().toISOString()
                        }
                    };

                    await db.collection('songs').doc(songId).update(updatePayload);

                    if (lyricsData.isInstrumental) {
                        instrumentalCount++;
                        console.log(`${prefix} 🎵 Instrumental track registered: "${songName}" by ${artistName}`);
                    } else if (lyricsData.synced) {
                        syncedCount++;
                        const lineCount = lyricsData.synced.split('\n').filter(l => l.trim().length > 0).length;
                        console.log(`${prefix} ✅ Saved SYNCED lyrics (${lineCount} lines): "${songName}" by ${artistName}`);
                    } else {
                        plainCount++;
                        console.log(`${prefix} 📄 Saved PLAIN lyrics: "${songName}" by ${artistName}`);
                    }

                    newlyFetchedCount++;
                } else {
                    notFoundCount++;
                    console.log(`${prefix} ⚠️ No lyrics found for: "${songName}" by ${artistName}`);
                }
            } catch (err) {
                failedCount++;
                console.error(`${prefix} ❌ Error updating "${songName}":`, err.message);
            }

            // Gentle delay to respect API rate limits
            await sleep(250);
        }

        console.log('\n===============================================');
        console.log('📊 Batch Lyrics Sync Summary:');
        console.log('===============================================');
        console.log(`📁 Total Songs in Database:    ${totalSongs}`);
        console.log(`⏩ Already Had Lyrics:          ${alreadyHadCount}`);
        console.log(`✨ Newly Fetched & Saved:      ${newlyFetchedCount}`);
        console.log(`   ├── ⏱️ Time-Synced (LRC):   ${syncedCount}`);
        console.log(`   ├── 📄 Plain Text Lyrics:    ${plainCount}`);
        console.log(`   └── 🎵 Instrumental Tracks:  ${instrumentalCount}`);
        console.log(`⚠️ Not Found / Unavailable:    ${notFoundCount}`);
        if (failedCount > 0) {
            console.log(`❌ Failed with Errors:         ${failedCount}`);
        }
        console.log('===============================================\n');
        console.log('🎉 All lyrics have been processed and saved directly into Firestore!');
        process.exit(0);

    } catch (err) {
        console.error('❌ Fatal error during batch lyrics sync:', err);
        process.exit(1);
    }
}

main();
