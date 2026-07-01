const { db, admin } = require('./firebase');

async function categorizeSongs() {
    console.log('Fetching all songs from Firestore...');
    const songsSnapshot = await db.collection('songs').get();
    const songs = [];
    songsSnapshot.forEach(doc => {
        songs.push(doc.data());
    });

    console.log(`Found ${songs.length} songs.`);

    // Predefined keywords for categories
    const categories = {
        'Hindi': { keywords: ['arijit', 'pritam', 'shreya', 'amitabh', 'hindi', 'bollywood', 'rahman', 'sunidhi', 'javed', 'k.k.', 'kk', 'mohit', 'chauhan', 'sonu', 'nigam', 'atif', 'aslam', 'kumar', 'sanu', 'udit', 'narayan', 'shaan', 'himesh', 'reshmiya', 'bhojpuri', 'punjabi'], match: (s) => false }, // will use simple matching
        'Malayalam': { keywords: ['malayalam', 'vineeth', 'sreenivasan', 'shaan', 'rahman', 'gopi', 'sundar', 'ks', 'chithra', 'yesudas', 'mg', 'sreekumar', 'sujatha', 'mohanlal', 'mammootty', 'dq', 'dulquer', 'nivin', 'pauly', 'fahadh', 'faasil', 'job', 'kurian', 'sushin', 'shyam'], match: (s) => false },
        'Tamil': { keywords: ['tamil', 'anirudh', 'ravichander', 'ar', 'rahman', 'hariharan', 'karthik', 'sid', 'sriram', 'vijay', 'ajith', 'surya', 'dhanush', 'harris', 'jayaraj', 'yuvan', 'shankar', 'raja', 'ilayaraja', 'spb'], match: (s) => false },
        'English': { keywords: ['english', 'justin', 'bieber', 'ed', 'sheeran', 'taylor', 'swift', 'ariana', 'grande', 'drake', 'eminem', 'weeknd', 'post', 'malone', 'billie', 'eilish', 'dua', 'lipa', 'shawn', 'mendes', 'camila', 'cabello', 'charlie', 'puth', 'selena', 'gomez', 'maroon', '5', 'coldplay', 'imagine', 'dragons', 'one', 'direction'], match: (s) => false },
        'Pop': { keywords: ['pop', 'remix', 'dance', 'dj', 'party', 'club', 'mix', 'mashup', 'justin', 'bieber', 'ed', 'sheeran', 'taylor', 'swift', 'ariana', 'grande', 'dua', 'lipa', 'weeknd'], match: (s) => false },
        'Feel Good': { keywords: ['feel', 'good', 'chill', 'relax', 'lofi', 'acoustic', 'unplugged', 'melody', 'love', 'romantic', 'peace'], match: (s) => false }
    };

    const categorizedLists = {};
    for (const cat of Object.keys(categories)) {
        categorizedLists[cat] = new Set();
    }

    songs.forEach(song => {
        const text = `${song.name} ${song.artist}`.toLowerCase();
        let matched = false;
        
        // Simple keyword match
        for (const [catName, catData] of Object.entries(categories)) {
            for (const keyword of catData.keywords) {
                if (text.includes(keyword)) {
                    categorizedLists[catName].add(song.id);
                    matched = true;
                    break;
                }
            }
        }
        
        // If not matched, maybe put in a generic one
        if (!matched) {
            categorizedLists['Made For You'] = categorizedLists['Made For You'] || new Set();
            categorizedLists['Made For You'].add(song.id);
        }
    });

    // Create or update playlists
    for (const [catName, songIds] of Object.entries(categorizedLists)) {
        if (songIds.size > 0) {
            console.log(`Creating/Updating Playlist: ${catName} with ${songIds.size} songs`);
            
            // Check if playlist already exists with this name
            const plQuery = await db.collection('playlists').where('name', '==', catName).get();
            let plId = `pl-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
            
            let existingSongs = [];
            if (!plQuery.empty) {
                plId = plQuery.docs[0].id;
                existingSongs = plQuery.docs[0].data().songs || [];
            }
            
            const combinedSongs = Array.from(new Set([...existingSongs, ...Array.from(songIds)]));
            
            await db.collection('playlists').doc(plId).set({
                id: plId,
                name: catName,
                songs: combinedSongs,
                image: '', // Will get a random cover if empty
                created_at: new Date().toISOString()
            }, { merge: true });
        }
    }
    
    console.log('Done!');
    process.exit(0);
}

categorizeSongs().catch(console.error);
