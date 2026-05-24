const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const apiId = parseInt(process.env.TELEGRAM_API_ID);
const apiHash = process.env.TELEGRAM_API_HASH;
const botToken = process.env.TELEGRAM_BOT_TOKEN;
const destination = (process.env.TELEGRAM_CHANNEL_ID || "").trim().replace(/['"]/g, "");

const stringSession = new StringSession(process.env.TELEGRAM_SESSION || "");

let client = null;

async function ensureConnected() {
    if (!client) {
        if (!apiId || !apiHash) {
            console.error('❌ Missing TELEGRAM_API_ID or TELEGRAM_API_HASH');
            throw new Error('Telegram credentials not configured');
        }
        client = new TelegramClient(stringSession, apiId, apiHash, {
            connectionRetries: 15,
            useWSS: false,
            autoReconnect: true,
            connectionTimeout: 10000,
        });
    }

    if (!client.connected) {
        console.log('📡 Connecting to Telegram...');
        try {
            await client.start({
                botAuthToken: botToken,
            });
            console.log('✅ Telegram client connected');
        } catch (err) {
            console.error('❌ Failed to connect to Telegram:', err);
            throw err;
        }
    }
}

async function uploadToTelegram(filePath, metadata) {
    await ensureConnected();

    try {
        const result = await client.sendFile(destination, { 
            file: filePath,
            caption: `🎵 **${metadata.name}**\n👤 ${metadata.artist}\n💿 ${metadata.album}`,
            workers: 1, // Use single worker for more stable uploads on weak connections
        });
        
        console.log('File uploaded to Telegram successfully');
        return result.id; 
    } catch (err) {
        console.error('Error uploading to Telegram:', err);
        throw err;
    }
}

async function deleteFromTelegram(messageId) {
    await ensureConnected();
    try {
        await client.deleteMessages(destination, [messageId], { revoke: true });
        console.log(`Successfully deleted message ${messageId} from Telegram`);
    } catch (err) {
        console.error(`Error deleting message ${messageId} from Telegram:`, err);
        // Don't throw here, we still want to delete from Firestore even if TG fails
    }
}

module.exports = { uploadToTelegram, deleteFromTelegram };
