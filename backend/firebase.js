const admin = require('firebase-admin');
const path = require('path');

let serviceAccount;

if (process.env.FIREBASE_KEY_JSON) {
    try {
        serviceAccount = JSON.parse(process.env.FIREBASE_KEY_JSON);
    } catch (err) {
        console.error('❌ Failed to parse FIREBASE_KEY_JSON environment variable:', err.message);
    }
}

if (!serviceAccount) {
    try {
        serviceAccount = require('./firebase-key.json');
    } catch (err) {
        console.error('❌ Missing firebase-key.json and FIREBASE_KEY_JSON environment variable');
    }
}

if (serviceAccount && !admin.apps.length) {
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
}

const db = admin.firestore();
db.settings({ ignoreUndefinedProperties: true });

module.exports = { db, admin };
