const { TelegramClient } = require('telegram');
const { StringSession } = require('telegram/sessions');
const input = require('input');

const apiId = 34768070;
const apiHash = '53c5955951e1489621e49d4cf4cc5c86';
const botToken = '7715076968:AAFEiPDgmavQ27ZGm8rUKxp2jBfD4JrZIWY';

(async () => {
    const client = new TelegramClient(new StringSession(""), apiId, apiHash, { connectionRetries: 5 });
    await client.start({ botAuthToken: botToken });
    console.log("YOUR_SESSION_STRING:", client.session.save());
    await client.disconnect();
})();