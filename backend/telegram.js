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
    console.log('📡 [Telegram] Preparing fresh connection...');
    if (!apiId || !apiHash) {
        throw new Error('Telegram credentials not configured');
    }
    
    // Always spawn a fresh client to prevent stale socket hangs on Cloud Run
    const freshClient = new TelegramClient(stringSession, apiId, apiHash, {
        connectionRetries: 3,
        useWSS: false,
        autoReconnect: false, // Serverless request is short-lived, no auto-reconnect needed
        connectionTimeout: 8000,
    });

    try {
        console.log('📡 [Telegram] Connecting...');
        await freshClient.start({ botAuthToken: botToken });
        console.log('✅ [Telegram] Connected successfully');

        console.log('⏳ [Telegram] Uploading file...');
        const result = await freshClient.sendFile(destination, { 
            file: filePath,
            caption: `🎵 **${metadata.name}**\n👤 ${metadata.artist}\n💿 ${metadata.album}`,
            workers: 1,
        });
        
        console.log('✅ [Telegram] File uploaded successfully');
        return result.id; 
    } catch (err) {
        console.error('❌ [Telegram] Error during fresh connection/upload:', err);
        throw err;
    } finally {
        try {
            console.log('📡 [Telegram] Disconnecting and cleaning up resources...');
            await freshClient.disconnect();
            await freshClient.destroy();
        } catch (disErr) {
            console.warn('[Telegram] Disconnect error (ignored):', disErr.message);
        }
    }
}

async function deleteFromTelegram(messageId) {
    if (!apiId || !apiHash) return;
    
    const freshClient = new TelegramClient(stringSession, apiId, apiHash, {
        connectionRetries: 3,
        useWSS: false,
        autoReconnect: false,
        connectionTimeout: 8000,
    });

    try {
        await freshClient.start({ botAuthToken: botToken });
        await freshClient.deleteMessages(destination, [messageId], { revoke: true });
        console.log(`Successfully deleted message ${messageId} from Telegram`);
    } catch (err) {
        console.error(`Error deleting message ${messageId} from Telegram:`, err);
    } finally {
        try {
            await freshClient.disconnect();
            await freshClient.destroy();
        } catch (disErr) {
            // ignore
        }
    }
}

module.exports = { uploadToTelegram, deleteFromTelegram };
