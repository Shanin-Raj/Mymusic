const { db } = require('./firebase');

async function check() {
    console.log('🔍 Checking specific tracks for "image" field...');
    try {
        // Checking "Kadhal Aasai" which was our test track
        const id = '3gnWw0LToxswxfC6Eb8GBp';
        const doc = await db.collection('songs').doc(id).get();
        
        if (doc.exists) {
            const data = doc.data();
            console.log(`Track: ${data.name}`);
            console.log(`Image field: ${data.image ? data.image : '❌ MISSING'}`);
            console.log('Full data:', JSON.stringify(data, null, 2));
        } else {
            console.log('❌ Track not found in database.');
        }
    } catch (err) {
        console.error('❌ Error:', err.message);
    }
    process.exit(0);
}

check();
