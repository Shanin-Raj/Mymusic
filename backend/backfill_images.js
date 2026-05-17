const { getPlaylistTracks } = require('./spotify');
const { db } = require('./firebase');
const admin = require('firebase-admin');
const input = require('input');

async function run() {
    console.log('🖼️  Smart Album Art Fixer — Automating your covers');
    
    let url = await input.text('Enter Spotify Link (Playlist/Track) or leave empty to AUTO-FIX everything:');
    
    let tracksToProcess = [];

    if (url.trim()) {
        if (!url.includes('spotify.com/')) {
            console.error('❌ Invalid Spotify URL');
            return;
        }
        console.log('📡 Fetching provided link...');
        tracksToProcess = await getPlaylistTracks(url);
    } else {
        console.log('🔍 Scanning database for tracks missing images...');
        const snapshot = await db.collection('songs').get();
        const allSongs = [];
        snapshot.forEach(doc => allSongs.push(doc.data()));
        
        // Find tracks missing images (excluding manual ones for now unless they have a known name)
        const missing = allSongs.filter(s => !s.image || s.image === '');
        console.log(`📊 Found ${missing.length} tracks missing images.`);
        
        for (const song of missing) {
            // Only auto-fix songs with standard spotify IDs (not manual ones)
            if (song.id && !song.id.startsWith('manual-')) {
                tracksToProcess.push({
                    id: song.id,
                    name: song.name,
                    url: `https://open.spotify.com/track/${song.id}`
                });
            }
        }
    }

    if (tracksToProcess.length === 0) {
        console.log('✅ Nothing to process.');
        return;
    }

    console.log(`🚀 Processing ${tracksToProcess.length} tracks...`);
    let updated = 0;
    let failed = 0;

    for (const item of tracksToProcess) {
        try {
            process.stdout.write(`⏳ Updating: ${item.name}... `);
            
            // If we only have ID/URL, fetch metadata now
            let trackData = item;
            if (!item.image) {
                const fresh = await getPlaylistTracks(item.url || `https://open.spotify.com/track/${item.id}`);
                if (fresh && fresh[0]) trackData = fresh[0];
            }

            if (trackData.image) {
                await db.collection('songs').doc(item.id).update({
                    image: trackData.image,
                    album: trackData.album || 'Unknown Album',
                    updated_at: admin.firestore.FieldValue.serverTimestamp()
                });
                console.log('✅ FIXED');
                updated++;
            } else {
                console.log('⏭️  No image found.');
                failed++;
            }
        } catch (err) {
            console.log('❌ FAILED:', err.message);
            failed++;
        }
        // Small delay to prevent rate limiting
        await new Promise(r => setTimeout(r, 500));
    }

    console.log(`\n✨ Finished! Fixed: ${updated}, Failed: ${failed}`);
    console.log('Changes are live in your app instantly.');
    process.exit(0);
}

run();
