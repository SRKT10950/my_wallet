// PWA Service Worker & Push Notification Manager for My Wallet

(function() {
  let isRefreshing = false;

  window.myWalletPwa = {
    swRegistration: null,
    updateAvailable: false,
    onUpdateCallback: null,

    init: function() {
      // Service workers are only supported over HTTP/HTTPS origins, not file://
      if ('serviceWorker' in navigator && window.location.protocol.startsWith('http')) {
        window.addEventListener('load', () => {
          this.registerServiceWorker();
        });

        // Safely listen for controller changes without infinite loops
        navigator.serviceWorker.addEventListener('controllerchange', () => {
          if (isRefreshing) return;
          isRefreshing = true;
          console.log('[PWA Manager] Service worker controller changed cleanly.');
        });
      }
    },

    registerServiceWorker: function() {
      if (!window.location.protocol.startsWith('http')) return;

      const swUrl = 'sw_custom.js';
      
      navigator.serviceWorker.register(swUrl, { updateViaCache: 'none' })
        .then((registration) => {
          this.swRegistration = registration;
          console.log('[PWA Manager] ServiceWorker registered with scope:', registration.scope);

          // Check if there is already a waiting SW
          if (registration.waiting) {
            this.handleUpdateWaiting(registration.waiting);
          }

          // Listen for new SW updates found
          registration.onupdatefound = () => {
            const installingWorker = registration.installing;
            if (installingWorker) {
              installingWorker.onstatechange = () => {
                if (installingWorker.state === 'installed' && navigator.serviceWorker.controller) {
                  console.log('[PWA Manager] New content is available; update pending.');
                  this.handleUpdateWaiting(installingWorker);
                }
              };
            }
          };
        })
        .catch((err) => {
          console.warn('[PWA Manager] Service Worker registration skipped/failed:', err);
        });
    },

    handleUpdateWaiting: function(worker) {
      this.updateAvailable = true;
      if (typeof this.onUpdateCallback === 'function') {
        this.onUpdateCallback();
      }
    },

    checkForUpdates: function() {
      if (this.swRegistration && window.location.protocol.startsWith('http')) {
        console.log('[PWA Manager] Checking for Service Worker updates...');
        return this.swRegistration.update()
          .then(() => {
            if (this.updateAvailable) {
              return { status: 'UPDATE_FOUND' };
            }
            return { status: 'LATEST' };
          })
          .catch(err => {
            console.error('[PWA Manager] Update check failed:', err);
            return { status: 'ERROR', error: err.toString() };
          });
      }
      return Promise.resolve({ status: 'NO_SW' });
    },

    applyUpdate: function() {
      if (this.swRegistration && this.swRegistration.waiting) {
        console.log('[PWA Manager] Sending SKIP_WAITING to waiting Service Worker...');
        this.swRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });
      }
      this.forcePurgeAndReload();
    },

    forcePurgeAndReload: function() {
      console.log('[PWA Manager] Purging all caches and force reloading...');
      if ('caches' in window) {
        caches.keys().then((keys) => {
          return Promise.all(keys.map(key => caches.delete(key)));
        }).then(() => {
          window.location.reload();
        }).catch(() => {
          window.location.reload();
        });
      } else {
        window.location.reload();
      }
    },

    requestNotificationPermission: function() {
      if (!('Notification' in window)) {
        return Promise.resolve('UNSUPPORTED');
      }
      return Notification.requestPermission();
    },

    sendTestNotification: function() {
      if (!('Notification' in window)) {
        alert('Push notifications are not supported on this browser/device.');
        return Promise.resolve(false);
      }

      if (Notification.permission === 'granted') {
        if (this.swRegistration) {
          this.swRegistration.showNotification('My Wallet Alert ⚡', {
            body: 'Web Push Notifications are active! Offline & fast sync ready.',
            icon: 'icons/Icon-192.png',
            badge: 'icons/Icon-192.png',
            vibrate: [100, 50, 100],
            tag: 'my-wallet-test'
          });
          return Promise.resolve(true);
        } else {
          new Notification('My Wallet Alert ⚡', {
            body: 'Web Push Notifications are active! Offline & fast sync ready.',
            icon: 'icons/Icon-192.png'
          });
          return Promise.resolve(true);
        }
      } else {
        return this.requestNotificationPermission().then(permission => {
          if (permission === 'granted') {
            return this.sendTestNotification();
          } else {
            alert('Notification permission denied. Please allow notifications in browser settings.');
            return false;
          }
        });
      }
    },

    isStandalone: function() {
      return (window.matchMedia('(display-mode: standalone)').matches) || 
             (window.navigator.standalone === true) || 
             (document.referrer.includes('android-app://'));
    }
  };

  window.myWalletPwa.init();
})();
