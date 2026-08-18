importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyA5pLUtdDV3B3NkmzZ-DbQJY-YIQOlc3xA',
  authDomain: 'ezerfresh-f87af.firebaseapp.com',
  projectId: 'ezerfresh-f87af',
  storageBucket: 'ezerfresh-f87af.firebasestorage.app',
  messagingSenderId: '562553165879',
  appId: '1:562553165879:web:40f7258a3985dafdcdc7b2',
  measurementId: 'G-T69TWKT6KQ',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const title = notification.title || 'Ezer Fresh';
  const options = {
    body: notification.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(title, options);
});

// Clicking a background notification should bring the app to the front
// rather than doing nothing. If a tab is already open we focus it (so the
// user doesn't end up with duplicate tabs of the app); otherwise we open
// one. This mirrors the tap-to-open behaviour the Android build gets from
// FirebaseMessaging.onMessageOpenedApp.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    clients
      .matchAll({ type: 'window', includeUncontrolled: true })
      .then((windowClients) => {
        for (const client of windowClients) {
          if ('focus' in client) {
            return client.focus();
          }
        }
        if (clients.openWindow) {
          return clients.openWindow('/');
        }
      }),
  );
});
