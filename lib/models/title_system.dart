// ═══════════════════════════════════════════════════════════
//  TITLE SYSTEM - Sistem Julukan/Gelar Pemain
// ═══════════════════════════════════════════════════════════
// Sistem ini menentukan julukan pemain berdasarkan:
// 1. Rank (F-SSR) → Prefix (Novice, Apprentice, Expert, dll)
// 2. Atribut XP Tertinggi → Suffix (Warrior, Guardian, Strategist, dll)
// 3. Kondisi Khusus → Gelar Spesial (The Greatest, The Beginner)

class TitleSystem {
  // ─── Rank Prefix Mapping ─────────────────────────────────
  // Menentukan awalan gelar berdasarkan rank pemain
  static String getRankPrefix(String rank) {
    switch (rank) {
      case 'F':
      case 'E':
        return 'Novice'; // Pemula
      case 'D':
      case 'C':
        return 'Apprentice'; // Murid
      case 'B':
      case 'A':
        return 'Expert'; // Ahli
      case 'S':
      case 'SS':
        return 'Master'; // Master
      case 'SSS':
        return 'Legendary'; // Legenda
      case 'SSR':
        return 'Mythical'; // Mitos
      default:
        return 'Novice';
    }
  }

  // ─── Attribute Suffix Mapping ────────────────────────────
  // Menentukan akhiran gelar berdasarkan atribut XP tertinggi
  static String getAttributeSuffix(String highestAttribute) {
    switch (highestAttribute) {
      case 'Strength':
        return 'Warrior'; // Pejuang
      case 'Defense':
        return 'Guardian'; // Pelindung
      case 'Intelligence':
        return 'Strategist'; // Ahli Strategi
      case 'Vitality':
        return 'Immortal'; // Abadi
      case 'Agility':
        return 'Shadow'; // Bayangan
      default:
        return 'Wanderer'; // Pengembara (default)
    }
  }

  // ─── Get Player Title ────────────────────────────────────
  /// Fungsi utama untuk mendapatkan julukan lengkap pemain
  /// 
  /// Parameter:
  /// - rank: Rank pemain (F, E, D, C, B, A, S, SS, SSS, SSR)
  /// - categoryXp: Map berisi XP per kategori {'Strength': 1000, 'Defense': 500, ...}
  /// - level: Level pemain saat ini
  /// 
  /// Return: String julukan lengkap (contoh: "Expert Shadow", "The Greatest")
  static String getPlayerTitle({
    required String rank,
    required Map<String, int> categoryXp,
    required int level,
  }) {
    // 1. Cek kondisi khusus: Semua atribut 0 (belum ngerjain apa-apa)
    final totalXp = categoryXp.values.fold(0, (sum, xp) => sum + xp);
    if (totalXp == 0) {
      return 'The Beginner'; // Gelar untuk pemula yang belum mulai
    }

    // 2. Cek kondisi khusus: Rank SSR + Level tinggi + Semua atribut tinggi
    if (rank == 'SSR' && level >= 150) {
      // Cek apakah semua atribut sudah mencapai threshold tinggi (misal: 9000+)
      final allAttributesHigh = categoryXp.values.every((xp) => xp >= 9000);
      if (allAttributesHigh) {
        return 'The Greatest'; // Gelar tertinggi untuk yang sudah maksimal semua
      }
    }

    // 3. Tentukan atribut dengan XP tertinggi
    String highestAttribute = 'Strength';
    int highestXp = 0;
    
    categoryXp.forEach((attribute, xp) {
      if (xp > highestXp) {
        highestXp = xp;
        highestAttribute = attribute;
      }
    });

    // 4. Gabungkan Prefix (dari Rank) + Suffix (dari Atribut)
    final prefix = getRankPrefix(rank);
    final suffix = getAttributeSuffix(highestAttribute);
    
    return '$prefix $suffix';
  }

  // ─── Get Title Color ─────────────────────────────────────
  /// Menentukan warna julukan berdasarkan rank
  static int getTitleColorHex(String rank) {
    switch (rank) {
      case 'F':
        return 0xFF9E9E9E; // Abu-abu
      case 'E':
        return 0xFFFFFFFF; // Putih
      case 'D':
        return 0xFF4CAF50; // Hijau
      case 'C':
        return 0xFF2196F3; // Biru
      case 'B':
        return 0xFF9C27B0; // Ungu
      case 'A':
        return 0xFFFF9800; // Orange
      case 'S':
        return 0xFFF44336; // Merah
      case 'SS':
        return 0xFFFFD700; // Gold
      case 'SSS':
        return 0xFFFF1744; // Merah Terang
      case 'SSR':
        return 0xFFE91E63; // Pink/Magenta (Rainbow effect)
      default:
        return 0xFFFFFFFF;
    }
  }

  // ─── Get Title Icon ──────────────────────────────────────
  /// Menentukan emoji/icon untuk julukan berdasarkan kondisi
  static String getTitleIcon(String title) {
    if (title == 'The Greatest') return '👑'; // Mahkota untuk yang terhebat
    if (title == 'The Beginner') return '🌱'; // Tunas untuk pemula
    if (title.contains('Mythical')) return '✨'; // Bintang untuk Mythical
    if (title.contains('Legendary')) return '⭐'; // Bintang untuk Legendary
    if (title.contains('Master')) return '🔥'; // Api untuk Master
    if (title.contains('Expert')) return '💎'; // Berlian untuk Expert
    if (title.contains('Apprentice')) return '📚'; // Buku untuk Apprentice
    if (title.contains('Novice')) return '🎯'; // Target untuk Novice
    return '⚔️'; // Pedang default
  }

  // ─── Get All Possible Titles ─────────────────────────────
  /// Mengembalikan daftar semua kemungkinan julukan untuk referensi
  static List<String> getAllPossibleTitles() {
    final prefixes = ['Novice', 'Apprentice', 'Expert', 'Master', 'Legendary', 'Mythical'];
    final suffixes = ['Warrior', 'Guardian', 'Strategist', 'Immortal', 'Shadow'];
    
    final titles = <String>['The Beginner', 'The Greatest'];
    
    for (var prefix in prefixes) {
      for (var suffix in suffixes) {
        titles.add('$prefix $suffix');
      }
    }
    
    return titles;
  }

  // ─── Get Title Description ───────────────────────────────
  /// Memberikan deskripsi untuk setiap julukan
  static String getTitleDescription(String title, {bool isEnglish = false}) {
    if (title == 'The Greatest') {
      return isEnglish 
        ? 'The ultimate title for those who have mastered all attributes and reached the pinnacle of power.'
        : 'Gelar tertinggi untuk mereka yang telah menguasai semua atribut dan mencapai puncak kekuatan.';
    }
    
    if (title == 'The Beginner') {
      return isEnglish
        ? 'A fresh start. Complete your first quest to earn a new title!'
        : 'Awal yang baru. Selesaikan quest pertamamu untuk mendapat gelar baru!';
    }

    // Deskripsi berdasarkan suffix
    if (title.contains('Warrior')) {
      return isEnglish
        ? 'A fierce combatant who excels in physical strength and power.'
        : 'Pejuang tangguh yang unggul dalam kekuatan fisik dan daya tempur.';
    }
    
    if (title.contains('Guardian')) {
      return isEnglish
        ? 'A stalwart defender who protects and endures through any challenge.'
        : 'Pelindung setia yang bertahan dan melindungi dalam segala tantangan.';
    }
    
    if (title.contains('Strategist')) {
      return isEnglish
        ? 'A brilliant mind who conquers through knowledge and wisdom.'
        : 'Pikiran cemerlang yang menaklukkan melalui pengetahuan dan kebijaksanaan.';
    }
    
    if (title.contains('Immortal')) {
      return isEnglish
        ? 'An enduring soul who maintains peak health and vitality.'
        : 'Jiwa abadi yang menjaga kesehatan dan vitalitas puncak.';
    }
    
    if (title.contains('Shadow')) {
      return isEnglish
        ? 'A swift and agile warrior who strikes with speed and precision.'
        : 'Pejuang lincah dan cepat yang menyerang dengan kecepatan dan presisi.';
    }

    return isEnglish
      ? 'A unique title earned through dedication and perseverance.'
      : 'Gelar unik yang diraih melalui dedikasi dan ketekunan.';
  }
}
