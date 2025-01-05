'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "7d69e653079438abfbb24b82a655b0a4",
"main.dart.js": "973f3618ca77967085535a220f12abcc",
"assets/FontManifest.json": "69777db7f0de4127623721230e9b6960",
"assets/AssetManifest.bin": "1326a187a11649b06d830c2ca889a8ad",
"assets/fonts/MaterialIcons-Regular.otf": "3265e4dca96cbeed42cb8c8a4076328d",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Light.ttf": "b248483f59d25fca6fb75ba8196f7037",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Thin.ttf": "9b3a9c37f57376f4572cc30aa6506367",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Medium.ttf": "7aa0d1123977dab52b1e01f61f0a9a7f",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Black.ttf": "c7cf13f6288ece850a978a0cfa764cd4",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Bold.ttf": "1bdb5bf9e923e1bc6418342bcf6fb3e0",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf": "dd4fa7df965b4d3227bf42b9a77da3e0",
"assets/assets/images/swordsman_U_attack4.png": "78a4ca0c2107bbd463fc2c47bb323e8a",
"assets/assets/images/builders_block.png": "69453803717ea4a484fd9e6bce034fa8",
"assets/assets/images/swordsman_attackL3.png": "60f851966dba8994b223712c019dd963",
"assets/assets/images/belt.png": "ed3d92cc59883696036e35c7c7ae0803",
"assets/assets/images/armer_ability.png": "52df60bd745cdb5988286645afd3ff79",
"assets/assets/images/swordsman_attack5.png": "7347315888670b864f4aa8f2d3d81b47",
"assets/assets/images/swordsman_attackL2.png": "8107d59ffe0d779ccc466f8e860d8bab",
"assets/assets/images/guardian_U_attack4.png": "0cfbf99ae4edbd473130a6a14c075739",
"assets/assets/images/bug_report.png": "2a1162d650c93ac1b92dbb863c91ae41",
"assets/assets/images/guardian_U_attack3.png": "dbdbc05908e6e3ac3154fc7b795d1fac",
"assets/assets/images/drill.png": "c4295097f65fb64f44619185e5a1ee48",
"assets/assets/images/swordsman_L_attack5.png": "48d491d97ce9d5b3a0efa7ad104fed76",
"assets/assets/images/settings.png": "5764fed6946013bcb82e7d0347e43db0",
"assets/assets/images/jewels.png": "00e3ef851d3f1c630818f35c853fda23",
"assets/assets/images/swordsman_attack_round2.png": "b543302237ac5b9413781a51af68cb0f",
"assets/assets/images/magic.png": "fccdd4895008bf3bd1977b280785a9d0",
"assets/assets/images/jewel2.png": "ba4383b02f781aafe7baae4450733f62",
"assets/assets/images/wizard_attack2.png": "e1a5737f57072423f36903fbe536b0e3",
"assets/assets/images/swordsman_L_attack4.png": "321812f082a46af8621afcc34fe6822e",
"assets/assets/images/swordsman_attackU3.png": "9318b54e3e9dae5dd47cf462a14b067c",
"assets/assets/images/swordsman.png": "a291baffde75f057381263a05f951d9a",
"assets/assets/images/jewel.png": "cbb0a56b0d3effce8ff91ebefb530eb0",
"assets/assets/images/guardian_attackR1.png": "ca64b4ba613fac3c828249516d92e61b",
"assets/assets/images/guardian_attack3.png": "8598a882edafb7a1108db718f2ee2681",
"assets/assets/images/magma.png": "17c4fbf9c839a7bd6070dfe4b5495810",
"assets/assets/images/wizard.png": "07dffc71f0cdeb68d8b2f281a5a00ea1",
"assets/assets/images/stage_alpha.png": "2832574240ed5a631322a4a99c3fd772",
"assets/assets/images/guardian_attackR2.png": "574386a453a18a46f140e4f0a96c0fa7",
"assets/assets/images/rabbit.png": "0d1cf2762ccdb340600586fa7b22db4b",
"assets/assets/images/swordsman_U_attack3.png": "1ffc9f9d303fc112b69cb0e884582b94",
"assets/assets/images/guardian_attack1.png": "b40ae2fe5b1fe1c5da66d87676edd72d",
"assets/assets/images/swordsman_attackR3.png": "8c4b8cf1e122461b2e66d0b0411f16da",
"assets/assets/images/tmp.png": "d0d009286adbc68e01bb48357261181f",
"assets/assets/images/swordsman_R_attack3.png": "20cef5f49e02d55fca01f70dcc204599",
"assets/assets/images/guardian_attackL3.png": "53531cacdb91e584bd4633654af3b133",
"assets/assets/images/guardian_U_attack1.png": "a5413c3c1ea68216021ef14a0f8ec646",
"assets/assets/images/guardian_attackR3.png": "8f7c852a27d29af9a5a8ab5ef123610e",
"assets/assets/images/guardian_R_attack1.png": "6a1ba5197c8b424a00387b43bd129892",
"assets/assets/images/warp.png": "65ac49a20a606abdffe2b33e9d27e20a",
"assets/assets/images/pusher.png": "6b9cb8881b960bacec6a6d110e98ddc2",
"assets/assets/images/undo.png": "20294b58a78e7b6cce0ed58778c48719",
"assets/assets/images/p_key_icon.png": "466e2d99ffece68594c5da4c85b2ea71",
"assets/assets/images/swordsman_R_attack4.png": "994f211dec46417972440318291a3429",
"assets/assets/images/guardian.png": "c2e20527367c9f6cfec1f456647ecc70",
"assets/assets/images/swordsman_U_attack2.png": "7408dd4aafb7a786e5002cd51981e784",
"assets/assets/images/floor.png": "26df1dc90700eb34252e6e2222cf3c28",
"assets/assets/images/swordsman_attackD3.png": "55cdb2584afa064bb11feebfd18a3eca",
"assets/assets/images/hand_ability.png": "ff9fcdb11617ef259302f1a749a24047",
"assets/assets/images/block.png": "49ef281ed131b498e841eb1979fb62ab",
"assets/assets/images/guardian_attackU3.png": "cbe0b7678df1aa68aace7ed06fc02d4f",
"assets/assets/images/swordsman_R_attack1.png": "d27d4bc0499813cf547817570d286b68",
"assets/assets/images/guardian_attackL2.png": "2ec9d8e5b23d375dc642e80d2cb8cfa2",
"assets/assets/images/guardian_U_attack5.png": "5adf8eeb439a760f8b7a9d5b9830c9d2",
"assets/assets/images/builder.png": "79b0dad3f748dc7a675298e384a89959",
"assets/assets/images/tmp2.png": "b4cd063ee1c46b2df06968bf0098fc82",
"assets/assets/images/swordsman_attack_round3.png": "ee5323aa16d3ce559c805cde3a9546dd",
"assets/assets/images/swordsman_attack2.png": "152fb7fe82820bd6d99daa876a0b1e62",
"assets/assets/images/merge_effect.png": "39d20c245052407912c3fd711c51bd3b",
"assets/assets/images/noimage.png": "cc16cb484659ec73f24b0b8c79e52d70",
"assets/assets/images/wizard_attack3.png": "c2c8ab3c7b1ede962fb094b07bd381a7",
"assets/assets/images/bomb.png": "84afb89be7ea212adf6620004aa9c48a",
"assets/assets/images/swordsman_attackL1.png": "3d69065814071062cce938debbe54466",
"assets/assets/images/swordsman_attackU2.png": "2445949a9c2304582dbe52862c5bddb8",
"assets/assets/images/guardian_L_attack4.png": "07a8c3dc763cd28e31aafc387165e17e",
"assets/assets/images/jewels_ai.png": "0d2cf670f799ec43c45f52eb8fd2147e",
"assets/assets/images/swordsman_L_attack2.png": "3dc8b5029149600cc031db5ab4df0742",
"assets/assets/images/guardian_L_attack5.png": "b108aad6148becb7b81fa2a67182a95e",
"assets/assets/images/guardian_attack2.png": "a34ce8d740d82f8ae887880620946a6e",
"assets/assets/images/swordsman_R_attack5.png": "56b450e45ca313e5a9134eb3760addcd",
"assets/assets/images/guardian_attackL1.png": "159fca62950f9b86fb316ccd720bca69",
"assets/assets/images/swordsman_attack1.png": "41d82401eacdcb17235f190ac12a0e5e",
"assets/assets/images/swordsman_U_attack5.png": "40ee28c920d83545f29cca7a87048421",
"assets/assets/images/archer_attack3.png": "0cb1219efb549380b723a7095484a0c4",
"assets/assets/images/block2.png": "66545da77a215ed4fbc32e2baf070249",
"assets/assets/images/wizard_attack1.png": "e50d07b55e3c7c904ba06ce0a973bd65",
"assets/assets/images/guardian_attackD2.png": "f91cd0be8be75735bf1da22514f64ec7",
"assets/assets/images/guardian_R_attack4.png": "6ae598b0d5dae6983b0e9bc78921a753",
"assets/assets/images/arrows_output.png": "ef79024eaecde156e8b2b3820ff3e46c",
"assets/assets/images/guardian_L_attack3.png": "60791a0552ec134cce608dbcbadeaa12",
"assets/assets/images/leg_ability.png": "8553556729f5abfeba32e7a6a2bada9b",
"assets/assets/images/trap.png": "47851071dd5f58a046990e82be70917a",
"assets/assets/images/space_key_icon.png": "b141e043fc8cb9f55824a91acc08ebe1",
"assets/assets/images/swordsman_attackD2.png": "9a4790bf77ea28468659c65fec074b9c",
"assets/assets/images/swordsman_U_attack1.png": "609681c06a81352aff339cea7a2c7ddb",
"assets/assets/images/guardian_L_attack1.png": "38e3b61c525f597362de7b6013587a07",
"assets/assets/images/swordsman_L_attack1.png": "8712862cd601c3a2fe97e63ad09316dc",
"assets/assets/images/guardian_attackD3.png": "ea0c3a5af24f06d56ab7d53f049c95e1",
"assets/assets/images/archer_attack2.png": "94f48c561d549196837d2e88dd88932d",
"assets/assets/images/guardian_attackU2.png": "06ae344033aca1932678340393bbfa49",
"assets/assets/images/guardian_U_attack2.png": "510e350f9917a990c7fb3616a96614f6",
"assets/assets/images/ghost.png": "477609593e91da2bd8053c4f2824c976",
"assets/assets/images/arch.png": "af4e846fa5be2e36317dca330cb3738c",
"assets/assets/images/swordsman_attack3.png": "a721d344bbffafcf72c4491178373cc9",
"assets/assets/images/water.png": "bb594830475a5e86249f325eae4c033a",
"assets/assets/images/swordsman_attackD1.png": "c16a9edacf5c33c1e6f0128825cbae49",
"assets/assets/images/swordsman_R_attack2.png": "74b31297e5e2218d2f091de291bf1007",
"assets/assets/images/archer_attack1.png": "6c06ed6e674a82a154778ac2861fb022",
"assets/assets/images/swordsman_L_attack3.png": "82dec64dec2a6118c18fcc03b4ebdcfa",
"assets/assets/images/swordsman_attackR1.png": "3a1a84664cb87c7632437d1bb74b33ce",
"assets/assets/images/guardian_attack5.png": "4730d03bc4affd530ea40e16359177ae",
"assets/assets/images/swordsman_attackR2.png": "6c637e8c6f31ee20711ad939d1c0606e",
"assets/assets/images/spike.png": "7ce79ca644e814afe8a08582a1b48624",
"assets/assets/images/up_key_icon.png": "b76f5a8ba7cb805b6ba37dcdc1f9269f",
"assets/assets/images/guardian_R_attack3.png": "088098d9d3b23b616723d8025ad89427",
"assets/assets/images/archer.png": "48fee367d8d98fbcc4dee75c5e783eff",
"assets/assets/images/pocket_ability.png": "941ff5519f207ad3b96df3f7b873f99c",
"assets/assets/images/kangaroo.png": "0ec75367027cedbd4e5ebbe857a09812",
"assets/assets/images/gorilla.png": "c576ad23ee5f755390c9d5098b3d5a19",
"assets/assets/images/swordsman_attack_round1.png": "36c3f5fcd7bd17a2d4270c57fd263923",
"assets/assets/images/loading.png": "4c6db31d305abe18ba78978366cea1d1",
"assets/assets/images/swordsman_attack4.png": "42b0545c3818b37398fa08a07e0863f9",
"assets/assets/images/coin.png": "86614a81d8d3758d9a384c93c024bf00",
"assets/assets/images/guardian_attack4.png": "aad2bc05d93a184af617972473945720",
"assets/assets/images/swordsman_attackU1.png": "bdec0c28fa9e57d1bfdfb2ea37789ce2",
"assets/assets/images/guardian_attackU1.png": "87477d62580f098d301aa7a7b29ea738",
"assets/assets/images/guardian_R_attack2.png": "9c0da9729b235a52aae2d4b912f1a65e",
"assets/assets/images/arrow.png": "2dc3e22571ede47c33fd9ba8e07d3d00",
"assets/assets/images/player_controll_arrow.png": "27ce947b07c9527000132131fec7ea4f",
"assets/assets/images/guardian_attackD1.png": "0ba53287aa1a7e937727c04b3d1b262d",
"assets/assets/images/guardian_L_attack2.png": "47083d1d75c8b921dd7c437e2f14b9ff",
"assets/assets/images/treasure_box.png": "4c0278f057471d88dc68db90bfeae251",
"assets/assets/images/guardian_R_attack5.png": "9dd377a4f2b48ed73306efe09944323f",
"assets/assets/images/turtle.png": "c62cbf171bf7ad9d2c9955cc6aa65e88",
"assets/assets/images/player.png": "d0bce0ad2779e5b49a9ca8f6be690925",
"assets/assets/images/down_key_icon.png": "b9b42fbdfdc6ef0302e4683659fac21f",
"assets/assets/audio/explode.mp3": "bd841c971ffb28d430689355f9392ef3",
"assets/assets/audio/maou_bgm_8bit29.mp3": "ec4a718b7755dd003fee6e10078bbb9c",
"assets/assets/audio/trap1.mp3": "0157fa661a2f4f0cfedca9beb7cd13b2",
"assets/assets/audio/get_skill.mp3": "0a42da9f0f87e34fb9ccee4e58731fba",
"assets/assets/audio/kettei_old.mp3": "15d36847f7747499de3ed903ead4375f",
"assets/assets/audio/kettei.mp3": "0de7d70ec9fabd3ac41764c43d8374d2",
"assets/assets/audio/merge.mp3": "593db147543a46017a8abd5839eb7233",
"assets/assets/texts/config_obj_in_block_distribution.csv": "459ea303e5c117d63a1898127b0748d3",
"assets/assets/texts/config_block_floor_distribution.csv": "87ea9cc9c8e50fcd9f9df512a2bf94aa",
"assets/assets/texts/config_base.json": "f578f93042449f7a7c92e7b226475d94",
"assets/assets/texts/config_jewel_level_in_block_map.csv": "41944e9bbf4808486b35be61d1cc012b",
"assets/assets/texts/config_block_floor_map.csv": "8d0c7280664db8f016dc3b502c9203ea",
"assets/assets/texts/config_obj_in_block_map.csv": "732666b10b62d6c6085560097af98e01",
"assets/assets/texts/version_log.md": "909db3763b32a6b2cf120d3ec3f73576",
"assets/assets/texts/config_max_obj_num_from_block_map.csv": "c28c8ad8e55e34612acd15511febd0a4",
"assets/assets/texts/config_fixed_static_obj_map.csv": "170b8e4ca0f4152246fb78847ebed967",
"assets/assets/texts/config_merge_appear_obj_map.csv": "8628819125caf8a8ecc05f7f9fdff5dd",
"assets/NOTICES": "c14f3cf1ca2cbe050d3f41b9ac0bac45",
"assets/shaders/ink_sparkle.frag": "4096b5150bac93c41cbc9b45276bd90f",
"assets/AssetManifest.json": "a00eb921c24921613ad844683f992b23",
"assets/AssetManifest.bin.json": "559899b177bcdac0bf1f77cb0af36f44",
"index.html": "165afb3d01ca0a694d97288f138f209e",
"/": "165afb3d01ca0a694d97288f138f209e",
"manifest.json": "d593d7b7919ed86f7fb9821bab42e003",
"canvaskit/canvaskit.js": "eb8797020acdbdf96a12fb0405582c1b",
"canvaskit/chromium/canvaskit.js": "0ae8bbcc58155679458a0f7a00f66873",
"canvaskit/chromium/canvaskit.wasm": "143af6ff368f9cd21c863bfa4274c406",
"canvaskit/skwasm.js": "87063acf45c5e1ab9565dcf06b0c18b8",
"canvaskit/canvaskit.wasm": "73584c1a3367e3eaf757647a8f5c5989",
"canvaskit/skwasm.wasm": "2fc47c0a0c3c7af8542b601634fe9674",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"icons/Icon-maskable-192.png": "a8deada709af63c1b6b309690256bff5",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "f9ab1a6e2db97c26969625094e3c3559",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"version.json": "197377225291f51b4ea78e2a4aeec63f"};
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
