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

// Instalação imediata do Service Worker
self.addEventListener('install', function(event) {
  console.log('[firebase-messaging-sw.js] Instalando Service Worker...');
  self.skipWaiting();
});

// Ativação e controle imediato sobre todas as abas e janelas
self.addEventListener('activate', function(event) {
  console.log('[firebase-messaging-sw.js] Ativando Service Worker e reivindicando controle...');
  event.waitUntil(self.clients.claim());
});

// Recepção de mensagens em background via Firebase SDK
messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Mensagem recebida em segundo plano (FCM): ', payload);

  var notificationTitle = payload.notification?.title || payload.data?.title || 'Conecta Saúde - SUS';
  var body = payload.notification?.body || payload.data?.body || 'Nova mensagem recebida no hospital.';
  var conversationId = payload.data?.conversationId;
  var channelId = payload.data?.channelId;

  var notificationOptions = {
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: {
      url: conversationId
        ? '/chat/' + conversationId
        : channelId
          ? '/channels/' + channelId
          : '/conversations',
      conversationId: conversationId,
      channelId: channelId,
    },
    vibrate: [200, 100, 200],
    tag: conversationId ? 'chat_' + conversationId : channelId ? 'channel_' + channelId : 'conecta_saude',
    renotify: true,
    requireInteraction: false,
  };

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Manipulador de clique na notificação do sistema operacional
self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  var targetUrl = 'https://conecta-hospital.web.app/conversations';
  if (event.notification.data) {
    var d = event.notification.data;
    if (d.url) {
      targetUrl = 'https://conecta-hospital.web.app' + d.url;
    } else if (d.conversationId) {
      targetUrl = 'https://conecta-hospital.web.app/chat/' + d.conversationId;
    } else if (d.channelId) {
      targetUrl = 'https://conecta-hospital.web.app/channels/' + d.channelId;
    }
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      for (var i = 0; i < clientList.length; i++) {
        var client = clientList[i];
        if (client.url.startsWith('https://conecta-hospital.web.app') && 'focus' in client) {
          client.navigate(targetUrl);
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(targetUrl);
      }
    })
  );
});
