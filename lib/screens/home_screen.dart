import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widget/custom_navbar.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import 'login_screen.dart';
import 'add_task_screen.dart';
import 'daily_screen.dart';
import 'statistic_screen.dart';
import '../models/app_schema.dart';
import '../widget/screen_header.dart';
import '../services/notification_service.dart';
import 'profile_screen.dart';
import '../widget/avatar_preview.dart';
import '../widget/dev_tools_sheet.dart';
import '../widget/rpg_tutorial_overlay.dart';
import '../widget/rank_up_overlay.dart';
import '../widget/level_up_overlay.dart';
import '../widget/rpg_loading.dart';
import '../widget/active_buffs_widget.dart';
import '../theme/rpg_theme.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';
import '../widget/theme_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Use dynamic AppColors instead of static RPGColors
  static Map<String, Color> get catColors => RPGColors.catColors;
  static Map<String, IconData> get catIcons => RPGIcons.catIcons;

  static const Map<String, Map<String, List<String>>> catGroups = {
    'Strength': {
      'Latihan Beban': ['Chest Day', 'Leg Day', 'Back Day'],
      'Calisthenics': ['Push-up 100x', 'Pull-up', 'Dips'],
      'Olahraga Air': ['Renang 30 Menit'],
      'Combat': ['Boxing', 'Muay Thai'],
    },
    'Intelligence': {
      'Skill Teknis': ['Ngoding Flutter', 'Desain UI/UX'],
      'Literasi': ['Baca Buku 10 Hal', 'Ringkasan Artikel'],
      'Bahasa': ['Belajar 5 Kosakata Baru', 'Latihan Grammar'],
      'Logika': ['Main Catur', 'Sudoku'],
    },
    'Defense': {
      'Mindfulness': ['Meditasi 5 Menit'],
      'Refleksi': ['Journaling Malam'],
      'Stoicism': ['Latihan Kontrol Emosi'],
      'Digital Detox': ['1 Jam Tanpa HP'],
    },
    'Agility': {
      'Cardio Lari': ['Jogging 20 Menit', 'Lari 5K'],
      'Sport': ['Badminton', 'Futsal'],
      'Endurance': ['Bersepeda 30 Menit'],
      'HIIT': ['HIIT 15 Menit'],
    },
    'Vitality': {
      'Kualitas Tidur': ['Tidur Sebelum Jam 10'],
      'Hidrasi': ['Minum 2L Air'],
      'Nutrisi': ['Makan Serat/Protein', 'Sarapan Sehat'],
      'Recovery': ['Stretching/Yoga'],
    },
  };

  // State
  String _userName = 'User';
  String _username = '';
  int _xp = 0, _level = 1, _hp = 80, _coin = 0;
  int _maxHp = 100;
  String _rank = 'F';
  String? _lastRank;
  int? _lastLevel;
  String _role = 'user';
  int _currentIndex = 0;
  bool _isRecentExpanded = false;
  final Map<String, bool> _expandedCats = {};
  Map<String, String> _equippedItems = {};
  Timestamp? _xpBonusUntil;
  Timestamp? _goldBonusUntil;
  String? _baseBody;
  Offset _godModeOffset = const Offset(
    16,
    50,
  ); // Initial position (top right-ish)

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted || !doc.exists) return;
    final d = doc.data()!;
    setState(() {
      _userName = d[UserSchema.name] ?? 'User';
      _username = d[UserSchema.username] ?? '';
      _xp = d[UserSchema.xp] ?? 0;
      _level = d['level'] ?? 1;
      _hp = d[UserSchema.hp] ?? d['hp'] ?? 80;
      _maxHp = d[UserSchema.maxHp] ?? 100;
      _coin = d[UserSchema.gold] ?? d['coin'] ?? 0;
      _role = d[UserSchema.role] ?? 'user';
      _rank = _getRank(d);
      _lastRank = _rank;
      _lastLevel = _level;
      if (d[UserSchema.equippedItems] != null) {
        _equippedItems = Map<String, String>.from(d[UserSchema.equippedItems]);
      }
      _xpBonusUntil = d[UserSchema.xpBonusUntil] as Timestamp?;
      _goldBonusUntil = d[UserSchema.goldBonusUntil] as Timestamp?;
      _baseBody = d[UserSchema.baseBody] as String?;
      _checkPendingTasksAndNotify(uid);
    });
  }

  // --- SISTEM PENGINGAT (REMINDER/NOTIFICATION SYSTEM) ---
  /// Fungsi ini berjalan otomatis di latar belakang saat Dashboard (Home) terbuka.
  /// Tugasnya adalah mengecek apakah user memiliki task hari ini yang belum dicentang selesai,
  /// dan memunculkan notifikasi (Push Notification) di HP jika memang ada.
  Future<void> _checkPendingTasksAndNotify(String uid) async {
    // 1. Tentukan batas waktu hari ini (Jam 00:00 hari ini sampai Jam 00:00 besoknya)
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 2. Tarik semua data dari Firebase di mana status "done" = false (belum dikerjakan)
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where(TaskSchema.done, isEqualTo: false)
        .get();

    // 3. Saring (Filter) datanya secara lokal di HP
    // Catatan Sidang: Kenapa difilter di HP, bukan langsung dari Query Firebase?
    // Karena query berdasarkan rentang tanggal (range query) di Firebase sering bentrok
    // dengan query boolean (done = false) jika index (aturan database) belum di-setting manual di Firebase Console.
    final todayTasks = snap.docs.where((d) {
      final ts = d.data()[TaskSchema.createdAt] as Timestamp?;
      if (ts == null) return false;
      final dt = ts.toDate(); // Ubah format waktu server ke waktu lokal
      
      // Kembalikan TRUE hanya jika task ini dibuat HARI INI
      return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
    }).toList();

    // 4. Jika ada task hari ini yang belum selesai, kirim Notifikasi ke layar atas HP
    if (todayTasks.isNotEmpty && mounted) {
      // Kita panggil LocaleService secara langsung tanpa context watch agar tidak bentrok dengan widget tree
      final locSvc = Provider.of<LocaleService>(context, listen: false);
      final l = locSvc.l; // Ambil kamus bahasanya
      
      // Panggil fungsi Notifikasi Lokal (Tampil di panel notifikasi HP)
      await NotificationService().showNotification(
        id: 999, // ID statis agar notifikasi lama tertumpuk/ter-update oleh yang baru
        title: l.notifPendingTitle(todayTasks.length),
        body: l.notifPendingBody(todayTasks.length),
      );
    }
  }

  Future<void> _logout() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String _getRank(Map<String, dynamic> d) => RankSystem.calculateRank(
    d['level'] ?? 1,
    str: d[UserSchema.strengthXp] ?? 0,
    def: d[UserSchema.defenseXp] ?? 0,
    intl: d[UserSchema.intelligenceXp] ?? 0,
    vit: d[UserSchema.vitalityXp] ?? 0,
    agi: d[UserSchema.agilityXp] ?? 0,
  );

  Color _getRankColor(String r) {
    Color color = Color(RankSystem.rankColorHex(r));
    if ((AppColors.currentTheme == AppThemeType.lightMode || AppColors.currentTheme == AppThemeType.anime) && color == const Color(0xFFFFFFFF)) {
      return AppColors.primary; // Make SSR visible in light/anime modes
    }
    return color;
  }

  int _xpNext(int lv) => 100 + (lv - 1) * 50;

  Widget _getScreen() {
    switch (_currentIndex) {
      case 0:
        return _homeView();
      case 1:
        return const DailyScreen();
      case 2:
        return StatisticScreen(); // Removed const
      case 3:
        return const ProfileScreen();
      default:
        return _homeView();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const RpgLoading();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        Map<String, dynamic> tutorialsCompleted = {};
        if (snapshot.hasData && snapshot.data!.exists) {
          final d = snapshot.data!.data() as Map<String, dynamic>;
          _userName = d[UserSchema.name] ?? 'User';
          _username = d[UserSchema.username] ?? '';
          _xp = d[UserSchema.xp] ?? 0;
          _level = d['level'] ?? 1;
          _hp = d[UserSchema.hp] ?? d['hp'] ?? 80;
          _maxHp = d[UserSchema.maxHp] ?? 100;
          _coin = d[UserSchema.gold] ?? d['coin'] ?? 0;
          _role = d[UserSchema.role] ?? 'user';
          
          final newRank = _getRank(d);
          final newLevel = d['level'] ?? 1;

          if (mounted) {
            bool rankChanged = _lastRank != null && _lastRank != newRank;
            bool levelChanged = _lastLevel != null && _lastLevel != newLevel;
            
            if (rankChanged || levelChanged) {
              final newTitle = RankSystem.getDynamicTitle(
                d[UserSchema.strengthXp] ?? 0,
                d[UserSchema.defenseXp] ?? 0,
                d[UserSchema.intelligenceXp] ?? 0,
                d[UserSchema.vitalityXp] ?? 0,
                d[UserSchema.agilityXp] ?? 0,
                newRank,
                newLevel,
                d[UserSchema.totalTasksDone] ?? 0,
              );

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  if (rankChanged) {
                    RankUpOverlay.show(context, newRank: newRank, title: newTitle);
                  } else if (levelChanged) {
                    LevelUpOverlay.show(context, newLevel: newLevel, title: newTitle);
                  }
                }
              });
            }
          }

          _lastRank = newRank;
          _rank = newRank;
          _lastLevel = newLevel;
          
          if (d[UserSchema.equippedItems] != null) {
            _equippedItems = Map<String, String>.from(
              d[UserSchema.equippedItems],
            );
          }
          _xpBonusUntil = d[UserSchema.xpBonusUntil] as Timestamp?;
          _goldBonusUntil = d[UserSchema.goldBonusUntil] as Timestamp?;
          _baseBody = d[UserSchema.baseBody] as String?;

          if (d['tutorialsCompleted'] != null) {
            tutorialsCompleted = Map<String, dynamic>.from(d['tutorialsCompleted']);
          }
        }

        final String currentTabName;
        final List<String> currentSteps;
        final l = context.lw;
        switch (_currentIndex) {
          case 0:
            currentTabName = 'home';
            currentSteps = l.tutorialHome;
            break;
          case 1:
            currentTabName = 'daily';
            currentSteps = l.tutorialDaily;
            break;
          case 2:
            currentTabName = 'stats';
            currentSteps = l.tutorialStats;
            break;
          case 3:
            currentTabName = 'profile';
            currentSteps = l.tutorialProfile;
            break;
          default:
            currentTabName = 'home';
            currentSteps = l.tutorialHome;
        }
        final bool isTutorialCompleted = tutorialsCompleted[currentTabName] ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              SafeArea(child: _getScreen()),
              if (_role == 'admin')
                Positioned(
                  top: _godModeOffset.dy,
                  left:
                      MediaQuery.of(context).size.width -
                      _godModeOffset.dx -
                      50,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        double newY = _godModeOffset.dy + details.delta.dy;
                        double newX = _godModeOffset.dx - details.delta.dx;
                        newY = newY.clamp(
                          20.0,
                          MediaQuery.of(context).size.height - 150,
                        );
                        newX = newX.clamp(
                          0.0,
                          MediaQuery.of(context).size.width - 60,
                        );
                        _godModeOffset = Offset(newX, newY);
                      });
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DevToolsSheet(
                              userData: {
                                UserSchema.gold: _coin,
                                UserSchema.level: _level,
                                UserSchema.xp: _xp,
                              },
                              onUpdated: () {}, // No longer need manual refresh
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                              width: AppColors.borderWidth * 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.bolt,
                            color: Colors.amber,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (!isTutorialCompleted)
                RpgTutorialOverlay(
                  steps: currentSteps,
                  onCompleted: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      'tutorialsCompleted.$currentTabName': true,
                    });
                  },
                  onSkipped: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      'tutorialsCompleted.home': true,
                      'tutorialsCompleted.daily': true,
                      'tutorialsCompleted.stats': true,
                      'tutorialsCompleted.profile': true,
                    });
                  },
                ),
            ],
          ),
          bottomNavigationBar: CustomNavbar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
            },
            onTaskAdded: () {}, // No longer need manual refresh
            onAddPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTaskSheet(onTaskAdded: () {}),
              );
            },
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════
  //  HOME VIEW — Tampilan Utama Dashboard RPG
  // ══════════════════════════════════════════
  Widget _homeView() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();
    
    // 1. Hitung batasan waktu untuk hari ini (Dari jam 00:00 hari ini sampai 00:00 besok)
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // 2. Cek apakah HP (Health Point) pemain sedang sekarat (kurang dari 20)
    final isCritical = _hp < 20;

    // 3. Mengambil data misi (tasks) secara langsung dan terus-menerus (Stream) dari Firebase
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .snapshots(),
      builder: (context, snap) {
        final allDocs = snap.data?.docs ?? [];
        
        // 4. Memfilter hanya misi-misi yang dibuat HARI INI
        final todayDocs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final ts = data[TaskSchema.createdAt] as Timestamp?;
          if (ts == null) return false;
          final dt = ts.toDate();
          return dt.isAfter(todayStart) && dt.isBefore(todayEnd);
        }).toList();
        
        // 5. Menghitung jumlah misi hari ini yang SUDAH SELESAI (done = true)
        final doneCount = todayDocs
            .where((d) => (d.data() as Map<String, dynamic>)['done'] == true)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar / Header Logo
              const ScreenHeader(title: 'Home'),
              _buildHeader(), // Kartu Profil Pemain (Nama, HP, Level, XP)
              SizedBox(height: 12),
              _buildDailyProgress(doneCount, todayDocs.length), // Progress Bar Harian
              SizedBox(height: 12),
              // Jika sekarat munculkan peringatan, jika aman munculkan kata mutiara
              isCritical ? _buildVitalityAlert() : _buildMotivationCard(),
              SizedBox(height: 16),
              _buildCategoryBoard(allDocs), // Daftar Kategori (Strength, Agility, dll)
              SizedBox(height: 20),
              Text(
                context.lw.homeRecentActivity,
                style: GoogleFonts.nunito(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _buildRecentActivity(uid), // Riwayat aktivitas (History)
            ],
          ),
        );
      },
    );
  }

  // --- BAGIAN DAFTAR KATEGORI ---
  // Fungsi ini bertugas menggambar judul "Category List" beserta seluruh dropdown kategori.
  Widget _buildCategoryBoard(List<QueryDocumentSnapshot> allDocs) {
    final l = context.lw;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.isEn ? 'Category List' : 'Daftar Kategori',
          style: GoogleFonts.nunito(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        // Melakukan perulangan (loop) pada setiap kategori (Strength, Intelligence, dll)
        // dan merendernya menggunakan fungsi _buildExpandableCategory
        ...catGroups.keys.map((catName) => _buildExpandableCategory(catName, allDocs)),
      ],
    );
  }

  // Fungsi ini bertugas menggambar SATU blok kategori (Misal: khusus Strength saja).
  // Di dalamnya terdapat logika perhitungan level/mastery dan daftar misi-misi default (preset).
  Widget _buildExpandableCategory(String cat, List<QueryDocumentSnapshot> allDocs) {
    final l = context.lw;
    
    // 1. Cek apakah kategori ini sedang dibuka (expanded) atau ditutup (collapsed)
    final isExpanded = _expandedCats[cat] ?? (cat == 'Strength');
    
    // 2. Ambil warna dan ikon khusus untuk kategori ini dari RPGColors
    final color = catColors[cat] ?? AppColors.textPrimary;
    final icon = catIcons[cat] ?? Icons.star_rounded;
    
    // 3. Ambil daftar misi bawaan (preset) untuk kategori ini
    final group = catGroups[cat] ?? {};

    int totalPresets = 0;
    group.forEach((sub, list) => totalPresets += list.length);

    // 4. Hitung berapa banyak misi dari kategori ini yang SUDAH diselesaikan oleh user
    // Ini berguna untuk menentukan "Mastery Tier" (tingkat kemahiran) user di kategori ini
    final completedCount = allDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['category'] == cat && data['done'] == true;
    }).length;

    // 5. Fungsi kecil untuk menentukan pangkat/tier berdasarkan jumlah misi yang selesai
    String getMasteryTier(int count) {
      if (count >= 30) return 'MASTER'; // Selesai 30+ misi
      if (count >= 15) return 'TIER III';
      if (count >= 5) return 'TIER II';
      return 'TIER I'; // Pemula
    }
    final tier = getMasteryTier(completedCount);

    // 6. Konversi tier menjadi huruf Rank (S, A, B, C) untuk ditampilkan di UI
    String getRankLetter(String tierName) {
      switch (tierName) {
        case 'MASTER': return 'S';
        case 'TIER III': return 'A';
        case 'TIER II': return 'B';
        case 'TIER I':
        default: return 'C';
      }
    }
    final rankLetter = getRankLetter(tier);

    // 7. Tentukan warna pita (ribbon) berdasarkan Rank
    Color getRibbonColor(String tierName) {
      switch (tierName) {
        case 'MASTER': return const Color(0xFFFFB300); // Gold untuk Rank S
        case 'TIER III': return const Color(0xFFC62828); // Crimson untuk Rank A
        case 'TIER II': return const Color(0xFF1E88E5); // Biru untuk Rank B
        case 'TIER I':
        default: return const Color(0xFF757575); // Abu-abu untuk Rank C
      }
    }
    final ribbonColor = getRibbonColor(tier);

    // 8. Hitung berapa banyak misi di kategori ini yang SEDANG berjalan (belum selesai)
    final activeQuestsCount = allDocs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      return data['category'] == cat && data['done'] == false;
    }).length;

    // Menggunakan ThemeCard agar mendukung border komik //
    return ThemeCard(
      margin: const EdgeInsets.only(bottom: 12),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      borderColor: isExpanded
          ? color.withValues(alpha: 0.6) // Glowing neon category outline
          : AppColors.accent.withValues(alpha: 0.18), // Brass Trim
      borderWidth: AppColors.borderWidth,
      boxShadow: isExpanded
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              )
            ]
          : [],
      child: Column(
        children: [
          // Header Row
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              // AudioService.playClick();
              setState(() {
                _expandedCats[cat] = !isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Dual-Ring concentric Rune circle frame wrapping the main category icon
                  // Menggunakan ThemeCard untuk cincin ikon kategori (bulat) //
                  ThemeCard(
                    padding: const EdgeInsets.all(3),
                    isCircle: true,
                    borderColor: color.withValues(alpha: 0.3),
                    borderWidth: AppColors.borderWidth * 1.5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // Title, Hero Class Badge and active quests stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l.catName(cat),
                              style: GoogleFonts.nunito(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 6),
                            // Mapped static RPG hero class badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                  width: AppColors.borderWidth,
                                ),
                              ),
                              child: Text(
                                l.className(cat),
                                style: GoogleFonts.outfit(
                                  color: color,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          activeQuestsCount > 0
                              ? '$activeQuestsCount ${l.isEn ? 'Active Quest(s)' : 'Misi Aktif'}'
                              : (l.isEn ? 'No Active Quests' : 'Misi Selesai / Kosong'),
                          style: GoogleFonts.nunito(
                            color: activeQuestsCount > 0 ? color.withValues(alpha: 0.8) : AppColors.textPrimary.withValues(alpha: 0.30),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mapped Rank Ribbon Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ribbonColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ribbonColor.withValues(alpha: 0.4),
                        width: AppColors.borderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          rankLetter,
                          style: GoogleFonts.outfit(
                            color: ribbonColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'RANK',
                          style: GoogleFonts.outfit(
                            color: ribbonColor.withValues(alpha: 0.6),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // 9. Jika kategori di-expand (diklik/dibuka), tampilkan daftar sub-kategori & misi bawaan
          if (isExpanded) ...[
            Divider(color: AppColors.textDisabled, height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: group.entries.map((entry) {
                  final subName = entry.key;
                  final taskList = entry.value;
                  final isLastSub = entry.key == group.keys.last;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subcategory title with color line accent
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, top: 4),
                        child: Row(
                          children: [
                            Container(
                              width: AppColors.borderWidth * 3,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.subCatName(subName),
                              style: GoogleFonts.nunito(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 10. Menampilkan "Chip" (tombol kecil) untuk setiap misi bawaan
                      // Chip ini dibungkus dengan Wrap agar otomatis turun ke baris baru jika layarnya penuh
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: taskList.map((presetTask) {
                          return InkWell(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              // AudioService.playClick();
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AddTaskSheet(
                                  onTaskAdded: _loadUserData,
                                  initialCategory: cat,
                                  initialTitle: presetTask,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                  width: AppColors.borderWidth,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, color: color, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    l.questName(presetTask),
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (!isLastSub) const SizedBox(height: 14),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Header (Kartu Profil) ──────────────────────────────────────────
  // Fungsi ini bertugas menggambar bagian paling atas layar yang berisi:
  // Foto avatar, Nama, Rank, Level, HP (darah), XP, dan Jumlah Koin.
  Widget _buildHeader() {
    // 1. Hitung total XP yang dibutuhkan untuk naik ke level berikutnya
    final xpN = _xpNext(_level);
    
    // 2. Hitung persentase XP saat ini (untuk mengisi bar progress)
    final xpProg = (_xp % xpN) / xpN;
    
    // 3. Hitung persentase Darah (HP) saat ini
    final eProg = _hp / _maxHp;
    
    // 4. Dapatkan warna pangkat (misalnya SSR warna pelangi, A warna merah, dll)
    final rc = _getRankColor(_rank);
    final isSSR = _rank == 'SSR';

    // Menggunakan ThemeCard agar header terlihat memiliki tema komik //
    return ThemeCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.cardBorder,
      borderWidth: AppColors.borderWidth,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Container menggunakan ThemeCard //
              SizedBox(
                width: 84,
                height: 84,
                child: ThemeCard(
                  backgroundColor: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  borderColor: AppColors.primary.withValues(alpha: 0.3),
                  borderWidth: AppColors.borderWidth * 2,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                child: AvatarPreview(
                  equippedItems: _equippedItems,
                  size: 84,
                  showBackground: true,
                  baseBody: _baseBody,
                ),
              ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '@$_username',
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary.withValues(alpha: 0.54),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: rc.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: rc.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                        boxShadow: isSSR
                            ? [
                                BoxShadow(
                                  color: rc.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSSR) ...[
                            Text('✨', style: TextStyle(fontSize: 10)),
                            SizedBox(width: AppColors.borderWidth * 3),
                          ],
                          Text(
                            '$_rank  •  Lv.$_level',
                            style: GoogleFonts.nunito(
                              color: rc,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    // Active Buffs Row
                    ActiveBuffsWidget(equippedItems: _equippedItems, xpBonusUntil: _xpBonusUntil, goldBonusUntil: _goldBonusUntil),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        color: AppColors.gold,
                        size: 18,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '$_coin',
                        style: GoogleFonts.nunito(
                          color: AppColors.gold,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            context.lw.isEn ? 'Logout' : 'Logout',
                            style: GoogleFonts.nunito(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          _bar(
            'HP',
            Icons.favorite_rounded,
            _hp,
            _maxHp,
            eProg,
            AppColors.hp,
          ),
          SizedBox(height: 4),
          _bar(
            'XP',
            Icons.star_rounded,
            _xp % xpN,
            xpN,
            xpProg,
            AppColors.xp,
          ),
        ],
      ),
    );
  }

  Widget _buildBuffBadge(String emoji, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            text,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi bantuan (helper) untuk menggambar bar (baik untuk HP maupun XP)
  Widget _bar(
    String label, // Contoh: "HP" atau "XP"
    IconData ic,  // Ikon (Hati untuk HP, Bintang untuk XP)
    int val,      // Nilai saat ini
    int mx,       // Nilai maksimal
    double prog,  // Persentase (0.0 sampai 1.0)
    Color c,      // Warna bar (misal: Merah untuk HP)
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ic, color: c, size: 13),
            SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary.withValues(alpha: 0.60),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Text(
              '$val / $mx',
              style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 9,
            color: c.withValues(alpha: 0.12),
            child: FractionallySizedBox(
              widthFactor: prog.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c, c.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Daily Progress (Progres Harian) ──────────────────────────────────
  // Menampilkan kotak dengan progress bar yang menunjukkan persentase misi 
  Widget _buildDailyProgress(int done, int total) {
    // Hindari error pembagian dengan nol (0) jika total task = 0
    final p = total == 0 ? 0.0 : done / total;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flag_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.lw.isEn ? 'Today\'s Progress' : 'Progress Hari Ini',
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '$done/$total ${context.lw.isEn ? 'task(s)' : 'task'}',
                      style: GoogleFonts.nunito(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: p,
                          minHeight: 6,
                          backgroundColor: AppColors.textPrimary.withValues(alpha: 0.10),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      '${(p * 100).toInt()}%',
                      style: GoogleFonts.nunito(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Alert / Motivasi (Peringatan & Kata Mutiara) ────────────────────────────────
  // Muncul apabila HP karakter sedang kritis (< 20)
  Widget _buildVitalityAlert() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.lw.isEn ? 'Your Character is Exhausted!' : 'Karaktermu Lelah!',
                  style: GoogleFonts.nunito(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Energy di bawah 20%. Ambil task Vitality sebelum HP berkurang!',
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary.withValues(alpha: 0.54),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Muncul secara acak setiap hari jika HP pemain sedang aman (tidak kritis)
  Widget _buildMotivationCard() {
    final l = context.lw;
    final q = l.isEn ? [
      'Consistency is the key. Complete one task today!',
      'Every small step builds a powerful character.',
      'Level up comes not from one effort, but from habit.',
      'Start first, perfect later.',
    ] : [
      'Konsistensi adalah kuncinya. Kerjakan satu task hari ini!',
      'Setiap langkah kecil membentuk karakter yang kuat.',
      'Level naik bukan dari satu usaha, tapi dari kebiasaan.',
      'Mulai dulu, sempurna belakangan.',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              q[DateTime.now().day % q.length],
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary.withValues(alpha: 0.8),
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Activity (Riwayat Aktivitas Terakhir) ─────────────────────────────────
  // Menampilkan 3 misi terakhir yang baru saja diselesaikan oleh pemain.
  Widget _buildRecentActivity(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where(TaskSchema.done, isEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        var docs = List<QueryDocumentSnapshot>.from(snap.data?.docs ?? []);
        
        // Mengurutkan misi secara lokal (di HP) dari yang paling BARU selesai ke yang terlama.
        // Hal ini dilakukan agar tidak perlu menyetel "composite index" secara manual di Firebase.
        docs.sort((a, b) {
          final tA = (a.data() as Map)[TaskSchema.completedAt] as Timestamp?;
          final tB = (b.data() as Map)[TaskSchema.completedAt] as Timestamp?;
          if (tA == null) return 1;
          if (tB == null) return -1;
          return tB.compareTo(tA);
        });
        final totalDocs = docs.length;
        if (!_isRecentExpanded && docs.length > 3) docs = docs.sublist(0, 3);
        else if (_isRecentExpanded && docs.length > 10) docs = docs.sublist(0, 10);
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Center(
              child: Text(
                context.lw.isEn ? 'No completed activity yet' : 'Belum ada aktivitas selesai',
                style: GoogleFonts.nunito(color: AppColors.textHint, fontSize: 12),
              ),
            ),
          );
        }
        // Menggunakan ThemeCard agar modal bawah sesuai tema //
        return ThemeCard(
          backgroundColor: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          borderColor: AppColors.cardBorder,
          child: Column(
            children: docs.asMap().entries.map<Widget>((e) {
              final i = e.key;
              final data = e.value.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Task';
              final cat = data['category'] ?? 'Strength';
              final xp = data[TaskSchema.xp] ?? 20;
              final ts = data[TaskSchema.completedAt] as Timestamp?;
              final t = ts != null ? _fmtTime(ts.toDate()) : (context.lw.isEn ? 'Just now' : 'Baru saja');

              return Column(
                children: [
                  if (i > 0) Divider(color: AppColors.textPrimary.withValues(alpha: 0.10), height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.nunito(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '$t  •  $cat',
                                style: GoogleFonts.nunito(
                                  color: AppColors.textPrimary.withValues(alpha: 0.38),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.xp.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+$xp XP',
                            style: GoogleFonts.nunito(
                              color: AppColors.xp,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList()..addAll([
              if (totalDocs > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRecentExpanded = !_isRecentExpanded;
                    });
                  },
                  child: Text(
                    _isRecentExpanded 
                        ? (context.lw.isEn ? 'Show Less' : 'Tampilkan Lebih Sedikit')
                        : (context.lw.isEn ? 'Show More' : 'Tampilkan Lebih Banyak'),
                    style: GoogleFonts.nunito(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }

  String _fmtTime(DateTime dt) {
    final now = DateTime.now();
    final l = context.lw;
    if (dt.day == now.day && dt.month == now.month) {
      return '${l.isEn ? 'Today' : 'Hari ini'} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (dt.day == now.day - 1) return l.isEn ? 'Yesterday' : 'Kemarin';
    return '${dt.day}/${dt.month}';
  }
}


