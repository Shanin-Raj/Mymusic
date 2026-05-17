const { db } = require('./firebase');
const fs = require('fs');
const path = require('path');

const DB_PATH = path.join(__dirname, 'library.json');

async function migrate() {
    console.log('🚀 Starting migration to Firebase...');
    
    if (!fs.existsSync(DB_PATH)) {
        console.error('❌ library.json not found!');
        return;
    }

    const data = JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
    const songs = Object.values(data.songs);
    console.log(`📊 Found ${songs.length} songs to migrate.`);

    let count = 0;
    for (const song of songs) {
        try {
            // Use song.id as the document ID for uniqueness
            await db.collection('songs').doc(song.id).set({
                ...song,
                updated_at: admin.firestore.FieldValue.serverTimestamp()
            });
            count++;
            if (count % 20 === 0) console.log(`✅ Migrated ${count}/${songs.length}...`);
        } catch (err) {
            console.error(`❌ Failed to migrate ${song.name}:`, err.message);
        }
    }

    console.log(`✨ Migration complete! Total songs uploaded: ${count}`);
    process.exit(0);
}

// Need 'admin' for serverTimestamp
const admin = require('firebase-admin');
migrate();
