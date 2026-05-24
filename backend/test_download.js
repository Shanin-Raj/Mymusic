const { downloadSong } = require('./downloader');

async function test() {
    console.log('Starting downloader test...');
    try {
        const path = await downloadSong('Shape of You', 'Ed Sheeran');
        console.log('Download success, path:', path);
    } catch (err) {
        console.error('Download failed with error:', err);
    }
}

test();
