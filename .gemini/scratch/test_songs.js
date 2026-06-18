const { db } = require('../../backend/firebase');

async function testGetLibrary() {
    console.log('Testing getLibrary sort logic...');
    try {
        const snapshot = await db.collection('songs').get();
        const songs = [];
        snapshot.forEach(doc => songs.push(doc.data()));
        console.log(`Successfully fetched ${songs.length} raw songs.`);
        
        songs.sort((a, b) => {
            const dateB = b.added_at?.toDate ? b.added_at.toDate() : new Date(b.added_at || 0);
            const dateA = a.added_at?.toDate ? a.added_at.toDate() : new Date(a.added_at || 0);
            return dateB - dateA;
        });
        
        console.log('✅ Sort completed successfully without errors!');
        console.log('Sample sorted song:', songs[0]?.name, 'added at:', songs[0]?.added_at);
    } catch (err) {
        console.error('❌ Sort failed with error:', err.message);
        console.error(err.stack);
    }
    process.exit(0);
}

testGetLibrary();
