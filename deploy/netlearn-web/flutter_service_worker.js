'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "5668aec18c9709791f7db3f7910175f7",
"version.json": "bf3d9ea4b247238fc4bb47b78f0fa239",
"index.html": "baed054aeb4d9093ccff7b41293aa890",
"/": "baed054aeb4d9093ccff7b41293aa890",
"main.dart.js": "c05bede9b380682109a7f7722a8cab0a",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "21980edc3dea6697d08b3a983da5ed90",
"assets/AssetManifest.json": "d4723dc355008a746ee0d25bfa2ab3fc",
"assets/NOTICES": "6d8baf846fb514fbd9e448127aeb34ff",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "21fdae78b121493f18496bbea9b0fe1d",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/youtube_player_iframe/assets/player.html": "663ba81294a9f52b1afe96815bb6ecf9",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "ea58fa27cd4bc886d706f7ff6463ecdc",
"assets/fonts/MaterialIcons-Regular.otf": "7a74477581ad3b656f14439a06c08b50",
"assets/assets/images/materi_4_1.png": "32c3df2658c553180613a5c1e49eb836",
"assets/assets/images/materi_4_3.png": "d668f0783b88450cdac70c587227f144",
"assets/assets/images/materi_2_5.png": "21595576f5b6aacfc0cdab3bff7f57d0",
"assets/assets/images/materi_2_4.png": "42147ea03ef4ca299dfad47addd9aee7",
"assets/assets/images/materi_4_2.png": "17d358b03b5154a7943227d2eefed9eb",
"assets/assets/images/materi_2_1.png": "a1da98367336c82a26304fb6e3389d69",
"assets/assets/images/materi_2_3.png": "20601f433f8aef356bbc4f9b0051d615",
"assets/assets/images/materi_2_2.png": "965fd260052f8b857a744dd3fe2e0cd0",
"assets/assets/images/materi_5_2.png": "ea793724070322ef780f3cd02ac24bf0",
"assets/assets/images/materi_1_4.png": "556e7d7889a9e0b8081d1be3b61c505a",
"assets/assets/images/materi_5_1.png": "2f5626058cdecaf16c94b275fe1c6c1e",
"assets/assets/images/material_placeholder.png": "2cc018c924d87674e7af112ea54cf8d9",
"assets/assets/images/materi_1_1.png": "e9419cfb373ab773f4128db0eccb2c83",
"assets/assets/images/materi_3_3.png": "becf5de14f498f7ecb0ddaaeec1dbd22",
"assets/assets/images/materi_3_2.png": "c1d46c25277ed8e6fb0cba080b717d7a",
"assets/assets/images/materi_1_2.png": "e259657efd8919782f6525ffba3b562f",
"assets/assets/images/materi_3_1.png": "c7a852d305ce449cb10b2263f172f249",
"assets/assets/images/materi_1_3.png": "4ef9136d89d36027160bf07f29e59c07",
"assets/assets/images/logo.png": "aff0cb87aab96718ff27d878b4a54476",
"assets/assets/audio/incorrect.mp3": "5a9e0c29e4c1f1241fb0376860b03547",
"assets/assets/audio/win.mp3": "39a2ed2eb9786701f7749f672b89714e",
"assets/assets/audio/beep.mp3": "2bcaae6b637cce40408f6c8d21acb8a8",
"assets/assets/audio/lose.mp3": "730ccb7ad43e553bdef73aa911d37cb5",
"assets/assets/audio/correct.mp3": "36aa9b78b425171fee4f6d933e71b3c8",
"assets/assets/audio/retro.mp3": "c898044d6821c3748b3f16561005e7e3",
"assets/assets/lottie/win.json": "0c4954f0b9e3d0e3b8ad51211d88668f",
"assets/assets/lottie/lose.json": "42e757543d0dae25cee43ea05038a6e9",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
