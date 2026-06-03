// ============================================================
// APP LOCALE — Single source of truth untuk semua string UI
// Mendukung: Bahasa Indonesia (id) & English (en)
// ============================================================

enum AppLang { id, en }

class L {
  final AppLang lang;
  const L(this.lang);

  bool get isEn => lang == AppLang.en;

  // ── Generic helper ─────────────────────────────────────
  String get(String id, String en) => isEn ? en : id;

  // ════════════════════════════════════════════════════════
  //  NAV & TABS
  // ════════════════════════════════════════════════════════
  String get navHome          => get('Beranda', 'Home');
  String get navDaily         => get('Harian', 'Daily');
  String get navStats         => get('Statistik', 'Stats');
  String get navProfile       => get('Profil', 'Profile');

  // ════════════════════════════════════════════════════════
  //  KATEGORI
  // ════════════════════════════════════════════════════════
  String get catStrength      => get('Kekuatan', 'Strength');
  String get catDefense       => get('Pertahanan', 'Defense');
  String get catIntelligence  => get('Kecerdasan', 'Intelligence');
  String get catAgility       => get('Kelincahan', 'Agility');
  String get catVitality      => get('Vitalitas', 'Vitality');

  String catName(String key) {
    switch (key) {
      case 'Strength':    return catStrength;
      case 'Defense':     return catDefense;
      case 'Intelligence':return catIntelligence;
      case 'Agility':     return catAgility;
      case 'Vitality':    return catVitality;
      default:            return key;
    }
  }

  String get catDescStrength    => get('Fisik & Olahraga',       'Physical & Sports');
  String get catDescDefense     => get('Mental & Refleksi',       'Mental & Reflection');
  String get catDescIntelligence=> get('Belajar & Pengetahuan',   'Learning & Knowledge');
  String get catDescAgility     => get('Kecepatan & Kegesitan',   'Speed & Agility');
  String get catDescVitality    => get('Kesehatan & Tidur',       'Health & Sleep');

  String catDesc(String key) {
    switch (key) {
      case 'Strength':    return catDescStrength;
      case 'Defense':     return catDescDefense;
      case 'Intelligence':return catDescIntelligence;
      case 'Agility':     return catDescAgility;
      case 'Vitality':    return catDescVitality;
      default:            return key;
    }
  }

  // Category Benefits
  List<String> catBenefits(String key) {
    switch (key) {
      case 'Strength':
        return isEn ? [
          'Stronger & more energetic body',
          'Increased muscle mass',
          'Boosted confidence',
          'Better metabolism',
        ] : [
          'Tubuh lebih kuat & bertenaga',
          'Massa otot meningkat',
          'Kepercayaan diri naik',
          'Metabolisme lebih baik',
        ];
      case 'Defense':
        return isEn ? [
          'More stable mental state',
          'Less prone to burnout',
          'Better emotional management',
          'Improved focus & concentration',
        ] : [
          'Mental lebih stabil',
          'Tidak mudah burnout',
          'Pengelolaan emosi lebih baik',
          'Fokus & konsentrasi meningkat',
        ];
      case 'Intelligence':
        return isEn ? [
          'Faster learning ability',
          'Sharper problem solving',
          'Developing technical skills',
          'Increased creativity',
        ] : [
          'Kemampuan belajar lebih cepat',
          'Problem solving lebih tajam',
          'Skill teknis berkembang',
          'Kreativitas meningkat',
        ];
      case 'Vitality':
        return isEn ? [
          'Stable energy throughout the day',
          'Faster recovery',
          'Strong body immunity',
          'Always positive mood',
        ] : [
          'Energi stabil sepanjang hari',
          'Pemulihan lebih cepat',
          'Imunitas tubuh kuat',
          'Mood selalu positif',
        ];
      case 'Agility':
        return isEn ? [
          'Increased stamina & endurance',
          'More agile body',
          'Healthy cardiovascular',
          'Improved reflexes & speed',
        ] : [
          'Stamina & daya tahan naik',
          'Tubuh lebih gesit',
          'Kardiovaskular sehat',
          'Refleks & kecepatan meningkat',
        ];
      default:
        return [];
    }
  }

  // Category Attribute Bonus
  String catAttrBonus(String key) {
    switch (key) {
      case 'Strength':    return isEn ? 'STR +XP every task completed' : 'STR +XP setiap task selesai';
      case 'Defense':     return isEn ? 'DEF +XP every task completed' : 'DEF +XP setiap task selesai';
      case 'Intelligence':return isEn ? 'INT +XP every task completed' : 'INT +XP setiap task selesai';
      case 'Vitality':    return isEn ? 'VIT +XP & Energy +10 every task completed' : 'VIT +XP & Energy +10 setiap task selesai';
      case 'Agility':     return isEn ? 'AGI +XP every task completed' : 'AGI +XP setiap task selesai';
      default:            return '';
    }
  }

  // Category Detail Screen
  String get catDetailInfo              => get('Info', 'Info');
  String get catDetailRecommendations   => get('Rekomendasi', 'Recommendations');
  String get catDetailActiveTasks       => get('Task Aktif', 'Active Tasks');
  String get catDetailAbout             => get('Tentang', 'About');
  String get catDetailBenefits          => get('Manfaat', 'Benefits');
  String get catDetailAttributeBonus    => get('Attribute Bonus', 'Attribute Bonus');
  String get catDetailAddTask           => get('+ Tambah', '+ Add');
  String catDetailNoActiveTasks(String category) => isEn 
    ? 'No active tasks in $category'
    : 'Tidak ada task aktif di $category';
  String get catDetailOpenRecommendations => get('Buka tab Rekomendasi untuk menambah task', 'Open Recommendations tab to add tasks');
  String get catDetailCursedTask        => get('⚠️ CURSED  •  +25% Durasi', '⚠️ CURSED  •  +25% Duration');
  String get catDetailTimerRunning      => get(' Jalan', ' Running');
  String get catDetailStart             => get(' Start', ' Start');
  String get catDetailDone              => get(' Selesai', ' Done');

  // ════════════════════════════════════════════════════════
  //  CLASS NAMES (RPG)
  // ════════════════════════════════════════════════════════
  String get classWarrior   => get('PRAJURIT', 'WARRIOR');
  String get classPaladin   => get('PALADIN',  'PALADIN');
  String get classArchmage  => get('ARCHMAGE', 'ARCHMAGE');
  String get classAssassin  => get('ASSASSIN', 'ASSASSIN');
  String get classDruid     => get('DRUID',    'DRUID');

  String className(String key) {
    switch (key) {
      case 'Strength':    return classWarrior;
      case 'Defense':     return classPaladin;
      case 'Intelligence':return classArchmage;
      case 'Agility':     return classAssassin;
      case 'Vitality':    return classDruid;
      default:            return key;
    }
  }

  // ════════════════════════════════════════════════════════
  //  DIFFICULTY
  // ════════════════════════════════════════════════════════
  List<String> get difficultyLabels => isEn
      ? ['Easy', 'Normal', 'Hard', 'Extreme']
      : ['Mudah', 'Normal', 'Sulit', 'Ekstrem'];

  String diffLabel(int index) => difficultyLabels[index.clamp(0, 3)];

  // ════════════════════════════════════════════════════════
  //  FREQUENCY
  // ════════════════════════════════════════════════════════
  String get freqDaily        => get('Harian',    'Daily');
  String get freqWeekly       => get('Mingguan',  'Weekly');
  String get freqDailyDesc    => get('Reset tiap hari',  'Resets each day');
  String get freqWeeklyDesc   => get('Deadline 7 hari',  '7-day deadline');

  // ════════════════════════════════════════════════════════
  //  PROOF TYPES
  // ════════════════════════════════════════════════════════
  String get proofNone        => get('Tidak Ada', 'None');
  String get proofPhoto       => get('Foto',      'Photo');
  String get proofText        => get('Tulisan',   'Text');

  String proofLabel(String type) {
    switch (type) {
      case 'photo': return proofPhoto;
      case 'text':  return proofText;
      default:      return proofNone;
    }
  }

  // ════════════════════════════════════════════════════════
  //  HOME SCREEN
  // ════════════════════════════════════════════════════════
  String get homeGreetingMorning  => get('Selamat Pagi',  'Good Morning');
  String get homeGreetingAfternoon=> get('Selamat Siang', 'Good Afternoon');
  String get homeGreetingEvening  => get('Selamat Malam', 'Good Evening');
  String get homeDailyProgress    => get('Progress Harian',  'Daily Progress');
  String get homeQuestBoard       => get('Papan Quest',       'Quest Board');
  String get homeAccept           => get('Terima',            'Accept');
  String get homeViewAll          => get('Lihat Semua',       'View All');
  String get homeRecentActivity   => get('Aktivitas Terkini', 'Recent Activity');
  String get homeMotivation       => get('Jangan menyerah, Hero!', 'Keep going, Hero!');
  String get homeDanger           => get('⚠️ HP Kritis! Segera selesaikan misimu!', '⚠️ Critical HP! Complete your missions now!');
  String get homeTasksDone        => get('selesai', 'done');
  String get homeTasksOf          => get('dari',   'of');
  String get homeNoTasks          => get('Belum ada tugas hari ini', 'No tasks today');

  // ════════════════════════════════════════════════════════
  //  DAILY SCREEN
  // ════════════════════════════════════════════════════════
  String get dailyTitle           => get('Quest Aktif',     'Active Quests');
  String get dailyEmpty           => get('Tidak ada quest aktif hari ini.', 'No active quests today.');
  String get dailyStart           => get('Mulai',    'Start');
  String get dailyPause           => get('Jeda',     'Pause');
  String get dailyResume          => get('Lanjut',   'Resume');
  String get dailyComplete        => get('Selesai',  'Complete');
  String get dailyFailed          => get('Gagal',    'Failed');
  String get dailyPending         => get('Pending',  'Pending');
  String get dailyRunning         => get('Berjalan', 'Running');
  String get dailyCompleted       => get('Selesai',  'Completed');
  String get dailySubmitProof     => get('Upload Bukti',    'Upload Proof');
  String get dailyAddQuest        => get('Tambah Quest',    'Add Quest');
  String get dailyFilterAll       => get('Semua',   'All');
  String get dailyFilterActive    => get('Aktif',   'Active');
  String get dailyFilterDone      => get('Selesai', 'Done');

  // ════════════════════════════════════════════════════════
  //  STATISTIC SCREEN
  // ════════════════════════════════════════════════════════
  String get statsTabPersonal     => get('Statistik Saya',    'My Stats');
  String get statsTabLeaderboard  => get('Peringkat Global',  'Global Ranking');
  String get statsLevel           => get('Level',     'Level');
  String get statsRank            => get('Peringkat', 'Rank');
  String get statsStreak          => get('Streak',    'Streak');
  String get statsLongestStreak   => get('Streak Terpanjang', 'Longest Streak');
  String get statsTotalDone       => get('Total Selesai',     'Total Done');
  String get statsTotalFailed     => get('Total Gagal',       'Total Failed');
  String get statsGold            => get('Gold',  'Gold');
  String get statsHP              => get('HP',    'HP');
  String get statsShare           => get('Bagikan Kartu',     'Share Card');
  String get statsHistory         => get('Lihat Riwayat',     'View History');
  String get statsAttributes      => get('Atribut',       'Attributes');
  String get statsRankRoadmap     => get('Peta Peringkat', 'Rank Roadmap');
  String get statsDays            => get('hari', 'days');
  String get statsLeaderboard     => get('Hall of Champions', 'Hall of Champions');
  String get statsYou             => get('(Kamu)',    '(You)');
  String get statsKamu            => get('Kamu',      'You');
  String get statsViewProfile     => get('Lihat Profil', 'View Profile');
  
  // Missing translations for statistic screen and badges
  String get statsSelesai         => get('Selesai', 'Completed');
  String get statsGagal           => get('Gagal', 'Failed');
  String get statsLongest         => get('Terpanjang', 'Longest');
  String get statsTitleBasedOn    => get('Gelar berdasarkan atribut tertinggimu', 'Title based on your highest attribute');
  String get statsLogHistory      => get('Log Riwayat Task', 'Task History Log');
  String get statsViewAchievements=> get('Lihat semua pencapaian Anda', 'View all your achievements');
  String get statsNoBadge         => get('Belum ada badge yang dipasang', 'No badges equipped');
  String get statsRankJourney     => get('Perjalanan Rank', 'Rank Journey');
  String get statsUnlocked        => get('Terbuka!', 'Unlocked!');
  String get statsPrepareImage    => get('Menyiapkan gambar kartu karakter...', 'Preparing character card image...');

  // ════════════════════════════════════════════════════════
  //  BADGE SCREEN / CARD
  // ════════════════════════════════════════════════════════
  String get badgeUnlocked        => get('Terbuka!', 'Unlocked!');
  String get badgeUnequip         => get('Dilepas', 'Unequip');
  String get badgeEquip           => get('Pakai', 'Equip');
  String get badgeClaim           => get('Klaim', 'Claim');

  // ════════════════════════════════════════════════════════
  //  RANK & LEVEL UP OVERLAY
  // ════════════════════════════════════════════════════════
  String get notifRankUpTitle     => get('NAIK RANK!', 'RANK UP!');
  String notifRankUpBody(String r)=> get('Kamu telah mencapai Rank $r', 'You have reached Rank $r');
  String get notifLevelUpTitle    => get('NAIK LEVEL!', 'LEVEL UP!');
  String notifLevelUpBody(int l)  => get('Kamu telah mencapai Level $l', 'You have reached Level $l');
  String get notifAwesome         => get('MANTAP', 'AWESOME');

  // Dynamic title
  String dynamicTitle(String key) {
    if (isEn) return key; // EN uses the original English keys
    switch (key) {
      case 'The Beginner':       return 'Si Pemula';
      case 'The Iron Warrior':   return 'Prajurit Besi';
      case 'The Iron Tank':      return 'Tameng Besi';
      case 'The Wise Strategist':return 'Ahli Strategi';
      case 'The Undying':        return 'Sang Abadi';
      case 'The Swift Shadow':   return 'Bayangan Kilat';
      case 'The Adventurer':     return 'Si Petualang';
      default:                   return key;
    }
  }

  // ════════════════════════════════════════════════════════
  //  PROFILE / SETTINGS
  // ════════════════════════════════════════════════════════
  String get profileTitle         => get('Profil',       'Profile');
  String get profileSettings      => get('Pengaturan',   'Settings');
  String get profileTheme         => get('Tema Tampilan','Theme Display');
  String get profileLogout        => get('Keluar',       'Logout');

  // ════════════════════════════════════════════════════════
  //  THEME SELECTOR SCREEN
  // ════════════════════════════════════════════════════════
  String get themeTitle           => get('Pilih Tema', 'Choose Theme');
  String get themeSubtitle        => get('🎨 Sesuaikan Petualanganmu', '🎨 Customize Your Adventure');
  String get themeDesc            => get('Pilih tema yang sesuai dengan gayamu', 'Choose a theme that matches your style');
  String get themeTipTitle        => get('Tip Tema', 'Theme Tip');
  String get themeTipDesc         => get('Preferensi tema akan disimpan secara otomatis dan diterapkan ke seluruh aplikasi!', 'Your theme preference is saved automatically and will be applied across the entire app!');
  String get profileEditName      => get('Ubah Nama',    'Edit Name');
  String get profileChangeAvatar  => get('Ganti Avatar', 'Change Avatar');
  String get profileSound         => get('Efek Suara',   'Sound Effects');
  String get profileSoundOn       => get('Aktif',        'On');
  String get profileSoundOff      => get('Mati',         'Off');
  String get profileResetTutorial => get('Reset Panduan Misi',   'Reset Tutorial Guide');
  String get profileLanguage      => get('Bahasa / Language',    'Language / Bahasa');
  String get profileLangID        => get('🇮🇩 Indonesia',         '🇮🇩 Indonesia');
  String get profileLangEN        => get('🇬🇧 English',           '🇬🇧 English');
  String get profileCharacter     => get('Karakter',             'Character');
  String get profileTabBadges     => get('Badges',               'Badges');
  String get profileTabAvatar     => get('Avatar',               'Avatar');
  String get profileTabItems      => get('Items',                'Items');
  String profileInsufficientCoins(int price) =>
      get('Koin tidak cukup! Butuh $price koin.', 'Not enough coins! Need $price coins.');
  String get profileInsufficientGold =>
      get('Gold tidak cukup!', 'Not enough Gold!');
  String get profileHpRestored =>
      get('HP dipulihkan! (+30 HP)', 'HP restored! (+30 HP)');
  String get profileXpBonusActive =>
      get('Bonus XP 2x Aktif selama 1 jam!', '2x XP bonus active for 1 hour!');

  // ════════════════════════════════════════════════════════
  //  ADD TASK SCREEN
  // ════════════════════════════════════════════════════════
  String get addTaskTitle         => get('Tambah Task',           'Add Task');
  String get addTaskTitleField    => get('Judul Task',            'Task Title');
  String get addTaskTitleHint     => get('Contoh: Push up 30x',  'Example: 30 push-ups');
  String get addTaskNotes         => get('Catatan (opsional)',    'Notes (optional)');
  String get addTaskNotesHint     => get('Tambahkan catatan...',  'Add notes...');
  String get addTaskCategory      => get('Kategori',              'Category');
  String get addTaskDifficulty    => get('Difficulty',            'Difficulty');
  String get addTaskFrequency     => get('Frekuensi',             'Frequency');
  String get addTaskDuration      => get('Durasi Timer',          'Timer Duration');
  String get addTaskDurationNone  => get('No Timer',              'No Timer');
  String get addTaskDurationHint  => get('Klik untuk atur durasi pengerjaan', 'Tap to set task duration');
  String get addTaskProof         => get('Bukti Penyelesaian',    'Completion Proof');
  String get addTaskProofHint     => get('Diperlukan setelah task selesai', 'Required after task completion');
  String get addTaskDeadline      => get('Deadline',              'Deadline');
  String get addTaskSubmit        => get('Buat Task',             'Create Task');
  String get addTaskSuccess       => get('Task ditambahkan!',     'Task created!');

  // Quest ideas (per category)
  List<String> questIdeas(String category) {
    if (isEn) {
      switch (category) {
        case 'Strength':    return ['20 push-ups', 'Lift weights 15m', 'Morning run 2km', 'Plank 2 min'];
        case 'Intelligence':return ['Read 10 pages', 'Code 30 min', 'DuoLingo 1 lesson', 'Write journal'];
        case 'Defense':     return ['Clean room', 'Tidy up desk', 'Wash dishes', 'Make bed'];
        case 'Vitality':    return ['Drink 2L water', 'Sleep by 11pm', 'Eat fruit', 'Walk 10k steps'];
        case 'Agility':     return ['Morning stretch', 'Yoga 10 min', 'Leisurely walk 15m', 'Take the stairs'];
        default:            return [];
      }
    } else {
      switch (category) {
        case 'Strength':    return ['Push up 20x', 'Angkat beban 15m', 'Lari pagi 2km', 'Plank 2 menit'];
        case 'Intelligence':return ['Baca buku 10 hal', 'Belajar coding 30m', 'DuoLingo 1 lesson', 'Nulis jurnal'];
        case 'Defense':     return ['Bersihkan kamar', 'Rapikan meja', 'Cuci piring', 'Merapikan kasur'];
        case 'Vitality':    return ['Minum air 2L', 'Tidur jam 11 malam', 'Makan buah', 'Jalan kaki 10rb langkah'];
        case 'Agility':     return ['Stretching pagi', 'Yoga 10 menit', 'Jalan santai 15m', 'Naik tangga'];
        default:            return [];
      }
    }
  }

  // ════════════════════════════════════════════════════════
  //  AVATAR SHOP
  // ════════════════════════════════════════════════════════
  String get shopTitle            => get('Arsenal',   'Arsenal');
  String get shopBuy              => get('Beli',      'Buy');
  String get shopEquip            => get('Pakai',     'Equip');
  String get shopEquipped         => get('Dipakai',   'Equipped');
  String get shopLocked           => get('Terkunci',  'Locked');
  String get shopNotEnoughGold    => get('Gold tidak cukup!', 'Not enough Gold!');
  String get shopBuySuccess       => get('Item berhasil dibeli!', 'Item purchased!');
  String get shopCosmetic         => get('Hanya Kosmetik', 'Cosmetic Only');

  // Tier labels
  String get tierNovice   => get('Novice',  'Novice');
  String get tierVeteran  => get('Veteran', 'Veteran');
  String get tierElite    => get('Elite',   'Elite');
  String get tierMythic   => get('Mythic',  'Mythic');

  // Category tabs (shop)
  String shopCategoryLabel(String cat) {
    switch (cat) {
      case 'Head':        return get('Kepala',      'Head');
      case 'Body':        return get('Baju',        'Body');
      case 'Pants':       return get('Celana',      'Pants');
      case 'Pet':         return get('Peliharaan',  'Pet');
      case 'Wallpaper':   return get('Latar',       'Wallpaper');
      case 'Body 1 Set':  return get('Kostum',      'Costume');
      default:            return cat;
    }
  }

  // Item names (EN translation for items that have Indonesian names)
  String itemName(String itemId, String fallbackName) {
    const Map<String, String> enNames = {
      'none_head':              'No Headgear',
      'head_default_login_male1':'Male Style 1',
      'head_default_login_male2':'Male Style 2',
      'head_default_login_female1':'Female Style 1',
      'head_default_login_female2':'Female Style 2',
      'none_body':              'No Top',
      'outfit_cardigan_blue':   'Blue Cardigan',
      'outfit_student':         'School Uniform',
      'none_pants':             'No Bottoms',
      'pants_jeans':            'Jeans',
      'skirt_student':          'School Skirt',
      'none_wallpaper':         'No Wallpaper',
      'wallpaper_hutan':        'Magic Forest',
      'none_skin':              'No Costume',
      'default_skinboy':        'Boy Default',
      'default_skingirl':       'Girl Default',
      'armor_druid':            'Druid Robe',
      'none_pet':               'No Pet',
      // Most EN names are already English — no translation needed
    };

    if (isEn) return enNames[itemId] ?? fallbackName;
    // Indonesian names that need explicit translation:
    const Map<String, String> idNames = {
      'none_head':              'Tanpa Topi',
      'head_default_login_male1':'Cowok Gaya 1',
      'head_default_login_male2':'Cowok Gaya 2',
      'head_default_login_female1':'Cewek Gaya 1',
      'head_default_login_female2':'Cewek Gaya 2',
      'none_body':              'Tanpa Baju',
      'outfit_cardigan_blue':   'Kardigan Biru',
      'outfit_student':         'Baju Sekolah',
      'none_pants':             'Tanpa Celana',
      'pants_jeans':            'Celana Jeans',
      'skirt_student':          'Rok Sekolah',
      'none_wallpaper':         'Tanpa Wallpaper',
      'none_skin':              'Tanpa Kostum',
      'none_pet':               'Tidak Ada',
      'default_skinboy':        'Baju Cowok',
      'default_skingirl':       'Baju Cewek',
    };
    return idNames[itemId] ?? fallbackName;
  }

  // Passive description
  String passiveDesc(double gold, double xp, double hp) {
    List<String> parts = [];
    if (gold > 0) parts.add('+${(gold * 100).toInt()}% ${get('Gold', 'Gold')}');
    if (xp > 0)   parts.add('+${(xp * 100).toInt()}% XP');
    if (hp > 0)   parts.add('+${hp.toInt()} ${get('Max HP', 'Max HP')}');
    return parts.isEmpty ? shopCosmetic : parts.join(' & ');
  }

  // ════════════════════════════════════════════════════════
  //  GENERAL BUTTONS & MESSAGES
  // ════════════════════════════════════════════════════════
  String get btnSave      => get('Simpan',   'Save');
  String get btnCancel    => get('Batal',    'Cancel');
  String get btnClose     => get('Tutup',    'Close');
  String get btnConfirm   => get('Konfirmasi','Confirm');
  String get btnOk        => get('Oke',      'OK');
  String get btnNext      => get('Lanjut →', 'Next →');
  String get btnGotIt     => get('Mengerti ✓', 'Got it ✓');
  String get btnSkip      => get('Lewati',   'Skip');
  String get btnApply     => get('Terapkan', 'Apply');
  String get btnReset     => get('Reset',    'Reset');

  String get msgLoading   => get('Memuat...', 'Loading...');
  String get msgError     => get('Terjadi kesalahan', 'Something went wrong');
  String get msgSuccess   => get('Berhasil!', 'Success!');
  String get msgNotLoggedIn => get('Belum login', 'Not logged in');

  // ════════════════════════════════════════════════════════
  //  AUTH SCREENS
  // ════════════════════════════════════════════════════════
  String get authLogin        => get('Masuk',         'Sign In');
  String get authRegister     => get('Daftar',        'Register');
  String get authEmail        => get('Email',          'Email');
  String get authPassword     => get('Kata Sandi',    'Password');
  String get authName         => get('Nama Lengkap',  'Full Name');
  String get authUsername     => get('Username',      'Username');
  String get authLoginBtn     => get('Masuk',         'Sign In');
  String get authRegisterBtn  => get('Buat Akun',     'Create Account');
  String get authNoAccount    => get('Belum punya akun?', 'No account?');
  String get authHaveAccount  => get('Sudah punya akun?', 'Already have an account?');

  // ════════════════════════════════════════════════════════
  //  ONBOARDING
  // ════════════════════════════════════════════════════════
  String get onboardingTitle  => get('Selamat Datang, Hero!', 'Welcome, Hero!');

  // ════════════════════════════════════════════════════════
  //  CHARACTER CREATION
  // ════════════════════════════════════════════════════════
  String get charCreateSubtitle   => get('Buat Karaktermu',        'Create Your Character');
  String get charSelectGender     => get('Pilih Gender',           'Select Gender');
  String get charGenderHint       => get('Bisa diubah kapan saja', 'Can be changed anytime');
  String get charMale             => get('Cowok',                  'Male');
  String get charFemale           => get('Cewek',                  'Female');
  String get charSelectHeadBtn    => get('Pilih Karakter →',         'Select Character →');
  String get charSelectStyle      => get('Pilih Gaya',             'Choose Style');
  String get charHead             => get('Karakter',                 'Character');
  String get charHeadStyleSection => get('PILIH KARAKTER',           'CHOOSE CHARACTER');
  String get charStartAdventure   => get('Mulai Petualangan! ⚔️', 'Start Adventure! ⚔️');
  String charStyleLabel(int n)    => get('Gaya $n',                'Style $n');
  String charSaveFailed(String e) => get('Gagal menyimpan: $e',   'Failed to save: $e');

  // ════════════════════════════════════════════════════════
  //  HISTORY SCREEN
  // ════════════════════════════════════════════════════════
  String get historyTitle     => get('Riwayat Quest',  'Quest History');
  String get historyReviewTitle => get('Riwayat & Ulasan', 'History & Review');
  String get historyEmpty     => get('Belum ada riwayat.', 'No history yet.');
  String get historyEmptyTasks => get('Belum ada history task yang selesai', 'No completed tasks yet');
  String get historyCompleted => get('Diselesaikan',   'Completed');
  String get historyDone      => get('Selesai',        'Done');
  String get historyFailed    => get('Gagal',          'Failed');
  String get historyNotesLabel => get('Catatan / Jurnal:', 'Notes / Journal:');
  String get historyPhotoUnavailable =>
      get('Foto tidak dapat dimuat\n(Firebase Storage belum aktif)',
          'Photo cannot be loaded\n(Firebase Storage not active)');

  List<String> get monthShort => isEn
      ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
      : ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];

  List<String> get dayShort => isEn
      ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
      : ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  // Performance Chart
  String get statsPerformanceXp => get('Grafik Kinerja (XP)', 'Performance XP');
  String get statsNoData => get('Belum ada data', 'No data available');
  String get statsTab1W => get('1 Mgg', '1 Wk');
  String get statsTab1M => get('1 Bln', '1 Mo');
  String get statsTab1Y => get('1 Thn', '1 Yr');
  String get statsCatAll => get('Semua', 'All');

  // ════════════════════════════════════════════════════════
  //  FOCUS TIMER
  // ════════════════════════════════════════════════════════
  String get timerTitle       => get('Fokus Timer',  'Focus Timer');
  String get timerStart       => get('Mulai',        'Start');
  String get timerPause       => get('Jeda',         'Pause');
  String get timerResume      => get('Lanjut',       'Resume');
  String get timerStop        => get('Berhenti',     'Stop');
  String get timerComplete    => get('Selesai!',     'Complete!');
  String get timerFreeMode    => get('Mode Bebas',   'Free Mode');
  String get timerFocusMode   => get('Focus Mode',   'Focus Mode');
  String get timerSetManual   => get('Set Waktu Manual', 'Set Time Manually');
  String get timerMinutes     => get('Menit',        'Minutes');
  String get timerSeconds     => get('Detik',        'Seconds');
  String get timerContinue    => get('Lanjut',       'Continue');
  String get timerGiveUpTitle => get('Menyerah?',    'Give Up?');
  String get timerGiveUpMsg   =>
      get('Task akan ditandai GAGAL. Penalti HP & Gold akan dikenakan.',
          'Task will be marked FAILED. HP & Gold penalties will apply.');
  String get timerYesGiveUp   => get('Ya, Menyerah', 'Yes, Give Up');
  String get timerGiveUpBtn   => get('Menyerah',     'Give Up');
  String get timerPaused      => get('Dijeda',       'Paused');
  String get timerRemaining   => get('Tersisa',      'Remaining');
  String get timerWorkTask    => get('Kerjakan taskmu', 'Work on your task');
  String get timerPressDone   =>
      get('Tekan Selesai saat sudah dikerjakan', 'Press Done when finished');
  String get timerDoneBtn     => get('Selesai ✓',    'Done ✓');
  String get timerFailedSnack =>
      get('Task gagal! -10 HP sebagai penalti.', 'Task failed! -10 HP penalty.');

  // ════════════════════════════════════════════════════════
  //  PROOF SCREEN
  // ════════════════════════════════════════════════════════
  String get proofTitle           => get('Proof of Work', 'Proof of Work');
  String get proofUploadPhoto     => get('Upload Foto Bukti', 'Upload Proof Photo');
  String get proofPhotoHint       =>
      get('Foto harus menunjukkan kamu sudah menyelesaikan task',
          'Photo must show you completed the task');
  String get proofTapCamera       => get('Tap untuk buka kamera', 'Tap to open camera');
  String get proofWriteSummary    => get('Tulis Ringkasan', 'Write Summary');
  String get proofSummaryHint     =>
      get('Jelaskan apa yang kamu pelajari atau lakukan',
          'Describe what you learned or did');
  String get proofSummaryFieldHint =>
      get('Tulis ringkasan kegiatanmu di sini...', 'Write your activity summary here...');
  String get proofVerifying       =>
      get('Memverifikasi penyelesaian Quest...', 'Verifying Quest completion...');
  String get proofVerifyingHint   =>
      get('Harap tunggu sebentar, sistem sedang mencatat progres RPG-mu.',
          'Please wait, the system is recording your RPG progress.');
  String get proofSubmitBtn       => get('Submit Bukti & Selesai', 'Submit Proof & Finish');
  String get proofNeedPhoto       => get('Upload foto bukti dulu!', 'Upload proof photo first!');
  String get proofNeedText        => get('Isi ringkasan/catatan dulu!', 'Fill in summary/notes first!');
  String proofSaveFailed(String e) =>
      get('Gagal menyimpan bukti: $e', 'Failed to save proof: $e');
  String get proofQuestComplete   => get('QUEST COMPLETE', 'QUEST COMPLETE');
  String get proofShareText       =>
      get('Saya baru saja menyelesaikan task: ', 'I just completed a task: ');
  String get proofShareHashtags   => get(' ⚔️🔥 #DailyRPG', ' ⚔️🔥 #DailyRPG');

  // ════════════════════════════════════════════════════════
  //  NOTIFICATIONS
  // ════════════════════════════════════════════════════════
  String notifPendingTitle(int count) => isEn
      ? 'SYSTEM ALERT: PENDING QUESTS'
      : 'SYSTEM ALERT: QUEST TERTUNDA';
  String notifPendingBody(int count) => isEn
      ? 'You have $count pending quests. Your character\'s vitality will decrease if you ignore your duty.'
      : 'Kamu memiliki $count quest tertunda. Vitalitas karaktermu akan menurun jika kamu mengabaikan tugasmu.';

  // ════════════════════════════════════════════════════════
  //  TUTORIAL STEPS (xqvx The Creator)
  // ════════════════════════════════════════════════════════
  List<String> get tutorialHome => isEn ? [
    'Greetings, Adventurer! I am xqvx The Creator, your spiritual guide in this realm. Allow me to guide your journey.',
    'At the top, monitor your vital attributes: HP, XP, Level, and Gold. Should your HP fall to zero due to failed missions, you will suffer a severe penalty!',
    'Below lies the Tavern Quest Board. Missions are grouped by their respective physical and mental disciplines. Choose your path and accept a quest to begin!',
  ] : [
    'Salam, Pahlawan! Aku adalah xqvx The Creator, pemandu spiritualmu di ranah RPG ini. Izinkan aku memandu awal perjalananmu.',
    'Di bagian atas, pantau atribut vitalmu: HP, XP, Level, dan Gold. Jika HP-mu habis karena misi yang gagal, karaktermu akan menerima penalti berat!',
    'Di bawahnya adalah Papan Misi Utama. Misi dikelompokkan berdasarkan disiplin fisik dan mental. Pilih jalurmu dan terima quest untuk memulai!',
  ];

  List<String> get tutorialDaily => isEn ? [
    'Welcome to the Active Quest Room. All missions you have accepted from the Tavern will be listed here.',
    'Once you conquer a mission in the real world, mark it here to claim your rightful XP and Gold bounties.',
  ] : [
    'Selamat datang di Ruang Quest Aktif. Semua misi yang telah kamu ambil dari Papan Misi akan tercatat di sini.',
    'Setelah kamu menaklukkan sebuah misi di dunia nyata, tandai di sini untuk mengklaim hadiah XP dan Gold milikmu.',
  ];

  List<String> get tutorialStats => isEn ? [
    'You have entered the Hall of Records. Here, you may analyze the growth of your five core attributes.',
    'Monitor your Performance Chart to track your XP progress over time, and maintain your Daily Streak to prove your consistency.',
    'You can also inspect your Quest History log to review past triumphs, or check the Leaderboard tab to compare your rank globally!',
    'Every successful quest permanently enhances your prowess based on its category, shaping your ultimate title and destiny!',
  ] : [
    'Kamu telah memasuki Ruang Catatan Kuno. Di sini, kamu bisa menganalisis pertumbuhan kelima atribut utamamu.',
    'Pantau Grafik Kinerja untuk melihat laju XP-mu dari waktu ke waktu, dan pertahankan Streak harianmu sebagai bukti ketekunan.',
    'Kamu juga bisa memeriksa Log Riwayat untuk melihat jejak pencapaian masa lalumu, atau membuka tab Peringkat untuk bersaing secara global!',
    'Setiap quest yang berhasil akan meningkatkan kekuatanmu secara permanen, membentuk gelar dan takdir akhir karaktermu!',
  ];

  List<String> get tutorialProfile => isEn ? [
    'Welcome to the Grand Arsenal and Dressing Room! Exchange your hard-earned Gold for legendary artifacts and companions.',
    'You can fully customize your Avatar here with unique outfits, majestic pets, and magnificent backgrounds.',
    'Do not forget to proudly display your unlocked Badges, showcasing your rarest achievements to the world!',
    'You may also purchase consumable Potions for instant healing or temporary XP multipliers before embarking on tough quests.',
  ] : [
    'Selamat datang di Gudang Senjata dan Ruang Ganti! Tukarkan Gold hasil jerih payahmu dengan berbagai artefak legendaris.',
    'Kamu bisa bebas melakukan kustomisasi Avatar di sini menggunakan kostum unik, hewan pendamping, hingga latar belakang magis.',
    'Jangan lupa untuk memasang Lencana yang telah kamu raih, pamerkan pencapaian terlangkamu kepada dunia!',
    'Kamu juga bisa memborong Ramuan ajaib untuk pemulihan instan atau pengganda XP sementara sebelum memulai misi yang berat.',
  ];

  List<String> get tutorialAddTask => isEn ? [
    'This is the Quest Creation Scroll. Use it to forge new challenges into your personal log.',
    'Determine the Quest Title, or select from the ancient scriptures provided below.',
    'Align your quest with a core discipline: Strength, Defense, Intelligence, Vitality, or Agility.',
    'Set the Difficulty. A higher peril yields a far greater bounty of XP and Gold upon triumph.',
    'Select your Proof of Completion, establish a deadline, and forge the quest. May victory be yours!',
  ] : [
    'Ini adalah Gulungan Penciptaan Quest. Gunakan untuk menempa tantangan baru ke dalam catatan pribadimu.',
    'Tentukan Judul Quest, atau pilih dari naskah kuno yang tersedia di bagian bawah layar.',
    'Pilih satu disiplin atribut yang sejalan dengan misimu: Strength, Defense, Intelligence, Vitality, atau Agility.',
    'Atur tingkat Kesulitan. Tantangan yang lebih berat akan menghasilkan hadiah XP dan Gold yang jauh lebih besar.',
    'Pilih metode Bukti Penyelesaian, tentukan batas waktu, dan ciptakan quest tersebut. Raihlah kemenanganmu!',
  ];

  List<String> get tutorialLeaderboard => isEn ? [
    'Behold the Hall of Champions! This is the global hierarchy of all adventurers across the realms.',
    'Your rank is dictated by your Level. Conquer more quests to ascend the ranks and claim glory.',
    'Observe the highest ranks, for they are legends. Surpass them through sheer discipline and daily perseverance.',
    'The highlighted row marks your current standing. Select another adventurer to view their profile and arsenal.',
  ] : [
    'Saksikanlah Aula Sang Juara! Ini adalah hierarki global seluruh petualang di ranah ini.',
    'Peringkatmu ditentukan oleh Level karaktermu. Taklukkan lebih banyak quest untuk naik peringkat dan meraih kejayaan.',
    'Perhatikan petarung di peringkat teratas, mereka adalah legenda. Lampaui mereka melalui kedisiplinan dan ketekunan harianmu.',
    'Baris yang disorot menandai posisimu saat ini. Pilih petualang lain untuk melihat profil dan persenjataan mereka.',
  ];

  // Tutorial UI strings
  String get tutorialSkip       => get('Lewati', 'Skip');
  String get tutorialNext       => get('Lanjut →', 'Next →');
  String get tutorialUnderstood => get('Mengerti ✓', 'Got it ✓');

  // ════════════════════════════════════════════════════════
  //  SUBCATEGORY NAMES (home quest board)
  // ════════════════════════════════════════════════════════
  String subCatName(String key) {
    if (isEn) {
      const Map<String, String> en = {
        'Latihan Beban':      'Weight Training',
        'Calisthenics':       'Calisthenics',
        'Olahraga Air':       'Water Sports',
        'Combat':             'Combat',
        'Skill Teknis':       'Technical Skills',
        'Literasi':           'Literacy',
        'Bahasa':             'Language',
        'Logika':             'Logic',
        'Mindfulness':        'Mindfulness',
        'Refleksi':           'Reflection',
        'Stoicism':           'Stoicism',
        'Digital Detox':      'Digital Detox',
        'Cardio Lari':        'Cardio Run',
        'Sport':              'Sports',
        'Endurance':          'Endurance',
        'HIIT':               'HIIT',
        'Kualitas Tidur':     'Sleep Quality',
        'Hidrasi':            'Hydration',
        'Nutrisi':            'Nutrition',
        'Recovery':           'Recovery',
      };
      return en[key] ?? key;
    }
    return key; // already Indonesian
  }

  // Quest names inside subcategories
  String questName(String key) {
    if (isEn) {
      const Map<String, String> en = {
        'Chest Day':              'Chest Day',
        'Leg Day':                'Leg Day',
        'Back Day':               'Back Day',
        'Push-up 100x':           '100x Push-ups',
        'Pull-up':                'Pull-ups',
        'Dips':                   'Dips',
        'Renang 30 Menit':        'Swim 30 Minutes',
        'Boxing':                 'Boxing',
        'Muay Thai':              'Muay Thai',
        'Ngoding Flutter':        'Coding Flutter',
        'Desain UI/UX':           'UI/UX Design',
        'Baca Buku 10 Hal':       'Read 10 Pages',
        'Ringkasan Artikel':      'Article Summary',
        'Belajar 5 Kosakata Baru':'Learn 5 New Words',
        'Latihan Grammar':        'Grammar Practice',
        'Main Catur':             'Play Chess',
        'Sudoku':                 'Sudoku',
        'Meditasi 5 Menit':       'Meditate 5 Min',
        'Journaling Malam':       'Evening Journaling',
        'Latihan Kontrol Emosi':  'Emotion Control',
        '1 Jam Tanpa HP':         '1 Hour No Phone',
        'Jogging 20 Menit':       'Jog 20 Minutes',
        'Lari 5K':                'Run 5K',
        'Badminton':              'Badminton',
        'Futsal':                 'Futsal',
        'Bersepeda 30 Menit':     'Cycle 30 Minutes',
        'HIIT 15 Menit':          'HIIT 15 Minutes',
        'Tidur Sebelum Jam 10':   'Sleep Before 10pm',
        'Minum 2L Air':           'Drink 2L Water',
        'Makan Serat/Protein':    'Eat Fiber/Protein',
        'Sarapan Sehat':          'Healthy Breakfast',
        'Stretching/Yoga':        'Stretching/Yoga',
      };
      return en[key] ?? key;
    }
    return key;
  }
}
