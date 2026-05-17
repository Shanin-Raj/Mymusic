const { db } = require('./firebase');

async function debug() {
    console.log('🔍 Checking Firestore "songs" collection...');
    try {
        const snapshot = await db.collection('songs').get();
        console.log(`📊 Found ${snapshot.size} documents in collection.`);
        
        if (snapshot.size > 0) {
            console.log('📄 Sample first song:');
            console.log(JSON.stringify(snapshot.docs[0].data(), null, 2));
        } else {
            console.log('❌ COLLECTION IS EMPTY!');
        }
    } catch (err) {
        console.error('❌ Firestore Error:', err.message);
    }
    process.exit(0);
}

debug();
