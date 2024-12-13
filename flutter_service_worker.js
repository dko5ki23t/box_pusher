'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "7d69e653079438abfbb24b82a655b0a4",
"main.dart.js": "924c53a6cf6eb05866a938b6972ca438",
"assets/FontManifest.json": "69777db7f0de4127623721230e9b6960",
"assets/AssetManifest.bin": "11cc77ac8a57f49018032f2cb339acee",
"assets/fonts/MaterialIcons-Regular.otf": "32fce58e2acb9c420eab0fe7b828b761",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Light.ttf": "b248483f59d25fca6fb75ba8196f7037",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Thin.ttf": "9b3a9c37f57376f4572cc30aa6506367",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Medium.ttf": "7aa0d1123977dab52b1e01f61f0a9a7f",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Black.ttf": "c7cf13f6288ece850a978a0cfa764cd4",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Bold.ttf": "1bdb5bf9e923e1bc6418342bcf6fb3e0",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf": "dd4fa7df965b4d3227bf42b9a77da3e0",
"assets/assets/images/swordsman_U_attack4.png": "01fd0e3778f231696dbedbfec4aa197f",
"assets/assets/images/builders_block.png": "837c867769f811dcec0fa92427d59b3b",
"assets/assets/images/swordsman_attackL3.png": "c3522bd9f2d8553824882622bbdc9384",
"assets/assets/images/belt.png": "b5207d642d1ded96638856edb02b24bb",
"assets/assets/images/armer_ability.png": "c3d913e1a384a07512f632c6c662f0f0",
"assets/assets/images/swordsman_attack5.png": "8b04918411ce9d8cab463170a4224f2e",
"assets/assets/images/swordsman_attackL2.png": "b1f60a4ba2c0431579c504e0c161c57d",
"assets/assets/images/guardian_U_attack4.png": "c53622bea643770fe433fbe92442e4f7",
"assets/assets/images/guardian_U_attack3.png": "12cc5ce1e3bb0ff129dc0db16def477b",
"assets/assets/images/drill.png": "e10f4c74f102e3981eedfa77408c764f",
"assets/assets/images/swordsman_L_attack5.png": "8df1f42959d783a241a1f08e70ff4d49",
"assets/assets/images/settings.png": "9a6a05bdfdae4f3d09df495c410e6a46",
"assets/assets/images/jewels.png": "de6b9e4f86da8e3d8fdf4ae8d949c657",
"assets/assets/images/swordsman_attack_round2.png": "bc252c7283630581aeff7e7e08993069",
"assets/assets/images/magic.png": "2f0c6966693968a1577f9efe211abe50",
"assets/assets/images/jewel2.png": "136f852056bfaa262f7f528818390f17",
"assets/assets/images/wizard_attack2.png": "3c6730f8cbd22615eed0c7b04ea9af3b",
"assets/assets/images/swordsman_L_attack4.png": "6bc4b44395daa6ebbae2cc71e5fc0f30",
"assets/assets/images/swordsman_attackU3.png": "9c3d4d5b4c673b25da8ef8adf2029f1d",
"assets/assets/images/swordsman.png": "60f57708de256976b9649da7898cccf6",
"assets/assets/images/jewel.png": "455adcd6c24d9bd981fe3a65902f2fb9",
"assets/assets/images/guardian_attackR1.png": "74337221ed2497852bc1da63575ecdbe",
"assets/assets/images/guardian_attack3.png": "7fc3cf1e8bd89f58bc9c4c36c5bff5a8",
"assets/assets/images/magma.png": "17c4fbf9c839a7bd6070dfe4b5495810",
"assets/assets/images/wizard.png": "24dfa9a6c0f5f5fa018457d75a39debe",
"assets/assets/images/stage_alpha.png": "92873e031c18c7b37d0899459556b331",
"assets/assets/images/guardian_attackR2.png": "0fe306164a190f5ff4356a26f0cf42f0",
"assets/assets/images/rabbit.png": "6f7f3cf57185650d43bae9fa4ade4eeb",
"assets/assets/images/swordsman_U_attack3.png": "a255c8211af48559d987cbd6f5786aae",
"assets/assets/images/guardian_attack1.png": "0bcca2a7fd7222f7025990665dcf81bf",
"assets/assets/images/swordsman_attackR3.png": "840a44a644cb704bfd36c2e0174fa7b2",
"assets/assets/images/tmp.png": "3082ad4f7d0c6191ffe9e8f76623140b",
"assets/assets/images/swordsman_R_attack3.png": "3d18ec53ecee8c5c65ef1277d48dcde9",
"assets/assets/images/guardian_attackL3.png": "642406de2b3db92db389f545ffe877db",
"assets/assets/images/guardian_U_attack1.png": "1144b8a35855e41d1a973b298d4440af",
"assets/assets/images/guardian_attackR3.png": "3389bc3fef105796abbb1257db7437d3",
"assets/assets/images/guardian_R_attack1.png": "740f2fc67ddfbdb4d0d0e4a3e858b2aa",
"assets/assets/images/warp.png": "ffc9f6d040fe30197ed7da0ce947b377",
"assets/assets/images/pusher.png": "2502a988da2cb72d2016b13c369cc17e",
"assets/assets/images/undo.png": "20294b58a78e7b6cce0ed58778c48719",
"assets/assets/images/swordsman_R_attack4.png": "7c79878387980b892be6475c2491b1c9",
"assets/assets/images/guardian.png": "2f98fbae07d25f9ecf265418dba1127f",
"assets/assets/images/swordsman_U_attack2.png": "7261c19349730491459b8d79ea8cdd9e",
"assets/assets/images/floor.png": "26df1dc90700eb34252e6e2222cf3c28",
"assets/assets/images/swordsman_attackD3.png": "53bee5718e4de89e46202ce2b60a6295",
"assets/assets/images/hand_ability.png": "ff9fcdb11617ef259302f1a749a24047",
"assets/assets/images/block.png": "0533b28a9780553e9803f2bc3a1bab06",
"assets/assets/images/guardian_attackU3.png": "20c725d08d802c0889c431baa380badf",
"assets/assets/images/swordsman_R_attack1.png": "24125ec430034c0522ff92f4734a53a2",
"assets/assets/images/guardian_attackL2.png": "b88fb5db1ebb01dd572f1166a3641a0f",
"assets/assets/images/guardian_U_attack5.png": "5f04c656506c74316953479149def79c",
"assets/assets/images/builder.png": "12a545571d2d284d0061873dfaf51d28",
"assets/assets/images/tmp2.png": "b4cd063ee1c46b2df06968bf0098fc82",
"assets/assets/images/swordsman_attack_round3.png": "537e55d46505755ae58b2356d0ec3ce8",
"assets/assets/images/swordsman_attack2.png": "a7c6ed7f5dbe82be964d3a574fa0a06e",
"assets/assets/images/merge_effect.png": "39d20c245052407912c3fd711c51bd3b",
"assets/assets/images/noimage.png": "c954b20728e559629a3031967fbc743c",
"assets/assets/images/wizard_attack3.png": "837c65fadc659511af4e97b6bd849275",
"assets/assets/images/bomb.png": "d1d857760cbc27a086dbd9d3236e5e08",
"assets/assets/images/swordsman_attackL1.png": "b5b73627773bb9ecc377df068fa16863",
"assets/assets/images/swordsman_attackU2.png": "a89d841270e1c3fc6c3929c927db54f2",
"assets/assets/images/guardian_L_attack4.png": "1cd64d33ba75086eb8b7fbf0d62cfff0",
"assets/assets/images/jewels_ai.png": "8a7a23d385c7a1ec8d248ca499132c18",
"assets/assets/images/swordsman_L_attack2.png": "dc0ae7e964b2a7ebb069dcd982935304",
"assets/assets/images/guardian_L_attack5.png": "425f4561a53af1f5d2990427d1a4bb35",
"assets/assets/images/guardian_attack2.png": "0cb387731be4b0fbf6502c8ee5449ffc",
"assets/assets/images/swordsman_R_attack5.png": "59dca7bb11c864d6385d90f6450032f8",
"assets/assets/images/guardian_attackL1.png": "de157609e31952d6c06f6e8c630d43b9",
"assets/assets/images/swordsman_attack1.png": "2615e32c9c0579f49a11e6aa1dfeee65",
"assets/assets/images/swordsman_U_attack5.png": "b4568c49d6cd25316f4e5ba112683acc",
"assets/assets/images/archer_attack3.png": "8841a8c523dc5d9dc4a1610333236799",
"assets/assets/images/block2.png": "2e6d79e8aaaa1c3ff6f1953a9f899ca7",
"assets/assets/images/wizard_attack1.png": "9d77742c96e004992d8fc6518cea802f",
"assets/assets/images/guardian_attackD2.png": "a89eac966719543fc22f16db1c903cf4",
"assets/assets/images/guardian_R_attack4.png": "d82fd821502876b5e7ce5fd333c81f29",
"assets/assets/images/guardian_L_attack3.png": "13c588a7b3f90e423598ea8efe04fbdd",
"assets/assets/images/leg_ability.png": "8553556729f5abfeba32e7a6a2bada9b",
"assets/assets/images/trap.png": "f381186d8b5dadb877ad714663c67b63",
"assets/assets/images/swordsman_attackD2.png": "4445b3451da81b1c90ab75fdf41c83ec",
"assets/assets/images/swordsman_U_attack1.png": "cc63aa52436dd4784d3127d4f85ff232",
"assets/assets/images/guardian_L_attack1.png": "6027b61a57b2953c592da41c61b935cd",
"assets/assets/images/swordsman_L_attack1.png": "2129a3d59e333711856fe5c6a51c1936",
"assets/assets/images/guardian_attackD3.png": "1f5cc472c517fa678bf226fe5af0c13a",
"assets/assets/images/archer_attack2.png": "1241632989ae53ee9f331399241aba5b",
"assets/assets/images/guardian_attackU2.png": "03eff39e5f87407a860f73cb6d7b502a",
"assets/assets/images/guardian_U_attack2.png": "a25f143810e19f4fd67555d049cc3c8a",
"assets/assets/images/ghost.png": "440d6d84ddcc7d5f48e20dcdbc7fafd2",
"assets/assets/images/arch.png": "aa27af303202c7b122e499915f962ec0",
"assets/assets/images/swordsman_attack3.png": "6056744df5fc094fad5ec3f23dd9717a",
"assets/assets/images/water.png": "bb594830475a5e86249f325eae4c033a",
"assets/assets/images/swordsman_attackD1.png": "b486bd09953519febb7aedfd69827dca",
"assets/assets/images/swordsman_R_attack2.png": "854260326c39bdd0abec7edb51b4936c",
"assets/assets/images/archer_attack1.png": "3f8476bd36bf6872c2bfce16102d1cf1",
"assets/assets/images/swordsman_L_attack3.png": "ce0b035a5e38a3007e53adb1d8c9008b",
"assets/assets/images/swordsman_attackR1.png": "999a39827954bada74fd8c83ef43c56b",
"assets/assets/images/guardian_attack5.png": "b6854efd80ca1ad56a7e53c04c61d6f5",
"assets/assets/images/swordsman_attackR2.png": "4d20f43efd77f8734c4e042717e3aa94",
"assets/assets/images/spike.png": "eb0c7cee28440f23acd7e3d16f7f221c",
"assets/assets/images/guardian_R_attack3.png": "ab96c68c37858269ca0a3c9ea7cc6811",
"assets/assets/images/archer.png": "6c7a3cbfcb25b0bdd609fbd2070125b9",
"assets/assets/images/pocket_ability.png": "941ff5519f207ad3b96df3f7b873f99c",
"assets/assets/images/kangaroo.png": "876a04231ab2c312fa15fdcb8ee00afc",
"assets/assets/images/gorilla.png": "d90db0779822408029b7127002c3045f",
"assets/assets/images/swordsman_attack_round1.png": "85d995129d363c576a844771bcf89190",
"assets/assets/images/swordsman_attack4.png": "6b3269479e1f27d7b4a424f36246a1e0",
"assets/assets/images/coin.png": "64c7e3a2cfb44868b7afba7719a45ea6",
"assets/assets/images/guardian_attack4.png": "538f044f0d051102f8ea3a9daef279ec",
"assets/assets/images/swordsman_attackU1.png": "7ce0d5bff139460ecf96482b7184f49e",
"assets/assets/images/guardian_attackU1.png": "4b7d3316304777ce3f4488fbb56eb667",
"assets/assets/images/guardian_R_attack2.png": "f84f011cbc8fd07dfc2bd87db18afdbc",
"assets/assets/images/arrow.png": "2dc3e22571ede47c33fd9ba8e07d3d00",
"assets/assets/images/player_controll_arrow.png": "27ce947b07c9527000132131fec7ea4f",
"assets/assets/images/guardian_attackD1.png": "e987e350735cba655c39d842958abd4c",
"assets/assets/images/guardian_L_attack2.png": "d22894f1fce6b9029e5f2dfb15db6af7",
"assets/assets/images/treasure_box.png": "4c0278f057471d88dc68db90bfeae251",
"assets/assets/images/guardian_R_attack5.png": "b757e97073cd2ccc1b5cef2374770e58",
"assets/assets/images/turtle.png": "be6f55b1a8b7cadd402bd11c126f04db",
"assets/assets/images/player.png": "6f06157e387d41583ce9607dbf1d15a0",
"assets/assets/audio/explode.mp3": "bd841c971ffb28d430689355f9392ef3",
"assets/assets/audio/maou_bgm_8bit29.mp3": "ec4a718b7755dd003fee6e10078bbb9c",
"assets/assets/audio/trap1.mp3": "0157fa661a2f4f0cfedca9beb7cd13b2",
"assets/assets/audio/get_skill.mp3": "0a42da9f0f87e34fb9ccee4e58731fba",
"assets/assets/audio/kettei_old.mp3": "15d36847f7747499de3ed903ead4375f",
"assets/assets/audio/kettei.mp3": "0de7d70ec9fabd3ac41764c43d8374d2",
"assets/assets/audio/merge.mp3": "593db147543a46017a8abd5839eb7233",
"assets/assets/texts/config_base.json": "7ac760dcd0c00e24cd621e36afa9f1ed",
"assets/assets/texts/config_jewel_level_in_block_map.csv": "41944e9bbf4808486b35be61d1cc012b",
"assets/assets/texts/config_block_floor_map.csv": "8d0c7280664db8f016dc3b502c9203ea",
"assets/assets/texts/config_obj_in_block_map.csv": "74e8a830e78da2228181a275883dd710",
"assets/assets/texts/config_max_obj_num_from_block_map.csv": "c28c8ad8e55e34612acd15511febd0a4",
"assets/assets/texts/config_fixed_static_obj_map.csv": "170b8e4ca0f4152246fb78847ebed967",
"assets/assets/texts/config_merge_appear_obj_map.csv": "8628819125caf8a8ecc05f7f9fdff5dd",
"assets/NOTICES": "81e5c87d0d43a0e5f9e1a4bc80a919a2",
"assets/shaders/ink_sparkle.frag": "4096b5150bac93c41cbc9b45276bd90f",
"assets/AssetManifest.json": "f5616a94abbef21b954074805e917711",
"assets/AssetManifest.bin.json": "3d0b3926ed77d796e47df131798b0669",
"index.html": "9a1661a6407b0cf845d53aa6c71576d4",
"/": "9a1661a6407b0cf845d53aa6c71576d4",
"manifest.json": "d593d7b7919ed86f7fb9821bab42e003",
"canvaskit/canvaskit.js": "eb8797020acdbdf96a12fb0405582c1b",
"canvaskit/chromium/canvaskit.js": "0ae8bbcc58155679458a0f7a00f66873",
"canvaskit/chromium/canvaskit.wasm": "143af6ff368f9cd21c863bfa4274c406",
"canvaskit/skwasm.js": "87063acf45c5e1ab9565dcf06b0c18b8",
"canvaskit/canvaskit.wasm": "73584c1a3367e3eaf757647a8f5c5989",
"canvaskit/skwasm.wasm": "2fc47c0a0c3c7af8542b601634fe9674",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"version.json": "d0ad384d19a42ca3eeb7ba84ee6b6f8d"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"assets/AssetManifest.json",
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
