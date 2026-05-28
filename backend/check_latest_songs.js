const { db } = require('./firebase');

async function run() {
    try {
        const doc = await db.collection('songs').doc('manual-9216c8bd7f94').get();
        if (doc.exists) {
            console.log(JSON.stringify(doc.data(), null, 2));
        } else {
            console.log('Not found!');
        }
    } catch (e) {
        console.error(e);
    }
    process.exit(0);
}
run();
