const CACHE_NAME = 'sonic-vault-v2';
const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/styles.css',
  '/app.js',
  '/manifest.json',
  'https://fonts.googleapis.com/css2?family=Montserrat:wght@500;600;700;800&family=Hanken+Grotesk:wght@300;400;500;600;700&display=swap',
  'https://fonts.googleapis.com/icon?family=Material+Symbols+Rounded'
];

// Install — cache static assets
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(STATIC_ASSETS))
  );
  self.skipWaiting();
});

// Activate — clean up old caches
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch strategy:
// 1. Audio/SSE -> Bypass cache (Network Only)
// 2. API -> Network First, Fallback to Cache
// 3. Static -> Stale-While-Revalidate (Fast & Updates in background)

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  // 1. Audio streams or SSE (Network Only)
  if (url.pathname.startsWith('/api/stream') || url.pathname.startsWith('/api/download-all')) {
    return;
  }

  // 2. API calls (Network First)
  if (url.pathname.startsWith('/api/')) {
    event.respondWith(
      fetch(event.request).catch(() => caches.match(event.request))
    );
    return;
  }

  // 3. Static Assets (Stale-While-Revalidate)
  event.respondWith(
    caches.open(CACHE_NAME).then(cache => {
      return cache.match(event.request).then(cachedResponse => {
        const fetchPromise = fetch(event.request).then(networkResponse => {
          cache.put(event.request, networkResponse.clone());
          return networkResponse;
        });
        return cachedResponse || fetchPromise;
      });
    })
  );
});
