'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"analytics.js": "4a9142cef9138882a3cb096e6e8ab6e1",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"manifest.json": "173ab279d16d7b7b600e3c7a19c96303",
"index.html": "59b21fb2c6b1424e281516567a11afc3",
"/": "59b21fb2c6b1424e281516567a11afc3",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "9e2a3575d07374a157e05b3a6dd94fa7",
"assets/assets/images/retailers/Aldi_Sued.jpg": "fedecb3d4168510e36c419941839830e",
"assets/assets/images/retailers/marktkauf.png": "f78b1d29d1025422038514210f521645",
"assets/assets/images/retailers/edeka.svg": "0d80b5ebeb5631969404394492d7bf33",
"assets/assets/images/retailers/kaufland.png": "bb4e9aac2cf824b3784c8ae119e303dc",
"assets/assets/images/retailers/edeka.png": "afadc61d43071e9874fa5873a621bf39",
"assets/assets/images/retailers/Scottie.png": "ff2004f525c76dc727a92634dcdbbf61",
"assets/assets/images/retailers/rewe.png": "5af52d7dc6f0a5a50ee993ae9af56c77",
"assets/assets/images/retailers/penny.png": "daa6fc7eec4ad989af4b26cf233014d6",
"assets/assets/images/retailers/globus.png": "ad21e7b5e6e153d44b2cc155e38e7e25",
"assets/assets/images/retailers/aldi.svg": "0c34c939531ed10bee147447a1cc88e3",
"assets/assets/images/retailers/biocompany.png": "e108cc28b2a8f890f64759219180f402",
"assets/assets/images/retailers/netto.png": "7e55f7cedb21dc49354c94ba69800fc3",
"assets/assets/images/retailers/aldi.png": "38873998e54010f73bd1a070257bea7b",
"assets/assets/images/retailers/norma.png": "04f96fde7feee92e474d16ee4d411a4d",
"assets/assets/images/retailers/real.png": "7b0ca8d0c68080e28cc656a2e0a71fd3",
"assets/assets/images/retailers/lidl.png": "f7cfdc2b7a7383465dd913be582577ec",
"assets/assets/images/retailers/nahkauf.png": "2e35a172013635e3e9fc60032b37dc40",
"assets/assets/images/retailers/nahkauf.jpg": "c88ed38c684422057db82e58ac900c07",
"assets/assets/images/retailers/edeka.jpg": "d0c6f0e55e456d102eabdb593afda3d0",
"assets/assets/images/retailers/norma.jpg": "0d79c499a84a759d8f8f34694db2cdc2",
"assets/assets/images/retailers/rewe.svg": "0a661c351a8c497a3a14803f884e6e7a",
"assets/assets/images/products/tomaten.jpg": "620c0698372d308594bb967b0b05f4d4",
"assets/assets/images/products/quark.jpg": "c583176e5f2f531bb392f3f2b7d1ab35",
"assets/assets/images/products/gouda.jpg": "8bc0112b5c61666151a93b4e370b0b80",
"assets/assets/images/products/milchbroetchen.jpg": "d5427b18818150a126e70bf7948d7784",
"assets/assets/images/products/drinks.jpg": "917433b138e2cbb4b5710b649fc67b6f",
"assets/assets/images/products/bio_apfel.jpg": "eaadcea7b27af24b75a6249be0a9b2e5",
"assets/assets/images/products/bio_bananen.jpg": "b940b28afb0740075653594719b2d265",
"assets/assets/images/products/meat.jpg": "3d47c0d6b9c9442c9e40173cfb2bfad4",
"assets/assets/images/products/schnitzel.jpg": "c53e1c4f9060ed8ce1507e3cf673d2c2",
"assets/assets/images/products/vollmilch.jpg": "5519df9d38fc6ff0f029acc7e2f86906",
"assets/assets/images/products/mineralwasser.jpg": "24d6e3a03ffd71b797c1b3eddc0d93a7",
"assets/assets/images/products/croissants.jpg": "f666fa8ffad5b45311b79ede27bea7c2",
"assets/assets/images/products/broetchen.jpg": "93100a6e5bbeb681a7ac5c241daaf45a",
"assets/assets/images/products/haehnchen.jpg": "e08e93345822a49fa08f698572126928",
"assets/assets/images/products/butter.jpg": "02f04aa0a14e1769dcfb76a0a0299da7",
"assets/assets/images/products/gurken.jpg": "2ad54bb9c800c7fd36e35da2723afd3d",
"assets/assets/images/products/cola.jpg": "bbb924f9b28470f050118ef31bfb7c1a",
"assets/assets/images/products/bratwurst.jpg": "134e71f7d382c03006561b38d2e545e9",
"assets/assets/images/products/joghurt.jpg": "74a4cf0d8a23fb72bfe84966ca3129d1",
"assets/assets/images/products/bio_vollmilch.jpg": "aabc3b188d2915e6d88ac9294758e054",
"assets/assets/images/products/apfelsaft.jpg": "534df4fbf199c90ba36eb7266b0aaff6",
"assets/assets/images/products/dairy.jpg": "486e6069978a465aa840ac1bfb9596fe",
"assets/assets/images/products/kartoffeln.jpg": "0466b1aa387fd6a3a1cadae74c174889",
"assets/assets/images/products/bananen.jpg": "4557a5dda60be0d22e564350d2016330",
"assets/assets/images/products/bread.jpg": "9772197baa0f01e081546bbaa26eacb0",
"assets/assets/images/products/vollkornbrot.jpg": "0eeac0f3e70bf349826519e6daa8b39e",
"assets/assets/images/products/rinderhack.jpg": "150e60485ffcec529a884987c232ee37",
"assets/assets/images/products/fruits.jpg": "760403e521f2555ae4d0ab9962b972c8",
"assets/assets/images/products/apfel.jpg": "5172903f9d4431220d05a8bbc76c9541",
"assets/assets/images/product_placeholder.svg": "823d11c15da0b80998598f3622925a34",
"assets/assets/images/logo.svg": "be7451a137bd9fb6e2e559308b774fbe",
"assets/assets/images/map_placeholder.png": "868a264e02da3e7c655b58b9f46b902f",
"assets/fonts/MaterialIcons-Regular.otf": "876341733b6c07b5cede271ec17fb6e8",
"assets/NOTICES": "ac86604a7e650213a7130a7cd9595e0a",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/flutter_map/lib/assets/flutter_map_logo.png": "208d63cc917af9713fc9572bd5c09362",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin": "e688acd0e902069a2aa3e196f7c22779",
"assets/AssetManifest.json": "af0c2cb5859b4cd1d6baaa23c2a6d25f",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"robots.txt": "89dcb0b245e44b354bec3ee8fdb8d158",
"CNAME": "b13d7d0b24b8cb91deb73f97170cf017",
"sitemap.xml": "f0a32cb91cc21adfa3c916ae665efcf4",
"flutter_bootstrap.js": "bc9c8af99fce5fab6dcbccfb2dabe2e1",
"version.json": "44ebcf554db5384995ec8e487a1d1359",
"main.dart.js": "479fd7c054e6348f046582950a62b130"};
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
