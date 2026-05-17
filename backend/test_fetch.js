// No require('node-fetch') needed in Node 22
require('dotenv').config();

async function test() {
  const clientId = process.env.SPOTIFY_CLIENT_ID;
  const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
  const auth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  try {
    const authRes = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: 'grant_type=client_credentials'
    });

    const authData = await authRes.json();
    if (!authData.access_token) {
        console.error('Auth Failed:', authData);
        return;
    }
    console.log('Auth Success');

    const playlistId = '4PGK1wbbQCC45DIbIym5MA';
    const res = await fetch(`https://api.spotify.com/v1/playlists/${playlistId}/tracks`, {
      headers: {
        'Authorization': `Bearer ${authData.access_token}`
      }
    });

    console.log('Status Code:', res.status);
    const body = await res.text();
    console.log('Response Body:', body);

  } catch (err) {
    console.error('Fetch Error:', err);
  }
}

test();
