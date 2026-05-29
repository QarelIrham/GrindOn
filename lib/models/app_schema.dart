library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  static const String musicEnabled = 'musicEnabled';
  static const String xpBonusUntil = 'xpBonusUntil';
  static const String goldBonusUntil = 'goldBonusUntil';
  static const String claimedBadges = 'claimedBadges';
  static const String equippedBadges = 'equippedBadges';

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
      'gold_scroll': 0,
      'strength_potion': 0,
      'agility_potion': 0,
      'intelligence_potion': 0,
      'vitality_potion': 0,
      'defense_potion': 0,
      'mystery_box': 0,
      'revive_token': 0,
    },
    claimedBadges: [],
    equippedBadges: [],
    soundEnabled: true,
    musicEnabled: true,
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
    'SSR',
  ];

  // ─ Rank dari Level & Stat ──────────────────────────
  static String calculateRank(int level, {int str = 0, int def = 0, int intl = 0, int vit = 0, int agi = 0}) {
    if (level >= 150) return 'SSR'; // Mythical
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

  // ─ Gelar Dinamis berdasarkan Stat ───────────
  static String getDynamicTitle(
    int str, int def, int intl, int vit, int agi,
    String rank, int level, int tasksDone,
  ) {
    if (rank == 'SSR' && str >= 9999 && def >= 9999 && intl >= 9999 && vit >= 9999 && agi >= 9999) {
      return 'The Greatest';
    }

    if (str == 0 && def == 0 && intl == 0 && vit == 0 && agi == 0) {
      return 'The Beginner';
    }

    String prefix = 'Novice';
    if (rank == 'F' || rank == 'E') prefix = 'Novice';
    else if (rank == 'D' || rank == 'C') prefix = 'Apprentice';
    else if (rank == 'B' || rank == 'A') prefix = 'Expert';
    else if (rank == 'S' || rank == 'SS') prefix = 'Master';
    else if (rank == 'SSS') prefix = 'Legendary';
    else if (rank == 'SSR') prefix = 'Mythical';

    int maxStat = str;
    String topStat = 'str';
    if (def > maxStat) { maxStat = def; topStat = 'def'; }
    if (intl > maxStat) { maxStat = intl; topStat = 'intl'; }
    if (vit > maxStat) { maxStat = vit; topStat = 'vit'; }
    if (agi > maxStat) { maxStat = agi; topStat = 'agi'; }

    String suffix = 'Warrior';
    switch (topStat) {
      case 'str': suffix = 'Warrior'; break;
      case 'def': suffix = 'Guardian'; break;
      case 'intl': suffix = 'Strategist'; break;
      case 'vit': suffix = 'Immortal'; break;
      case 'agi': suffix = 'Shadow'; break;
    }

    return '$prefix $suffix';
  }

  // ─ Warna Rank (konsisten di semua screen) ─────
  static int rankColorHex(String rank) {
    switch (rank) {
      case 'SSR': return 0xFFFFFFFF; // Putih Diamond bersinar
      case 'SSS': return 0xFFFFD700; // Emas Bercahaya
      case 'SS': return 0xFF00FFFF; // Cyan Neon
      case 'S': return 0xFFFF1493; // Deep Pink
      case 'A': return 0xFFFF3333; // Bright Red
      case 'B': return 0xFFFF8C00; // Dark Orange
      case 'C': return 0xFF9932CC; // Dark Orchid
      case 'D': return 0xFF1E90FF; // Dodger Blue
      case 'E': return 0xFF32CD32; // Lime Green
      case 'F': return 0xFF708090; // Slate Gray
      default: return 0xFF94A3B8;
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
    final rank = calculateRank(level);
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
  final IconData iconData;
  final IconData? flutterIcon;
  final int rewardXp;
  final int rewardGold;

  const AppBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.threshold,
    required this.colorHex,
    this.iconData = Icons.star,
    this.flutterIcon,
    this.rewardXp = 50,
    this.rewardGold = 10,
  });
}

class BadgeSystem {
  static const List<AppBadge> allBadges = [
    // --- STRENGTH ---
    AppBadge(id: "strength_1", name: "Trainee Muscle", description: "Capai 100 XP Strength", icon: "🏋️", flutterIcon: Icons.fitness_center, category: "Strength", threshold: 100, colorHex: 0xFFEF4444),
    AppBadge(id: "strength_2", name: "Iron Fist", description: "Capai 500 XP Strength", icon: "👊", flutterIcon: Icons.sports_martial_arts, category: "Strength", threshold: 500, colorHex: 0xFFEF4444),
    AppBadge(id: "strength_3", name: "Warrior", description: "Capai 2000 XP Strength", icon: "⚔️", flutterIcon: Icons.hardware, category: "Strength", threshold: 2000, colorHex: 0xFFEF4444),
    AppBadge(id: "strength_4", name: "Titan Strength", description: "Capai 5000 XP Strength", icon: "🌋", flutterIcon: Icons.local_fire_department, category: "Strength", threshold: 5000, colorHex: 0xFFEF4444),
    AppBadge(id: "strength_5", name: "Hercules", description: "Capai 9999 XP Strength", icon: "💪", flutterIcon: Icons.sports_kabaddi, category: "Strength", threshold: 9999, colorHex: 0xFFEF4444),

    // --- AGILITY ---
    AppBadge(id: "agility_1", name: "Quick Steps", description: "Capai 100 XP Agility", icon: "👟", flutterIcon: Icons.directions_run, category: "Agility", threshold: 100, colorHex: 0xFFF59E0B),
    AppBadge(id: "agility_2", name: "Wind Walker", description: "Capai 500 XP Agility", icon: "🌪️", flutterIcon: Icons.speed, category: "Agility", threshold: 500, colorHex: 0xFFF59E0B),
    AppBadge(id: "agility_3", name: "Sonic Speed", description: "Capai 2000 XP Agility", icon: "⚡", flutterIcon: Icons.air, category: "Agility", threshold: 2000, colorHex: 0xFFF59E0B),
    AppBadge(id: "agility_4", name: "Lightning", description: "Capai 5000 XP Agility", icon: "🌩️", flutterIcon: Icons.electric_bolt, category: "Agility", threshold: 5000, colorHex: 0xFFF59E0B),
    AppBadge(id: "agility_5", name: "Speed Force", description: "Capai 9999 XP Agility", icon: "☄️", flutterIcon: Icons.flight, category: "Agility", threshold: 9999, colorHex: 0xFFF59E0B),

    // --- INTELLIGENCE ---
    AppBadge(id: "intel_1", name: "Bright Mind", description: "Capai 100 XP Intelligence", icon: "💡", flutterIcon: Icons.auto_stories, category: "Intelligence", threshold: 100, colorHex: 0xFF3B82F6),
    AppBadge(id: "intel_2", name: "Sage Student", description: "Capai 500 XP Intelligence", icon: "📜", flutterIcon: Icons.lightbulb, category: "Intelligence", threshold: 500, colorHex: 0xFF3B82F6),
    AppBadge(id: "intel_3", name: "Scholar", description: "Capai 2000 XP Intelligence", icon: "📚", flutterIcon: Icons.menu_book, category: "Intelligence", threshold: 2000, colorHex: 0xFF3B82F6),
    AppBadge(id: "intel_4", name: "Archmage", description: "Capai 5000 XP Intelligence", icon: "🔮", flutterIcon: Icons.psychology, category: "Intelligence", threshold: 5000, colorHex: 0xFF3B82F6),
    AppBadge(id: "intel_5", name: "Omniscient", description: "Capai 9999 XP Intelligence", icon: "🧠", flutterIcon: Icons.school, category: "Intelligence", threshold: 9999, colorHex: 0xFF3B82F6),

    // --- VITALITY ---
    AppBadge(id: "vital_1", name: "Healthy Soul", description: "Capai 100 XP Vitality", icon: "🥗", flutterIcon: Icons.favorite, category: "Vitality", threshold: 100, colorHex: 0xFF10B981),
    AppBadge(id: "vital_2", name: "Enduring", description: "Capai 500 XP Vitality", icon: "❤️‍🩹", flutterIcon: Icons.health_and_safety, category: "Vitality", threshold: 500, colorHex: 0xFF10B981),
    AppBadge(id: "vital_3", name: "Immortal Breath", description: "Capai 2000 XP Vitality", icon: "🍃", flutterIcon: Icons.medical_services, category: "Vitality", threshold: 2000, colorHex: 0xFF10B981),
    AppBadge(id: "vital_4", name: "Life Force", description: "Capai 5000 XP Vitality", icon: "💖", flutterIcon: Icons.shield, category: "Vitality", threshold: 5000, colorHex: 0xFF10B981),
    AppBadge(id: "vital_5", name: "World Tree", description: "Capai 9999 XP Vitality", icon: "🌳", flutterIcon: Icons.spa, category: "Vitality", threshold: 9999, colorHex: 0xFF10B981),

    // --- DEFENSE ---
    AppBadge(id: "def_1", name: "Wooden Guard", description: "Capai 100 XP Defense", icon: "🪵", flutterIcon: Icons.security, category: "Defense", threshold: 100, colorHex: 0xFF8B5CF6),
    AppBadge(id: "def_2", name: "Iron Wall", description: "Capai 500 XP Defense", icon: "🛡️", flutterIcon: Icons.gpp_good, category: "Defense", threshold: 500, colorHex: 0xFF8B5CF6),
    AppBadge(id: "def_3", name: "Steel Fort", description: "Capai 2000 XP Defense", icon: "🏰", flutterIcon: Icons.shield_moon, category: "Defense", threshold: 2000, colorHex: 0xFF8B5CF6),
    AppBadge(id: "def_4", name: "Indestructible", description: "Capai 5000 XP Defense", icon: "💎", flutterIcon: Icons.admin_panel_settings, category: "Defense", threshold: 5000, colorHex: 0xFF8B5CF6),
    AppBadge(id: "def_5", name: "Aegis", description: "Capai 9999 XP Defense", icon: "⛩️", flutterIcon: Icons.castle, category: "Defense", threshold: 9999, colorHex: 0xFF8B5CF6),

    // --- STREAK ---
    AppBadge(id: "streak_1", name: "Warm Up", description: "Capai 3 hari streak", icon: "🔥", flutterIcon: Icons.whatshot, category: "streak", threshold: 3, colorHex: 0xFFF97316),
    AppBadge(id: "streak_2", name: "Consistent", description: "Capai 7 hari streak", icon: "🌋", flutterIcon: Icons.local_fire_department, category: "streak", threshold: 7, colorHex: 0xFFF97316),
    AppBadge(id: "streak_3", name: "Unstoppable", description: "Capai 30 hari streak", icon: "☄️", flutterIcon: Icons.flare, category: "streak", threshold: 30, colorHex: 0xFFF97316),

    // --- GOLD ---
    AppBadge(id: "gold_1", name: "Saver", description: "Kumpulkan 1000 Gold", icon: "💰", flutterIcon: Icons.monetization_on_rounded, category: "gold", threshold: 1000, colorHex: 0xFFFFD700),
    AppBadge(id: "gold_2", name: "Merchant", description: "Kumpulkan 10000 Gold", icon: "🪙", flutterIcon: Icons.paid, category: "gold", threshold: 10000, colorHex: 0xFFFFD700),
    AppBadge(id: "gold_3", name: "Billionaire", description: "Kumpulkan 99999 Gold", icon: "💎", flutterIcon: Icons.diamond, category: "gold", threshold: 99999, colorHex: 0xFFFFD700),
  ];
}

