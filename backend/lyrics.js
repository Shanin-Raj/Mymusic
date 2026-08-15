const https = require('https');

/**
 * Cleans track titles for better search accuracy across lyrics databases.
 * Removes movie info, feat artists, video tags, etc.
 */
function cleanSongTitle(title) {
    if (!title) return '';
    return title
        .replace(/\(From\s+[^)]+\)/gi, '')
        .replace(/\(feat\.?[^)]*\)/gi, '')
        .replace(/\(ft\.?[^)]*\)/gi, '')
        .replace(/\[.*?\]/g, '')
        .replace(/\(Official.*?\)/gi, '')
        .replace(/\(Lyrical.*?\)/gi, '')
        .replace(/\(Audio.*?\)/gi, '')
        .replace(/\(Video.*?\)/gi, '')
        .replace(/\(Original.*?\)/gi, '')
        .replace(/\(Remix.*?\)/gi, '')
        .replace(/\(Reprise.*?\)/gi, '')
        .replace(/\(Female.*?\)/gi, '')
        .replace(/\(Male.*?\)/gi, '')
        .replace(/\(Duet.*?\)/gi, '')
        .replace(/["'“”`]/g, '')
        .replace(/[-–—]/g, ' ')
        .replace(/\s+/g, ' ')
        .trim();
}

function cleanArtistName(artist) {
    if (!artist) return '';
    return artist
        .replace(/,.*$/, '')
        .replace(/&.*$/, '')
        .replace(/feat\..*$/i, '')
        .replace(/ft\..*$/i, '')
        .replace(/["'“”`]/g, '')
        .replace(/\s+/g, ' ')
        .trim();
}

/**
 * Helper to make HTTPS GET requests with headers and timeout
 */
function httpsGet(url) {
    return new Promise((resolve) => {
        const req = https.get(url, {
            headers: {
                'User-Agent': 'MixtapeApp/2.0 (https://github.com/Shanin-Raj/Mymusic)'
            },
            timeout: 8000
        }, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        resolve(null);
                    }
                } else {
                    resolve(null);
                }
            });
        });

        req.on('error', () => {
            resolve(null);
        });

        req.on('timeout', () => {
            req.destroy();
            resolve(null);
        });
    });
}

/**
 * Helper to pick the best matching result from a list of search results
 */
function pickBestMatch(results, durationSec) {
    if (!Array.isArray(results) || results.length === 0) return null;

    let best = null;

    // 1. Duration within 4 seconds AND has synced lyrics
    if (durationSec > 0) {
        best = results.find(r => r.syncedLyrics && Math.abs(r.duration - durationSec) <= 4);
    }

    // 2. Duration within 6 seconds AND has plain lyrics
    if (!best && durationSec > 0) {
        best = results.find(r => (r.syncedLyrics || r.plainLyrics) && Math.abs(r.duration - durationSec) <= 6);
    }

    // 3. First result with synced lyrics
    if (!best) {
        best = results.find(r => r.syncedLyrics);
    }

    // 4. Any result with plain lyrics
    if (!best) {
        best = results.find(r => r.plainLyrics || r.instrumental);
    }

    return best || results[0];
}

/**
 * Fetches synced & plain lyrics from LRCLIB.
 * @param {string} trackName
 * @param {string} artistName
 * @param {number} durationMs
 * @param {string} [albumName]
 * @returns {Promise<{synced: string|null, plain: string|null, isInstrumental: boolean, source: string}|null>}
 */
async function fetchLyrics(trackName, artistName, durationMs = 0, albumName = '') {
    if (!trackName) return null;

    const cleanTitle = cleanSongTitle(trackName);
    const cleanArtist = cleanArtistName(artistName);
    const durationSec = durationMs > 0 ? Math.round(durationMs / 1000) : 0;

    // Strategy 1: Exact match lookup with clean title & artist
    try {
        let getUrl = `https://lrclib.net/api/get?track_name=${encodeURIComponent(cleanTitle || trackName)}&artist_name=${encodeURIComponent(cleanArtist || artistName)}`;
        if (durationSec > 0) {
            getUrl += `&duration=${durationSec}`;
        }
        if (albumName) {
            getUrl += `&album_name=${encodeURIComponent(albumName)}`;
        }

        const exactResult = await httpsGet(getUrl);
        if (exactResult && (exactResult.syncedLyrics || exactResult.plainLyrics || exactResult.instrumental)) {
            return {
                synced: exactResult.syncedLyrics || null,
                plain: exactResult.plainLyrics || null,
                isInstrumental: !!exactResult.instrumental,
                source: 'lrclib'
            };
        }
    } catch (_) {}

    // Strategy 2: Exact match with raw trackName & artistName (if different)
    if (cleanTitle !== trackName || cleanArtist !== artistName) {
        try {
            let rawGetUrl = `https://lrclib.net/api/get?track_name=${encodeURIComponent(trackName)}&artist_name=${encodeURIComponent(artistName)}`;
            if (durationSec > 0) rawGetUrl += `&duration=${durationSec}`;
            const rawExact = await httpsGet(rawGetUrl);
            if (rawExact && (rawExact.syncedLyrics || rawExact.plainLyrics || rawExact.instrumental)) {
                return {
                    synced: rawExact.syncedLyrics || null,
                    plain: rawExact.plainLyrics || null,
                    isInstrumental: !!rawExact.instrumental,
                    source: 'lrclib'
                };
            }
        } catch (_) {}
    }

    // Strategy 3: Search with cleanTitle + cleanArtist
    try {
        const query = `${cleanTitle} ${cleanArtist}`.trim();
        const searchUrl = `https://lrclib.net/api/search?q=${encodeURIComponent(query)}`;
        const searchResults = await httpsGet(searchUrl);
        const best = pickBestMatch(searchResults, durationSec);

        if (best && (best.syncedLyrics || best.plainLyrics || best.instrumental)) {
            return {
                synced: best.syncedLyrics || null,
                plain: best.plainLyrics || null,
                isInstrumental: !!best.instrumental,
                source: 'lrclib'
            };
        }
    } catch (_) {}

    // Strategy 4: Search with cleanTitle only (useful when multiple artists listed)
    if (cleanTitle && cleanTitle.length > 2) {
        try {
            const searchUrl = `https://lrclib.net/api/search?q=${encodeURIComponent(cleanTitle)}`;
            const searchResults = await httpsGet(searchUrl);
            const best = pickBestMatch(searchResults, durationSec);

            if (best && (best.syncedLyrics || best.plainLyrics || best.instrumental)) {
                return {
                    synced: best.syncedLyrics || null,
                    plain: best.plainLyrics || null,
                    isInstrumental: !!best.instrumental,
                    source: 'lrclib'
                };
            }
        } catch (_) {}
    }

    // Strategy 5: Search with raw trackName
    if (trackName !== cleanTitle) {
        try {
            const searchUrl = `https://lrclib.net/api/search?q=${encodeURIComponent(trackName)}`;
            const searchResults = await httpsGet(searchUrl);
            const best = pickBestMatch(searchResults, durationSec);

            if (best && (best.syncedLyrics || best.plainLyrics || best.instrumental)) {
                return {
                    synced: best.syncedLyrics || null,
                    plain: best.plainLyrics || null,
                    isInstrumental: !!best.instrumental,
                    source: 'lrclib'
                };
            }
        } catch (_) {}
    }

    return null;
}

module.exports = { fetchLyrics, cleanSongTitle, cleanArtistName };
