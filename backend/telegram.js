const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const fs = require('fs');
require('dotenv').config();

const apiId = parseInt(process.env.TELEGRAM_API_ID);
const apiHash = process.env.TELEGRAM_API_HASH;
const botToken = process.env.TELEGRAM_BOT_TOKEN;
const destination = process.env.TELEGRAM_CHANNEL_ID || 'me';

const stringSession = new StringSession(""); // Empty for now, we can save it later

const client = new TelegramClient(stringSession, apiId, apiHash, {
    connectionRetries: 5,
});

async function uploadToTelegram(filePath, metadata) {
    if (!client.connected) {
        await client.start({
            botAuthToken: botToken,
        });
    }

    try {
        const result = await client.sendFile(destination, { 
            file: filePath,
            caption: `🎵 **${metadata.name}**\n👤 ${metadata.artist}\n💿 ${metadata.album}`,
            attributes: [], // We can add audio attributes here if needed
        });
        
        console.log('File uploaded to Telegram successfully');
        return result.id; // Returns the message ID
    } catch (err) {
        console.error('Error uploading to Telegram:', err);
        throw err;
    }
}

module.exports = { uploadToTelegram };
