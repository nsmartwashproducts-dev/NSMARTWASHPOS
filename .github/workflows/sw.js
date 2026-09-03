// Smart-Wash POS — service worker
// Caches the app shell so it installs as a real app and keeps working offline.
// (Business data itself is handled by the app's own local storage / Supabase sync,
// this only caches the files needed to load the app.)

const CACHE_NAME = 'smart-wash-pos-v1';
const APP_SHELL = [
  './',
  './index.html',
  './manifest.json',
  './logo.png',
  './icons/icon-192.png',
  './icons/icon-512.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const req = event.request;

  // Always go to network for cross-origin requests (fonts, Chart.js, Supabase, etc.)
  // so live sync and CDN assets keep working; fall back to cache if offline.
  event.respondWith(
    fetch(req)
      .then((res) => {
        // Cache a copy of same-origin GET requests as we go.
        if (req.method === 'GET' && new URL(req.url).origin === self.location.origin) {
          const resClone = res.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(req, resClone));
        }
        return res;
      })
      .catch(() => caches.match(req).then((cached) => cached || caches.match('./index.html')))
  );
});
