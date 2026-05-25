import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// --- MESIN RENDER AVATAR (AVATAR PREVIEW) ---
/// Widget ini berfungsi menyatukan gambar-gambar terpisah (background, badan, baju, celana, kepala, dan pet)
/// menjadi satu kesatuan utuh karakter 2D.
/// Data baju apa yang dipakai dikirim melalui `equippedItems`.
class AvatarPreview extends StatelessWidget {
  // Map yang berisi ID barang yang sedang dipakai. Contoh: {'head': 'head_samurai', 'clothes': 'armor_knight'}
  final Map<String, String> equippedItems;
  
  // Ukuran kotak render avatar (default 140x140 pixel)
  final double size;
  
  // Apakah mau menampilkan background hutan/kastil di belakangnya?
  final bool showBackground;
  
  // Baju dasar bawaan (contoh: cowok/cewek) jika user belum pakai armor
  final String? baseBody; 

  const AvatarPreview({
    super.key,
    required this.equippedItems,
    this.size = 140,
    this.showBackground = true,
    this.baseBody,
  });

  // Fungsi Kamus: Mengubah ID (teks pendek dari Firestore) menjadi alamat path file PNG sungguhan.
  String _getAssetPath(String category, String id) {
    // Jika tidak pakai apa-apa, jangan ambil gambar apapun (kembalikan string kosong)
    if (id == 'none' || id == 'default' || id.startsWith('none_')) return '';

    // Daftar lengkap semua aset gambar 2D yang ada di aplikasi
    final Map<String, String> assetPaths = {
      // --- DAFTAR KEPALA (HELMET/HAT) ---
      'head_buddha': 'lib/assets/Head/head_buddha.png',
      'head_samurai': 'lib/assets/Head/head_samurai.png',
      'head_desert_man': 'lib/assets/Head/head_Desert_man.png',
      'head_barbarian': 'lib/assets/Head/head_barbarian.png',
      'head_spartan': 'lib/assets/Head/head_spartan.png',
      'head_guard_helmet': 'lib/assets/Head/head_guard_helmet.png',
      'head_engineer': 'lib/assets/Head/head_engineer.png',
      'head_assassin': 'lib/assets/Head/head_assassin.png',
      'head_valkyrie': 'lib/assets/Head/head_valkyrie.png',
      'head_mage': 'lib/assets/Head/head_mage.png',
      'head_robot': 'lib/assets/Head/head_robot.png',
      'head_engineerfm': 'lib/assets/Head/head_engineerfm.png',
      'head_lich': 'lib/assets/Head/head_lich.png',
      'head_darkvoid': 'lib/assets/Head/head_darkvoid.png',
      'head_bluepyro': 'lib/assets/Head/head_bluepyro.png',
      'head_icefrost': 'lib/assets/Head/head_icefrost.png',
      'head_queen': 'lib/assets/Head/head_queen.png',
      'head_silverman': 'lib/assets/Head/head_silverman.png',
      'head_water': 'lib/assets/Head/head_water.png',
      'head_glitch': 'lib/assets/Head/Head_glitch.png',
      
      // --- DAFTAR KEPALA BAWAAN (DEFAULT) ---
      'head_default_login_male1': 'lib/assets/Head/head_default_login_male1.png',
      'head_default_login_male2': 'lib/assets/Head/head_default_login_male2.png',
      'head_default_login_female1': 'lib/assets/Head/head_default_login_female1.png',
      'head_default_login_female2': 'lib/assets/Head/head_default_login_female2.png',

      // --- DAFTAR BAJU / ARMOR ---
      'outfit_cardigan_blue': 'lib/assets/armor/outfit_cardigan_blue.png',
      'outfit_student': 'lib/assets/armor/outfit_student.png',
      'body_desertman': 'lib/assets/armor/body_desertman.png',
      'armor_druid': 'lib/assets/armor/armor_druid.png',
      'armor_executioner': 'lib/assets/armor/armor_executioner.png',
      'armor_gladiator': 'lib/assets/armor/armor_gladiator.png',
      'body_orc': 'lib/assets/Body1Set/body_orc.png',
      'armor_assassin': 'lib/assets/armor/armor_assassin.png',
      'armor_red_mage': 'lib/assets/armor/armor_red_mage.png',
      'armor_wizard_robe': 'lib/assets/Body1Set/armor_wizard_robe.png',
      'body_engineer': 'lib/assets/Body1Set/body_engineer.png',
      'body_mage': 'lib/assets/armor/body_mage.png',
      'skull_mage_armor': 'lib/assets/armor/skull_mage_armor.png',
      'armor_knight': 'lib/assets/armor/armor_knight.png',
      'armor_crimson_guard': 'lib/assets/armor/armor_crimson_guard.png',
      'armor_demon': 'lib/assets/armor/armor_demon.png',
      'body_icefrost': 'lib/assets/armor/body_icefrost.png',
      'body_samurai': 'lib/assets/armor/body_samurai.png',

      // --- DAFTAR KULIT DASAR (SKINS) ---
      'default_skinboy': 'lib/assets/Body1Set/default_skinboy.png',
      'default_skingirl': 'lib/assets/Body1Set/default_skingirl.png',
      'skin_void': 'lib/assets/Body1Set/skin_void.png',
      'skin_glitch': 'lib/assets/Body1Set/skin_glitch.png',
      'skin_silver': 'lib/assets/Body1Set/skin_silver.png',
      'skin_blue_flare': 'lib/assets/Body1Set/skin_blue_flare.png',
      'skin_water_elemental': 'lib/assets/Body1Set/skin_water_elemental.png',

      // --- DAFTAR CELANA (PANTS) ---
      'pants_jeans': 'lib/assets/pants/pants_jeans.png',
      'skirt_student': 'lib/assets/pants/skirt_student.png',
      'boot_desertman': 'lib/assets/pants/boot_desertman.png',
      'pants_sparta': 'lib/assets/pants/pants_sparta.png',
      'skirt_red_mage': 'lib/assets/pants/skirt_red_mage.png',
      'pants_robot': 'lib/assets/pants/pants_robot.png',
      'pants_assassin': 'lib/assets/pants/pants_assasin.png',
      'pants_knight': 'lib/assets/pants/pants_knight.png',
      'boots_icefrost': 'lib/assets/pants/boots_icefrost.png',
      'boots_mage': 'lib/assets/pants/boots_mage.png',
      'boots_samurai': 'lib/assets/pants/boots_samurai.png',
      'skiullpants': 'lib/assets/pants/skiullpants.png',

      // --- DAFTAR PELIHARAAN (PETS) ---
      'gloop': 'lib/assets/pet/gloop.png',
      'armadillo': 'lib/assets/pet/armadillo_spebles.png',
      'spore_shroom': 'lib/assets/pet/Spore_shroom.png',
      'tardigrada': 'lib/assets/pet/Tardigrada.png',
      'raven': 'lib/assets/pet/raven.png',
      'axolotl_prism': 'lib/assets/pet/Axolotl_prism.png',
      'gearwing': 'lib/assets/pet/Gearwing.png',
      'eyeball_plant': 'lib/assets/pet/eyeball_plant.png',
      'giggling': 'lib/assets/pet/giggling.png',
      'brain_jar': 'lib/assets/pet/brain_jar.png',
      'lumi_cat': 'lib/assets/pet/lumi_cat.png',
      'magmus': 'lib/assets/pet/magmus.png',
      'glacier': 'lib/assets/pet/Glacier.png',
      'clockwork_jellyfish': 'lib/assets/pet/clockwork_jellyfish.png',
      'steam_jellyfish': 'lib/assets/pet/steam_jellyfish.png',
      'mimic_chest': 'lib/assets/pet/mimic_chest.png',
      'plague_rat': 'lib/assets/pet/plague_rat.png',
      'possessed_skull': 'lib/assets/pet/possed_skull.png',
      'iron_serpent': 'lib/assets/pet/iron_serpent.png',
      'meowmortis': 'lib/assets/pet/meowmortis.png',
      'pyra': 'lib/assets/pet/pyra.png',
      'obsidian_drake': 'lib/assets/pet/obsidian_drake.png',
      'nether_wasp': 'lib/assets/pet/nether_wasp.png',
      'lion_scorpion': 'lib/assets/pet/lion_scorpion.png',
      'void_cat_cube': 'lib/assets/pet/void_cat_cube.png',
      'void_feaster': 'lib/assets/pet/Void_feaster.png',
      'armored_bone_spider': 'lib/assets/pet/armored_bone_spider.png',

      // --- DAFTAR LATAR BELAKANG (WALLPAPER) ---
      'wallpaper_hutan': 'lib/assets/wallpaper/wallpaper hutan.png',
      'wallpaper_sparta': 'lib/assets/wallpaper/wallpaper sparta.png',
      'wallpaper_ice': 'lib/assets/wallpaper/walpaper_ice.png',
      'wallpaper_bawah_laut': 'lib/assets/wallpaper/wallpaper_bawah_laut.png',
      'wallpaper_dark_knight': 'lib/assets/wallpaper/wallpaper dark knight.png',
      'wallpapaer_undergrund': 'lib/assets/wallpaper/wallpapaer_undergrund.png',
      'wallpaper_castle_dark': 'lib/assets/wallpaper/wallpaper castle dark.png',
      'wallpaper_celestial': 'lib/assets/wallpaper/wallpaper_celestial.png',
      'wallpaper_towerdragon': 'lib/assets/wallpaper/wallpaper_towerdragon.png',
    };

    // Mencari kecocokan ID dengan daftar di atas. Jika tidak ketemu, kembalikan string kosong.
    return assetPaths[id] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // 1. Persiapan pengambilan path gambar untuk masing-masing tipe
    final bgPath = _getAssetPath('background', equippedItems['background'] ?? 'default');
    final headPath = _getAssetPath('head', equippedItems['head'] ?? 'none');
    final clothesPath = _getAssetPath('clothes', equippedItems['clothes'] ?? 'none');
    final pantsPath = _getAssetPath('pants', equippedItems['pants'] ?? 'none');
    final petPath = _getAssetPath('pet', equippedItems['pet'] ?? 'none');

    return Container(
      width: size,
      height: size,
      // clipBehavior antiAlias memastikan gambar yang melewati batas kotak bundar dipotong dengan rapi
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // Jika tidak ada background wallpaper, gunakan warna kotak abu-abu gelap
        color: showBackground && bgPath.isEmpty ? Color(0xFF1E1E2E) : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.15),
        border: showBackground
            ? Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10), width: AppColors.borderWidth)
            : null,
      ),
      // --- INI RAHASIANYA (STACK Z-INDEX) ---
      // Stack adalah widget yang memungkinkan kita menumpuk berlapis-lapis gambar
      // Yang dipanggil duluan akan berada di posisi paling bawah
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lapis 1 (Terbawah): Wallpaper Background
          if (showBackground && bgPath.isNotEmpty)
            Positioned.fill(
              child: Image.asset(
                bgPath,
                fit: BoxFit.cover,
                // Menggelapkan wallpaper sedikit agar karakternya lebih menonjol
                color: AppColors.textPrimary.withValues(alpha: 0.4),
                colorBlendMode: BlendMode.darken,
              ),
            ),

          // Lapis 2: Tubuh Dasar (Selalu body.png)
          // File png ini berisi bentuk siluet badan polos yang harus selalu ada
          Image.asset(
            'lib/assets/Body1Set/body.png',
            width: size * 0.9,
            height: size * 0.9,
            fit: BoxFit.contain, // Contain memastikan gambarnya tidak penyok
            // Jika gambarnya tidak sengaja terhapus, render kotak kosong saja agar tidak error
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),

          // Lapis 3, 4, 5: Celana, Baju, Wajah
          // Celana dipanggil dulu agar pinggangnya tertutup oleh baju jika bajunya panjang.
          // Kepala dipanggil terakhir agar rambutnya/helmnya menutupi kerah baju.
          if (pantsPath.isNotEmpty) _buildLayer(pantsPath, size * 0.9),
          if (clothesPath.isNotEmpty) _buildLayer(clothesPath, size * 0.9),
          if (headPath.isNotEmpty) _buildLayer(headPath, size * 0.9),

          // Lapis 6 (Teratas): Peliharaan (Pet)
          // Pet menggunakan skala yang sama karena filenya (seperti armadillo_spebles.png)
          // sudah diatur posisi X dan Y aslinya agar berada di sebelah karakter.
          if (petPath.isNotEmpty) _buildLayer(petPath, size * 0.9),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk memanggil widget Image
  Widget _buildLayer(String path, double layerSize) {
    return Image.asset(
      path,
      width: layerSize,
      height: layerSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(),
    );
  }
}
