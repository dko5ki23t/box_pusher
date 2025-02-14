'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"flutter_bootstrap.js": "581649cc796102a099907c18656d0218",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"main.dart.js": "4eea853f15d5a703ae86f7220862f304",
"version.json": "f9c7a16d2334285daa31727482ca5694",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/FontManifest.json": "69777db7f0de4127623721230e9b6960",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.json": "0b935e51d56303b59b5ea11668537801",
"assets/assets/texts/config_floor_in_block_distribution.csv": "5741ee0046945e634e18ab456ee8e452",
"assets/assets/texts/config_obj_in_block_distribution.csv": "5c5692176677cd511daf38a2f19f1944",
"assets/assets/texts/config_obj_in_block_map.csv": "3ed12e283a86013930517743112c0497",
"assets/assets/texts/version_log.md": "04c6c91dc8e3927671af59b5bf35ff56",
"assets/assets/texts/config_jewel_level_in_block_map.csv": "b39c9c536278827c219c64e1417e2350",
"assets/assets/texts/config_base.json": "90717c4d20f75d5f85ca589ef8e95e81",
"assets/assets/texts/config_floor_in_block_map.csv": "ecc5d789a77951b5d9296ba054183a9b",
"assets/assets/texts/config_block_floor_distribution.csv": "edaf26236b9367275ce9d3e76fb42f1e",
"assets/assets/texts/config_shop_info.csv": "aca53071f5781c57a4b8b31e2374f04a",
"assets/assets/texts/config_fixed_static_obj_map.csv": "2bcc6f3313c2773a5dc8a4f359796be2",
"assets/assets/texts/config_merge_appear_obj_map.csv": "1d6fc6aa566625cd624909a9ae1ff172",
"assets/assets/texts/config_max_obj_num_from_block_map.csv": "22355fa9b8ba33aff9b7e8908f23f077",
"assets/assets/texts/config_block_floor_map.csv": "327348e9cb2342e593290e0cddcab678",
"assets/assets/images/merge_ability.png": "c3adebdfb457b88381fb0cf844315e02",
"assets/assets/images/guardian_U_attack3.png": "dbdbc05908e6e3ac3154fc7b795d1fac",
"assets/assets/images/ghost.png": "75d0724f3e5fe4392d8e542f1416f832",
"assets/assets/images/pusher.png": "6b9cb8881b960bacec6a6d110e98ddc2",
"assets/assets/images/swordsman_attackR2.png": "6c637e8c6f31ee20711ad939d1c0606e",
"assets/assets/images/builders_block.png": "69453803717ea4a484fd9e6bce034fa8",
"assets/assets/images/swordsman_R_attack5.png": "56b450e45ca313e5a9134eb3760addcd",
"assets/assets/images/jewels.png": "00e3ef851d3f1c630818f35c853fda23",
"assets/assets/images/arrow.png": "1b7a2e933cb469aa8649da336c17e8b2",
"assets/assets/images/spawner.png": "bb45bb9e47d7cdd1b7256e64aa5f0eaf",
"assets/assets/images/drill.png": "c4295097f65fb64f44619185e5a1ee48",
"assets/assets/images/guardian_L_attack2.png": "47083d1d75c8b921dd7c437e2f14b9ff",
"assets/assets/images/tutorial_ability.png": "310269abb3f2b49192aea1e63b782b9b",
"assets/assets/images/guardian_attackU3.png": "cbe0b7678df1aa68aace7ed06fc02d4f",
"assets/assets/images/swordsman_R_attack3.png": "20cef5f49e02d55fca01f70dcc204599",
"assets/assets/images/builder.png": "79b0dad3f748dc7a675298e384a89959",
"assets/assets/images/swordsman_attack4.png": "42b0545c3818b37398fa08a07e0863f9",
"assets/assets/images/armer_ability.png": "8bb48a5864cc348a97faba574b055e6c",
"assets/assets/images/guardian_U_attack5.png": "5adf8eeb439a760f8b7a9d5b9830c9d2",
"assets/assets/images/guardian.png": "caee38a1e59efa4b151fafce0e028eae",
"assets/assets/images/girl_org.png": "4ce87384a36881d3bae1a501707e14f1",
"assets/assets/images/guardian_attackL1.png": "159fca62950f9b86fb316ccd720bca69",
"assets/assets/images/swordsman_U_attack4.png": "78a4ca0c2107bbd463fc2c47bb323e8a",
"assets/assets/images/right_key_icon.png": "437f09db31510a4c40d2c0e27419bfec",
"assets/assets/images/swordsman_attackU2.png": "2445949a9c2304582dbe52862c5bddb8",
"assets/assets/images/kangaroo_org.png": "7f59c280fd17f4e4d2ae38a7e3e8c1e7",
"assets/assets/images/p_key_icon.png": "617addc18af9ad4d6808ac8771015a30",
"assets/assets/images/swordsman_attackL1.png": "3d69065814071062cce938debbe54466",
"assets/assets/images/magma.png": "9a9965617d4960b7493dd6395716c972",
"assets/assets/images/guardian_U_attack1.png": "a5413c3c1ea68216021ef14a0f8ec646",
"assets/assets/images/swordsman_attackR1.png": "3a1a84664cb87c7632437d1bb74b33ce",
"assets/assets/images/guardian_attack_round3.png": "61abe5e498d9db42b88646a716cc31ee",
"assets/assets/images/title_logo.png": "5fb0b3e5cd18a261c93b857557e08ff8",
"assets/assets/images/settings.png": "7832cf7bf4b2e7399f3dc57ba7a976bf",
"assets/assets/images/swordsman_attack_round1.png": "36c3f5fcd7bd17a2d4270c57fd263923",
"assets/assets/images/swordsman_L_attack3.png": "82dec64dec2a6118c18fcc03b4ebdcfa",
"assets/assets/images/pocket_ability_old.png": "941ff5519f207ad3b96df3f7b873f99c",
"assets/assets/images/archer_attack2.png": "94f48c561d549196837d2e88dd88932d",
"assets/assets/images/guardian_attackD1.png": "0ba53287aa1a7e937727c04b3d1b262d",
"assets/assets/images/pocket_ability.png": "c2e526f0942e6d28a32e1496143cf8e2",
"assets/assets/images/player_controll_arrow.png": "27ce947b07c9527000132131fec7ea4f",
"assets/assets/images/tmp.png": "d0d009286adbc68e01bb48357261181f",
"assets/assets/images/block2.png": "66545da77a215ed4fbc32e2baf070249",
"assets/assets/images/noimage.png": "677eb3b55d109e30650518c0a9dab9b9",
"assets/assets/images/shop_pay2.png": "fb7255f2b999faef881ac1f86d5c673d",
"assets/assets/images/fire.png": "faa0d30a7032a49a2504505fa1ceffbf",
"assets/assets/images/guardian_U_attack4.png": "0cfbf99ae4edbd473130a6a14c075739",
"assets/assets/images/player_old.png": "f935c9d4756c13dfcdb9917e2143b559",
"assets/assets/images/guardian_U_attack2.png": "510e350f9917a990c7fb3616a96614f6",
"assets/assets/images/trap.png": "47851071dd5f58a046990e82be70917a",
"assets/assets/images/guardian_attackL2.png": "2ec9d8e5b23d375dc642e80d2cb8cfa2",
"assets/assets/images/wizard_attack2.png": "e1a5737f57072423f36903fbe536b0e3",
"assets/assets/images/guardian_attackR3.png": "8f7c852a27d29af9a5a8ab5ef123610e",
"assets/assets/images/tutorial3.png": "671f2b58c23da1ebbca79164e96beb3c",
"assets/assets/images/guardian_attackD2.png": "f91cd0be8be75735bf1da22514f64ec7",
"assets/assets/images/down_key_icon.png": "0ce2f80b9db50cda060b87344cfb8d81",
"assets/assets/images/shop.png": "4fdd392bb131be0a777f3f00a5d37041",
"assets/assets/images/canon_weight.png": "ad34e1c586d5bc5a50a821e946c69467",
"assets/assets/images/jewel2.png": "ba4383b02f781aafe7baae4450733f62",
"assets/assets/images/guardian_attackD3.png": "ea0c3a5af24f06d56ab7d53f049c95e1",
"assets/assets/images/guardian_L_attack1.png": "38e3b61c525f597362de7b6013587a07",
"assets/assets/images/swordsman_attackD1.png": "c16a9edacf5c33c1e6f0128825cbae49",
"assets/assets/images/arch.png": "af4e846fa5be2e36317dca330cb3738c",
"assets/assets/images/swordsman_attack3.png": "a721d344bbffafcf72c4491178373cc9",
"assets/assets/images/gorilla_org.png": "2e4a03202a21500299739361b8fed65a",
"assets/assets/images/archer_attack3.png": "0cb1219efb549380b723a7095484a0c4",
"assets/assets/images/weight.png": "99d7cb284606ce25b713b9d8d8af21f2",
"assets/assets/images/shop_pay.png": "02224fec6beb1d6ed71d34358f33365d",
"assets/assets/images/canonball.png": "c4b08f75a5a5e502f7c104640fad641e",
"assets/assets/images/swordsman_U_attack2.png": "7408dd4aafb7a786e5002cd51981e784",
"assets/assets/images/swordsman_R_attack2.png": "74b31297e5e2218d2f091de291bf1007",
"assets/assets/images/swordsman_attackU3.png": "9318b54e3e9dae5dd47cf462a14b067c",
"assets/assets/images/barrierman.png": "c3a30f5f7f7fe0a8566691f1ef44dc00",
"assets/assets/images/merge_ability_old.png": "a73beac123227ff1c710ab9733310d1a",
"assets/assets/images/turtle.png": "c62cbf171bf7ad9d2c9955cc6aa65e88",
"assets/assets/images/archer.png": "48fee367d8d98fbcc4dee75c5e783eff",
"assets/assets/images/guardian_attack_round2.png": "98955ffffacbf431619bc711a773c82b",
"assets/assets/images/shift_key_icon.png": "8469f62259da93ee8991f3de5ded71d8",
"assets/assets/images/treasure_box.png": "4c0278f057471d88dc68db90bfeae251",
"assets/assets/images/arrows_output.png": "ef79024eaecde156e8b2b3820ff3e46c",
"assets/assets/images/undo.png": "20294b58a78e7b6cce0ed58778c48719",
"assets/assets/images/guardian_attack2.png": "a34ce8d740d82f8ae887880620946a6e",
"assets/assets/images/pinch_inout.png": "ae1ad13c3a2538a5a21f5933925d2da5",
"assets/assets/images/guardian_R_attack2.png": "9c0da9729b235a52aae2d4b912f1a65e",
"assets/assets/images/swordsman_L_attack2.png": "3dc8b5029149600cc031db5ab4df0742",
"assets/assets/images/guardian_R_attack5.png": "9dd377a4f2b48ed73306efe09944323f",
"assets/assets/images/leg_ability.png": "10f6c81d6f4bf4ca76c05339fea326e5",
"assets/assets/images/armer_ability_old.png": "52df60bd745cdb5988286645afd3ff79",
"assets/assets/images/guardian_attackR1.png": "ca64b4ba613fac3c828249516d92e61b",
"assets/assets/images/swordsman_attackU1.png": "bdec0c28fa9e57d1bfdfb2ea37789ce2",
"assets/assets/images/hand_ability_old2.png": "0a9274e4a722d44897507d4e8fc4f9fc",
"assets/assets/images/smoke.png": "a563735be6a400f21c51fe5df46f22ae",
"assets/assets/images/guardian_attack1.png": "b40ae2fe5b1fe1c5da66d87676edd72d",
"assets/assets/images/belt.png": "ed3d92cc59883696036e35c7c7ae0803",
"assets/assets/images/swordsman.png": "a291baffde75f057381263a05f951d9a",
"assets/assets/images/wand.png": "2aebc247578030457bf86812ba23d886",
"assets/assets/images/hand_ability_old.png": "ff9fcdb11617ef259302f1a749a24047",
"assets/assets/images/magic.png": "fccdd4895008bf3bd1977b280785a9d0",
"assets/assets/images/wizard_attack3.png": "c2c8ab3c7b1ede962fb094b07bd381a7",
"assets/assets/images/swordsman_attackL3.png": "60f851966dba8994b223712c019dd963",
"assets/assets/images/leg_ability_old.png": "8553556729f5abfeba32e7a6a2bada9b",
"assets/assets/images/guardian_attackU1.png": "87477d62580f098d301aa7a7b29ea738",
"assets/assets/images/boneman.png": "41291257a3c0eed99d942ce7ccecf2da",
"assets/assets/images/wizard.png": "07dffc71f0cdeb68d8b2f281a5a00ea1",
"assets/assets/images/merge_effect.png": "39d20c245052407912c3fd711c51bd3b",
"assets/assets/images/wizard_attack1.png": "e50d07b55e3c7c904ba06ce0a973bd65",
"assets/assets/images/gorilla.png": "c576ad23ee5f755390c9d5098b3d5a19",
"assets/assets/images/coin.png": "86614a81d8d3758d9a384c93c024bf00",
"assets/assets/images/swordsman_attack2.png": "152fb7fe82820bd6d99daa876a0b1e62",
"assets/assets/images/turtle_org.png": "6e5e14e1794e125e0f9b218fe29e1789",
"assets/assets/images/swordsman_attackD2.png": "9a4790bf77ea28468659c65fec074b9c",
"assets/assets/images/bomb.png": "c27d85901967c538347c4529a0e6e914",
"assets/assets/images/swordsman_attack5.png": "7347315888670b864f4aa8f2d3d81b47",
"assets/assets/images/swordsman_R_attack4.png": "994f211dec46417972440318291a3429",
"assets/assets/images/girl_tutorial.png": "d016184df187bd452a351479a8d39350",
"assets/assets/images/tutorial2.png": "f076a94ac71879465663a55ccaab7d8c",
"assets/assets/images/rabbit.png": "0d1cf2762ccdb340600586fa7b22db4b",
"assets/assets/images/archer_attack1.png": "6c06ed6e674a82a154778ac2861fb022",
"assets/assets/images/guardian_R_attack1.png": "6a1ba5197c8b424a00387b43bd129892",
"assets/assets/images/tutorial_sozai.png": "ab88c17f0634ae32b6df1c735981a492",
"assets/assets/images/swordsman_attackL2.png": "8107d59ffe0d779ccc466f8e860d8bab",
"assets/assets/images/kangaroo.png": "0ec75367027cedbd4e5ebbe857a09812",
"assets/assets/images/swordsman_L_attack1.png": "8712862cd601c3a2fe97e63ad09316dc",
"assets/assets/images/block.png": "49ef281ed131b498e841eb1979fb62ab",
"assets/assets/images/guardian_R_attack4.png": "6ae598b0d5dae6983b0e9bc78921a753",
"assets/assets/images/swordsman_attackD3.png": "55cdb2584afa064bb11feebfd18a3eca",
"assets/assets/images/smoker.png": "c1d67fa02d59ae3f302f246fb55607cf",
"assets/assets/images/tmp2.png": "b4cd063ee1c46b2df06968bf0098fc82",
"assets/assets/images/guardian_attack4.png": "aad2bc05d93a184af617972473945720",
"assets/assets/images/guardian_L_attack4.png": "07a8c3dc763cd28e31aafc387165e17e",
"assets/assets/images/warp.png": "65ac49a20a606abdffe2b33e9d27e20a",
"assets/assets/images/player.png": "fbf6bf27c68fdb8585b156094dd38a7f",
"assets/assets/images/shop_item.png": "6eafb3e006310d5c4e1463a454cd0e30",
"assets/assets/images/left_key_icon.png": "6e9ace260bac023b3ff349f8dc3c2ed6",
"assets/assets/images/swordsman_U_attack5.png": "40ee28c920d83545f29cca7a87048421",
"assets/assets/images/long_tap.png": "33d3c5a8dd7b20338dac60e033e05ea2",
"assets/assets/images/jewels_ai.png": "0d2cf670f799ec43c45f52eb8fd2147e",
"assets/assets/images/swordsman_attack_round3.png": "ee5323aa16d3ce559c805cde3a9546dd",
"assets/assets/images/swordsman_U_attack1.png": "609681c06a81352aff339cea7a2c7ddb",
"assets/assets/images/up_key_icon.png": "afd1ae48a0adfd531a7d20605c9c3507",
"assets/assets/images/noimage_old.png": "cc16cb484659ec73f24b0b8c79e52d70",
"assets/assets/images/girl.png": "0b1dd708aaa9111c7c8d899c7b2dea2e",
"assets/assets/images/guardian_attack_magic3.png": "b5afc3d36556878ee2da981c0271b7ef",
"assets/assets/images/hand_ability_old3.png": "890d88d0bc4c82e3385b0d7983fc55be",
"assets/assets/images/guardian_attack5.png": "4730d03bc4affd530ea40e16359177ae",
"assets/assets/images/guardian_magic.png": "75ff2ab15009867b970660a0e567aedf",
"assets/assets/images/loading.png": "4c6db31d305abe18ba78978366cea1d1",
"assets/assets/images/swordsman_attack1.png": "41d82401eacdcb17235f190ac12a0e5e",
"assets/assets/images/swordsman_R_attack1.png": "d27d4bc0499813cf547817570d286b68",
"assets/assets/images/rabbit_org.png": "fb67ed392de452b593f540aaa35e4d01",
"assets/assets/images/swordsman_attackR3.png": "8c4b8cf1e122461b2e66d0b0411f16da",
"assets/assets/images/water.png": "e395be2181266d47f2fda74e2081a62b",
"assets/assets/images/guardian_L_attack3.png": "60791a0552ec134cce608dbcbadeaa12",
"assets/assets/images/jewel.png": "cbb0a56b0d3effce8ff91ebefb530eb0",
"assets/assets/images/guardian_L_attack5.png": "b108aad6148becb7b81fa2a67182a95e",
"assets/assets/images/magic_circle.png": "e5c625f268fa80a406d5d8d6415f7664",
"assets/assets/images/guardian_attackR2.png": "574386a453a18a46f140e4f0a96c0fa7",
"assets/assets/images/swordsman_U_attack3.png": "1ffc9f9d303fc112b69cb0e884582b94",
"assets/assets/images/bug_report.png": "2a1162d650c93ac1b92dbb863c91ae41",
"assets/assets/images/swordsman_attack_round2.png": "b543302237ac5b9413781a51af68cb0f",
"assets/assets/images/tutorial1.png": "3e836247b6f0aaeddb5c1dd22c473427",
"assets/assets/images/spawn_effect.png": "58eaee3d108934423633ff9ba6c81e94",
"assets/assets/images/eye_ability.png": "c967728421e642869bbe2ec060e4fefd",
"assets/assets/images/guardian_attack_bow2.png": "193abe248595147860eeffe44ff21b54",
"assets/assets/images/bow.png": "17f6a686299c530cc5dc1abf18ca9520",
"assets/assets/images/tanukibasic.png": "5029df2a6bbe9d719802b1e58fd9cca9",
"assets/assets/images/forbidden_ability.png": "883ae5067e788fd9cacf7bcf522f9d54",
"assets/assets/images/shop_trans.png": "42c4b15b86c1ef802a7a3f61c13f8e4b",
"assets/assets/images/hand_ability.png": "7ea9a4db64679f050864206c463d3b7c",
"assets/assets/images/guardian_attackU2.png": "06ae344033aca1932678340393bbfa49",
"assets/assets/images/guardian_arrow.png": "64b8fdbd4488e2be070c7f6e34e238ef",
"assets/assets/images/guardian_R_attack3.png": "088098d9d3b23b616723d8025ad89427",
"assets/assets/images/guardian_attackL3.png": "53531cacdb91e584bd4633654af3b133",
"assets/assets/images/mouse_wheel.png": "eda6b260665874a307e32e5d52b0029d",
"assets/assets/images/stage_alpha.png": "2832574240ed5a631322a4a99c3fd772",
"assets/assets/images/spike.png": "7ce79ca644e814afe8a08582a1b48624",
"assets/assets/images/space_key_icon.png": "e4e33b0d5b852551cb8ea0c063ac93f9",
"assets/assets/images/floor.png": "26df1dc90700eb34252e6e2222cf3c28",
"assets/assets/images/swordsman_L_attack4.png": "321812f082a46af8621afcc34fe6822e",
"assets/assets/images/swordsman_L_attack5.png": "48d491d97ce9d5b3a0efa7ad104fed76",
"assets/assets/images/canon.png": "5be45d49d725a32ebbc6c3654913f972",
"assets/assets/images/guardian_attack3.png": "8598a882edafb7a1108db718f2ee2681",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Medium.ttf": "7aa0d1123977dab52b1e01f61f0a9a7f",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Light.ttf": "b248483f59d25fca6fb75ba8196f7037",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Thin.ttf": "9b3a9c37f57376f4572cc30aa6506367",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Black.ttf": "c7cf13f6288ece850a978a0cfa764cd4",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Regular.ttf": "dd4fa7df965b4d3227bf42b9a77da3e0",
"assets/assets/fonts/Noto_Sans_JP/static/NotoSansJP-Bold.ttf": "1bdb5bf9e923e1bc6418342bcf6fb3e0",
"assets/assets/audio/trap1.mp3": "0157fa661a2f4f0cfedca9beb7cd13b2",
"assets/assets/audio/explode.mp3": "bd841c971ffb28d430689355f9392ef3",
"assets/assets/audio/get_skill.mp3": "0a42da9f0f87e34fb9ccee4e58731fba",
"assets/assets/audio/warp.mp3": "f1bfcce99026ca0d2e5b72270c7ac5fa",
"assets/assets/audio/merge.mp3": "593db147543a46017a8abd5839eb7233",
"assets/assets/audio/maou_bgm_8bit29.mp3": "ec4a718b7755dd003fee6e10078bbb9c",
"assets/assets/audio/spawn.mp3": "0e831a44b713fe7c1c4c8060bd441442",
"assets/assets/audio/kettei_old.mp3": "15d36847f7747499de3ed903ead4375f",
"assets/assets/audio/kettei.mp3": "0de7d70ec9fabd3ac41764c43d8374d2",
"assets/assets/audio/player_damaged.mp3": "869140bcbbab641d997dfaf469a3e210",
"assets/NOTICES": "5e2478bd083cddb7861abfd70b4625b2",
"assets/AssetManifest.bin": "b3bffe6888d70afb9e0a5732b00a0a10",
"assets/fonts/MaterialIcons-Regular.otf": "74b99f0a1e9caadcad9381d412a30de0",
"assets/AssetManifest.bin.json": "b93c544964320d83e48623e0c79b4331",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"index.html": "f51c68ae4470df52906bcb0998b7bc80",
"/": "f51c68ae4470df52906bcb0998b7bc80",
"manifest.json": "d593d7b7919ed86f7fb9821bab42e003",
"flutter.js": "4b2350e14c6650ba82871f60906437ea"};
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
