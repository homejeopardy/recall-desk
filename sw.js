/* Quizletish offline support.
   Deliberately conservative, because a service worker that serves stale files is very
   hard for a student to get out of:
   - the page and decks.json are fetched from the network first, so an edit you publish
     is never hidden behind a cache; the cache is only the fallback when the network
     fails or the chromebook is off the wifi.
   - fonts are cache-first, since they never change and are the slow part.
   - nothing else is touched: the GitHub and Supabase APIs always go to the network,
     and a failed call stays a failed call rather than becoming a stale success. */
var VERSION = 'quizletish-v1';
var SHELL = ['./', './index.html', './decks.json'];

self.addEventListener('install', function (e) {
  e.waitUntil(caches.open(VERSION).then(function (c) {
    return c.addAll(SHELL).catch(function () { /* a miss here must not block install */ });
  }).then(function () { return self.skipWaiting(); }));
});

self.addEventListener('activate', function (e) {
  e.waitUntil(caches.keys().then(function (keys) {
    return Promise.all(keys.filter(function (k) { return k !== VERSION; })
                           .map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});

/* Lets the page tell a stuck worker to stand down. */
self.addEventListener('message', function (e) {
  if (e.data === 'unregister') {
    self.registration.unregister().then(function () {
      return caches.keys().then(function (keys) {
        return Promise.all(keys.map(function (k) { return caches.delete(k); }));
      });
    });
  }
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;

  var url;
  try { url = new URL(req.url); } catch (err) { return; }

  // Anything live stays live: never cache the APIs.
  if (url.hostname.indexOf('supabase') > -1 || url.hostname.indexOf('github') > -1) return;

  var sameSite = url.origin === self.location.origin;
  var isFont = url.hostname.indexOf('fonts.googleapis.com') > -1 || url.hostname.indexOf('fonts.gstatic.com') > -1;

  if (isFont) {
    e.respondWith(caches.match(req).then(function (hit) {
      return hit || fetch(req).then(function (res) {
        var copy = res.clone();
        caches.open(VERSION).then(function (c) { c.put(req, copy); });
        return res;
      });
    }));
    return;
  }

  if (!sameSite) return;

  // Network first, cache as the safety net.
  e.respondWith(
    fetch(req).then(function (res) {
      if (res && res.ok) {
        var copy = res.clone();
        caches.open(VERSION).then(function (c) { c.put(req, copy); });
      }
      return res;
    }).catch(function () {
      return caches.match(req).then(function (hit) {
        return hit || caches.match('./index.html');
      });
    })
  );
});
