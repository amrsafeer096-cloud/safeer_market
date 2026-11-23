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

function routeFromType(type) {
  switch ((type || '').toLowerCase()) {
    case 'order':
      return '/orders';
    case 'magazine':
      return '/magazines';
    case 'offers':
    case 'promo':
      return '/offers';
    case 'loyalty':
      return '/rewards';
    case 'chat':
    case 'support':
    case 'support_chat':
      return '/support/chat';
    case 'new_order':
      return '/driver';
    default:
      return '/notifications';
  }
}

function resolveRoute(data) {
  const d = data || {};
  const action = (d.action || '').toString();
  const stage = (d.stage || '').toString();
  const orderId = (d.order_id || '').toString().trim();
  if (action === 'rate_order' && orderId) {
    return '/orders/' + orderId + '/rate';
  }
  if (
    orderId &&
    (stage === 'out_for_delivery' || stage === 'arriving_soon')
  ) {
    return '/orders/' + orderId + '/track';
  }
  const type = (d.type || '').toString().toLowerCase();
  // Customer types: follow type. Staff new_order keeps role-specific route.
  if (
    type === 'order' ||
    type === 'magazine' ||
    type === 'offers' ||
    type === 'promo' ||
    type === 'loyalty' ||
    type === 'chat' ||
    type === 'support' ||
    type === 'support_chat'
  ) {
    return routeFromType(type);
  }
  const explicit = (d.route || '').toString().trim();
  if (explicit.startsWith('/')) return explicit;
  return routeFromType(type);
}

function appUrl(route) {
  const path = route && route.startsWith('/') ? route : '/notifications';
  return new URL('/#' + path, self.location.origin).href;
}

function payloadData(notificationData) {
  const raw = notificationData || {};
  // Firebase SDK wraps its own notifications under FCM_MSG.
  if (raw.FCM_MSG) {
    const msg = raw.FCM_MSG;
    return Object.assign({}, (msg.data || {}), {
      title: (msg.notification && msg.notification.title) || undefined,
      body: (msg.notification && msg.notification.body) || undefined,
    });
  }
  return raw;
}

function openOrFocus(url) {
  return self.clients
    .matchAll({ type: 'window', includeUncontrolled: true })
    .then((tabs) => {
      for (const tab of tabs) {
        if (new URL(tab.url).origin === self.location.origin && 'focus' in tab) {
          return tab.focus().then((client) => {
            if (client && 'navigate' in client) {
              return client.navigate(url);
            }
            return self.clients.openWindow(url);
          });
        }
      }
      return self.clients.openWindow(url);
    });
}

// Pushes with a `notification` block (everything send-push sends) are shown
// by the Firebase SDK from their `webpush.notification` options, with sound
// and a click link. Data-only pushes are shown here.
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const data = payload.data || {};
  const urgent = data.type === 'new_order';
  const route = resolveRoute(data);
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
    data: { url: appUrl(route), ...data },
  });
});

// Clicks on data-only notifications above and on FCM_MSG trays from the SDK.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const raw = event.notification.data || {};
  let url = raw.url;
  if (!url || raw.FCM_MSG) {
    url = appUrl(resolveRoute(payloadData(raw)));
  }
  event.waitUntil(openOrFocus(url));
});
