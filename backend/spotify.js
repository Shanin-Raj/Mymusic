const fetch = require('node-fetch');
const { getTracks, getData } = require('spotify-url-info')(fetch);

async function getPlaylistTracks(url) {
  try {
    console.log(`📡 Fetching Spotify metadata for: ${url}`);
    
    // For single tracks, getData is the most detailed
    if (url.includes('/track/')) {
        const data = await getData(url);
        
        // Comprehensive image extraction
        const img = data.visualIdentity?.image?.[0]?.url || 
                    data.coverArt?.sources?.[0]?.url || 
                    data.album?.images?.[0]?.url || 
                    data.image;

        console.log(`✅ Extracted image for ${data.name}: ${img ? 'YES' : 'NO'}`);

        return [{
            id: data.id || url.split('/track/')[1].split('?')[0],
            name: data.name,
            artist: data.artists?.[0]?.name || data.artist || "Unknown Artist",
            album: data.album?.name || "Unknown Album",
            image: img || null,
            duration_ms: data.duration_ms || data.duration
        }];
    }

    // For playlists, fallback to getTracks
    const tracks = await getTracks(url);
    console.log(`📊 Found ${tracks.length} tracks in playlist.`);
    
    return tracks.map(track => {
      const img = track.image || 
                  track.visualIdentity?.image?.[0]?.url || 
                  track.coverArt?.sources?.[0]?.url || 
                  track.album?.images?.[0]?.url;

      return {
        id: track.id || track.uri?.split(':').pop() || `sp-${Date.now()}`,
        name: track.name,
        artist: track.artist || track.artists?.[0]?.name || "Unknown Artist",
        album: track.album?.name || "Unknown Album",
        image: img || null,
        duration_ms: track.duration_ms || track.duration
      };
    });
  } catch (err) {
    console.error('❌ Spotify metadata error:', err.message);
    throw err;
  }
}

module.exports = { getPlaylistTracks };
