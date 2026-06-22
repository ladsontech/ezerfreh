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
