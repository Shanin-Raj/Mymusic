const { db } = require('../backend/firebase');

async function run() {
    try {
        const snapshot = await db.collection('songs')
            .orderBy('added_at', 'desc')
            .limit(5)
            .get();
        
        console.log(`Found ${snapshot.size} latest songs:`);
        snapshot.forEach(doc => {
            const data = doc.data();
            console.log(`- ID: ${doc.id}`);
            console.log(`  Name: ${data.name}`);
            console.log(`  Artist: ${data.artist}`);
            console.log(`  Album: ${data.album}`);
            console.log(`  Telegram Message ID: ${data.tg_message_id}`);
            console.log(`  Added At: ${data.added_at ? (data.added_at.toDate ? data.added_at.toDate().toISOString() : data.added_at) : 'N/A'}`);
        });
    } catch (err) {
        console.error('Error fetching songs:', err);
    }
    process.exit(0);
}

run();
