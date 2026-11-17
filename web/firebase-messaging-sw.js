importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCNgDh9f6BpEtMfyyeD6pQjerZAyXiApXI',
  authDomain: 'dekorin-app.firebaseapp.com',
  projectId: 'dekorin-app',
  storageBucket: 'dekorin-app.firebasestorage.app',
  messagingSenderId: '448756050947',
  appId: '1:448756050947:web:b2f810cb1da53624b13236'
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) || 'Dekorin';
  const body = (payload.notification && payload.notification.body) || 'Ada notifikasi baru';
  return self.registration.showNotification(title, {
    body: body,
    icon: '/icons/Icon-192.png',
    data: payload.data || {}
  });
});
