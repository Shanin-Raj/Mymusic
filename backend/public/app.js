/* ══════════════════════════════════════════════
   SONIC VAULT — App Controller
   ══════════════════════════════════════════════ */

const API = '';
let allSongs = [];
let currentSong = null;
let currentIndex = -1;
let isPlaying = false;
let currentPlaylist = [];       // active queue (may be shuffled)
let isShuffleOn = false;
let repeatMode = 0;            // 0=off  1=repeat-all  2=repeat-one
const likedSongs = new Set(JSON.parse(localStorage.getItem('sv_liked') || '[]'));

let _preCachedNextId = null;

function triggerPreCacheNext() {
  if (currentPlaylist.length === 0 || currentIndex === -1) return;
  
  let nextIndex;
  if (isShuffleOn) {
    if (currentPlaylist.length <= 1) return;
    // Prediction for shuffle: pick a random one that isn't current
    nextIndex = Math.floor(Math.random() * currentPlaylist.length);
    if (nextIndex === currentIndex) nextIndex = (nextIndex + 1) % currentPlaylist.length;
  } else {
    nextIndex = currentIndex + 1;
    if (nextIndex >= currentPlaylist.length) {
      if (repeatMode === 1) nextIndex = 0;
      else return; // end of playlist
    }
  }

  const nextSong = currentPlaylist[nextIndex];
  if (nextSong && nextSong.id !== _preCachedNextId) {
    _preCachedNextId = nextSong.id;
    console.log('📡 Pre-caching next song:', nextSong.name);
    fetch('/api/precache/' + nextSong.id).catch(err => {
      console.error('Precache failed:', err);
    });
  }
}

// ── DOM CACHE ──
const $ = (s) => document.querySelector(s);
const $$ = (s) => document.querySelectorAll(s);

const loginScreen = $('#screen-login');
const appShell = $('#app-shell');
const miniPlayer = $('#mini-player');
const bottomNav = $('#bottom-nav');

// ═══════════════════════════════════════
// INIT
// ═══════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  initWaveform();
  bindLogin();
  bindNavigation();
  bindSearch();
  bindPlayerControls();
  bindSettings();
  bindSleepTimer();
  bindDownloadAll();

  // Auto-enter app if already logged in from this device
  if (localStorage.getItem('sv_session') === '1') {
    loginScreen.classList.add('hidden');
    appShell.classList.remove('hidden');
    loadAppData();
  }
});

// ═══════════════════════════════════════
// WAVEFORM ANIMATION
// ═══════════════════════════════════════
function initWaveform() {
  const container = $('#waveform-container');
  if (!container) return;
  const count = 60;
  for (let i = 0; i < count; i++) {
    const bar = document.createElement('div');
    bar.className = 'wave-bar';
    const h = 20 + Math.random() * 140;
    bar.style.height = h + 'px';
    bar.style.animationDelay = (Math.random() * 1.5) + 's';
    bar.style.animationDuration = (0.8 + Math.random() * 0.8) + 's';
    container.appendChild(bar);
  }
}

// ═══════════════════════════════════════
// LOGIN
// ═══════════════════════════════════════
function bindLogin() {
  ['btn-enter', 'btn-guest', 'btn-google'].forEach(id => {
    const btn = document.getElementById(id);
    if (btn) btn.addEventListener('click', enterApp);
  });
}

function enterApp() {
  localStorage.setItem('sv_session', '1');
  loginScreen.classList.remove('active');
  loginScreen.classList.add('hidden');
  appShell.classList.remove('hidden');
  loadAppData();
}

// ═══════════════════════════════════════
// DATA LOADING
// ═══════════════════════════════════════
async function loadAppData() {
  // Load from cache first for instant UI
  const cachedSongs = localStorage.getItem('sv_songs_cache');
  if (cachedSongs) {
    allSongs = JSON.parse(cachedSongs);
    renderHome();
    renderLibrary({ totalSongs: allSongs.length, totalArtists: new Set(allSongs.map(s => s.artist)).size, totalDurationMs: allSongs.reduce((acc, s) => acc + (s.duration_ms || 0), 0) });
  }

  try {
    const [songsRes, statsRes] = await Promise.all([
      fetch(API + '/api/songs'),
      fetch(API + '/api/stats')
    ]);
    const songsData = await songsRes.json();
    const statsData = await statsRes.json();
    
    allSongs = songsData.songs || [];
    localStorage.setItem('sv_songs_cache', JSON.stringify(allSongs));
    
    renderHome();
    renderLibrary(statsData);
    renderDownloads(statsData);
  } catch (err) {
    console.error('Failed to load data:', err);
  }
}

// ═══════════════════════════════════════
// HOME SCREEN
// ═══════════════════════════════════════
function renderHome() {
  // Recently Played (last 6)
  const recentGrid = $('#recent-grid');
  const recent = allSongs.slice(-6).reverse();
  const colors = ['#1DB954','#5B86E5','#fc5c7d','#f7971e','#8E2DE2','#11998e'];
  recentGrid.innerHTML = recent.map((s, i) => {
    const bg = s.image ? `url(${s.image}) center/cover` : `linear-gradient(135deg,${colors[i%6]},${colors[(i+1)%6]}30)`;
    return `
      <div class="recent-item" data-id="${s.id}">
        <div class="recent-art" style="background:${bg}">
          ${!s.image ? `<span class="material-symbols-rounded" style="font-size:18px;color:${colors[i%6]}">music_note</span>` : ''}
        </div>
        <span class="ri-name">${s.name}</span>
      </div>
    `;
  }).join('');

  recentGrid.querySelectorAll('.recent-item').forEach(el => {
    el.addEventListener('click', () => playSongById(el.dataset.id));
  });

  // Home tracks (first 15)
  const homeList = $('#home-tracks');
  renderTrackList(homeList, allSongs.slice(0, 15));

  updateGreeting();
}

function updateGreeting() {
  const h = new Date().getHours();
  const title = $('.page-title');
  if (h < 12) title.textContent = 'Good Morning';
  else if (h < 17) title.textContent = 'Good Afternoon';
  else title.textContent = 'Good Evening';
}

// ═══════════════════════════════════════
// LIBRARY SCREEN
// ═══════════════════════════════════════
function renderLibrary(stats) {
  $('#stat-songs').textContent = stats.totalSongs;
  $('#stat-artists').textContent = stats.totalArtists;
  const hrs = Math.round(stats.totalDurationMs / 3600000);
  $('#stat-hours').textContent = hrs + 'h';

  const list = $('#library-tracks');
  renderTrackList(list, allSongs);

  $('#btn-shuffle-all')?.addEventListener('click', () => {
    const shuffled = [...allSongs].sort(() => Math.random() - 0.5);
    playSong(shuffled[0], shuffled);
  });
  $('#btn-play-all')?.addEventListener('click', () => {
    if (allSongs.length) playSong(allSongs[0], allSongs);
  });
}

// ═══════════════════════════════════════
// DOWNLOADS SCREEN
// ═══════════════════════════════════════
function renderDownloads(stats) {
  const total = stats.totalSongs;
  $('#storage-used').textContent = total;
  $('#synced-count').textContent = total;

  // Animate ring
  const ring = $('#storage-ring-fill');
  if (ring) {
    const pct = Math.min(total / 100, 1);
    ring.style.strokeDashoffset = 314 - (314 * pct);
  }

  const list = $('#downloaded-tracks');
  renderTrackList(list, allSongs.slice(0, 20));
}

// ═══════════════════════════════════════
// SEARCH
// ═══════════════════════════════════════
function bindSearch() {
  const input = $('#search-input');
  const clearBtn = $('#search-clear');
  const resultsSection = $('#search-results-section');
  const browseSection = $('#browse-section');
  let debounce;

  input.addEventListener('input', () => {
    clearTimeout(debounce);
    const q = input.value.trim();
    clearBtn.classList.toggle('hidden', !q);

    if (!q) {
      resultsSection.style.display = 'none';
      browseSection.style.display = 'block';
      return;
    }

    debounce = setTimeout(async () => {
      // Local fallback search first
      const qLower = q.toLowerCase();
      const localResults = allSongs.filter(s => 
        s.name.toLowerCase().includes(qLower) || 
        s.artist.toLowerCase().includes(qLower)
      );

      resultsSection.style.display = 'block';
      browseSection.style.display = 'none';

      // Attempt remote search if API is available, otherwise show local
      if (API && API.length > 5) {
        try {
          const res = await fetch(API + `/api/search?q=${encodeURIComponent(q)}`);
          const data = await res.json();
          $('#search-results-title').textContent = `${data.total} Results (Cloud)`;
          renderTrackList($('#search-results'), data.results);
          return;
        } catch (e) { console.warn('Remote search failed, using local vault.'); }
      }

      // Show local results if remote fails or isn't configured
      $('#search-results-title').textContent = `${localResults.length} Results in Vault`;
      renderTrackList($('#search-results'), localResults);
    }, 300);
  });

  clearBtn.addEventListener('click', () => {
    input.value = '';
    clearBtn.classList.add('hidden');
    resultsSection.style.display = 'none';
    browseSection.style.display = 'block';
  });
}

// ═══════════════════════════════════════
// TRACK RENDERING
// ═══════════════════════════════════════
function renderTrackList(container, songs) {
  const palette = ['#1a3a2a','#2a1a3a','#3a2a1a','#1a2a3a','#3a1a2a','#2a3a1a'];
  container.innerHTML = songs.map((s, i) => {
    const dur = formatDuration(s.duration_ms);
    const bg = palette[i % palette.length];
    const isActive = currentSong && currentSong.id === s.id;
    const isLiked = likedSongs.has(s.id);
    
    // Improved album art rendering with console check
    if (s.image) console.log(`[UI] Rendering image for ${s.name}: ${s.image}`);

    const artContent = s.image 
      ? `<img src="${s.image}" class="track-img" alt="art" onerror="this.parentElement.innerHTML='<span class=\'track-idx\'>${i+1}</span>'">`
      : `<span class="track-idx" style="font-size:12px;color:var(--on-surface-dim);font-weight:600">${i + 1}</span>`;

    return `
      <div class="track-item ${isActive ? 'playing' : ''}" data-id="${s.id}">
        <div class="track-art" style="background:${bg}">
          ${artContent}
          <div class="track-eq"><div class="eq-bar"></div><div class="eq-bar"></div><div class="eq-bar"></div></div>
        </div>
        <div class="track-meta">
          <div class="track-name">${s.name}</div>
          <div class="track-artist">${s.artist.split(',')[0].trim()}</div>
        </div>
        <div class="track-right">
          ${isLiked ? '<span class="material-symbols-rounded track-liked">favorite</span>' : ''}
          <span class="track-duration">${dur}</span>
          <button class="icon-btn more-btn" aria-label="More Options"><span class="material-symbols-rounded">more_vert</span></button>
        </div>
      </div>
    `;
  }).join('');

  container.querySelectorAll('.track-item').forEach(el => {
    el.addEventListener('click', () => playSongById(el.dataset.id));
  });
}

function formatDuration(ms) {
  if (!ms) return '0:00';
  const mins = Math.floor(ms / 60000);
  const secs = Math.floor((ms % 60000) / 1000);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
}

// ═══════════════════════════════════════
// PLAYER (real audio streaming)
// ═══════════════════════════════════════
const audio = new Audio();
audio.preload = 'auto';
audio.autoplay = true;
document.addEventListener('DOMContentLoaded', () => {
  audio.style.display = 'none';
  document.body.appendChild(audio);
});

function playSongById(id) {
  const song = allSongs.find(s => s.id === id);
  if (song) playSong(song);
}

function playSong(song, playlist) {
  _preCachedNextId = null;
  currentSong = song;
  isPlaying = true;
  currentPlaylist = playlist || allSongs;
  currentIndex = currentPlaylist.findIndex(s => s.id === song.id);

  // Update player screen
  $('#player-title').textContent = song.name;
  $('#player-artist').textContent = song.artist;
  $('#time-total').textContent = formatDuration(song.duration_ms);
  
  // Update artwork with fallback
  const playerArt = $('#player-art');
  if (song.image) {
      playerArt.innerHTML = `<img src="${song.image}" class="player-img-full" alt="art" onerror="this.parentElement.innerHTML='<div class=\'player-art-inner\'><span class=\'material-symbols-rounded player-art-icon\'>music_note</span></div>'">`;
  } else {
      playerArt.innerHTML = `<div class="player-art-inner"><span class="material-symbols-rounded player-art-icon">music_note</span></div>`;
  }

  // Update mini player artwork
  const miniArt = $('#mini-art');
  if (song.image) {
      miniArt.innerHTML = `<img src="${song.image}" class="mini-img" alt="art" onerror="this.parentElement.innerHTML='<span class=\'material-symbols-rounded\'>music_note</span>'">`;
  } else {
      miniArt.innerHTML = `<span class="material-symbols-rounded">music_note</span>`;
  }

  $('#mini-title').textContent = song.name;
  $('#mini-artist').textContent = song.artist.split(',')[0].trim();
  
  const isPlayerActive = $('#screen-player').classList.contains('active');
  if (isPlayerActive) {
    miniPlayer.style.display = 'none';
    miniPlayer.classList.add('hidden');
    bottomNav.style.display = 'none';
  } else {
    miniPlayer.style.display = 'block';
    miniPlayer.classList.remove('hidden');
    bottomNav.style.display = 'flex';
  }

  // Set loading state
  updatePlayIcon('hourglass_top');
  $('#player-source').textContent = 'Loading from Vault...';

  // Stream audio
  audio.src = `/api/stream/${song.id}`;
  
  const playPromise = audio.play();
  if (playPromise !== undefined) {
    playPromise.then(() => {
      updatePlayIcon('pause');
      $('#player-source').textContent = 'Playing from Vault';
    }).catch(err => {
      console.error('Playback failed:', err);
      updatePlayIcon('play_arrow');
      $('#player-source').textContent = 'Playback paused (Tap to Resume)';
    });
  }

  // Update liked state
  const favIcon = $('#btn-favorite .material-symbols-rounded');
  if (favIcon) {
    favIcon.textContent = likedSongs.has(song.id) ? 'favorite' : 'favorite_border';
    favIcon.style.color = likedSongs.has(song.id) ? '#fc5c7d' : '';
  }

  $$('.track-item').forEach(el => {
    el.classList.toggle('playing', el.dataset.id === song.id);
  });

  updateMediaSession(song);
}

function updateMediaSession(song) {
  if ('mediaSession' in navigator) {
    navigator.mediaSession.metadata = new MediaMetadata({
      title: song.name,
      artist: song.artist,
      album: 'Sonic Vault',
      artwork: [
        { src: song.image || '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
        { src: song.image || '/icons/icon-512.png', sizes: '512x512', type: 'image/png' }
      ]
    });

    navigator.mediaSession.setActionHandler('play', () => audio.play());
    navigator.mediaSession.setActionHandler('pause', () => audio.pause());
    navigator.mediaSession.setActionHandler('previoustrack', () => playPrev());
    navigator.mediaSession.setActionHandler('nexttrack', () => playNext());
    navigator.mediaSession.setActionHandler('seekto', (details) => {
      if (details.seekTime !== undefined && isFinite(audio.duration)) {
        audio.currentTime = details.seekTime;
      }
    });
  }
}

function updatePlayIcon(icon) {
  $('#btn-play').querySelector('.material-symbols-rounded').textContent = icon;
  $('#mini-play').querySelector('.material-symbols-rounded').textContent = icon === 'hourglass_top' ? 'hourglass_top' : icon;
}

// Audio events
let _isDraggingProgress = false;

audio.addEventListener('timeupdate', () => {
  if (!audio.duration || !isFinite(audio.duration)) return;
  
  if (audio.duration - audio.currentTime < 30) {
    triggerPreCacheNext();
  }

  const pct = (audio.currentTime / audio.duration) * 100;
  if (!_isDraggingProgress) {
    const fill = $('#progress-fill');
    const thumb = $('#progress-thumb');
    if (fill) fill.style.width = pct + '%';
    if (thumb) thumb.style.opacity = '1'; // Redundant force visibility
    $('#time-current').textContent = formatDuration(audio.currentTime * 1000);
  }
  $('#mini-progress').style.width = pct + '%';
  $('#time-total').textContent = formatDuration(audio.duration * 1000);
  
  if ('mediaSession' in navigator && isFinite(audio.duration)) {
    navigator.mediaSession.setPositionState({
      duration: audio.duration,
      playbackRate: audio.playbackRate,
      position: audio.currentTime
    });
  }
});

audio.addEventListener('ended', () => {
  if (repeatMode === 2) {
    audio.currentTime = 0;
    audio.play().catch(e => console.error(e));
  } else {
    playNext();
  }
});

audio.addEventListener('playing', () => {
  isPlaying = true;
  updatePlayIcon('pause');
});

audio.addEventListener('pause', () => {
  isPlaying = false;
  updatePlayIcon('play_arrow');
});

let _loadingTimer = null;
audio.addEventListener('waiting', () => {
  clearTimeout(_loadingTimer);
  _loadingTimer = setTimeout(() => {
    if (audio.readyState < 3) updatePlayIcon('hourglass_top');
  }, 1200);
});

audio.addEventListener('canplay', () => {
  clearTimeout(_loadingTimer);
  if (isPlaying) updatePlayIcon('pause');
});

function togglePlay() {
  if (audio.paused) audio.play();
  else audio.pause();
}

function playNext() {
  const queue = currentPlaylist.length ? currentPlaylist : allSongs;
  if (!queue.length) return;
  if (isShuffleOn) {
    let nextIdx;
    do { nextIdx = Math.floor(Math.random() * queue.length); }
    while (nextIdx === currentIndex && queue.length > 1);
    currentIndex = nextIdx;
  } else {
    currentIndex = (currentIndex + 1) % queue.length;
  }
  playSong(queue[currentIndex], queue);
}

function playPrev() {
  const queue = currentPlaylist.length ? currentPlaylist : allSongs;
  if (!queue.length) return;
  if (audio.currentTime > 3) {
    audio.currentTime = 0;
    return;
  }
  currentIndex = (currentIndex - 1 + queue.length) % queue.length;
  playSong(queue[currentIndex], queue);
}

function bindPlayerControls() {
  $('#btn-play')?.addEventListener('click', togglePlay);
  $('#mini-play')?.addEventListener('click', (e) => { e.stopPropagation(); togglePlay(); });
  $('#btn-next')?.addEventListener('click', playNext);
  $('#mini-next')?.addEventListener('click', (e) => { e.stopPropagation(); playNext(); });
  $('#btn-prev')?.addEventListener('click', playPrev);
  $('#mini-prev')?.addEventListener('click', (e) => { e.stopPropagation(); playPrev(); });
  $('#btn-player-back')?.addEventListener('click', () => navigateTo(lastScreen || 'home'));
  $('#mini-player-tap')?.addEventListener('click', () => navigateTo('player'));

  $('#btn-shuffle')?.addEventListener('click', () => {
    isShuffleOn = !isShuffleOn;
    $('#btn-shuffle').classList.toggle('ctrl-active', isShuffleOn);
  });

  $('#btn-repeat')?.addEventListener('click', (e) => {
    e.stopPropagation();
    repeatMode = (repeatMode + 1) % 3;
    const icons = ['repeat', 'repeat', 'repeat_one'];
    const repeatBtn = $('#btn-repeat');
    repeatBtn.querySelector('.material-symbols-rounded').textContent = icons[repeatMode];
    if (repeatMode === 0) repeatBtn.classList.remove('ctrl-active');
    else repeatBtn.classList.add('ctrl-active');
  });

  $('#btn-favorite')?.addEventListener('click', (e) => {
    e.stopPropagation();
    if (!currentSong) return;
    const isLiked = likedSongs.has(currentSong.id);
    if (isLiked) likedSongs.delete(currentSong.id);
    else likedSongs.add(currentSong.id);
    localStorage.setItem('sv_liked', JSON.stringify([...likedSongs]));
    playSong(currentSong, currentPlaylist); // Refresh visuals
  });

  $('#btn-queue')?.addEventListener('click', () => {
    renderQueuePanel();
    $('#queue-panel').classList.toggle('hidden');
  });
  $('#queue-close')?.addEventListener('click', () => {
    $('#queue-panel').classList.add('hidden');
  });

  $$('#screen-library .chip').forEach(chip => {
    chip.addEventListener('click', () => {
      $$('#screen-library .chip').forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      const text = chip.textContent.toLowerCase().trim();
      const list = $('#library-tracks');
      if (text === 'liked') renderTrackList(list, allSongs.filter(s => likedSongs.has(s.id)));
      else if (text === 'recently added') renderTrackList(list, [...allSongs].reverse());
      else renderTrackList(list, allSongs);
    });
  });

  // More menu delegation
  document.addEventListener('click', (e) => {
    const moreBtn = e.target.closest('.icon-btn');
    if (moreBtn && moreBtn.querySelector('.material-symbols-rounded')?.textContent === 'more_vert') {
      e.stopPropagation();
      const item = moreBtn.closest('.track-item') || moreBtn.closest('.queue-item');
      const songId = item?.dataset.id || item?.dataset.songid || currentSong?.id;
      const song = allSongs.find(s => s.id === songId);
      if (song) showSongOptions(song);
    } else {
      $('#song-options-menu')?.classList.add('hidden');
    }
  });

  // Progress Bar
  const progressBar = $('.progress-bar');
  if (progressBar) {
    const getPct = (clientX) => {
      const rect = progressBar.getBoundingClientRect();
      return Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
    };

    const updateVisual = (pct) => {
      if (!audio.duration || !isFinite(audio.duration)) return;
      $('#progress-fill').style.width = (pct * 100) + '%';
      $('#time-current').textContent = formatDuration(pct * audio.duration * 1000);
    };

    const commitSeek = (pct) => {
      if (!audio.duration || !isFinite(audio.duration)) return;
      audio.currentTime = pct * audio.duration;
    };

    const onStart = (e) => {
      if (!audio.duration || !isFinite(audio.duration)) return;
      _isDraggingProgress = true;
      const clientX = e.touches ? e.touches[0].clientX : e.clientX;
      updateVisual(getPct(clientX));
    };

    const onMove = (e) => {
      if (!_isDraggingProgress) return;
      const clientX = e.touches ? e.touches[0].clientX : e.clientX;
      updateVisual(getPct(clientX));
    };

    const onEnd = (e) => {
      if (!_isDraggingProgress) return;
      _isDraggingProgress = false;
      const clientX = e.changedTouches ? e.changedTouches[0].clientX : e.clientX;
      commitSeek(getPct(clientX));
    };

    progressBar.addEventListener('mousedown', onStart);
    progressBar.addEventListener('touchstart', onStart, { passive: true });
    window.addEventListener('mousemove', onMove);
    window.addEventListener('touchmove', onMove, { passive: true });
    window.addEventListener('mouseup', onEnd);
    window.addEventListener('touchend', onEnd);
    progressBar.addEventListener('click', (e) => {
      if (!_isDraggingProgress && audio.duration) commitSeek(getPct(e.clientX));
    });
  }
}

function showSongOptions(song) {
  let menu = $('#song-options-menu');
  if (!menu) {
    menu = document.createElement('div');
    menu.id = 'song-options-menu';
    menu.className = 'song-options-menu hidden';
    document.body.appendChild(menu);
  }

  menu.innerHTML = `
    <div class="menu-header">
      <div class="menu-song-name">${song.name}</div>
      <div class="menu-song-artist">${song.artist}</div>
    </div>
    <div class="menu-item" id="opt-like">
      <span class="material-symbols-rounded">${likedSongs.has(song.id) ? 'favorite' : 'favorite_border'}</span>
      ${likedSongs.has(song.id) ? 'Remove from Liked' : 'Add to Liked'}
    </div>
    <div class="menu-item" id="opt-queue">
      <span class="material-symbols-rounded">queue_music</span>
      Add to Queue
    </div>
  `;

  menu.classList.remove('hidden');
  $('#opt-like').onclick = () => {
    if (likedSongs.has(song.id)) likedSongs.delete(song.id);
    else likedSongs.add(song.id);
    localStorage.setItem('sv_liked', JSON.stringify([...likedSongs]));
    menu.classList.add('hidden');
    loadAppData(); // Refresh
  };
  $('#opt-queue').onclick = () => {
    currentPlaylist.push(song);
    menu.classList.add('hidden');
  };
}

function renderQueuePanel() {
  const list = $('#queue-list');
  const queue = currentPlaylist.length ? currentPlaylist : allSongs;
  list.innerHTML = queue.map((s, i) => `
    <div class="queue-item ${s.id === currentSong?.id ? 'queue-active' : ''}" data-idx="${i}">
      <div class="queue-num">${s.id === currentSong?.id ? '<span class="material-symbols-rounded" style="font-size:16px;color:var(--primary)">equalizer</span>' : i + 1}</div>
      <div class="queue-info">
        <div class="queue-name">${s.name}</div>
        <div class="queue-artist">${s.artist}</div>
      </div>
    </div>
  `).join('');
}

let lastScreen = 'home';
function navigateTo(screen) {
  if (screen !== 'player') lastScreen = screen;
  $$('.screen').forEach(s => s.classList.remove('active'));
  $(`#screen-${screen}`)?.classList.add('active');
  
  if (screen === 'player') {
    bottomNav.style.display = 'none';
    miniPlayer.classList.add('hidden');
    // Force visibility of player elements
    const extras = $('.player-extras');
    if (extras) extras.style.display = 'flex';
  } else {
    bottomNav.style.display = 'flex';
    if (currentSong) miniPlayer.classList.remove('hidden');
  }
}

function bindNavigation() {
  $$('.nav-item').forEach(btn => btn.addEventListener('click', () => navigateTo(btn.dataset.screen)));
}

function bindSettings() {
  $('#btn-signout')?.addEventListener('click', () => {
    localStorage.removeItem('sv_session');
    location.reload();
  });
}

function bindSleepTimer() {
  const modal = $('#sleep-modal');
  const timerBtn = $('#btn-sleep-timer');
  timerBtn?.addEventListener('click', () => modal.classList.remove('hidden'));
  $('#sleep-modal-close')?.addEventListener('click', () => modal.classList.add('hidden'));
  $$('.sleep-opt').forEach(btn => {
    btn.addEventListener('click', () => {
      const mins = parseInt(btn.dataset.minutes);
      if (mins > 0) {
        timerBtn.classList.add('timer-active');
        setTimeout(() => audio.pause(), mins * 60 * 1000);
      } else {
        timerBtn.classList.remove('timer-active');
      }
      modal.classList.add('hidden');
    });
  });
}

function bindDownloadAll() {
  $('#btn-download-all')?.addEventListener('click', () => startDownloadAll());
}

async function startDownloadAll() {
  const box = $('#download-progress-box');
  const fill = $('#dl-progress-fill');
  box.classList.remove('hidden');
  const es = new EventSource('/api/download-all');
  es.onmessage = (e) => {
    const data = JSON.parse(e.data);
    fill.style.width = (data.done / data.total * 100) + '%';
    if (data.status === 'complete') es.close();
  };
}
