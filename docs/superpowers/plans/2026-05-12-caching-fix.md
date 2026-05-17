# Caching Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Resolve mobile caching issues by bumping service worker version, improving fetch strategy, and adding version query parameters to static assets.

**Architecture:** Overwrite `sw.js` with `v2` cache and Stale-While-Revalidate strategy. Update `index.html` to append `?v=2` to script and link tags.

**Tech Stack:** JavaScript (Service Worker), HTML.

---

### Task 1: Update Service Worker

**Files:**
- Modify: `backend/public/sw.js` (Overwrite)

- [ ] **Step 1: Overwrite `sw.js` content**

Overwrite `backend/public/sw.js` with the provided `v2` content.

```javascript
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
```

### Task 2: Update Index HTML for Cache Busting

**Files:**
- Modify: `backend/public/index.html`

- [ ] **Step 1: Update `styles.css` link**

Change `<link rel="stylesheet" href="/styles.css">` to `<link rel="stylesheet" href="/styles.css?v=2">`.

- [ ] **Step 2: Update `app.js` script tag**

Change `<script src="/app.js"></script>` to `<script src="/app.js?v=2"></script>`.

### Task 3: Verification

- [ ] **Step 1: Verify `sw.js` content**

Run: `cat backend/public/sw.js`
Expected: `CACHE_NAME = 'sonic-vault-v2'` and the new fetch strategy.

- [ ] **Step 2: Verify `index.html` content**

Run: `grep -E "styles.css\?v=2|app.js\?v=2" backend/public/index.html`
Expected: Matches for both with `?v=2`.
