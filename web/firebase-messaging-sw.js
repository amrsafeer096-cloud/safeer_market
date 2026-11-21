/* Firebase Cloud Messaging service worker for Safeer Market (web / PWA).
 *
 * Shows native OS notifications (Windows / macOS action center, Android
 * tray) while the tab is in the background, minimised, or closed, as long as
 * the browser is running and notification permission was granted. The
 * firebase_messaging plugin registers this file automatically when the app
 * asks for a token. Keep the SDK version in step with firebase_core_web
 * (supportedFirebaseJsSdkVersion) and the config with lib/firebase_options.dart.
 */
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.19.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAP9R8tCJiVN7neKLcxPClHPNAXp--sFMA',
  appId: '1:1021134855570:web:d73c7a8cfef71f656a754b',
  messagingSenderId: '1021134855570',
  projectId: 'safeer-market',
  authDomain: 'safeer-market.firebaseapp.com',
  storageBucket: 'safeer-market.firebasestorage.app',
});

const messaging = firebase.messaging();
const ICON = '/icons/Icon-192.png';

function appUrl(route) {
  const path = route && route.startsWith('/') ? route : '/notifications';
  return new URL('/#' + path, self.location.origin).href;
}

// Pushes with a `notification` block (everything send-push sends) are shown
// by the Firebase SDK from their `webpush.notification` options, with sound
// and a click link. Data-only pushes are shown here.
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const data = payload.data || {};
  const urgent = data.type === 'new_order';
  return self.registration.showNotification(data.title || 'سفير ماركت', {
    body: data.body || '',
    icon: ICON,
    badge: ICON,
    image: data.image || undefined,
    tag: data.notification_id || data.order_id || data.type || 'safeer',
    renotify: true,
    requireInteraction: urgent,
    silent: false,
    vibrate: urgent ? [300, 100, 300, 100, 300] : [200],
    dir: 'rtl',
    lang: 'ar',
    data: { url: appUrl(data.route) },
  });
});

// Clicks on notifications shown above: focus an open Safeer Market tab, or
// open one. The SDK handles clicks on its own notifications (FCM_MSG).
self.addEventListener('notificationclick', (event) => {
  const data = event.notification.data || {};
  if (data.FCM_MSG || !data.url) return;
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((tabs) => {
      for (const tab of tabs) {
        if (new URL(tab.url).origin === self.location.origin && 'focus' in tab) {
          return tab.focus();
        }
      }
      return self.clients.openWindow(data.url);
    }),
  );
});
