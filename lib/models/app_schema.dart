/// ============================================================
/// APP SCHEMA — Single source of truth untuk field Firestore
/// ============================================================
/// Gunakan class ini sebagai referensi saat membaca/menulis data
/// agar tidak ada typo field di seluruh codebase.
/// ============================================================

library;

// ─── USER SCHEMA ────────────────────────────────────────────
// Collection: users/{uid}
//
// Field              Type        Keterangan
// ─────────────────────────────────────────────────────────────
// id                 String      UID Firebase Auth
// name               String      Nama lengkap
// username           String      Username (lowercase, unik)
// email              String      Email
// createdAt          Timestamp   Waktu registrasi
//
// — Stats —
// xp                 int         Total XP kumulatif
// level              int         Level saat ini (1-∞)
// rank               String      'E' | 'D' | 'C' | 'B' | 'A' | 'SSR'
// hp                 int         HP saat ini (0-100)
// maxHp              int         HP maksimum (default 100)
// gold               int         Koin emas untuk kustomisasi
//
// — Atribut per kategori (XP yang sudah dikumpulkan) —
// strengthXp         int         XP dari task Strength
// defenseXp          int         XP dari task Defense
// intelligenceXp     int         XP dari task Intelligence
// vitalityXp         int         XP dari task Vitality
// agilityXp          int         XP dari task Agility
//
// — Streak & Aktivitas —
// streak             int         Hari aktif berturut-turut
// lastActiveDate     String      Format: 'yyyy-MM-dd' (hari terakhir aktif)
// longestStreak      int         Rekor streak terpanjang
//
// — Punishment —
// isBurntOut         bool        true jika HP < 20% → lock task produktif
// totalTasksDone     int         Total task selesai sepanjang masa
// totalTasksFailed   int         Total task gagal sepanjang masa

// Kelas UserSchema: Menyimpan daftar nama kolom (field) untuk koleksi 'users' di Firestore.
// Tujuannya agar kita tidak salah ketik (typo) saat memanggil data dari database.
class UserSchema {
  static const String id = 'id';
  static const String name = 'name';
  static const String username = 'username';
  static const String email = 'email';
  static const String createdAt = 'createdAt';

  // Stats
  static const String xp = 'xp';
  static const String level = 'level';
  static const String rank = 'rank';
  static const String hp = 'hp';
  static const String maxHp = 'maxHp';
  static const String gold = 'gold';

  // Atribut
  static const String strengthXp = 'strengthXp';
  static const String defenseXp = 'defenseXp';
  static const String intelligenceXp = 'intelligenceXp';
  static const String vitalityXp = 'vitalityXp';
  static const String agilityXp = 'agilityXp';

  // Streak
  static const String streak = 'streak';
  static const String lastActiveDate = 'lastActiveDate';
  static const String longestStreak = 'longestStreak';

  // Punishment
  static const String isBurntOut = 'isBurntOut';
  static const String totalTasksDone = 'totalTasksDone';
  static const String totalTasksFailed = 'totalTasksFailed';

  // Avatar & Customization
  static const String equippedItems = 'equippedItems';
  static const String unlockedItems = 'unlockedItems';
  static const String inventory = 'inventory';
  static const String soundEnabled = 'soundEnabled';
  static const String xpBonusUntil = 'xpBonusUntil';

  // Character Creation
  static const String gender = 'gender';              // 'male' | 'female'
  static const String baseBody = 'baseBody';          // 'default_skinboy' | 'default_skingirl'
  static const String defaultHead = 'defaultHead';    // head ID chosen at creation
  static const String onboardingDone = 'onboardingDone'; // bool
  static const String role = 'role';                  // 'user' | 'admin'

  /// Default user document untuk registrasi baru
  static Map<String, dynamic> defaultUser({
    required String uid,
    required String name,
    required String username,
    required String email,
  }) => {
    id: uid,
    UserSchema.name: name,
    UserSchema.username: username.toLowerCase(),
    UserSchema.email: email,
    createdAt: null, // diisi FieldValue.serverTimestamp() saat set
    // Stats awal
    xp: 0,
    level: 1,
    rank: 'E',
    hp: 100,
    maxHp: 100,
    gold: 0,
    role: 'user',

    // Atribut awal
    strengthXp: 0,
    defenseXp: 0,
    intelligenceXp: 0,
    vitalityXp: 0,
    agilityXp: 0,

    // Streak
    streak: 0,
    lastActiveDate: '',
    longestStreak: 0,

    // Punishment
    isBurntOut: false,
    totalTasksDone: 0,
    totalTasksFailed: 0,
    equippedItems: {
      'head': 'head_default_login_male1',
      'clothes': 'none',
      'pants': 'none',
      'pet': 'none',
      'background': 'default',
    },
    unlockedItems: [
      'none',
      'default',
      'head_default_login_male1',
      'head_default_login_male2',
      'head_default_login_female1',
      'head_default_login_female2',
      'default_skinboy',
      'default_skingirl',
    ],
    inventory: {
      'red_potion': 0,
      'blue_potion': 0,
      'green_potion': 0,
      'xp_scroll': 0,
      'strength_potion': 0,
      'agility_potion': 0,
      'intelligence_potion': 0,
    },
    soundEnabled: true,
    gender: 'male',
    baseBody: 'default_skinboy',
    defaultHead: 'head_default_login_male1',
    onboardingDone: false,
  };
}

// ─── TASK SCHEMA ─────────────────────────────────────────────
// Collection: users/{uid}/tasks/{taskId}
//
// Field              Type        Keterangan
// ─────────────────────────────────────────────────────────────
// id                 String      UUID task
// uid                String      UID pemilik
// title              String      Judul task
// notes              String      Catatan/deskripsi
// category           String      'Strength'|'Defense'|'Intelligence'|'Vitality'|'Agility'
// difficulty         int         1=Easy, 2=Normal, 3=Hard, 4=Extreme
// xp                 int         XP reward jika selesai
// goldReward         int         Gold reward jika selesai
// duration           int         Durasi task dalam menit (0 = tidak ada timer)
// proofType          String      'none' | 'photo' | 'text'
//
// — Status —
// done               bool        true jika task selesai & terverifikasi
// timerStatus        String      'idle'|'running'|'completed'|'failed'
// timerStartAt       Timestamp?  Timestamp saat timer ditekan Start
// completedAt        Timestamp?  Timestamp saat task selesai
// failedAt           Timestamp?  Timestamp saat task gagal
//
// — Proof of Work —
// proofUrl           String      URL foto bukti (Firebase Storage)
// proofText          String      Teks bukti (untuk Intelligence/Defense)
// isVerified         bool        true jika bukti sudah diupload & valid
//
// — Timestamps —
// deadline           Timestamp   Deadline pengerjaan
// createdAt          Timestamp   Waktu dibuat

// Kelas TaskSchema: Menyimpan daftar nama kolom untuk koleksi 'tasks' di Firestore.
class TaskSchema {
  static const String id = 'id';
  static const String uid = 'uid';
  static const String title = 'title';
  static const String notes = 'notes';
  static const String category = 'category';
  static const String difficulty = 'difficulty';
  static const String xp = 'xp';
  static const String goldReward = 'goldReward';
  static const String duration = 'duration';
  static const String proofType = 'proofType';

  // Status
  static const String done = 'done';
  static const String timerStatus = 'timerStatus';
  static const String timerStartAt = 'timerStartAt';
  static const String completedAt = 'completedAt';
  static const String failedAt = 'failedAt';

  // Proof
  static const String proofUrl = 'proofUrl';
  static const String proofText = 'proofText';
  static const String isVerified = 'isVerified';

  // Cursed
  static const String isCursed = 'isCursed';
  static const String cursedMultiplier = 'cursedMultiplier';

  // Timestamps
  static const String deadline = 'deadline';
  static const String createdAt = 'createdAt';

  // Frequency
  static const String frequency = 'frequency';

  // Nilai konstan
  static const String proofTypeNone = 'none';
  static const String proofTypePhoto = 'photo';
  static const String proofTypeText = 'text';

  static const String timerIdle = 'idle';
  static const String timerRunning = 'running';
  static const String timerCompleted = 'completed';
  static const String timerFailed = 'failed';

  static const String freqDaily = 'daily';
  static const String freqWeekly = 'weekly';
}

// ─── RANK SYSTEM ─────────────────────────────────────────────
class RankSystem {
  // ─ Rank order (untuk UI) ──────────────
  static const List<String> rankOrder = [
    'F',
    'E',
    'D',
    'C',
    'B',
    'A',
    'S',
    'SS',
    'SSS',
  ];

  // ─ Rank dari Level ──────────────────────────
  static String rankFromLevel(int level) {
    if (level >= 121) return 'SSS'; // Endgame
    if (level >= 91) return 'SS'; // Prestige
    if (level >= 71) return 'S'; // Late game
    if (level >= 51) return 'A'; // Expert
    if (level >= 36) return 'B'; // Skilled
    if (level >= 21) return 'C'; // Adept
    if (level >= 11) return 'D'; // Novice
    if (level >= 6) return 'E'; // Beginner
    return 'F'; // Trainee / Newbie (Level 1-5)
  }

  // ─ Warna Rank (konsisten di semua screen) ─────
  static int rankColorHex(String rank) {
    switch (rank) {
      case 'SSS':
        return 0xFFFFD700; // Emas
      case 'SS':
        return 0xFF06B6D4; // Cyan
      case 'S':
        return 0xFFE879F9; // Pink
      case 'A':
        return 0xFFEF4444; // Merah
      case 'B':
        return 0xFFF97316; // Orange
      case 'C':
        return 0xFF8B5CF6; // Ungu
      case 'D':
        return 0xFF3B82F6; // Biru
      case 'E':
        return 0xFF10B981; // Hijau
      case 'F':
        return 0xFF94A3B8; // Abu-abu
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  /// XP yang dibutuhkan untuk naik dari level n ke n+1
  /// Rumus Arithmetic Progression: XP = a + (n-1) * d
  /// a = 100 (XP dasar), d = 50 (penambahan per level)
  static int xpForLevel(int level) => 100 + (level - 1) * 50;

  // ─ XP Reward berdasarkan difficulty (RBS Rule) ───
  static int xpReward(int difficulty) {
    switch (difficulty) {
      case 1:
        return 10; // Easy
      case 2:
        return 20; // Medium
      case 3:
        return 30; // Hard
      case 4:
        return 50; // Extreme
      default:
        return 10;
    }
  }

  /// Gold reward berdasarkan difficulty
  static int goldReward(int difficulty) {
    switch (difficulty) {
      case 1:
        return 5; // Easy
      case 2:
        return 10; // Medium
      case 3:
        return 20; // Hard
      case 4:
        return 50; // Extreme
      default:
        return 5;
    }
  }

  // ─ Hitung level progress di rank (untuk UI / Roadmap) ─
  static int levelInRank(int level) {
    final rank = rankFromLevel(level);
    switch (rank) {
      case 'F':
        return level; // 1-5
      case 'E':
        return level - 5; // 6-10 -> 1-5
      case 'D':
        return level - 10; // 11-20 -> 1-10
      case 'C':
        return level - 20; // 21-35 -> 1-15
      case 'B':
        return level - 35; // 36-50 -> 1-15
      case 'A':
        return level - 50; // 51-70 -> 1-20
      case 'S':
        return level - 70; // 71-90 -> 1-20
      case 'SS':
        return level - 90; // 91-120 -> 1-30
      case 'SSS':
        return level - 120; // 121+
      default:
        return level;
    }
  }

  static int levelsInRank(String rank) {
    switch (rank) {
      case 'F':
        return 5;
      case 'E':
        return 5;
      case 'D':
        return 10;
      case 'C':
        return 15;
      case 'B':
        return 15;
      case 'A':
        return 20;
      case 'S':
        return 20;
      case 'SS':
        return 30;
      case 'SSS':
        return 999;
      default:
        return 5;
    }
  }

  // ─ XP yang efektif dengan modifier HP (RBS Rule) ─
  static int effectiveXp(int baseXp, int currentHp) {
    if (currentHp > 80) return (baseXp * 1.1).round();
    if (currentHp < 30) return (baseXp * 0.9).round();
    return baseXp;
  }

  // ─ XP Streak Bonus (RBS Rule) ───────────────
  static int streakBonusXp(int baseXp, int streak) {
    if (streak >= 7) return (baseXp * 1.15).round();
    if (streak >= 5) return (baseXp * 1.10).round();
    return baseXp;
  }

  // ─ HP Constants (RBS Rule) ─
  static const int hpGainOnTaskComplete = 5;
  static const int hpLossOnTaskFail = 10;
  static const int hpGainOnDailyLogin = 2;
  static const int hpBonusThreshold = 80;
  static const int hpPenaltyThreshold = 30;
  static const int hpBurnoutThreshold = 20;
}

// ─── BADGE SYSTEM ─────────────────────────────────────────────
class AppBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // strength, agility, etc.
  final int threshold; // XP threshold in category
  final int colorHex;

  const AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.threshold,
    required this.colorHex,
  });
}

class BadgeSystem {
  static const List<AppBadge> allBadges = [
    // --- STRENGTH ---
    AppBadge(
      id: "strength_1",
      name: "Trainee Muscle",
      description: "Capai 100 XP Strength",
      icon: "🏋️",
      category: "Strength",
      threshold: 100,
      colorHex: 0xFFEF4444,
    ),
    AppBadge(
      id: "strength_2",
      name: "Iron Fist",
      description: "Capai 500 XP Strength",
      icon: "👊",
      category: "Strength",
      threshold: 500,
      colorHex: 0xFFEF4444,
    ),
    AppBadge(
      id: "strength_3",
      name: "Titan Strength",
      description: "Capai 2000 XP Strength",
      icon: "🌋",
      category: "Strength",
      threshold: 2000,
      colorHex: 0xFFB91C1C,
    ),

    // --- AGILITY ---
    AppBadge(
      id: "agility_1",
      name: "Quick Steps",
      description: "Capai 100 XP Agility",
      icon: "👟",
      category: "Agility",
      threshold: 100,
      colorHex: 0xFFF59E0B,
    ),
    AppBadge(
      id: "agility_2",
      name: "Wind Walker",
      description: "Capai 500 XP Agility",
      icon: "🌪️",
      category: "Agility",
      threshold: 500,
      colorHex: 0xFFF59E0B,
    ),
    AppBadge(
      id: "agility_3",
      name: "Sonic Speed",
      description: "Capai 2000 XP Agility",
      icon: "⚡",
      category: "Agility",
      threshold: 2000,
      colorHex: 0xFFD97706,
    ),

    // --- INTELLIGENCE ---
    AppBadge(
      id: "intel_1",
      name: "Bright Mind",
      description: "Capai 100 XP Intelligence",
      icon: "💡",
      category: "Intelligence",
      threshold: 100,
      colorHex: 0xFF3B82F6,
    ),
    AppBadge(
      id: "intel_2",
      name: "Sage Student",
      description: "Capai 500 XP Intelligence",
      icon: "📜",
      category: "Intelligence",
      threshold: 500,
      colorHex: 0xFF3B82F6,
    ),
    AppBadge(
      id: "intel_3",
      name: "Archmage",
      description: "Capai 2000 XP Intelligence",
      icon: "🔮",
      category: "Intelligence",
      threshold: 2000,
      colorHex: 0xFF1D4ED8,
    ),

    // --- VITALITY ---
    AppBadge(
      id: "vital_1",
      name: "Healthy Soul",
      description: "Capai 100 XP Vitality",
      icon: "🥗",
      category: "Vitality",
      threshold: 100,
      colorHex: 0xFF10B981,
    ),
    AppBadge(
      id: "vital_2",
      name: "Immortal Breath",
      description: "Capai 500 XP Vitality",
      icon: "🍃",
      category: "Vitality",
      threshold: 500,
      colorHex: 0xFF10B981,
    ),
    AppBadge(
      id: "vital_3",
      name: "World Tree",
      description: "Capai 2000 XP Vitality",
      icon: "🌳",
      category: "Vitality",
      threshold: 2000,
      colorHex: 0xFF047857,
    ),

    // --- DEFENSE ---
    AppBadge(
      id: "def_1",
      name: "Wooden Guard",
      description: "Capai 100 XP Defense",
      icon: "🪵",
      category: "Defense",
      threshold: 100,
      colorHex: 0xFF8B5CF6,
    ),
    AppBadge(
      id: "def_2",
      name: "Iron Wall",
      description: "Capai 500 XP Defense",
      icon: "🛡️",
      category: "Defense",
      threshold: 500,
      colorHex: 0xFF8B5CF6,
    ),
    AppBadge(
      id: "def_3",
      name: "Indestructible",
      description: "Capai 2000 XP Defense",
      icon: "💎",
      category: "Defense",
      threshold: 2000,
      colorHex: 0xFF6D28D9,
    ),

    // --- PROGRESS & TASKS ---
    AppBadge(
      id: "tasks_1",
      name: "Beginner Tasker",
      description: "Selesaikan 10 task",
      icon: "📝",
      category: "totalTasksDone",
      threshold: 10,
      colorHex: 0xFF6366F1,
    ),
    AppBadge(
      id: "tasks_2",
      name: "Hard Worker",
      description: "Selesaikan 50 task",
      icon: "🛠️",
      category: "totalTasksDone",
      threshold: 50,
      colorHex: 0xFF6366F1,
    ),
    AppBadge(
      id: "tasks_3",
      name: "Legendary Master",
      description: "Selesaikan 200 task",
      icon: "👑",
      category: "totalTasksDone",
      threshold: 200,
      colorHex: 0xFF4338CA,
    ),

    // --- LEVEL ---
    AppBadge(
      id: "level_1",
      name: "Novice",
      description: "Capai Level 10",
      icon: "🌱",
      category: "level",
      threshold: 10,
      colorHex: 0xFF06B6D4,
    ),
    AppBadge(
      id: "level_2",
      name: "Adventurer",
      description: "Capai Level 30",
      icon: "🗺️",
      category: "level",
      threshold: 30,
      colorHex: 0xFF06B6D4,
    ),
    AppBadge(
      id: "level_3",
      name: "Hero of Realms",
      description: "Capai Level 50",
      icon: "⚔️",
      category: "level",
      threshold: 50,
      colorHex: 0xFF06B6D4,
    ),
    AppBadge(
      id: "level_4",
      name: "Mythic Being",
      description: "Capai Level 100",
      icon: "🌌",
      category: "level",
      threshold: 100,
      colorHex: 0xFF0E7490,
    ),

    // --- STREAK ---
    AppBadge(
      id: "streak_1",
      name: "Warm Up",
      description: "Capai 3 hari streak",
      icon: "🔥",
      category: "streak",
      threshold: 3,
      colorHex: 0xFFF97316,
    ),
    AppBadge(
      id: "streak_2",
      name: "Consistent",
      description: "Capai 7 hari streak",
      icon: "🌋",
      category: "streak",
      threshold: 7,
      colorHex: 0xFFF97316,
    ),
    AppBadge(
      id: "streak_3",
      name: "Unstoppable",
      description: "Capai 30 hari streak",
      icon: "☄️",
      category: "streak",
      threshold: 30,
      colorHex: 0xFFC2410C,
    ),

    // --- SPECIALS ---
    AppBadge(
      id: "gold_1",
      name: "Saver",
      description: "Kumpulkan 1000 Gold",
      icon: "💰",
      category: "gold",
      threshold: 1000,
      colorHex: 0xFFFFD700,
    ),
    AppBadge(
      id: "gold_2",
      name: "Merchant King",
      description: "Kumpulkan 10000 Gold",
      icon: "💎",
      category: "gold",
      threshold: 10000,
      colorHex: 0xFFFFD700,
    ),
    AppBadge(
      id: "all_round_1",
      name: "Jack of All Trades",
      description: "Capai 100 XP di SEMUA kategori",
      icon: "🌟",
      category: "all_100",
      threshold: 100,
      colorHex: 0xFFEC4899,
    ),
    AppBadge(
      id: "hardcore_1",
      name: "Survivor",
      description: "Selesaikan 5 task dengan HP < 30",
      icon: "💀",
      category: "hp_low_tasks",
      threshold: 5,
      colorHex: 0xFF000000,
    ),
  ];
}

