const CACHE_NAME = 'my-wallet-v1.0.2';
const STATIC_ASSETS = [
  './',
  './index.html',
  './manifest.json',
  './favicon.png',
  './apple-touch-icon.png',
  './apple-touch-icon-precomposed.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './pwa_manager.js',
  './flutter_bootstrap.js',
  './flutter.js',
  './main.dart.js'
];

// Install Event: Pre-cache Core App Shell for instant cold launches
self.addEventListener('install', (event) => {
  console.log('[ServiceWorker] Installing SW version:', CACHE_NAME);
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ServiceWorker] Caching static app shell & engine assets...');
      return cache.addAll(STATIC_ASSETS).catch(err => {
        console.warn('[ServiceWorker] Static asset pre-caching warning:', err);
      });
    })
  );
});

// Activate Event: Delete Stale Cache Keys & Claim Clients Immediately
self.addEventListener('activate', (event) => {
  console.log('[ServiceWorker] Activating SW version:', CACHE_NAME);
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            console.log('[ServiceWorker] Clearing old cache:', cacheName);
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch Event: Stale-While-Revalidate for Instant ~50ms Startup on iOS PWA
self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') return;
  const url = new URL(event.request.url);

  // Ignore unsupported schemes (chrome-extension, etc)
  if (url.protocol !== 'http:' && url.protocol !== 'https:') return;

  event.respondWith(
    caches.match(event.request).then((cachedResponse) => {
      // Background revalidation
      const fetchPromise = fetch(event.request)
        .then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200) {
            const responseToCache = networkResponse.clone();
            caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, responseToCache);
            });
          }
          return networkResponse;
        })
        .catch(() => {
          // Offline fallback
        });

      // Serve from cache IMMEDIATELY if available for 0ms network latency launch
      return cachedResponse || fetchPromise || caches.match('./index.html');
    })
  );
});

// Message Listener for explicit user-triggered updates
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[ServiceWorker] Message SKIP_WAITING received.');
    self.skipWaiting();
  }
});

// Push Notifications
self.addEventListener('push', (event) => {
  let title = 'My Wallet Alert';
  let options = {
    body: 'You have an update or notification from My Wallet.',
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    vibrate: [100, 50, 100]
  };

  if (event.data) {
    try {
      const data = event.data.json();
      title = data.title || title;
      options.body = data.body || options.body;
      if (data.icon) options.icon = data.icon;
    } catch (e) {
      options.body = event.data.text();
    }
  }

  event.waitUntil(
    self.registration.showNotification(title, options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      if (clientList.length > 0) {
        let client = clientList[0];
        for (let i = 0; i < clientList.length; i++) {
          if (clientList[i].focused) {
            client = clientList[i];
            break;
          }
        }
        return client.focus();
      }
      return clients.openWindow('./');
    })
  );
});
