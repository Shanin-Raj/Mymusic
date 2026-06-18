const fetch = require('node-fetch');

const BASE_URL = 'http://localhost:8080';

async function runTests() {
    console.log('🧪 Starting endpoint verification...');

    // Test 1: GET /api/time
    try {
        console.log('Testing GET /api/time...');
        const timeRes = await fetch(`${BASE_URL}/api/time`);
        if (!timeRes.ok) throw new Error(`Status: ${timeRes.status}`);
        const timeData = await timeRes.json();
        console.log('✅ GET /api/time response:', timeData);
        if (typeof timeData.time !== 'number') throw new Error('Time is not a number');
    } catch (err) {
        console.error('❌ GET /api/time failed:', err.message);
    }

    let roomId;

    // Test 2: POST /api/rooms
    try {
        console.log('Testing POST /api/rooms...');
        const roomRes = await fetch(`${BASE_URL}/api/rooms`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' }
        });
        if (!roomRes.ok) throw new Error(`Status: ${roomRes.status}`);
        const roomData = await roomRes.json();
        console.log('✅ POST /api/rooms response:', roomData);
        if (!roomData.roomId) throw new Error('No roomId returned');
        roomId = roomData.roomId;
    } catch (err) {
        console.error('❌ POST /api/rooms failed:', err.message);
    }

    if (!roomId) {
        console.error('❌ Skipping remaining tests since room creation failed.');
        process.exit(1);
    }

    // Test 3: GET /api/rooms/:roomId
    try {
        console.log(`Testing GET /api/rooms/${roomId}...`);
        const roomGet = await fetch(`${BASE_URL}/api/rooms/${roomId}`);
        if (!roomGet.ok) throw new Error(`Status: ${roomGet.status}`);
        const roomData = await roomGet.json();
        console.log('✅ GET /api/rooms/:roomId response:', roomData);
    } catch (err) {
        console.error('❌ GET /api/rooms/:roomId failed:', err.message);
    }

    // Test 4: POST /api/rooms/:roomId/update
    try {
        console.log(`Testing POST /api/rooms/${roomId}/update...`);
        const updateRes = await fetch(`${BASE_URL}/api/rooms/${roomId}/update`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                currentSongId: 'song_test_123',
                isPlaying: true,
                position: 45000
            })
        });
        if (!updateRes.ok) throw new Error(`Status: ${updateRes.status}`);
        const updateData = await updateRes.json();
        console.log('✅ POST /api/rooms/:roomId/update response:', updateData);
        if (updateData.currentSongId !== 'song_test_123' || updateData.isPlaying !== true || updateData.position !== 45000) {
            throw new Error('Updated data does not match updates!');
        }
    } catch (err) {
        console.error('❌ POST /api/rooms/:roomId/update failed:', err.message);
    }

    // Test 5: Verify via GET /api/rooms/:roomId
    try {
        console.log(`Verifying updates via GET /api/rooms/${roomId}...`);
        const verifyGet = await fetch(`${BASE_URL}/api/rooms/${roomId}`);
        if (!verifyGet.ok) throw new Error(`Status: ${verifyGet.status}`);
        const verifyData = await verifyGet.json();
        console.log('✅ Verification GET /api/rooms/:roomId response:', verifyData);
        if (verifyData.currentSongId === 'song_test_123' && verifyData.isPlaying === true && verifyData.position === 45000) {
            console.log('🎉 ALL INTEGRATION TESTS PASSED SUCCESSFULLY!');
        } else {
            throw new Error('Data discrepancy in Firestore!');
        }
    } catch (err) {
        console.error('❌ Verification failed:', err.message);
    }

    console.log('🧪 Verification complete.');
}

runTests();
