// Firebase Cloud Messaging Service Worker para PWA e Web Push Notifications
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCfahJx22q7Be42eNAOW7xV3hWTLmemWII",
  authDomain: "conecta-hospital.firebaseapp.com",
  projectId: "conecta-hospital",
  storageBucket: "conecta-hospital.firebasestorage.app",
  messagingSenderId: "779815545602",
  appId: "1:779815545602:web:dfb3580daef5888122701b"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Mensagem recebida em segundo plano: ', payload);
  const notificationTitle = payload.notification?.title || payload.data?.title || 'Conecta Saúde - SUS';
  const notificationOptions = {
    body: payload.notification?.body || payload.data?.body || 'Nova mensagem recebida no hospital.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data,
    vibrate: [200, 100, 200],
    tag: payload.data?.conversationId ? 'chat_' + payload.data.conversationId : 'conecta_saude',
    renotify: true
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

self.addEventListener('notificationclick', function(event) {
  event.notification.close();
  var urlToOpen = '/';
  if (event.notification.data && event.notification.data.conversationId) {
    urlToOpen = '/#/chat/' + event.notification.data.conversationId;
  } else if (event.notification.data && event.notification.data.channelId) {
    urlToOpen = '/#/channels/' + event.notification.data.channelId;
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url && 'focus' in client) {
          if (urlToOpen !== '/') {
            client.navigate(urlToOpen);
          }
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(urlToOpen);
      }
    })
  );
});
