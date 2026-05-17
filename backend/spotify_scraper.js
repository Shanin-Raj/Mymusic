const fetch = require('node-fetch'); // Or just use global fetch if available
const path = require('path');

async function getPlaylistTracks(playlistId) {
    const url = `https://open.spotify.com/playlist/${playlistId}`;
    
    try {
        console.log(`Scraping public playlist: ${url}`);
        const response = await fetch(url);
        const html = await response.text();

        // Regex to find track names and artists in the JSON or HTML metadata
        // Spotify often embeds data in a <script id="initial-state"> tag
        const tracks = [];
        
        // Simple extraction from HTML for common meta tags or links
        // However, a more robust way is to look for the "track" objects in the page source
        
        // Let's try to match track links which usually contain names in their text
        // Or look for the JSON payload in the script tag
        const jsonMatch = html.match(/<script id="initial-state" type="text\/plain">([^<]+)<\/script>/);
        if (jsonMatch) {
            const jsonData = JSON.parse(Buffer.from(jsonMatch[1], 'base64').toString());
            // Navigate the complex state object to find tracks
            // This is brittle but works if we find the right key
            // Alternatively, just use regex to find track names and artists
        }

        // Fallback: Regex for track links which are usually in the format:
        // <a ... href="/track/ID">NAME</a>
        // This is simplified but effective for many cases
        const trackRegex = /href="\/track\/([a-zA-Z0-9]+)"[^>]*><div[^>]*>([^<]+)<\/div>/g;
        let match;
        const foundIds = new Set();

        // Let's use a more reliable regex for the public page
        // In the public page, track names are often inside <a> tags or <span> tags
        const metaRegex = /<meta property="og:description" content="Playlist · [^·]+ · ([0-9]+) items">/;
        const countMatch = html.match(metaRegex);
        const count = countMatch ? parseInt(countMatch[1]) : 0;
        console.log(`Playlist says it has ${count} items.`);

        // Better Regex for track names and artists from the public page
        // Spotify's public page has a simpler list for SEO
        const trackBlockRegex = /"name":"([^"]+)","type":"track","uri":"spotify:track:([a-zA-Z0-9]+)"/g;
        while ((match = trackBlockRegex.exec(html)) !== null) {
            if (!foundIds.has(match[2])) {
                tracks.push({
                    id: match[2],
                    name: match[1],
                    artist: "Unknown Artist", // Scraping artist is harder from this specific regex
                    album: "Unknown Album"
                });
                foundIds.add(match[2]);
            }
        }

        // If no tracks found via JSON, try to scrape from the simpler HTML list
        if (tracks.length === 0) {
            const simpleRegex = /<span class="track-name">([^<]+)<\/span>/g;
            // ...
        }

        // Wait, I have a better idea. 
        // We can use a library like 'spotify-url-info' which handles this scraping beautifully.
        // But I'll try to do a robust regex for now to avoid more installs.
        
        // Let's use the regex that matches the track names in the description if possible
        // Actually, the page contains a script with track info.
        
        return tracks;
    } catch (err) {
        console.error('Error scraping playlist:', err);
        throw err;
    }
}

module.exports = { getPlaylistTracks };
