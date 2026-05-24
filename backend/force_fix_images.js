const { getPlaylistTracks } = require('./spotify');
const { db } = require('./firebase');
const admin = require('firebase-admin');

async function run() {
    console.log('🚀 EMERGENCY IMAGE FIXER 🚀');
    
    try {
        console.log('🔍 Scanning database for tracks missing images...');
        const snapshot = await db.collection('songs').get();
        const missing = [];
        snapshot.forEach(doc => {
            const data = doc.data();
            if (!data.image || data.image === '') {
                missing.push(data);
            }
        });
        
        console.log(`📊 Found ${missing.length} tracks to fix.`);

        let count = 0;
        for (const song of missing) {
            if (song.id.startsWith('manual-')) continue;

            process.stdout.write(`⏳ Fixing: ${song.name}... `);
            try {
                const fresh = await getPlaylistTracks(`https://open.spotify.com/track/${song.id}`);
                if (fresh && fresh[0] && fresh[0].image) {
                    await db.collection('songs').doc(song.id).update({
                        image: fresh[0].image,
                        album: fresh[0].album || 'Unknown Album',
                        updated_at: admin.firestore.FieldValue.serverTimestamp()
                    });
                    console.log('✅ FIXED');
                    count++;
                } else {
                    console.log('⏭️  NO IMAGE FOUND');
                }
            } catch (e) {
                console.log('❌ ERROR');
            }
            await new Promise(r => setTimeout(r, 600)); // Respect rate limits
        }

        console.log(`\n✨ DONE! Successfully fixed ${count} songs.`);
    } catch (err) {
        console.error('❌ CRITICAL ERROR:', err.message);
    }
    process.exit(0);
}

run();
