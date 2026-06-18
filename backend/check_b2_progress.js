const { db } = require('./firebase');

async function checkProgress() {
    try {
        const snapshot = await db.collection('songs').get();
        let migratedCount = 0;
        let pendingCount = 0;
        
        snapshot.forEach(doc => {
            const data = doc.data();
            if (data.fileKey) {
                migratedCount++;
            } else {
                pendingCount++;
            }
        });
        
        console.log(`📊 B2 Migration Progress:`);
        console.log(`   Migrated (has fileKey): ${migratedCount}`);
        console.log(`   Pending (no fileKey):  ${pendingCount}`);
    } catch (err) {
        console.error('❌ Error checking progress:', err.message);
    }
    process.exit(0);
}

checkProgress();
