import 'package:flutter/material.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';


enum AvatarTier { novice, veteran, elite, mythic }

class AvatarItem {
  final String id;
  final String name;
  final IconData icon; // Fallback
  final String? imagePath; // PNG Asset
  final Color color; // Fallback
  final String category;
  final int price;
  final AvatarTier tier;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.icon,
    this.imagePath,
    required this.color,
    required this.category,
    this.price = 0,
    this.tier = AvatarTier.novice,
  });

  Map<String, double> get passiveStats {
    if (id.startsWith('none_')) {
      return {'goldBoost': 0.0, 'xpBoost': 0.0, 'maxHp': 0.0};
    }
    
    double goldBoost = 0.0;
    double xpBoost = 0.0;
    double maxHp = 0.0;

    switch (category) {
      case 'Pet':
        switch (tier) {
          case AvatarTier.novice: goldBoost = 0.02; break;
          case AvatarTier.veteran: goldBoost = 0.05; break;
          case AvatarTier.elite: goldBoost = 0.10; break;
          case AvatarTier.mythic: goldBoost = 0.20; break;
        }
        break;
      case 'Body':
      case 'Body 1 Set':
        switch (tier) {
          case AvatarTier.novice: xpBoost = 0.02; break;
          case AvatarTier.veteran: xpBoost = 0.05; break;
          case AvatarTier.elite: xpBoost = 0.10; break;
          case AvatarTier.mythic: xpBoost = 0.20; break;
        }
        break;
      case 'Head':
        switch (tier) {
          case AvatarTier.novice: xpBoost = 0.01; maxHp = 2.0; break;
          case AvatarTier.veteran: xpBoost = 0.02; maxHp = 5.0; break;
          case AvatarTier.elite: xpBoost = 0.05; maxHp = 10.0; break;
          case AvatarTier.mythic: xpBoost = 0.10; maxHp = 20.0; break;
        }
        break;
      case 'Pants':
        switch (tier) {
          case AvatarTier.novice: maxHp = 1.0; break;
          case AvatarTier.veteran: maxHp = 3.0; break;
          case AvatarTier.elite: maxHp = 5.0; break;
          case AvatarTier.mythic: maxHp = 10.0; break;
        }
        break;
      default:
        break;
    }

    return {
      'goldBoost': goldBoost,
      'xpBoost': xpBoost,
      'maxHp': maxHp,
    };
  }

  String passiveDescription(BuildContext context) {
    final stats = passiveStats;
    final gold = stats['goldBoost'] ?? 0.0;
    final xp = stats['xpBoost'] ?? 0.0;
    final hp = stats['maxHp'] ?? 0.0;
    
    final l = context.l;
    return l.passiveDesc(gold, xp, hp);
  }
}

class AvatarData {
  static final List<AvatarItem> allItems = [
    // --- NOVICE (White/Gray) ---
    AvatarItem(id: 'none_head', name: 'Tanpa Topi', icon: Icons.do_not_disturb_alt, color: Colors.grey, category: 'Head', tier: AvatarTier.novice),
    // Default login heads (free, unlocked at character creation)
    AvatarItem(id: 'head_default_login_male1', name: 'Cowok Gaya 1', icon: Icons.face, imagePath: 'lib/assets/Head/head_default_login_male1.png', color: AppColors.textPrimary, category: 'Head', price: 0, tier: AvatarTier.novice),
    AvatarItem(id: 'head_default_login_male2', name: 'Cowok Gaya 2', icon: Icons.face, imagePath: 'lib/assets/Head/head_default_login_male2.png', color: AppColors.textPrimary, category: 'Head', price: 0, tier: AvatarTier.novice),
    AvatarItem(id: 'head_default_login_female1', name: 'Cewek Gaya 1', icon: Icons.face, imagePath: 'lib/assets/Head/head_default_login_female1.png', color: AppColors.textPrimary, category: 'Head', price: 0, tier: AvatarTier.novice),
    AvatarItem(id: 'head_default_login_female2', name: 'Cewek Gaya 2', icon: Icons.face, imagePath: 'lib/assets/Head/head_default_login_female2.png', color: AppColors.textPrimary, category: 'Head', price: 0, tier: AvatarTier.novice),
    AvatarItem(id: 'head_buddha', name: 'Head Buddha', icon: Icons.face, imagePath: 'lib/assets/Head/head_buddha.png', color: AppColors.textPrimary, category: 'Head', price: 150, tier: AvatarTier.novice),
    AvatarItem(id: 'head_samurai', name: 'Samurai Mask', icon: Icons.face, imagePath: 'lib/assets/Head/head_samurai.png', color: AppColors.textPrimary, category: 'Head', price: 300, tier: AvatarTier.novice),
    AvatarItem(id: 'head_desert_man', name: 'Desert Man', icon: Icons.face, imagePath: 'lib/assets/Head/head_Desert_man.png', color: AppColors.textPrimary, category: 'Head', price: 450, tier: AvatarTier.novice),
    
    AvatarItem(id: 'none_body', name: 'Tanpa Baju', icon: Icons.do_not_disturb_alt, color: Colors.grey, category: 'Body', tier: AvatarTier.novice),
    AvatarItem(id: 'outfit_cardigan_blue', name: 'Cardigan Biru', icon: Icons.checkroom, imagePath: 'lib/assets/armor/outfit_cardigan_blue.png', color: AppColors.textPrimary, category: 'Body', price: 200, tier: AvatarTier.novice),
    AvatarItem(id: 'outfit_student', name: 'Baju Sekolah', icon: Icons.school, imagePath: 'lib/assets/armor/outfit_student.png', color: AppColors.textPrimary, category: 'Body', price: 350, tier: AvatarTier.novice),
    AvatarItem(id: 'body_desertman', name: 'Desert Body', icon: Icons.checkroom, imagePath: 'lib/assets/armor/body_desertman.png', color: AppColors.textPrimary, category: 'Body', price: 500, tier: AvatarTier.novice),

    AvatarItem(id: 'none_pants', name: 'Tanpa Celana', icon: Icons.do_not_disturb_alt, color: Colors.grey, category: 'Pants', tier: AvatarTier.novice),
    AvatarItem(id: 'pants_jeans', name: 'Celana Jeans', icon: Icons.accessibility, imagePath: 'lib/assets/pants/pants_jeans.png', color: AppColors.textPrimary, category: 'Pants', price: 150, tier: AvatarTier.novice),
    AvatarItem(id: 'skirt_student', name: 'Rok Sekolah', icon: Icons.accessibility, imagePath: 'lib/assets/pants/skirt_student.png', color: AppColors.textPrimary, category: 'Pants', price: 300, tier: AvatarTier.novice),
    AvatarItem(id: 'boot_desertman', name: 'Boot Desert', icon: Icons.accessibility, imagePath: 'lib/assets/pants/boot_desertman.png', color: AppColors.textPrimary, category: 'Pants', price: 400, tier: AvatarTier.novice),

    AvatarItem(id: 'none_wallpaper', name: 'Tanpa Wallpaper', icon: Icons.do_not_disturb_alt, color: Colors.grey, category: 'Wallpaper', tier: AvatarTier.novice),
    AvatarItem(id: 'wallpaper_hutan', name: 'Magic Forest', icon: Icons.forest, imagePath: 'lib/assets/wallpaper/wallpaper hutan.png', color: AppColors.textPrimary, category: 'Wallpaper', price: 800, tier: AvatarTier.novice),

    // --- VETERAN (Blue) ---
    AvatarItem(id: 'head_barbarian', name: 'Barbarian Helm', icon: Icons.security, imagePath: 'lib/assets/Head/head_barbarian.png', color: Colors.blue, category: 'Head', price: 1200, tier: AvatarTier.veteran),
    AvatarItem(id: 'head_spartan', name: 'Spartan Helm', icon: Icons.security, imagePath: 'lib/assets/Head/head_spartan.png', color: Colors.blue, category: 'Head', price: 1800, tier: AvatarTier.veteran),
    AvatarItem(id: 'head_guard_helmet', name: 'Guard Helmet', icon: Icons.security, imagePath: 'lib/assets/Head/head_guard_helmet.png', color: Colors.blue, category: 'Head', price: 2200, tier: AvatarTier.veteran),
    AvatarItem(id: 'head_engineer', name: 'Engineer Goggles', icon: Icons.build, imagePath: 'lib/assets/Head/head_engineer.png', color: Colors.blue, category: 'Head', price: 3000, tier: AvatarTier.veteran),

    AvatarItem(id: 'armor_druid', name: 'Jubah Druid', icon: Icons.nature, imagePath: 'lib/assets/armor/armor_druid.png', color: Colors.blue, category: 'Body', price: 1500, tier: AvatarTier.veteran),
    AvatarItem(id: 'armor_executioner', name: 'Executioner', icon: Icons.visibility_off, imagePath: 'lib/assets/armor/armor_executioner.png', color: Colors.blue, category: 'Body', price: 2500, tier: AvatarTier.veteran),
    AvatarItem(id: 'armor_gladiator', name: 'Gladiator Armor', icon: Icons.shield, imagePath: 'lib/assets/armor/armor_gladiator.png', color: Colors.blue, category: 'Body', price: 3200, tier: AvatarTier.veteran),
    AvatarItem(id: 'body_orc', name: 'Orc Body', icon: Icons.checkroom, imagePath: 'lib/assets/Body1Set/body_orc.png', color: Colors.blue, category: 'Body', price: 3500, tier: AvatarTier.veteran),

    AvatarItem(id: 'pants_sparta', name: 'Pants Sparta', icon: Icons.accessibility, imagePath: 'lib/assets/pants/pants_sparta.png', color: Colors.blue, category: 'Pants', price: 1000, tier: AvatarTier.veteran),
    AvatarItem(id: 'skirt_red_mage', name: 'Red Mage Skirt', icon: Icons.accessibility, imagePath: 'lib/assets/pants/skirt_red_mage.png', color: Colors.blue, category: 'Pants', price: 1800, tier: AvatarTier.veteran),
    AvatarItem(id: 'pants_robot', name: 'Pants Robot', icon: Icons.android, imagePath: 'lib/assets/pants/pants_robot.png', color: Colors.blue, category: 'Pants', price: 2500, tier: AvatarTier.veteran),

    AvatarItem(id: 'wallpaper_sparta', name: 'Arena Sparta', icon: Icons.wallpaper, imagePath: 'lib/assets/wallpaper/wallpaper sparta.png', color: Colors.blue, category: 'Wallpaper', price: 2500, tier: AvatarTier.veteran),
    AvatarItem(id: 'wallpaper_ice', name: 'Ice Cavern', icon: Icons.ac_unit, imagePath: 'lib/assets/wallpaper/walpaper_ice.png', color: Colors.blue, category: 'Wallpaper', price: 3500, tier: AvatarTier.veteran),

    // --- ELITE (Purple) ---
    AvatarItem(id: 'head_assassin', name: 'Assassin Mask', icon: Icons.visibility_off, imagePath: 'lib/assets/Head/head_assassin.png', color: Colors.purple, category: 'Head', price: 6000, tier: AvatarTier.elite),
    AvatarItem(id: 'head_valkyrie', name: 'Valkyrie Helm', icon: Icons.face, imagePath: 'lib/assets/Head/head_valkyrie.png', color: Colors.purple, category: 'Head', price: 8500, tier: AvatarTier.elite),
    AvatarItem(id: 'head_mage', name: 'Mage Hood', icon: Icons.auto_awesome, imagePath: 'lib/assets/Head/head_mage.png', color: Colors.purple, category: 'Head', price: 10000, tier: AvatarTier.elite),
    AvatarItem(id: 'head_robot', name: 'Robot Core', icon: Icons.android, imagePath: 'lib/assets/Head/head_robot.png', color: Colors.purple, category: 'Head', price: 12000, tier: AvatarTier.elite),
    AvatarItem(id: 'head_engineerfm', name: 'Engineer FM', icon: Icons.build, imagePath: 'lib/assets/Head/head_engineerfm.png', color: Colors.purple, category: 'Head', price: 14000, tier: AvatarTier.elite),

    AvatarItem(id: 'armor_assassin', name: 'Assassin Gear', icon: Icons.security, imagePath: 'lib/assets/armor/armor_assassin.png', color: Colors.purple, category: 'Body', price: 7000, tier: AvatarTier.elite),
    AvatarItem(id: 'armor_red_mage', name: 'Red Mage Robe', icon: Icons.auto_awesome, imagePath: 'lib/assets/armor/armor_red_mage.png', color: Colors.purple, category: 'Body', price: 9500, tier: AvatarTier.elite),
    AvatarItem(id: 'armor_wizard_robe', name: 'Wizard Robe', icon: Icons.auto_awesome, imagePath: 'lib/assets/Body1Set/armor_wizard_robe.png', color: Colors.purple, category: 'Body', price: 11000, tier: AvatarTier.elite),
    AvatarItem(id: 'body_engineer', name: 'Engineer Body', icon: Icons.build, imagePath: 'lib/assets/Body1Set/body_engineer.png', color: Colors.purple, category: 'Body', price: 13000, tier: AvatarTier.elite),
    AvatarItem(id: 'body_mage', name: 'Mage Body', icon: Icons.auto_awesome, imagePath: 'lib/assets/armor/body_mage.png', color: Colors.purple, category: 'Body', price: 14500, tier: AvatarTier.elite),
    AvatarItem(id: 'skull_mage_armor', name: 'Skull Armor', icon: Icons.auto_awesome, imagePath: 'lib/assets/armor/skull_mage_armor.png', color: Colors.purple, category: 'Body', price: 15000, tier: AvatarTier.elite),

    AvatarItem(id: 'pants_assassin', name: 'Pants Assassin', icon: Icons.accessibility, imagePath: 'lib/assets/pants/pants_assasin.png', color: Colors.purple, category: 'Pants', price: 6000, tier: AvatarTier.elite),
    AvatarItem(id: 'pants_knight', name: 'Pants Knight', icon: Icons.shield, imagePath: 'lib/assets/pants/pants_knight.png', color: Colors.purple, category: 'Pants', price: 8000, tier: AvatarTier.elite),
    AvatarItem(id: 'boots_icefrost', name: 'Icefrost Boots', icon: Icons.ac_unit, imagePath: 'lib/assets/pants/boots_icefrost.png', color: Colors.purple, category: 'Pants', price: 10000, tier: AvatarTier.elite),
    AvatarItem(id: 'boots_mage', name: 'Mage Boots', icon: Icons.auto_awesome, imagePath: 'lib/assets/pants/boots_mage.png', color: Colors.purple, category: 'Pants', price: 12000, tier: AvatarTier.elite),
    AvatarItem(id: 'boots_samurai', name: 'Samurai Boots', icon: Icons.accessibility, imagePath: 'lib/assets/pants/boots_samurai.png', color: Colors.purple, category: 'Pants', price: 14000, tier: AvatarTier.elite),
    AvatarItem(id: 'skiullpants', name: 'Skull Pants', icon: Icons.auto_awesome, imagePath: 'lib/assets/pants/skiullpants.png', color: Colors.purple, category: 'Pants', price: 15000, tier: AvatarTier.elite),

    AvatarItem(id: 'wallpaper_bawah_laut', name: 'Deep Ocean', icon: Icons.water, imagePath: 'lib/assets/wallpaper/wallpaper_bawah_laut.png', color: Colors.purple, category: 'Wallpaper', price: 8000, tier: AvatarTier.elite),
    AvatarItem(id: 'wallpaper_dark_knight', name: 'Dungeon Knight', icon: Icons.castle, imagePath: 'lib/assets/wallpaper/wallpaper dark knight.png', color: Colors.purple, category: 'Wallpaper', price: 12000, tier: AvatarTier.elite),
    AvatarItem(id: 'wallpapaer_undergrund', name: 'Underground', icon: Icons.terrain, imagePath: 'lib/assets/wallpaper/wallpapaer_undergrund.png', color: Colors.purple, category: 'Wallpaper', price: 15000, tier: AvatarTier.elite),

    // --- MYTHIC (Gold) ---
    AvatarItem(id: 'none_skin', name: 'Tanpa Kostum', icon: Icons.do_not_disturb_alt, color: Colors.grey, category: 'Body 1 Set', tier: AvatarTier.novice),
    AvatarItem(id: 'default_skinboy', name: 'Baju Cowok', icon: Icons.checkroom, imagePath: 'lib/assets/Body1Set/default_skinboy.png', color: AppColors.textPrimary, category: 'Body 1 Set', price: 0, tier: AvatarTier.novice),
    AvatarItem(id: 'default_skingirl', name: 'Baju Cewek', icon: Icons.checkroom, imagePath: 'lib/assets/Body1Set/default_skingirl.png', color: AppColors.textPrimary, category: 'Body 1 Set', price: 0, tier: AvatarTier.novice),
    AvatarItem(id: 'skin_void', name: 'Void Entity', icon: Icons.face, imagePath: 'lib/assets/Body1Set/skin_void.png', color: Colors.amber, category: 'Body 1 Set', price: 30000, tier: AvatarTier.mythic),
    AvatarItem(id: 'skin_glitch', name: 'Glitch Skin', icon: Icons.face, imagePath: 'lib/assets/Body1Set/skin_glitch.png', color: Colors.amber, category: 'Body 1 Set', price: 35000, tier: AvatarTier.mythic),
    AvatarItem(id: 'skin_silver', name: 'Silver Skin', icon: Icons.face, imagePath: 'lib/assets/Body1Set/skin_silver.png', color: Colors.amber, category: 'Body 1 Set', price: 25000, tier: AvatarTier.mythic),
    AvatarItem(id: 'skin_blue_flare', name: 'Blue Flare', icon: Icons.face, imagePath: 'lib/assets/Body1Set/skin_blue_flare.png', color: Colors.amber, category: 'Body 1 Set', price: 40000, tier: AvatarTier.mythic),
    AvatarItem(id: 'skin_water_elemental', name: 'Water Spirit', icon: Icons.face, imagePath: 'lib/assets/Body1Set/skin_water_elemental.png', color: Colors.amber, category: 'Body 1 Set', price: 50000, tier: AvatarTier.mythic),

    AvatarItem(id: 'head_lich', name: 'Lich King', icon: Icons.face, imagePath: 'lib/assets/Head/head_lich.png', color: Colors.amber, category: 'Head', price: 25000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_darkvoid', name: 'Dark Void', icon: Icons.face, imagePath: 'lib/assets/Head/head_darkvoid.png', color: Colors.amber, category: 'Head', price: 30000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_bluepyro', name: 'Blue Pyro', icon: Icons.face, imagePath: 'lib/assets/Head/head_bluepyro.png', color: Colors.amber, category: 'Head', price: 35000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_icefrost', name: 'Icefrost Mask', icon: Icons.face, imagePath: 'lib/assets/Head/head_icefrost.png', color: Colors.amber, category: 'Head', price: 38000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_queen', name: 'Queen Crown', icon: Icons.face, imagePath: 'lib/assets/Head/head_queen.png', color: Colors.amber, category: 'Head', price: 40000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_silverman', name: 'Silver Head', icon: Icons.face, imagePath: 'lib/assets/Head/head_silverman.png', color: Colors.amber, category: 'Head', price: 45000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_water', name: 'Water Crown', icon: Icons.face, imagePath: 'lib/assets/Head/head_water.png', color: Colors.amber, category: 'Head', price: 48000, tier: AvatarTier.mythic),
    AvatarItem(id: 'head_glitch', name: 'Glitch Head', icon: Icons.face, imagePath: 'lib/assets/Head/Head_glitch.png', color: Colors.amber, category: 'Head', price: 50000, tier: AvatarTier.mythic),

    AvatarItem(id: 'armor_knight', name: 'Knight Armor', icon: Icons.shield, imagePath: 'lib/assets/armor/armor_knight.png', color: Colors.amber, category: 'Body', price: 25000, tier: AvatarTier.mythic),
    AvatarItem(id: 'armor_crimson_guard', name: 'Crimson Guard', icon: Icons.shield, imagePath: 'lib/assets/armor/armor_crimson_guard.png', color: Colors.amber, category: 'Body', price: 30000, tier: AvatarTier.mythic),
    AvatarItem(id: 'armor_demon', name: 'Demon Plate', icon: Icons.whatshot, imagePath: 'lib/assets/armor/armor_demon.png', color: Colors.amber, category: 'Body', price: 45000, tier: AvatarTier.mythic),
    AvatarItem(id: 'body_icefrost', name: 'Icefrost Body', icon: Icons.ac_unit, imagePath: 'lib/assets/armor/body_icefrost.png', color: Colors.amber, category: 'Body', price: 50000, tier: AvatarTier.mythic),
    AvatarItem(id: 'body_samurai', name: 'Samurai Armor', icon: Icons.shield, imagePath: 'lib/assets/armor/body_samurai.png', color: Colors.amber, category: 'Body', price: 55000, tier: AvatarTier.mythic),

    AvatarItem(id: 'wallpaper_castle_dark', name: 'Dark Castle', icon: Icons.wallpaper, imagePath: 'lib/assets/wallpaper/wallpaper castle dark.png', color: Colors.amber, category: 'Wallpaper', price: 25000, tier: AvatarTier.mythic),
    AvatarItem(id: 'wallpaper_celestial', name: 'Celestial Altar', icon: Icons.wallpaper, imagePath: 'lib/assets/wallpaper/wallpaper_celestial.png', color: Colors.amber, category: 'Wallpaper', price: 35000, tier: AvatarTier.mythic),
    AvatarItem(id: 'wallpaper_towerdragon', name: 'Dragon Tower', icon: Icons.wallpaper, imagePath: 'lib/assets/wallpaper/wallpaper_towerdragon.png', color: Colors.amber, category: 'Wallpaper', price: 50000, tier: AvatarTier.mythic),

    // --- PETS ---
    AvatarItem(id: 'none_pet', name: 'Tidak Ada', icon: Icons.do_not_disturb_alt, color: Colors.grey, category: 'Pet', tier: AvatarTier.novice),
    AvatarItem(id: 'gloop', name: 'Slime Gloop', icon: Icons.pets, imagePath: 'lib/assets/pet/gloop.png', color: AppColors.textPrimary, category: 'Pet', price: 350, tier: AvatarTier.novice),
    AvatarItem(id: 'armadillo', name: 'Armadillo', icon: Icons.pets, imagePath: 'lib/assets/pet/armadillo_spebles.png', color: AppColors.textPrimary, category: 'Pet', price: 450, tier: AvatarTier.novice),
    AvatarItem(id: 'spore_shroom', name: 'Spore Shroom', icon: Icons.pets, imagePath: 'lib/assets/pet/Spore_shroom.png', color: AppColors.textPrimary, category: 'Pet', price: 600, tier: AvatarTier.novice),
    AvatarItem(id: 'tardigrada', name: 'Tardigrada', icon: Icons.pets, imagePath: 'lib/assets/pet/Tardigrada.png', color: AppColors.textPrimary, category: 'Pet', price: 750, tier: AvatarTier.novice),
    AvatarItem(id: 'raven', name: 'Raven', icon: Icons.pets, imagePath: 'lib/assets/pet/raven.png', color: AppColors.textPrimary, category: 'Pet', price: 800, tier: AvatarTier.novice),
    
    AvatarItem(id: 'axolotl_prism', name: 'Axolotl Prism', icon: Icons.pets, imagePath: 'lib/assets/pet/Axolotl_prism.png', color: Colors.blue, category: 'Pet', price: 1500, tier: AvatarTier.veteran),
    AvatarItem(id: 'gearwing', name: 'Gearwing', icon: Icons.pets, imagePath: 'lib/assets/pet/Gearwing.png', color: Colors.blue, category: 'Pet', price: 2000, tier: AvatarTier.veteran),
    AvatarItem(id: 'eyeball_plant', name: 'Eyeball Plant', icon: Icons.pets, imagePath: 'lib/assets/pet/eyeball_plant.png', color: Colors.blue, category: 'Pet', price: 2200, tier: AvatarTier.veteran),
    AvatarItem(id: 'giggling', name: 'Giggling Bag', icon: Icons.pets, imagePath: 'lib/assets/pet/giggling.png', color: Colors.blue, category: 'Pet', price: 2500, tier: AvatarTier.veteran),
    AvatarItem(id: 'brain_jar', name: 'Brain Jar', icon: Icons.pets, imagePath: 'lib/assets/pet/brain_jar.png', color: Colors.blue, category: 'Pet', price: 3000, tier: AvatarTier.veteran),
    AvatarItem(id: 'lumi_cat', name: 'Lumi Cat', icon: Icons.pets, imagePath: 'lib/assets/pet/lumi_cat.png', color: Colors.blue, category: 'Pet', price: 3500, tier: AvatarTier.veteran),
    
    AvatarItem(id: 'magmus', name: 'Magmus', icon: Icons.pets, imagePath: 'lib/assets/pet/magmus.png', color: Colors.purple, category: 'Pet', price: 6000, tier: AvatarTier.elite),
    AvatarItem(id: 'glacier', name: 'Glacier', icon: Icons.pets, imagePath: 'lib/assets/pet/Glacier.png', color: Colors.purple, category: 'Pet', price: 7500, tier: AvatarTier.elite),
    AvatarItem(id: 'clockwork_jellyfish', name: 'Clockwork Jelly', icon: Icons.pets, imagePath: 'lib/assets/pet/clockwork_jellyfish.png', color: Colors.purple, category: 'Pet', price: 8000, tier: AvatarTier.elite),
    AvatarItem(id: 'steam_jellyfish', name: 'Steam Jelly', icon: Icons.pets, imagePath: 'lib/assets/pet/steam_jellyfish.png', color: Colors.purple, category: 'Pet', price: 8500, tier: AvatarTier.elite),
    AvatarItem(id: 'mimic_chest', name: 'Mimic Chest', icon: Icons.pets, imagePath: 'lib/assets/pet/mimic_chest.png', color: Colors.purple, category: 'Pet', price: 9000, tier: AvatarTier.elite),
    AvatarItem(id: 'plague_rat', name: 'Plague Rat', icon: Icons.pets, imagePath: 'lib/assets/pet/plague_rat.png', color: Colors.purple, category: 'Pet', price: 9500, tier: AvatarTier.elite),
    AvatarItem(id: 'possessed_skull', name: 'Possessed Skull', icon: Icons.pets, imagePath: 'lib/assets/pet/possed_skull.png', color: Colors.purple, category: 'Pet', price: 10000, tier: AvatarTier.elite),
    AvatarItem(id: 'iron_serpent', name: 'Iron Serpent', icon: Icons.pets, imagePath: 'lib/assets/pet/iron_serpent.png', color: Colors.purple, category: 'Pet', price: 12000, tier: AvatarTier.elite),
    AvatarItem(id: 'meowmortis', name: 'Meowmortis', icon: Icons.pets, imagePath: 'lib/assets/pet/meowmortis.png', color: Colors.purple, category: 'Pet', price: 15000, tier: AvatarTier.elite),
    
    AvatarItem(id: 'pyra', name: 'Pyra Phoenix', icon: Icons.pets, imagePath: 'lib/assets/pet/pyra.png', color: Colors.amber, category: 'Pet', price: 25000, tier: AvatarTier.mythic),
    AvatarItem(id: 'obsidian_drake', name: 'Obsidian Drake', icon: Icons.pets, imagePath: 'lib/assets/pet/obsidian_drake.png', color: Colors.amber, category: 'Pet', price: 35000, tier: AvatarTier.mythic),
    AvatarItem(id: 'nether_wasp', name: 'Nether Wasp', icon: Icons.pets, imagePath: 'lib/assets/pet/nether_wasp.png', color: Colors.amber, category: 'Pet', price: 40000, tier: AvatarTier.mythic),
    AvatarItem(id: 'lion_scorpion', name: 'Manticore', icon: Icons.pets, imagePath: 'lib/assets/pet/lion_scorpion.png', color: Colors.amber, category: 'Pet', price: 45000, tier: AvatarTier.mythic),
    AvatarItem(id: 'void_cat_cube', name: 'Void Cat Cube', icon: Icons.pets, imagePath: 'lib/assets/pet/void_cat_cube.png', color: Colors.amber, category: 'Pet', price: 50000, tier: AvatarTier.mythic),
    AvatarItem(id: 'void_feaster', name: 'Void Feaster', icon: Icons.pets, imagePath: 'lib/assets/pet/Void_feaster.png', color: Colors.amber, category: 'Pet', price: 55000, tier: AvatarTier.mythic),
    AvatarItem(id: 'armored_bone_spider', name: 'Bone Spider', icon: Icons.pets, imagePath: 'lib/assets/pet/armored_bone_spider.png', color: Colors.amber, category: 'Pet', price: 65000, tier: AvatarTier.mythic),
  ];

  static Map<String, double> getEquippedStats(Map<String, String> equipped) {
    double goldBoost = 0.0;
    double xpBoost = 0.0;
    double maxHpBoost = 0.0;

    for (var itemId in equipped.values) {
      if (itemId.isEmpty || itemId.startsWith('none_')) continue;
      final item = allItems.firstWhere(
        (element) => element.id == itemId,
        orElse: () => const AvatarItem(
          id: '',
          name: '',
          icon: Icons.error,
          color: Colors.transparent,
          category: '',
        ),
      );
      if (item.id.isNotEmpty) {
        final stats = item.passiveStats;
        goldBoost += stats['goldBoost'] ?? 0.0;
        xpBoost += stats['xpBoost'] ?? 0.0;
        maxHpBoost += stats['maxHp'] ?? 0.0;
      }
    }

    return {
      'goldBoost': goldBoost,
      'xpBoost': xpBoost,
      'maxHp': maxHpBoost,
    };
  }
}
