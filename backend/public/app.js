/* ══════════════════════════════════════════════
   SONIC VAULT — App Controller (v41)
   ══════════════════════════════════════════════ */

const API = '';
let allSongs = [];
let allPlaylists = [];
let currentSong = null;
let currentIndex = -1;
let isPlaying = false;
let currentPlaylist = [];
let isShuffleOn = false;
let repeatMode = 0; 
const likedSongs = new Set(JSON.parse(localStorage.getItem('sv_liked') || '[]'));
let _preCachedNextId = null;
let isChangingSong = false;

// Room Sync Variables
let activeRoomId = localStorage.getItem('sv_room_id') || null;
let clockOffset = 0;
let isSyncingFromServer = false;
let sseEventSource = null;

function showToast(message) {
  let toast = document.querySelector('#app-toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'app-toast';
    toast.style.cssText = `
      position: fixed;
      bottom: calc(var(--nav-height) + 80px + env(safe-area-inset-bottom));
      left: 50%;
      transform: translateX(-50%) translateY(20px);
      background: var(--surface-high);
      color: var(--on-surface);
      padding: 12px 24px;
      border-radius: var(--radius-full);
      z-index: 999999;
      box-shadow: 0 8px 32px rgba(0,0,0,0.5);
      font-weight: 600;
      font-size: 14px;
      opacity: 0;
      transition: opacity 0.3s ease, transform 0.3s ease;
      pointer-events: none;
      border: 1px solid var(--glass-border);
      text-align: center;
      white-space: nowrap;
    `;
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.style.opacity = '1';
  toast.style.transform = 'translateX(-50%) translateY(0)';
  
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(-50%) translateY(20px)';
  }, 2500);
}

// Persistent Theme Handle
const theme = {
  isDark: localStorage.getItem('sv_theme') !== 'light',
  toggle() {
    this.isDark = !this.isDark;
    localStorage.setItem('sv_theme', this.isDark ? 'dark' : 'light');
    this.apply();
  },
  apply() {
    document.body.classList.toggle('dark-mode', this.isDark);
    const icons = document.querySelectorAll('#btn-theme .material-symbols-rounded, #btn-theme-player .material-symbols-rounded');
    icons.forEach(icon => {
      icon.textContent = this.isDark ? 'light_mode' : 'dark_mode';
    });
    
    const switchEl = document.querySelector('#settings-darkmode-switch');
    if (switchEl) {
      switchEl.checked = this.isDark;
    }
    // RETHINK: We do NOT call renderPlayerUI here anymore to avoid any risk of restart
    // Instead we just update the specific contrast-sensitive buttons
    updatePlayerExtrasVisibility();
  }
};

function updatePlayerExtrasVisibility() {
  const extras = document.querySelector('.player-extras');
  if (extras) {
    // Force specific colors if browser isn't picking up CSS vars correctly
    const color = theme.isDark ? '#FFFFFF' : '#000000';
    extras.querySelectorAll('.material-symbols-rounded').forEach(i => {
      if (!i.closest('.ctrl-active')) i.style.color = color;
    });
  }
}

document.addEventListener('DOMContentLoaded', () => {
  theme.apply();
  initWaveform();
  bindLogin();
  bindNavigation();
  bindSearch();
  bindPlayerControls();
  bindSettings();
  bindSleepTimer();
  bindThemeToggle();
  bindManualAdd();
  bindPlaylistAdd();
  bindPlaylistDetails();
  
  syncClock();
  bindRoomSettings();
  
  if (localStorage.getItem('sv_session') === '1') {
    document.querySelector('#screen-login').classList.add('hidden');
    document.querySelector('#app-shell').classList.remove('hidden');
    
    const currentHash = window.location.hash.replace('#', '') || 'home';
    navigateTo(currentHash, false);
    
    loadAppData();

    if (activeRoomId) {
      showRoomConnectedUI(activeRoomId);
      connectRoomSse(activeRoomId);
    }
  }
});

function initWaveform() {
  const container = document.querySelector('#waveform-container'); if (!container) return;
  for (let i = 0; i < 40; i++) {
    const bar = document.createElement('div'); bar.className = 'wave-bar';
    bar.style.height = (10 + Math.random() * 80) + 'px';
    bar.style.animationDelay = (Math.random() * 1.5) + 's';
    container.appendChild(bar);
  }
}

function bindLogin() {
  document.querySelector('#btn-enter')?.addEventListener('click', enterApp);
  document.querySelector('#btn-guest')?.addEventListener('click', enterApp);
}

function enterApp() { 
  localStorage.setItem('sv_session', '1'); 
  document.querySelector('#screen-login').classList.add('hidden'); 
  document.querySelector('#app-shell').classList.remove('hidden'); 
  loadAppData(); 
}

async function loadAppData() {
  const cachedSongs = localStorage.getItem('sv_songs_cache');
  if (cachedSongs) { allSongs = JSON.parse(cachedSongs); renderHome(); renderLibrary(); }
  
  try {
    const [songsRes, plRes] = await Promise.all([
        fetch('/api/songs'),
        fetch('/api/playlists')
    ]);
    const songsData = await songsRes.json();
    const plData = await plRes.json();
    
    allSongs = songsData.songs || [];
    allPlaylists = plData.playlists || [];
    
    localStorage.setItem('sv_songs_cache', JSON.stringify(allSongs));
    renderHome(); renderLibrary(); renderPlaylists();
  } catch (err) { console.error('Data Load Failed:', err); }
}

function renderHome() {
  const recentGrid = document.querySelector('#recent-grid');
  if (!recentGrid) return;
  const recent = allSongs.slice(-6).reverse();
  recentGrid.innerHTML = recent.map(s => `
    <div class="recent-item" data-id="${s.id}">
      <div class="recent-art">${s.image ? `<img src="${s.image}" class="track-img">` : ''}</div>
      <span class="ri-name">${s.name}</span>
    </div>
  `).join('');
  recentGrid.querySelectorAll('.recent-item').forEach(el => el.addEventListener('click', () => playSongById(el.dataset.id)));
  renderTrackList(document.querySelector('#home-tracks'), allSongs.slice(0, 10));
}

function renderLibrary() {
  const songCount = document.querySelector('#stat-songs');
  const artistCount = document.querySelector('#stat-artists');
  if (songCount) songCount.textContent = allSongs.length;
  if (artistCount) artistCount.textContent = new Set(allSongs.map(s => s.artist)).size;
  
  renderTrackList(document.querySelector('#library-tracks'), allSongs);
  document.querySelector('#btn-shuffle-all')?.addEventListener('click', () => { 
    const shuffled = [...allSongs].sort(() => Math.random() - 0.5); 
    if (shuffled.length) playSong(shuffled[0], shuffled); 
  });
  document.querySelector('#btn-play-all')?.addEventListener('click', () => { 
    if (allSongs.length) playSong(allSongs[0], allSongs); 
  });
}

function renderPlaylists() {
    const list = document.querySelector('#playlist-list');
    if (!list) return;
    list.innerHTML = allPlaylists.map(pl => `
        <div class="mix-card playlist-card" data-plid="${pl.id}">
            <div class="mix-art" style="background: linear-gradient(135deg, #222, #000);">
                <span class="material-symbols-rounded" style="font-size:48px;color:var(--primary)">folder</span>
            </div>
            <p class="mix-title">${pl.name}</p>
            <p class="mix-sub">${pl.songs.length} tracks</p>
        </div>
    `).join('');

    list.querySelectorAll('.playlist-card').forEach(card => {
        card.addEventListener('click', () => navigateToPlaylist(card.dataset.plid));
    });
}

async function navigateToPlaylist(id) {
    try {
        const res = await fetch(`/api/playlists/${id}`);
        const pl = await res.json();
        renderPlaylistDetails(pl);
        navigateTo('playlist-details');
    } catch (e) { alert('Failed to load playlist'); }
}

function addToQueue(song) {
  if (!currentPlaylist || currentPlaylist.length === 0) {
    currentPlaylist = [...allSongs];
    currentIndex = currentPlaylist.findIndex(s => s.id === (currentSong ? currentSong.id : ''));
  }
  
  currentPlaylist.push(song);
  showToast(`Added to Queue: ${song.name}`);
  renderQueuePanel();
}

function renderTrackList(container, songs, queueContext) {
  if (!container) return;
  const isLibrary = container.id === 'library-tracks';
  const isPlaylist = container.id === 'playlist-details-tracks';

  container.innerHTML = songs.map((s) => {
    const isActive = currentSong && currentSong.id === s.id;
    return `
      <div class="track-item ${isActive ? 'playing' : ''}" data-id="${s.id}">
        <div class="track-art">${s.image ? `<img src="${s.image}" class="track-img">` : ''}</div>
        <div class="track-meta">
          <div class="track-name">${s.name}</div>
          <div class="track-artist">${s.artist.split(',')[0]}</div>
        </div>
        <div class="track-right">
          ${isLibrary ? `<button class="icon-btn btn-song-delete" title="Delete Permanently" style="color:var(--on-surface-low); width: 32px; height: 32px;"><span class="material-symbols-rounded" style="font-size: 18px;">delete</span></button>` : ''}
          ${isPlaylist ? `<button class="icon-btn btn-song-remove-pl" title="Remove from Playlist" style="color:var(--on-surface-low); width: 32px; height: 32px;"><span class="material-symbols-rounded" style="font-size: 18px;">remove_circle_outline</span></button>` : ''}
          <button class="icon-btn btn-add-queue" title="Add to Queue" style="color:var(--on-surface-low); width: 32px; height: 32px;">
            <span class="material-symbols-rounded" style="font-size: 18px;">playlist_add</span>
          </button>
          ${likedSongs.has(s.id) ? '<span class="material-symbols-rounded track-liked">favorite</span>' : ''}
          <span class="track-duration">${formatDuration(s.duration_ms)}</span>
        </div>
      </div>
    `;
  }).join('');

  container.querySelectorAll('.track-item').forEach(el => {
    el.addEventListener('click', (e) => {
      if (e.target.closest('.icon-btn')) return; // Ignore if clicking remove/delete/queue button
      const songId = el.dataset.id;
      const targetSong = songs.find(s => s.id === songId);
      if (targetSong) {
        playSong(targetSong, queueContext || songs || allSongs);
      }
    });
  });

  // Bind Add to Queue
  container.querySelectorAll('.btn-add-queue').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const item = btn.closest('.track-item');
      const songId = item.dataset.id;
      const targetSong = songs.find(s => s.id === songId) || allSongs.find(s => s.id === songId);
      if (targetSong) {
        addToQueue(targetSong);
      }
    });
  });

  // Bind Delete from Library
  container.querySelectorAll('.btn-song-delete').forEach(btn => {
    btn.addEventListener('click', async (e) => {
        e.stopPropagation();
        const item = btn.closest('.track-item');
        const id = item.dataset.id;
        const song = allSongs.find(s => s.id === id);
        if (!confirm(`Permanently delete "${song.name}" from library and Telegram?`)) return;

        try {
            const res = await fetch(`/api/songs/${id}`, { method: 'DELETE' });
            const data = await res.json();
            if (data.status === 'ok') {
                loadAppData();
            } else {
                alert('Delete failed');
            }
        } catch (err) { alert('Error deleting song'); }
    });
  });

  // Bind Remove from Playlist
  container.querySelectorAll('.btn-song-remove-pl').forEach(btn => {
    btn.addEventListener('click', async (e) => {
        e.stopPropagation();
        const item = btn.closest('.track-item');
        const songId = item.dataset.id;
        if (!activePlaylist) return;

        try {
            const res = await fetch(`/api/playlists/${activePlaylist.id}/songs/${songId}`, { method: 'DELETE' });
            const data = await res.json();
            if (data.status === 'ok') {
                navigateToPlaylist(activePlaylist.id);
            } else {
                alert('Remove failed');
            }
        } catch (err) { alert('Error removing song from playlist'); }
    });
  });
}

function removeFromQueue(idx) {
  if (!currentPlaylist || currentPlaylist.length === 0) {
    currentPlaylist = [...allSongs];
  }
  
  const removedSong = currentPlaylist[idx];
  if (!removedSong) return;
  
  currentPlaylist.splice(idx, 1);
  
  if (idx === currentIndex) {
    if (currentPlaylist.length === 0) {
      audio.pause();
      currentSong = null;
      currentIndex = -1;
      document.querySelector('#mini-player').classList.add('hidden');
    } else {
      currentIndex = currentIndex % currentPlaylist.length;
      playSong(currentPlaylist[currentIndex], currentPlaylist);
    }
  } else if (idx < currentIndex) {
    currentIndex--;
  }
  
  showToast(`Removed from Queue: ${removedSong.name}`);
  renderQueuePanel();
  
  if (currentSong) {
    renderPlayerUI(currentSong);
  }
}

function renderQueuePanel() {
  const list = document.querySelector('#queue-list'); if (!list) return;
  const queue = currentPlaylist.length ? currentPlaylist : allSongs;
  list.innerHTML = queue.map((s, idx) => `
    <div class="queue-item ${s.id === currentSong?.id ? 'queue-active' : ''}" data-id="${s.id}" data-idx="${idx}">
      <div class="track-meta" style="flex:1">
        <div class="track-name" style="font-weight:700">${s.name}</div>
        <div class="track-artist" style="font-size:12px;color:var(--on-surface-dim)">${s.artist.split(',')[0]}</div>
      </div>
      <button class="icon-btn btn-remove-queue" title="Remove from Queue" style="color:var(--on-surface-low); width: 32px; height: 32px; margin-right: 8px;">
        <span class="material-symbols-rounded" style="font-size: 18px;">remove_circle_outline</span>
      </button>
      <span class="material-symbols-rounded" style="color:var(--on-surface-low)">drag_indicator</span>
    </div>
  `).join('');
  
  list.querySelectorAll('.queue-item').forEach(el => el.addEventListener('click', (e) => { 
    if (e.target.closest('.icon-btn')) return; // Ignore if clicking remove button
    const idx = parseInt(el.dataset.idx);
    const targetSong = queue[idx];
    if (targetSong) {
      playSong(targetSong, queue);
      document.querySelector('#queue-panel').classList.add('hidden'); 
    }
  }));

  list.querySelectorAll('.btn-remove-queue').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      const item = btn.closest('.queue-item');
      const idx = parseInt(item.dataset.idx);
      removeFromQueue(idx);
    });
  });
}

function formatDuration(ms) { if (!ms) return '0:00'; const mins = Math.floor(ms / 60000); const secs = Math.floor((ms % 60000) / 1000); return `${mins}:${secs.toString().padStart(2, '0')}`; }

const audio = new Audio(); audio.preload = 'auto'; audio.autoplay = true;

function playSongById(id) { const song = allSongs.find(s => s.id === id); if (song) playSong(song); }

function renderPlayerUI(song) {
  if (!song) return;
  document.querySelector('#player-title').textContent = song.name; 
  document.querySelector('#player-artist').textContent = song.artist;
  document.querySelector('#player-art').innerHTML = song.image ? `<img src="${song.image}" class="player-img-full">` : `<div class="player-art-inner"><span class="material-symbols-rounded" style="font-size:80px;color:var(--surface-dim)">music_note</span></div>`;
  document.querySelector('#mini-art').innerHTML = song.image ? `<img src="${song.image}" class="track-img">` : '';
  document.querySelector('#mini-title').textContent = song.name; 
  document.querySelector('#mini-artist').textContent = song.artist.split(',')[0];
  
  if (document.querySelector('#screen-player').classList.contains('active')) { 
    document.querySelector('#mini-player').classList.add('hidden'); 
    document.querySelector('#bottom-nav').style.display = 'none'; 
  } else { 
    document.querySelector('#mini-player').classList.remove('hidden'); 
    document.querySelector('#bottom-nav').style.display = 'flex'; 
  }
  
  renderFavoriteIcon(song);
  document.querySelectorAll('.track-item').forEach(el => el.classList.toggle('playing', el.dataset.id === song.id));
  updatePlayerExtrasVisibility();
}

function renderFavoriteIcon(song) {
  const favBtn = document.querySelector('#btn-favorite');
  if (favBtn) {
    const icon = favBtn.querySelector('.material-symbols-rounded');
    if (icon) {
      const isLiked = likedSongs.has(song.id);
      icon.textContent = isLiked ? 'favorite' : 'favorite_border'; 
      favBtn.style.color = isLiked ? 'var(--primary)' : (theme.isDark ? '#FFFFFF' : '#000000'); 
    }
  }
}

function playSong(song, playlist) {
  _preCachedNextId = null; 
  _nextTrackPreloaded = false;
  currentSong = song; 
  isPlaying = true; 
  currentPlaylist = playlist || allSongs; 
  currentIndex = currentPlaylist.findIndex(s => s.id === song.id);
  
  renderPlayerUI(song);

  isChangingSong = true;
  sendRoomStateUpdateDirect(song.id, true, 0);

  audio.src = `/api/stream/${song.id}`;
  audio.load();
  audio.play().catch(e => {
    isChangingSong = false;
    if (e.name === 'AbortError') {
      console.log('Play request was interrupted by a new request or pause.');
      return;
    }
    console.error('Audio Play Error:', e);
    alert('Failed to play track. Telegram might be slow — please try again in a few seconds.');
  });

  updateMediaSession(song);
}

function updateMediaSession(song) {
  if ('mediaSession' in navigator) {
    console.log('📱 Updating MediaSession for:', song.name);
    navigator.mediaSession.metadata = new MediaMetadata({ 
      title: song.name, 
      artist: song.artist, 
      album: 'Sonic Vault', 
      artwork: [
        { src: song.image || '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
        { src: song.image || '/icons/icon-512.png', sizes: '512x512', type: 'image/png' }
      ]
    });
    
    // Explicit handlers to ensure OS doesn't kill the session
    navigator.mediaSession.setActionHandler('play', () => audio.play()); 
    navigator.mediaSession.setActionHandler('pause', () => audio.pause());
    navigator.mediaSession.setActionHandler('previoustrack', () => playPrev()); 
    navigator.mediaSession.setActionHandler('nexttrack', () => playNext());
    
    try {
      navigator.mediaSession.setActionHandler('seekto', (details) => {
        if (details.seekTime && isFinite(details.seekTime)) {
          audio.currentTime = details.seekTime;
          updateMediaSessionPositionState();
        }
      });
    } catch (error) {
      console.log('MediaSession "seekto" not supported');
    }
    
    updateMediaSessionPositionState();
  }
}

function updateMediaSessionPositionState() {
  if ('mediaSession' in navigator && 'setPositionState' in navigator.mediaSession) {
    if (isFinite(audio.duration) && isFinite(audio.currentTime) && isFinite(audio.playbackRate)) {
      navigator.mediaSession.setPositionState({
        duration: audio.duration,
        playbackRate: audio.playbackRate,
        position: audio.currentTime
      });
    }
  }
}

let _isDraggingProgress = false;
let _nextTrackPreloaded = false;

audio.addEventListener('timeupdate', () => {
  if (isChangingSong) return;
  if (!audio.duration || !isFinite(audio.duration)) return;
  
  const remaining = audio.duration - audio.currentTime;
  
  // Predictive Pre-loading: 45 seconds before end
  if (remaining < 45 && !_nextTrackPreloaded) {
    _nextTrackPreloaded = true;
    triggerPreCacheNext();
  }

  const pct = (audio.currentTime / audio.duration) * 100;
  if (!_isDraggingProgress) { 
    const fill = document.querySelector('#progress-fill'); if (fill) fill.style.width = pct + '%';
    const curTime = document.querySelector('#time-current'); if (curTime) curTime.textContent = formatDuration(audio.currentTime * 1000);
  }
  const mFill = document.querySelector('#mini-progress'); if (mFill) mFill.style.width = pct + '%';
  const totalTime = document.querySelector('#time-total'); if (totalTime) totalTime.textContent = formatDuration(audio.duration * 1000);
});

audio.addEventListener('ended', () => {
  console.log('🎵 Track ended, moving to next...');
  _nextTrackPreloaded = false;
  playNext();
});
audio.addEventListener('playing', () => { 
  isPlaying = true;
  const playIcons = document.querySelectorAll('.material-symbols-rounded');
  playIcons.forEach(i => { if (i.textContent === 'play_arrow' && (i.closest('#btn-play') || i.closest('#mini-play'))) i.textContent = 'pause'; });
  isChangingSong = false;
  sendRoomStateUpdate();
});
audio.addEventListener('pause', () => { 
  isPlaying = false;
  const playIcons = document.querySelectorAll('.material-symbols-rounded');
  playIcons.forEach(i => { if (i.textContent === 'pause' && (i.closest('#btn-play') || i.closest('#mini-play'))) i.textContent = 'play_arrow'; });
  sendRoomStateUpdate();
});
audio.addEventListener('seeked', () => {
  sendRoomStateUpdate();
});

function playNext() {
  const queue = currentPlaylist.length ? currentPlaylist : allSongs; if (!queue.length) return;
  if (isShuffleOn) { let nextIdx; do { nextIdx = Math.floor(Math.random() * queue.length); } while (nextIdx === currentIndex && queue.length > 1); currentIndex = nextIdx; }
  else currentIndex = (currentIndex + 1) % queue.length;
  playSong(queue[currentIndex], queue);
}

function playPrev() { if (audio.currentTime > 3) { audio.currentTime = 0; return; } currentIndex = (currentIndex - 1 + currentPlaylist.length) % currentPlaylist.length; playSong(currentPlaylist[currentIndex], currentPlaylist); }

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
    _nextTrackPreloaded = true;
    _preCachedNextId = nextSong.id;
    console.log('📡 Pre-caching next song:', nextSong.name);
    fetch('/api/precache/' + nextSong.id).catch(err => {
      console.error('Precache failed:', err);
    });
  }
}

function bindPlayerControls() {
  document.querySelector('#btn-play')?.addEventListener('click', () => { isChangingSong = false; audio.paused ? audio.play() : audio.pause(); });
  document.querySelector('#mini-play')?.addEventListener('click', (e) => { e.stopPropagation(); isChangingSong = false; audio.paused ? audio.play() : audio.pause(); });
  document.querySelector('#btn-next')?.addEventListener('click', () => { isChangingSong = false; playNext(); }); 
  document.querySelector('#mini-next')?.addEventListener('click', (e) => { e.stopPropagation(); isChangingSong = false; playNext(); });
  document.querySelector('#btn-prev')?.addEventListener('click', () => { isChangingSong = false; playPrev(); });
  document.querySelector('#btn-player-back')?.addEventListener('click', () => history.back());
  
  // Make the entire mini-player container clickable to open the full-screen player, except when clicking the control buttons
  document.querySelector('#mini-player')?.addEventListener('click', (e) => {
    if (e.target.closest('.mini-controls')) return;
    navigateTo('player');
  });
  
  document.querySelector('#btn-shuffle')?.addEventListener('click', () => { 
    isShuffleOn = !isShuffleOn; 
    document.querySelector('#btn-shuffle').style.color = isShuffleOn ? 'var(--primary)' : ''; 
  });
  document.querySelector('#btn-repeat')?.addEventListener('click', () => { 
    repeatMode = (repeatMode + 1) % 2; 
    document.querySelector('#btn-repeat').style.color = repeatMode ? 'var(--primary)' : ''; 
  });
  document.querySelector('#btn-favorite')?.addEventListener('click', () => { 
    if (!currentSong) return; 
    if (likedSongs.has(currentSong.id)) likedSongs.delete(currentSong.id); 
    else likedSongs.add(currentSong.id); 
    localStorage.setItem('sv_liked', JSON.stringify([...likedSongs])); 
    renderFavoriteIcon(currentSong);
    // Also update track lists in background silently
    renderLibrary();
    renderHome();
  });
  document.querySelector('#btn-queue')?.addEventListener('click', () => { 
    renderQueuePanel(); 
    document.querySelector('#queue-panel').classList.remove('hidden'); 
  });
  document.querySelector('#queue-close')?.addEventListener('click', () => document.querySelector('#queue-panel').classList.add('hidden'));

  const progressBar = document.querySelector('.progress-bar');
  if (progressBar) {
    const getPct = (e) => { 
      const rect = progressBar.getBoundingClientRect(); 
      let cx;
      if (e.changedTouches && e.changedTouches.length > 0) cx = e.changedTouches[0].clientX;
      else if (e.touches && e.touches.length > 0) cx = e.touches[0].clientX;
      else cx = e.clientX;
      return Math.max(0, Math.min(1, (cx - rect.left) / rect.width)); 
    };
    const move = (e) => { 
      if (_isDraggingProgress) { 
        const pct = getPct(e);
        const fill = document.querySelector('#progress-fill');
        if (fill) fill.style.width = (pct * 100) + '%'; 
        const curTime = document.querySelector('#time-current');
        if (curTime && audio.duration) curTime.textContent = formatDuration(pct * audio.duration * 1000);
      } 
    };
    const start = (e) => { _isDraggingProgress = true; move(e); };
    const end = (e) => { if (_isDraggingProgress) { _isDraggingProgress = false; if (audio.duration) audio.currentTime = getPct(e) * audio.duration; } };
    progressBar.addEventListener('mousedown', start); window.addEventListener('mousemove', move); window.addEventListener('mouseup', end);
    progressBar.addEventListener('touchstart', start, {passive:true}); window.addEventListener('touchmove', move, {passive:true}); window.addEventListener('touchend', end);
  }
}

let currentScreen = 'home';
let lastScreen = 'home';

function navigateTo(screen, pushState = true) {
  if (screen === currentScreen && pushState) return;
  
  if (screen !== 'player' && screen !== 'playlist-details') {
    lastScreen = currentScreen !== 'player' && currentScreen !== 'playlist-details' ? currentScreen : lastScreen;
  }
  
  currentScreen = screen;
  
  if (pushState) {
    history.pushState({ screen }, '', '#' + screen);
  }
  
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = document.querySelector(`#screen-${screen}`);
  if (target) target.classList.add('active');
  
  document.querySelectorAll('.nav-item').forEach(btn => { 
    btn.classList.toggle('active', btn.dataset.screen === screen); 
  });
  
  const miniPlayer = document.querySelector('#mini-player');
  const bottomNav = document.querySelector('#bottom-nav');
  
  if (screen === 'player') { 
    if (bottomNav) bottomNav.style.display = 'none'; 
    if (miniPlayer) miniPlayer.classList.add('hidden'); 
  } else { 
    if (bottomNav) bottomNav.style.display = 'flex'; 
    if (currentSong && miniPlayer) miniPlayer.classList.remove('hidden'); 
    if (screen === 'library') {
      document.querySelector('#screen-library .page-title').textContent = 'Your Library';
    }
  }
}

// Global popstate history listener
window.addEventListener('popstate', (event) => {
  if (event.state && event.state.screen) {
    navigateTo(event.state.screen, false);
  } else {
    const hash = window.location.hash.replace('#', '') || 'home';
    navigateTo(hash, false);
  }
});

function bindNavigation() {
  document.querySelectorAll('.nav-item').forEach(btn => btn.addEventListener('click', () => navigateTo(btn.dataset.screen)));
  document.querySelectorAll('[data-nav]').forEach(btn => btn.addEventListener('click', () => navigateTo(btn.dataset.nav)));
  
  // Back button for settings
  document.querySelector('#btn-settings-back')?.addEventListener('click', () => history.back());
}

function bindSettings() { 
  document.querySelector('#btn-signout')?.addEventListener('click', () => { 
    localStorage.removeItem('sv_session'); 
    location.reload(); 
  }); 
}

function bindSearch() {
  const input = document.querySelector('#search-input'); 
  const clearBtn = document.querySelector('#search-clear');
  const browseSection = document.querySelector('#search-browse-section');
  const resultsSection = document.querySelector('#search-results-section');
  
  input?.addEventListener('input', () => {
    const q = input.value.trim().toLowerCase(); 
    clearBtn?.classList.toggle('hidden', !q);
    if (!q) { 
      if (resultsSection) resultsSection.style.display = 'none'; 
      if (browseSection) browseSection.style.display = 'block';
      return; 
    }
    const results = allSongs.filter(s => s.name.toLowerCase().includes(q) || s.artist.toLowerCase().includes(q));
    if (resultsSection) resultsSection.style.display = 'block'; 
    if (browseSection) browseSection.style.display = 'none';
    renderTrackList(document.querySelector('#search-results'), results);
  });
  
  clearBtn?.addEventListener('click', () => { 
    input.value = ''; 
    clearBtn.classList.add('hidden'); 
    if (resultsSection) resultsSection.style.display = 'none'; 
    if (browseSection) browseSection.style.display = 'block';
  });
}

let _sleepTimerId = null;
function bindSleepTimer() {
  document.querySelector('#btn-sleep-timer')?.addEventListener('click', () => document.querySelector('#sleep-modal').classList.remove('hidden'));
  document.querySelector('#sleep-modal-close')?.addEventListener('click', () => document.querySelector('#sleep-modal').classList.add('hidden'));
  document.querySelectorAll('.sleep-opt').forEach(btn => btn.addEventListener('click', () => {
    const mins = parseInt(btn.dataset.minutes);
    clearTimeout(_sleepTimerId);
    document.querySelectorAll('.sleep-opt').forEach(b => b.classList.remove('active'));
    
    if (mins > 0) {
      btn.classList.add('active');
      _sleepTimerId = setTimeout(() => {
        audio.pause();
        alert('Sleep timer reached: Music paused.');
      }, mins * 60000);
      document.querySelector('#btn-sleep-timer').style.color = 'var(--primary)';
    } else {
      document.querySelector('#btn-sleep-timer').style.color = '';
    }
    document.querySelector('#sleep-modal').classList.add('hidden');
  }));
}

function bindThemeToggle() {
  document.querySelector('#btn-theme')?.addEventListener('click', () => theme.toggle());
  document.querySelector('#btn-theme-player')?.addEventListener('click', () => theme.toggle());
  document.querySelector('#settings-darkmode-switch')?.addEventListener('change', () => theme.toggle());
}

function bindManualAdd() {
    const showBtn = document.querySelector('#btn-show-add');
    const modal = document.querySelector('#add-modal');
    const closeBtn = document.querySelector('#add-modal-close');
    
    showBtn?.addEventListener('click', () => modal.classList.remove('hidden'));
    closeBtn?.addEventListener('click', () => modal.classList.add('hidden'));

    // OLD MODAL (kept for safety if still used by some triggers)
    const modalSubmitBtn = document.querySelector('#btn-add-submit');
    const modalLoading = document.querySelector('#add-loading');
    
    modalSubmitBtn?.addEventListener('click', async () => {
        const url = document.querySelector('#add-url').value.trim();
        const name = document.querySelector('#add-name').value.trim();
        const artist = document.querySelector('#add-artist').value.trim();
        await performAddSong(url, name, artist, modalSubmitBtn, modalLoading, (msg) => {
            if (modalLoading) modalLoading.textContent = msg;
        });
    });

    // NEW CREATE SCREEN
    const mainSubmitBtn = document.querySelector('#btn-main-add-submit');
    const mainStatus = document.querySelector('#main-add-status');
    const mainStatusText = document.querySelector('#main-add-status-text');

    mainSubmitBtn?.addEventListener('click', async () => {
        const url = document.querySelector('#main-add-url').value.trim();
        const name = document.querySelector('#main-add-name').value.trim();
        const artist = document.querySelector('#main-add-artist').value.trim();
        
        await performAddSong(url, name, artist, mainSubmitBtn, mainStatus, (msg) => {
            if (mainStatusText) mainStatusText.textContent = msg;
        });
    });
}

async function performAddSong(url, name, artist, btn, statusEl, statusLogger) {
    if (!url && (!name || !artist)) return alert('Please enter a Link OR Name + Artist.');
    
    if (statusEl) statusEl.classList.remove('hidden');
    if (btn) btn.disabled = true;
    if (statusLogger) statusLogger('Initializing sync...');

    try {
        // Since we don't have a real stream for status yet, we'll simulate steps if it's a link
        if (url) {
            statusLogger('Fetching metadata from ' + (url.includes('spotify') ? 'Spotify' : 'YouTube') + '...');
            await new Promise(r => setTimeout(r, 1000));
            statusLogger('Downloading audio layers...');
            await new Promise(r => setTimeout(r, 1500));
            statusLogger('Syncing to Telegram Vault...');
        } else {
            statusLogger('Searching and downloading...');
        }

        const res = await fetch('/api/add-song', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ url, name, artist })
        });
        
        const data = await res.json();
        
        if (data.status === 'ok') {
            statusLogger('Success! Finalizing...');
            // Clear inputs
            document.querySelectorAll('#add-url, #main-add-url, #add-name, #main-add-name, #add-artist, #main-add-artist').forEach(i => i.value = '');
            loadAppData();
            alert('✨ Successfully added to vault!');
            if (statusEl) statusEl.classList.add('hidden');
            navigateTo('library');
        } else {
            handleSyncError(data);
        }
    } catch (e) {
        console.error('Sync Error:', e);
        alert('❌ Failed to connect to server. Check your connection.');
    } finally {
        if (statusEl) statusEl.classList.add('hidden');
        if (btn) btn.disabled = false;
        if (statusLogger) statusLogger('Syncing to cloud...');
    }
}

function handleSyncError(data) {
    let msg = 'Failed to add song.';
    if (data.type === 'TIMEOUT') {
        msg = '⏳ Telegram storage connection timed out. This usually happens on slow networks. The server is still trying in the background, check back in a minute.';
    } else if (data.message) {
        msg = '❌ Error: ' + data.message;
    }
    alert(msg);
}

function bindPlaylistAdd() {
    const showBtn = document.querySelector('#btn-show-playlist-add');
    const modal = document.querySelector('#playlist-modal');
    const closeBtn = document.querySelector('#playlist-modal-close');
    const submitBtn = document.querySelector('#btn-playlist-submit');

    showBtn?.addEventListener('click', () => modal.classList.remove('hidden'));
    closeBtn?.addEventListener('click', () => modal.classList.add('hidden'));

    submitBtn?.addEventListener('click', async () => {
        const name = document.querySelector('#playlist-name').value.trim();
        if (!name) return alert('Name required');

        try {
            const res = await fetch('/api/playlists', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name })
            });
            const data = await res.json();
            if (data.status === 'ok') {
                modal.classList.add('hidden');
                document.querySelector('#playlist-name').value = '';
                loadAppData();
            }
        } catch (e) { alert('Failed to create playlist'); }
    });
}

let activePlaylist = null;

function renderPlaylistDetails(playlist) {
  activePlaylist = playlist;
  
  const nameEl = document.querySelector('#playlist-details-name');
  if (nameEl) nameEl.textContent = playlist.name;
  
  const metaEl = document.querySelector('#playlist-details-meta');
  if (metaEl) {
    const totalMs = playlist.songs.reduce((acc, s) => acc + (s.duration_ms || 0), 0);
    const totalMins = Math.round(totalMs / 60000);
    metaEl.textContent = `${playlist.songs.length} tracks • ${totalMins} min`;
  }
  
  const listEl = document.querySelector('#playlist-details-tracks');
  if (listEl) {
    if (playlist.songs.length === 0) {
      listEl.innerHTML = `
        <div style="text-align:center;padding:48px 16px;color:var(--on-surface-dim)">
          <span class="material-symbols-rounded" style="font-size:48px;display:block;margin-bottom:12px;">queue_music</span>
          <p style="font-weight:600">This playlist is empty</p>
          <p style="font-size:12px;margin-top:4px;">Tap 'Add Songs' to sync tracks from your library.</p>
        </div>
      `;
    } else {
      renderTrackList(listEl, playlist.songs, playlist.songs);
    }
  }
}

function bindPlaylistDetails() {
  document.querySelector('#btn-playlist-details-back')?.addEventListener('click', () => {
    history.back();
  });
  
  document.querySelector('#btn-playlist-details-delete')?.addEventListener('click', async () => {
    if (!activePlaylist) return;
    if (!confirm(`Are you sure you want to delete the playlist "${activePlaylist.name}"?`)) return;
    
    try {
      const res = await fetch(`/api/playlists/${activePlaylist.id}`, { method: 'DELETE' });
      const data = await res.json();
      if (data.status === 'ok') {
        loadAppData();
        history.back();
      } else {
        alert('Failed to delete playlist');
      }
    } catch (e) {
      alert('Error deleting playlist');
    }
  });

  document.querySelector('#btn-playlist-play')?.addEventListener('click', () => {
    if (activePlaylist && activePlaylist.songs.length > 0) {
      playSong(activePlaylist.songs[0], activePlaylist.songs);
    } else {
      alert('This playlist is empty! Add some songs first.');
    }
  });

  document.querySelector('#btn-playlist-shuffle')?.addEventListener('click', () => {
    if (activePlaylist && activePlaylist.songs.length > 0) {
      isShuffleOn = true;
      const shBtn = document.querySelector('#btn-shuffle');
      if (shBtn) shBtn.style.color = 'var(--primary)';
      
      const randomIdx = Math.floor(Math.random() * activePlaylist.songs.length);
      playSong(activePlaylist.songs[randomIdx], activePlaylist.songs);
    } else {
      alert('This playlist is empty! Add some songs first.');
    }
  });

  document.querySelector('#btn-playlist-add-songs')?.addEventListener('click', () => {
    if (!activePlaylist) return;
    renderPlaylistAddSongsModal();
    document.querySelector('#playlist-songs-add-modal').classList.remove('hidden');
  });

  document.querySelector('#playlist-songs-add-modal-close')?.addEventListener('click', () => {
    document.querySelector('#playlist-songs-add-modal').classList.add('hidden');
  });
}

function renderPlaylistAddSongsModal() {
  const container = document.querySelector('#playlist-add-songs-list');
  if (!container || !activePlaylist) return;
  
  const songsToAdd = allSongs.filter(s => !activePlaylist.songs.some(ps => ps.id === s.id));
  
  if (songsToAdd.length === 0) {
    container.innerHTML = `
      <div style="text-align:center;padding:24px 8px;color:var(--on-surface-dim);font-size:14px;">
        All vault songs are already in this playlist!
      </div>
    `;
    return;
  }
  
  container.innerHTML = songsToAdd.map(s => `
    <div class="playlist-add-item">
      <div class="track-meta" style="flex:1;margin-right:12px;overflow:hidden;">
        <div class="track-name" style="font-weight:600;font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${s.name}</div>
        <div class="track-artist" style="font-size:12px;color:var(--on-surface-dim);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">${s.artist}</div>
      </div>
      <button class="btn-add-track-to-pl" data-sid="${s.id}">
        <span class="material-symbols-rounded">add</span>
      </button>
    </div>
  `).join('');
  
  container.querySelectorAll('.btn-add-track-to-pl').forEach(btn => {
    btn.addEventListener('click', async () => {
      const songId = btn.dataset.sid;
      btn.disabled = true;
      btn.style.opacity = '0.5';
      
      try {
        const res = await fetch(`/api/playlists/${activePlaylist.id}/add`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ songId })
        });
        const data = await res.json();
        if (data.status === 'ok') {
          const songObj = allSongs.find(s => s.id === songId);
          if (songObj) {
            activePlaylist.songs.push(songObj);
          }
          renderPlaylistDetails(activePlaylist);
          renderPlaylistAddSongsModal();
          loadAppData();
        } else {
          alert('Failed to add song to playlist');
          btn.disabled = false;
          btn.style.opacity = '1';
        }
      } catch (e) {
        alert('Error adding song to playlist');
        btn.disabled = false;
        btn.style.opacity = '1';
      }
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// LISTENING ROOM FUNCTIONS
// ─────────────────────────────────────────────────────────────────────────────

async function syncClock() {
  try {
    const start = Date.now();
    const res = await fetch('/api/time');
    const data = await res.json();
    const end = Date.now();
    const rtt = end - start;
    const estimatedServerTime = data.time + (rtt / 2);
    clockOffset = estimatedServerTime - end;
    console.log('⏰ Clock synced. Offset:', clockOffset, 'ms');
  } catch (e) {
    console.error('Failed to sync clock:', e);
  }
}

async function sendRoomStateUpdateDirect(songId, playing, position) {
  if (!activeRoomId || isSyncingFromServer) return;
  console.log(`📡 Sending Room Update Direct: roomId=${activeRoomId}, songId=${songId}, playing=${playing}, pos=${position}`);
  try {
    await fetch(`/api/rooms/${activeRoomId}/update`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        currentSongId: songId,
        isPlaying: playing,
        position: position
      })
    });
  } catch (err) {
    console.error('Failed to send room update:', err);
  }
}

async function sendRoomStateUpdate() {
  if (!activeRoomId || isSyncingFromServer || isChangingSong) return;
  
  const songId = currentSong ? currentSong.id : '';
  const playing = !audio.paused;
  const position = Math.round(audio.currentTime * 1000); // milliseconds

  await sendRoomStateUpdateDirect(songId, playing, position);
}

function handleRoomSseMessage(roomState) {
  if (!roomState || roomState.error) {
    console.warn('Room SSE error or empty state:', roomState);
    return;
  }

  const { roomId, currentSongId, isPlaying: targetPlaying, position: targetPos, updatedAt } = roomState;

  if (roomId !== activeRoomId) return;

  const currentLocalSongId = currentSong ? currentSong.id : '';
  
  isSyncingFromServer = true;

  const performSync = async () => {
    try {
      if (currentSongId && currentSongId !== currentLocalSongId) {
        console.log(`📡 Loading new room song: ${currentSongId}`);
        const songRes = await fetch(`/api/songs/${currentSongId}`);
        if (songRes.ok) {
          const songDetails = await songRes.json();
          
          let playlist = allSongs;
          if (currentPlaylist && currentPlaylist.length > 0) {
            playlist = currentPlaylist;
          }
          
          currentSong = songDetails;
          currentIndex = playlist.findIndex(s => s.id === currentSongId);
          if (currentIndex === -1) {
            playlist = [songDetails];
            currentIndex = 0;
          }
          currentPlaylist = playlist;
          
          renderPlayerUI(songDetails);
          audio.src = `/api/stream/${songDetails.id}`;
          audio.load();
        } else {
          console.error('Failed to fetch song details for sync');
          return;
        }
      }

      // Apply positions and states
      const serverNow = Date.now() + clockOffset;
      const elapsed = targetPlaying ? (serverNow - updatedAt) : 0;
      const targetTimeSeconds = (targetPos + elapsed) / 1000;

      if (targetPlaying) {
        if (audio.paused) {
          console.log('📡 SSE: Playing audio');
          await audio.play().catch(e => console.warn('Audio play failed in sync:', e));
        }
        
        const timeDiff = Math.abs(audio.currentTime - targetTimeSeconds);
        if (timeDiff > 1.5 && isFinite(audio.duration)) {
          console.log(`📡 SSE: Seeking from ${audio.currentTime}s to ${targetTimeSeconds}s`);
          audio.currentTime = Math.max(0, targetTimeSeconds);
        }
      } else {
        if (!audio.paused) {
          console.log('📡 SSE: Pausing audio');
          audio.pause();
        }
        const timeDiff = Math.abs(audio.currentTime - targetTimeSeconds);
        if (timeDiff > 0.5) {
          console.log(`📡 SSE: Seeking while paused from ${audio.currentTime}s to ${targetTimeSeconds}s`);
          audio.currentTime = Math.max(0, targetTimeSeconds);
        }
      }
    } catch (err) {
      console.error('Error in performSync:', err);
    } finally {
      setTimeout(() => {
        isSyncingFromServer = false;
      }, 300);
    }
  };

  performSync();
}

function connectRoomSse(roomId) {
  disconnectRoomSse();
  
  console.log(`📡 Opening SSE stream for room: ${roomId}`);
  sseEventSource = new EventSource(`/api/rooms/${roomId}/stream`);
  
  sseEventSource.onmessage = (event) => {
    try {
      const data = JSON.parse(event.data);
      handleRoomSseMessage(data);
    } catch (e) {
      console.error('Failed to parse SSE event message:', e);
    }
  };
  
  sseEventSource.onerror = (err) => {
    console.error('SSE Connection Error:', err);
    if (activeRoomId === roomId) {
      setTimeout(() => {
        if (activeRoomId === roomId) {
          console.log('📡 Reconnecting SSE...');
          connectRoomSse(roomId);
        }
      }, 3000);
    }
  };
}

function disconnectRoomSse() {
  if (sseEventSource) {
    console.log('📡 Closing SSE stream');
    sseEventSource.close();
    sseEventSource = null;
  }
}

function bindRoomSettings() {
  document.querySelector('#btn-room-create')?.addEventListener('click', async () => {
    try {
      const res = await fetch('/api/rooms', { method: 'POST' });
      if (!res.ok) throw new Error('Create room failed');
      const data = await res.json();
      
      activeRoomId = data.roomId;
      localStorage.setItem('sv_room_id', activeRoomId);
      
      showRoomConnectedUI(activeRoomId);
      connectRoomSse(activeRoomId);
      sendRoomStateUpdate();
    } catch (err) {
      alert('Failed to create listening room: ' + err.message);
    }
  });

  document.querySelector('#btn-room-join')?.addEventListener('click', async () => {
    const input = document.querySelector('#room-input-code');
    const code = input.value.trim().toUpperCase();
    if (!code) return alert('Please enter a room code');
    
    try {
      const res = await fetch(`/api/rooms/${code}`);
      if (!res.ok) {
        if (res.status === 404) throw new Error('Room not found. Check code.');
        throw new Error('Join failed');
      }
      const data = await res.json();
      
      activeRoomId = data.roomId;
      localStorage.setItem('sv_room_id', activeRoomId);
      
      showRoomConnectedUI(activeRoomId);
      connectRoomSse(activeRoomId);
      input.value = '';
    } catch (err) {
      alert('Failed to join listening room: ' + err.message);
    }
  });

  document.querySelector('#btn-room-leave')?.addEventListener('click', () => {
    disconnectRoomSse();
    activeRoomId = null;
    localStorage.removeItem('sv_room_id');
    showRoomDisconnectedUI();
  });

  document.querySelector('#btn-room-back')?.addEventListener('click', () => {
    history.back();
  });

  document.querySelector('#room-code-display')?.addEventListener('click', () => {
    const code = document.querySelector('#room-code-display').textContent;
    navigator.clipboard.writeText(code).then(() => {
      alert('📋 Room code copied to clipboard!');
    }).catch(err => {
      console.error('Clipboard copy failed:', err);
    });
  });
}

function showRoomConnectedUI(roomId) {
  document.querySelector('#room-state-disconnected').classList.add('hidden');
  document.querySelector('#room-state-connected').classList.remove('hidden');
  document.querySelector('#room-code-display').textContent = roomId;
}

function showRoomDisconnectedUI() {
  document.querySelector('#room-state-connected').classList.add('hidden');
  document.querySelector('#room-state-disconnected').classList.remove('hidden');
}
