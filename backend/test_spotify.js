const SpotifyWebApi = require('spotify-web-api-node');
require('dotenv').config();

const spotifyApi = new SpotifyWebApi({
  clientId: process.env.SPOTIFY_CLIENT_ID,
  clientSecret: process.env.SPOTIFY_CLIENT_SECRET,
});

async function test() {
  try {
    const data = await spotifyApi.clientCredentialsGrant();
    spotifyApi.setAccessToken(data.body['access_token']);
    console.log('Authenticated successfully');

    const playlistId = '4PGK1wbbQCC45DIbIym5MA';
    const tracks = await spotifyApi.getPlaylistTracks(playlistId);
    console.log(`Successfully fetched ${tracks.body.items.length} tracks`);
  } catch (err) {
    console.error('Test Failed:', JSON.stringify(err.body || err, null, 2));
  }
}

test();
