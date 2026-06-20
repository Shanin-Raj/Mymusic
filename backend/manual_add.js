const readline = require('readline');
const path = require('path');

// Ensure environment variables are loaded from backend/.env
require('dotenv').config({ path: path.join(__dirname, '.env') });

const { addSong } = require('./adder');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function askQuestion(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function main() {
    console.log('🎵 --- Mixtape Manual Song Adder --- 🎵\n');

    let url = process.argv[2];
    let name = '';
    let artist = '';

    if (!url) {
        console.log('How would you like to add a song?');
        console.log('1. Using a Spotify or YouTube link');
        console.log('2. Manually entering Song Name & Artist');
        const choice = await askQuestion('\nEnter choice (1 or 2): ');

        if (choice.trim() === '1') {
            url = await askQuestion('\n🔗 Enter Spotify or YouTube URL: ');
            if (!url || url.trim() === '') {
                console.log('❌ URL cannot be empty. Exiting.');
                rl.close();
                return;
            }
        } else if (choice.trim() === '2') {
            name = await askQuestion('\n📝 Enter Song Name: ');
            artist = await askQuestion('👤 Enter Artist Name: ');
            if (!name.trim() || !artist.trim()) {
                console.log('❌ Song Name and Artist Name are required for manual mode. Exiting.');
                rl.close();
                return;
            }
        } else {
            console.log('❌ Invalid choice. Exiting.');
            rl.close();
            return;
        }
    }

    rl.close();

    try {
        console.log('\n🚀 Starting addition process...');
        const result = await addSong({
            name: name ? name.trim() : undefined,
            artist: artist ? artist.trim() : undefined,
            url: url ? url.trim() : undefined
        });
        console.log('\n✅ Success! Song added successfully.');
        console.log(JSON.stringify(result, null, 2));
    } catch (err) {
        console.error('\n❌ Failed to add song:', err.message);
        process.exit(1);
    }
}

main();
