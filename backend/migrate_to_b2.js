const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const { Api } = require('telegram');
const { db } = require('./firebase');
const { uploadToB2 } = require('./s3');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const apiId = parseInt(process.env.TELEGRAM_API_ID);
const apiHash = process.env.TELEGRAM_API_HASH;
const botToken = process.env.TELEGRAM_BOT_TOKEN;
const channelId = (process.env.TELEGRAM_CHANNEL_ID || "").trim().replace(/['"]/g, "");
const stringSession = new StringSession(process.env.TELEGRAM_SESSION || "");

async function runMigration(logCallback) {
    const log = (msg) => {
        console.log(msg);
        if (logCallback) {
            try {
                logCallback(msg);
            } catch (err) {
                // Ignore callback write errors to prevent crashing if client disconnects
            }
        }
    };

    log('🏁 Starting Telegram to Backblaze B2 migration...');
    
    if (!apiId || !apiHash || !botToken || !channelId) {
        log('❌ Missing Telegram environment variables. Cannot proceed.');
        if (require.main === module) process.exit(1);
        throw new Error('Missing Telegram environment variables');
    }
    
    // Create downloads dir if it doesn't exist
    const downloadsDir = path.join(__dirname, 'downloads');
    if (!fs.existsSync(downloadsDir)) {
        fs.mkdirSync(downloadsDir, { recursive: true });
    }

    // 1. Fetch songs from Firestore
    log('📡 Fetching songs from Firestore...');
    const snapshot = await db.collection('songs').get();
    const songs = [];
    snapshot.forEach(doc => {
        songs.push(doc.data());
    });

    log(`📋 Found ${songs.length} total songs in Firestore.`);
    
    // Filter songs that need migration
    const songsToMigrate = songs.filter(s => !s.fileKey);
    log(`🔍 ${songsToMigrate.length} songs need migration (missing fileKey).`);

    if (songsToMigrate.length === 0) {
        log('✅ All songs are already migrated!');
        return;
    }

    // 2. Initialize Telegram Client
    log('📡 Connecting to Telegram...');
    const tgClient = new TelegramClient(stringSession, apiId, apiHash, {
        connectionRetries: 5,
        useWSS: true,
        autoReconnect: true,
        connectionTimeout: 10000,
    });
    
    await tgClient.start({ botAuthToken: botToken });
    log('✅ Connected to Telegram');
    
    const peer = await tgClient.getInputEntity(channelId);
    
    let successCount = 0;
    let failCount = 0;

    for (let i = 0; i < songsToMigrate.length; i++) {
        const song = songsToMigrate[i];
        const progress = `[${i + 1}/${songsToMigrate.length}]`;
        log(`⏳ ${progress} Processing: "${song.name}" by ${song.artist} (ID: ${song.id})`);
        
        if (!song.tg_message_id) {
            log(`   ⚠️ Skip: Song does not have a tg_message_id`);
            failCount++;
            continue;
        }

        const tempFile = path.join(downloadsDir, `migrate-${song.id}.m4a`);
        
        try {
            // Delete temp file if it somehow exists
            if (fs.existsSync(tempFile)) {
                fs.unlinkSync(tempFile);
            }

            log(`   Downloading from Telegram message ${song.tg_message_id}...`);
            const messages = await tgClient.invoke(new Api.channels.GetMessages({
                channel: peer,
                id: [new Api.InputMessageID({ id: parseInt(song.tg_message_id, 10) })]
            }));

            if (!messages.messages[0] || !messages.messages[0].media) {
                throw new Error(`Media not found in message ${song.tg_message_id}`);
            }

            const media = messages.messages[0].media;
            await tgClient.downloadMedia(media, { outputFile: tempFile });

            if (!fs.existsSync(tempFile) || fs.statSync(tempFile).size < 1024) {
                throw new Error('Downloaded file is empty or corrupted');
            }

            const fileSize = fs.statSync(tempFile).size;
            log(`   Downloaded successfully (${(fileSize / 1024 / 1024).toFixed(2)} MB). Uploading to B2...`);

            // Read buffer & upload to B2
            const fileKey = `${song.id}.m4a`;
            const buffer = fs.readFileSync(tempFile);
            await uploadToB2(buffer, fileKey, 'audio/mp4');
            log(`   Uploaded to B2 with key: ${fileKey}`);

            // Update Firestore
            await db.collection('songs').doc(song.id).update({
                fileKey: fileKey
            });
            log(`   Updated Firestore document.`);

            successCount++;
        } catch (err) {
            log(`   ❌ Failed to migrate: ${err.message}`);
            failCount++;
        } finally {
            // Clean up temp file
            if (fs.existsSync(tempFile)) {
                try {
                    fs.unlinkSync(tempFile);
                } catch (e) {
                    // Ignore
                }
            }
        }
    }

    log('📡 Disconnecting from Telegram...');
    await tgClient.disconnect();
    await tgClient.destroy();
    
    log(`🎉 Migration finished! Success: ${successCount}, Failed: ${failCount}`);
}

if (require.main === module) {
    runMigration().catch(err => {
        console.error('❌ Migration crashed:', err);
    });
}

module.exports = { runMigration };
