import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_schema.dart';
import '../widget/screen_header.dart';
import '../widget/avatar_preview.dart';
import '../widget/rpg_tutorial_overlay.dart';
import '../services/locale_service.dart';
import 'history_screen.dart';
import '../theme/rpg_theme.dart';
import '../theme/app_theme.dart';
import '../widget/theme_card.dart';
import '../widget/performance_chart.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen>
    with TickerProviderStateMixin {
  static Color get bgDark => AppColors.background;
  static Color get cardDark => AppColors.cardBackground;

  static Map<String, Color> get catColors => RPGColors.catColors;
  static Map<String, IconData> get catIcons => RPGIcons.catIcons;

  static const List<String> rankOrder = ['F', 'E', 'D', 'C', 'B', 'A', 'S', 'SS', 'SSS', 'SSR'];

  String _name = 'User';
  int _level = 1;
  int _xp = 0;
  String _rank = 'E';
  int _streak = 0;
  int _longestStreak = 0;
  int _totalDone = 0;
  int _totalFailed = 0;
  int _gold = 0;
  int _hp = 0;
  int _maxHp = 100;

  int _strengthXp = 0;
  int _defenseXp = 0;
  int _intelligenceXp = 0;
  int _vitalityXp = 0;
  int _agilityXp = 0;
  List<String> _equippedBadges = [];
  bool _isLoading = true;

  StreamSubscription<DocumentSnapshot>? _userSub;

  // Leaderboard tutorial
  bool _showLeaderboardTutorial = false;

  static const List<String> _leaderboardTutorialSteps = [
    'Selamat datang di **Hall of Champions**! Di sini kamu bisa melihat peringkat global seluruh Hero yang bertarung di Dunia RPG Task.',
    'Posisi di papan ini ditentukan oleh **Level** karaktermu. Semakin banyak misi yang kamu selesaikan, semakin tinggi levelmu dan posisimu!',
    'Perhatikan **#1, #2, #3** — mereka adalah para legend! Kalahkan mereka dengan rajin menyelesaikan misi harian dan mingguanmu.',
    'Baris yang disorot **ungu** adalah posisimu sendiri. Ketuk nama hero lain untuk melihat profil dan avatar mereka!',
  ];

  late AnimationController _barCtrl;
  late Animation<double> _barAnim;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _barCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;

      final d = doc.data()!;
      setState(() {
        _name = d[UserSchema.name] ?? 'User';
        _level = d[UserSchema.level] ?? 1;
        _xp = d[UserSchema.xp] ?? 0;
        
        _strengthXp = d[UserSchema.strengthXp] ?? 0;
        _defenseXp = d[UserSchema.defenseXp] ?? 0;
        _intelligenceXp = d[UserSchema.intelligenceXp] ?? 0;
        _vitalityXp = d[UserSchema.vitalityXp] ?? 0;
        _agilityXp = d[UserSchema.agilityXp] ?? 0;
        
        _rank = RankSystem.calculateRank(_level, str: _strengthXp, def: _defenseXp, intl: _intelligenceXp, vit: _vitalityXp, agi: _agilityXp);
        _streak = d[UserSchema.streak] ?? 0;
        _longestStreak = d[UserSchema.longestStreak] ?? 0;
        _totalDone = d[UserSchema.totalTasksDone] ?? 0;
        _totalFailed = d[UserSchema.totalTasksFailed] ?? 0;
        _gold = d[UserSchema.gold] ?? 0;
        _hp = d[UserSchema.hp] ?? 0;
        _maxHp = d[UserSchema.maxHp] ?? 100;
        
        _equippedBadges = List<String>.from(d[UserSchema.equippedBadges] ?? []);
        _isLoading = false;
      });
      _barCtrl.forward();

      // Check leaderboard tutorial
      final tutData = doc.data()!;
      final tutMap = tutData['tutorialsCompleted'] as Map<String, dynamic>? ?? {};
      final lbDone = tutMap['leaderboard'] as bool? ?? false;
      if (!lbDone && mounted) {
        setState(() => _showLeaderboardTutorial = true);
      }
    });
  }

  Future<void> _markLeaderboardTutorialDone(String uid) async {
    setState(() => _showLeaderboardTutorial = false);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'tutorialsCompleted.leaderboard': true});
  }

  Color _rankColor(String rank) {
    Color color = Color(RankSystem.rankColorHex(rank));
    if ((AppColors.currentTheme == AppThemeType.lightMode || AppColors.currentTheme == AppThemeType.anime) && color == const Color(0xFFFFFFFF)) {
      return AppColors.primary; // Use primary color for SSR in light/anime mode instead of white
    }
    return color;
  }

  int get _xpForThisLevel => RankSystem.xpForLevel(_level);

  // ── Gelar Pemain Dinamis (Dynamic Title) ───────────────────────────
  // Memberikan gelar spesial (Title) berdasarkan tipe misi apa yang paling sering dikerjakan.
  String _getDynamicTitle() {
    final rankStr = RankSystem.calculateRank(_level, str: _strengthXp, def: _defenseXp, intl: _intelligenceXp, vit: _vitalityXp, agi: _agilityXp);
    return RankSystem.getDynamicTitle(_strengthXp, _defenseXp, _intelligenceXp, _vitalityXp, _agilityXp, rankStr, _level, 0);
  }

  // Menjumlahkan semua XP dari 5 atribut kategori (Strength, Agility, dst)
  int get _totalAttrXp =>
      _strengthXp + _defenseXp + _intelligenceXp + _vitalityXp + _agilityXp;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Not logged in'));
    final l = context.lw;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final d = snapshot.data!.data() as Map<String, dynamic>;
          _name = d[UserSchema.name] ?? 'User';
          _level = d[UserSchema.level] ?? 1;
          _xp = d[UserSchema.xp] ?? 0;
          _rank = RankSystem.calculateRank(_level, str: _strengthXp, def: _defenseXp, intl: _intelligenceXp, vit: _vitalityXp, agi: _agilityXp);
          _streak = d[UserSchema.streak] ?? 0;
          _longestStreak = d[UserSchema.longestStreak] ?? 0;
          _totalDone = d[UserSchema.totalTasksDone] ?? 0;
          _totalFailed = d[UserSchema.totalTasksFailed] ?? 0;
          _gold = d[UserSchema.gold] ?? 0;
          _hp = d[UserSchema.hp] ?? 0;
          _maxHp = d[UserSchema.maxHp] ?? 100;
          _strengthXp = d[UserSchema.strengthXp] ?? 0;
          _defenseXp = d[UserSchema.defenseXp] ?? 0;
          _intelligenceXp = d[UserSchema.intelligenceXp] ?? 0;
          _vitalityXp = d[UserSchema.vitalityXp] ?? 0;
          _agilityXp = d[UserSchema.agilityXp] ?? 0;
          
          if (_isLoading) {
            _isLoading = false;
            Future.microtask(() => _barCtrl.forward(from: 0.0));
          }
        }

        final rankColor = _rankColor(_rank);

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 0.0),
                child: ScreenHeader(title: 'Statistics'),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.cardBorder, width: AppColors.borderWidth),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primary,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.textOnPrimary,
                  unselectedLabelColor: AppColors.textPrimary.withValues(alpha: 0.38),
                  labelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: l.statsTabPersonal),
                    Tab(text: l.statsTabLeaderboard),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildPersonalStats(rankColor, uid),
                    Stack(
                      children: [
                        _buildLeaderboardView(uid),
                        if (_showLeaderboardTutorial)
                          RpgTutorialOverlay(
                            steps: _leaderboardTutorialSteps,
                            accentColor: AppColors.primary,
                            onCompleted: () => _markLeaderboardTutorialDone(uid),
                            onSkipped: () => _markLeaderboardTutorialDone(uid),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab Statistik Personal ────────────────────────────────────────────────
  // Berisi tampilan kartu rank, grafik radar, tombol share, streak, dan bar attribut
  Widget _buildPersonalStats(Color rankColor, String uid) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoryButton(),
          const SizedBox(height: 12),
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgDark,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  _buildRankCard(rankColor),
                  const SizedBox(height: 14),
                  _buildRadarSection(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildShareButton(),
          const SizedBox(height: 14),
          _buildRankRoadmap(rankColor),
          const SizedBox(height: 14),
          _buildStreakRow(),
          const SizedBox(height: 14),
          PerformanceChart(uid: uid),
          const SizedBox(height: 14),
          _buildAttributeBars(),
          const SizedBox(height: 14),
          _buildDynamicTitle(),
        ],
      ),
    );
  }

  // --- LOGIKA PAPAN PERINGKAT GLOBAL (LEADERBOARD) ---
  Widget _buildLeaderboardView(String myUid) {
    // StreamBuilder digunakan agar jika ada player lain yang naik level (XP bertambah)
    // layar kita akan otomatis terupdate secara real-time tanpa perlu ditarik refresh.
    return StreamBuilder<QuerySnapshot>(
      // 1. Tembak Query ke koleksi 'users'
      stream: FirebaseFirestore.instance
          .collection('users')
          // 2. Urutkan berdasarkan LEVEL secara menurun (dari yang tertinggi ke terendah)
          // Catatan Sidang: Kenapa tidak urutkan XP? Karena level sudah mewakili XP kumulatif.
          .orderBy(UserSchema.level, descending: true)
          // 3. Batasi hanya 50 orang agar tidak memakan kuota baca database (Cost Optimization)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        // Tampilkan loading muter jika data masih ditarik dari server
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data!.docs;

        // Render daftar orang-orang ke dalam bentuk List yang bisa discroll
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final name = data[UserSchema.name] ?? 'Unknown';
            final username = data[UserSchema.username] ?? 'user';
            final level = data[UserSchema.level] ?? 1;
            
            // Konversi dari angka level menjadi Huruf Rank (S, A, B, dll)
            final rank = RankSystem.calculateRank(level, str: data[UserSchema.strengthXp] ?? 0, def: data[UserSchema.defenseXp] ?? 0, intl: data[UserSchema.intelligenceXp] ?? 0, vit: data[UserSchema.vitalityXp] ?? 0, agi: data[UserSchema.agilityXp] ?? 0);
            
            final uid = data[UserSchema.id] ?? '';
            // Deteksi apakah baris ini adalah diri kita sendiri
            final isMe = uid == myUid;
            
            // Ambil data baju/avatar orang lain untuk ditampilkan jika kita tap namanya
            final equipped = Map<String, String>.from(data[UserSchema.equippedItems] ?? {});
            final equippedBadgeIds = List<String>.from(data[UserSchema.equippedBadges] ?? []);

            return InkWell(
              // Munculkan dialog profil (layar popup) saat ditekan
              onTap: () => _showUserProfile(data),
              borderRadius: BorderRadius.circular(20),
              // Panggil UI Baris (Rank 1, 2, 3 warnanya akan dibuat spesial (Emas, Perak, Perunggu) di _buildLeaderboardRow)
              child: _buildLeaderboardRow(index + 1, name, username, level, rank, equipped, isMe, equippedBadgeIds),
            );
          },
        );
      },
    );
  }

  Widget _buildLeaderboardRow(
    int pos,
    String name,
    String username,
    int level,
    String rank,
    Map<String, String> equipped,
    bool isMe,
    List<String> equippedBadgeIds,
  ) {
    final rankCol = _rankColor(rank);
    Color posColor = AppColors.textPrimary.withValues(alpha: 0.38);
    List<Color> rowGradient = [cardDark, cardDark];
    double borderWidth = AppColors.borderWidth;
    Color borderColor = AppColors.cardBorder;

    final bool isComic = AppColors.currentTheme == AppThemeType.comicMonochrome;

    Color textColor = AppColors.textPrimary;
    Color subtitleColor = AppColors.textPrimary.withValues(alpha: 0.38);

    if (isComic) {
      if (pos == 1) {
        posColor = Colors.white;
        rowGradient = [Colors.black, Colors.black];
        borderColor = Colors.black;
        borderWidth = 2.0;
        textColor = Colors.white;
        subtitleColor = Colors.white70;
      } else if (pos == 2) {
        posColor = Colors.white;
        rowGradient = [const Color(0xFF424242), const Color(0xFF424242)]; // Hitam pudar
        borderColor = Colors.black;
        borderWidth = 1.5;
        textColor = Colors.white;
        subtitleColor = Colors.white70;
      } else if (pos == 3) {
        posColor = Colors.black;
        rowGradient = [const Color(0xFF9E9E9E), const Color(0xFF9E9E9E)]; // Putih gelap / Abu
        borderColor = Colors.black;
        borderWidth = 1.5;
        textColor = Colors.black;
        subtitleColor = Colors.black54;
      } else if (pos == 4) {
        posColor = Colors.black;
        rowGradient = [const Color(0xFFE0E0E0), const Color(0xFFE0E0E0)]; // Abu muda
        borderColor = Colors.black;
        textColor = Colors.black;
        subtitleColor = Colors.black54;
      } else if (pos == 5) {
        posColor = Colors.black;
        rowGradient = [const Color(0xFFF5F5F5), const Color(0xFFF5F5F5)]; // Abu sangat muda
        borderColor = Colors.black;
        textColor = Colors.black;
        subtitleColor = Colors.black54;
      } else {
        posColor = Colors.black;
        rowGradient = [Colors.white, Colors.white]; // Sisanya putih
        borderColor = Colors.black;
        textColor = Colors.black;
        subtitleColor = Colors.black54;
      }
    } else {
      if (pos == 1) {
        posColor = AppColors.gold;
        rowGradient = [AppColors.gold.withValues(alpha: 0.1), cardDark];
        borderColor = AppColors.gold.withValues(alpha: 0.3);
        borderWidth = AppColors.borderWidth > 1.0 ? AppColors.borderWidth : 1.5;
      } else if (pos == 2) {
        posColor = const Color(0xFFC0C0C0);
        rowGradient = [const Color(0xFFC0C0C0).withValues(alpha: 0.08), cardDark];
        borderColor = const Color(0xFFC0C0C0).withValues(alpha: 0.2);
      } else if (pos == 3) {
        posColor = const Color(0xFFCD7F32);
        rowGradient = [const Color(0xFFCD7F32).withValues(alpha: 0.05), cardDark];
        borderColor = const Color(0xFFCD7F32).withValues(alpha: 0.15);
      }
    }

    if (isMe) {
      borderColor = isComic ? Colors.black : AppColors.primary.withValues(alpha: 0.6);
      borderWidth = AppColors.borderWidth > 1.0 ? AppColors.borderWidth + 1.0 : 2.0;
    }

    return ThemeCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      gradient: LinearGradient(colors: rowGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(20),
      borderColor: borderColor,
      borderWidth: borderWidth,
      boxShadow: pos <= 3 ? [
        BoxShadow(color: posColor.withValues(alpha: 0.05), blurRadius: 10, spreadRadius: 1)
      ] : null,
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 30,
            child: Text(
              '#$pos',
              style: GoogleFonts.nunito(
                color: posColor,
                fontWeight: FontWeight.w900,
                fontSize: pos <= 3 ? 16 : 13,
              ),
            ),
          ),
          SizedBox(width: 8),
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: rankCol.withValues(alpha: 0.3)),
            ),
            child: AvatarPreview(
              equippedItems: equipped,
              size: 44,
              showBackground: true,
            ),
          ),
          SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name (Kamu)' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '@$username',
                  style: GoogleFonts.nunito(color: subtitleColor, fontSize: 11),
                ),
              ],
            ),
          ),
          // Rank & Level
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: rankCol.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: rankCol.withValues(alpha: 0.4)),
                ),
                child: Text(
                  rank,
                  style: GoogleFonts.nunito(
                    color: rankCol,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Lv.$level',
                style: GoogleFonts.nunito(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (equippedBadgeIds.isNotEmpty) ...[
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: equippedBadgeIds.map((id) {
                    try {
                      final b = BadgeSystem.allBadges.firstWhere((badge) => badge.id == id);
                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: b.flutterIcon != null
                            ? Icon(b.flutterIcon, size: 14, color: Color(b.colorHex))
                            : Text(b.icon, style: const TextStyle(fontSize: 12)),
                      );
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                  }).toList(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return ThemeCard(
      borderRadius: BorderRadius.circular(20),
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HistoryScreen()),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l.statsLogHistory,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    context.l.statsViewAchievements,
                    style: GoogleFonts.nunito(
                      color: AppColors.textPrimary.withValues(alpha: 0.54),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled, size: 24),
          ],
        ),
        ),
      ),
    );
  }

  // ── 1. Rank Card ──────────────────────────────────────────
  Widget _buildRankCard(Color rankColor) {
    final xpNeeded = _xpForThisLevel;
    final progress = (xpNeeded > 0 ? (_xp % xpNeeded) / xpNeeded : 0.0).clamp(0.0, 1.0);
    final hpProgress = (_maxHp > 0 ? _hp / _maxHp : 0.0).clamp(0.0, 1.0);

    // Rank Gradients
    final Map<String, List<Color>> rankGradients = {
      'F': [Color(0xFF94A3B8), Color(0xFF475569)],
      'E': [Color(0xFF4B5563), Color(0xFF1F2937)],
      'D': [AppColors.info, Color(0xFF1E3A8A)],
      'C': [Color(0xFF8B5CF6), Color(0xFF4C1D95)],
      'B': [AppColors.success, Color(0xFF064E3B)],
      'A': [AppColors.error, Color(0xFF7F1D1D)],
      'S': [Color(0xFFEC4899), Color(0xFF831843)],
      'SS': [Color(0xFF06B6D4), Color(0xFF3B82F6), Color(0xFF6366F1)],
      'SSS': [AppColors.warning, Color(0xFFB45309), AppColors.gold],
      'SSR': [const Color(0xFFFFFFFF), const Color(0xFFE0F7FA), const Color(0xFFFFFFFF)],
    };

    final gradient = rankGradients[_rank] ?? [Colors.grey, AppColors.textPrimary];

    // Menggunakan ThemeCard untuk Rank Card //
    return ThemeCard(
      padding: const EdgeInsets.all(24),
      backgroundColor: cardDark,
      borderRadius: BorderRadius.circular(30),
      borderColor: AppColors.cardBorder,
      borderWidth: AppColors.borderWidth,
      boxShadow: [
        BoxShadow(
          color: rankColor.withValues(alpha: 0.1),
          blurRadius: 30,
          spreadRadius: 2,
        ),
      ],
      child: Column(
        children: [
          // Centered Big Rank
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.textDisabled, width: 2),
              boxShadow: [
                BoxShadow(
                  color: rankColor.withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _rank,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: (_rank == 'SSS' || _rank == 'SSR') ? 36 : 54,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    Shadow(
                      color: (_rank == 'SSS' || _rank == 'SSR') ? Colors.black54 : Colors.transparent,
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _name,
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            'Level $_level  •  ${_getDynamicTitle()}',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary.withValues(alpha: 0.54),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildEquippedBadgesRow(_equippedBadges),
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _headerStat('HP', '$_hp/$_maxHp', AppColors.error, hpProgress),
              _headerStat('XP', '${_xp % xpNeeded}/$xpNeeded', AppColors.xp, progress),
              _headerStat('Coin', '$_gold', AppColors.warning, 1.0, isCoin: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color, double prog, {bool isCoin = false}) {
    return Column(
      children: [
        if (isCoin)
          Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18)
        else
          Text(label, style: GoogleFonts.nunito(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Text(value, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
        if (!isCoin) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prog,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── 2. Rank Roadmap ───────────────────────────────────────
  Widget _buildRankRoadmap(Color activeColor) {
    final currentRankIdx = rankOrder.indexOf(_rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: AppColors.borderWidth),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l.statsRankJourney, style: GoogleFonts.nunito(
            color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(rankOrder.length, (i) {
              final rank = rankOrder[i];
              final isPast = i < currentRankIdx;
              final isCurrent = i == currentRankIdx;
              final color = _rankColor(rank);

              return Column(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 400),
                    width: isCurrent ? 40 : 32,
                    height: isCurrent ? 40 : 32,
                    decoration: BoxDecoration(
                      color: isPast || isCurrent
                          ? color.withValues(alpha: 0.2)
                          : AppColors.textPrimary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCurrent ? color : isPast ? color.withValues(alpha: 0.5) : AppColors.textPrimary.withValues(alpha: 0.12),
                        width: isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(rank, style: GoogleFonts.nunito(
                        color: isCurrent ? color : isPast ? color.withValues(alpha: 0.7) : AppColors.textPrimary.withValues(alpha: 0.24),
                        fontSize: rank == 'SSR' ? 7 : 11,
                        fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                      )),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(isCurrent ? context.l.statsKamu : '',
                      style: GoogleFonts.nunito(color: color, fontSize: 8)),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── 3. Streak & Stats Row ─────────────────────────────────
  Widget _buildStreakRow() {
    return Row(
      children: [
        Expanded(child: _statCard(Icons.local_fire_department_rounded, '$_streak', 'Streak', AppColors.warning)),
        SizedBox(width: 10),
        Expanded(child: _statCard(Icons.emoji_events_rounded, '$_longestStreak', context.l.statsLongest, AppColors.gold)),
        SizedBox(width: 10),
        Expanded(child: _statCard(Icons.check_circle_rounded, '$_totalDone', context.l.statsSelesai, AppColors.success)),
        SizedBox(width: 10),
        Expanded(child: _statCard(Icons.cancel_rounded, '$_totalFailed', context.l.statsGagal, AppColors.error)),
      ],
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) =>
    ThemeCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      backgroundColor: cardDark,
      borderRadius: BorderRadius.circular(16),
      borderColor: color.withValues(alpha: 0.3),
      borderWidth: 1.5,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(value, style: GoogleFonts.nunito(
            color: color, fontSize: 18, fontWeight: FontWeight.w900,
          )),
          SizedBox(height: 2),
          Text(label, style: GoogleFonts.nunito(
            color: AppColors.textPrimary.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

  // ── 4. Radar Chart ────────────────────────────────────────
  Widget _buildRadarSection() {
    // Cari nilai atribut tertinggi untuk membuat skala chart dinamis
    final double maxStat = [_strengthXp, _intelligenceXp, _agilityXp, _vitalityXp, _defenseXp]
        .map((e) => e.toDouble())
        .reduce((a, b) => a > b ? a : b);
    
    // Biarkan stat tertinggi menyentuh ujung grafik agar terlihat lebih penuh
    // Minimal 100 agar chart ada bentuknya jika semua stats masih 0
    final double maxLimit = (maxStat < 100) ? 100.0 : maxStat;

    final values = [
      _strengthXp / maxLimit,
      _intelligenceXp / maxLimit,
      _agilityXp / maxLimit,
      _vitalityXp / maxLimit,
      _defenseXp / maxLimit,
    ].map((v) => v.clamp(0.0, 1.0)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: AppColors.borderWidth),
      ),
      child: Column(
        children: [
          Text('ATRIBUT', style: GoogleFonts.nunito(
            color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2,
          )),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: AnimatedBuilder(
              animation: _barAnim,
              builder: (_, __) => CustomPaint(
                size: const Size(double.infinity, 220),
                painter: _RadarPainter(
                  values: values.map<double>((v) => v * _barAnim.value).toList(),
                  labels: const ['Strength', 'Intelligence', 'Agility', 'Vitality', 'Defense'],
                  colors: [
                    catColors['Strength']!,
                    catColors['Intelligence']!,
                    catColors['Agility']!,
                    catColors['Vitality']!,
                    catColors['Defense']!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Attribute Bars ─────────────────────────────────────
  Widget _buildAttributeBars() {
    final attrs = [
      ('Strength', _strengthXp, catColors['Strength']!, catIcons['Strength']!),
      ('Intelligence', _intelligenceXp, catColors['Intelligence']!, catIcons['Intelligence']!),
      ('Defense', _defenseXp, catColors['Defense']!, catIcons['Defense']!),
      ('Vitality', _vitalityXp, catColors['Vitality']!, catIcons['Vitality']!),
      ('Agility', _agilityXp, catColors['Agility']!, catIcons['Agility']!),
    ];

    final maxXp = attrs.map((a) => a.$2).reduce((a, b) => a > b ? a : b);
    final maxVal = maxXp == 0 ? 1 : maxXp;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress Atribut', style: GoogleFonts.nunito(
            color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 14),
          ...attrs.map((attr) {
            final progress = (attr.$2 / maxVal).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(attr.$4, color: attr.$3, size: 14),
                      SizedBox(width: 6),
                      Text(attr.$1, style: GoogleFonts.nunito(
                        color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600,
                      )),
                      Spacer(),
                      Text('${attr.$2} XP', style: GoogleFonts.nunito(
                        color: attr.$3, fontSize: 11, fontWeight: FontWeight.w700,
                      )),
                    ],
                  ),
                  SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _barAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress * _barAnim.value,
                        minHeight: 7,
                        backgroundColor: AppColors.textPrimary.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(attr.$3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 6. Dynamic Title ──────────────────────────────────────
  Widget _buildDynamicTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Text('🎖️', style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(_getDynamicTitle(), style: GoogleFonts.nunito(
            color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800,
          )),
          SizedBox(height: 4),
          Text(context.l.statsTitleBasedOn,
              style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return ThemeCard(
      margin: const EdgeInsets.only(top: 16),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.primary,
      backgroundColor: AppColors.primary,
      child: InkWell(
        onTap: _shareProfileAsImage,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.share_rounded, color: AppColors.textOnPrimary, size: 18),
              SizedBox(width: 8),
              Text(
                context.l.statsShare,
                style: GoogleFonts.nunito(color: AppColors.textOnPrimary, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareProfileAsImage() async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l.statsPrepareImage), duration: Duration(seconds: 1)),
      );

      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/my_rpg_stats.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Lihat progres saya di Daily RPG! Rank: $_rank | Level: $_level ⚔️🔥',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan: $e')),
        );
      }
    }
  }

  void _showUserProfile(Map<String, dynamic> d) {
    final name = d[UserSchema.name] ?? 'Hero';
    final username = d[UserSchema.username] ?? 'user';
    final level = d[UserSchema.level] ?? 1;
    final rank = RankSystem.calculateRank(level, str: d[UserSchema.strengthXp] ?? 0, def: d[UserSchema.defenseXp] ?? 0, intl: d[UserSchema.intelligenceXp] ?? 0, vit: d[UserSchema.vitalityXp] ?? 0, agi: d[UserSchema.agilityXp] ?? 0);
    final equipped = Map<String, String>.from(d[UserSchema.equippedItems] ?? {});
    final equippedBadgeIds = List<String>.from(d[UserSchema.equippedBadges] ?? []);
    final rankColor = _rankColor(rank);

    final str = d[UserSchema.strengthXp] ?? 0;
    final intl = d[UserSchema.intelligenceXp] ?? 0;
    final vit = d[UserSchema.vitalityXp] ?? 0;
    final agi = d[UserSchema.agilityXp] ?? 0;
    final def = d[UserSchema.defenseXp] ?? 0;
    final tasksDone = d[UserSchema.totalTasksDone] ?? 0;
    final dynamicTitle = RankSystem.getDynamicTitle(str, def, intl, vit, agi, rank, level, tasksDone);

    // Hitung Radar Chart secara dinamis
    final double maxStat = [str, intl, agi, vit, def]
        .map((e) => e.toDouble())
        .reduce((a, b) => a > b ? a : b);
    final double maxLimit = (maxStat < 100) ? 100.0 : maxStat;

    final values = <double>[
      str / maxLimit,
      intl / maxLimit,
      agi / maxLimit,
      vit / maxLimit,
      def / maxLimit,
    ].map((v) => v.clamp(0.0, 1.0)).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardDark, // Changed to match theme
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: rankColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: rankColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textPrimary.withValues(alpha: 0.05),
                  border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: ClipOval(
                  child: AvatarPreview(equippedItems: equipped, size: 140, showBackground: true),
                ),
              ),
              const SizedBox(height: 20),
              // User Info
              Text(name, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
              Text('@$username', style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 13)),
              const SizedBox(height: 12),
              Icon(Icons.military_tech_rounded, color: AppColors.textSecondary, size: 24),
              Text(dynamicTitle, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              // Rank & Level Button Style
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: rankColor),
                    ),
                    child: Text('Rank $rank', style: GoogleFonts.nunito(color: rankColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Text('Lv.$level', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              _buildEquippedBadgesRow(equippedBadgeIds),
              const SizedBox(height: 16),
              Divider(color: AppColors.textPrimary.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 16),
              
              // Bottom Row (Spider Chart + Stats List)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Spider Chart di Kiri
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 120,
                      child: CustomPaint(
                        size: const Size(double.infinity, 120),
                        painter: _RadarPainter(
                          values: values,
                          labels: const ['STR', 'INT', 'AGI', 'VIT', 'DEF'],
                          colors: [
                            catColors['Strength']!,
                            catColors['Intelligence']!,
                            catColors['Agility']!,
                            catColors['Vitality']!,
                            catColors['Defense']!,
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // List Stat di Kanan
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMiniStatRow('STR', str, catColors['Strength']!),
                        _buildMiniStatRow('INT', intl, catColors['Intelligence']!),
                        _buildMiniStatRow('AGI', agi, catColors['Agility']!),
                        _buildMiniStatRow('VIT', vit, catColors['Vitality']!),
                        _buildMiniStatRow('DEF', def, catColors['Defense']!),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatRow(String label, int xp, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 11)),
          const Spacer(),
          Text('$xp XP', style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEquippedBadgesRow(List<String> badgeIds) {
    if (badgeIds.isEmpty) {
      return Text(
        context.l.statsNoBadge,
        style: GoogleFonts.nunito(
          color: AppColors.textPrimary.withValues(alpha: 0.38),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final badges = badgeIds.map((id) {
      try {
        return BadgeSystem.allBadges.firstWhere((b) => b.id == id);
      } catch (_) {
        return null;
      }
    }).where((b) => b != null).cast<AppBadge>().toList();

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: badges.map((b) {
        final color = Color(b.colorHex);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: b.flutterIcon != null
              ? Icon(b.flutterIcon, size: 24, color: color)
              : Text(b.icon, style: const TextStyle(fontSize: 20)),
        );
      }).toList(),
    );
  }
}

// ── Radar Chart CustomPainter ─────────────────────────────────
class _RadarPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;

  _RadarPainter({required this.values, required this.labels, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    const sides = 5;

    // 1. Menggambar jaring laba-laba (Grid lines)
    // Berbentuk segi-lima (pentagon) yang berlapis-lapis
    for (int level = 1; level <= 3; level++) {
      final r = radius * level / 3;
      final gridPaint = Paint()
        ..color = AppColors.textPrimary.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = (2 * pi * i / sides) - pi / 2;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 2. Menggambar garis sumbu (Axis lines) dari tengah ke ujung jari-jari
    final axisPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      canvas.drawLine(
        center,
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)),
        axisPaint,
      );
    }

    // 3. Mewarnai area grafik (Fill area) berdasarkan persentase XP pemain
    final fillPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final val = values[i].clamp(0.05, 1.0);
      final x = center.dx + radius * val * cos(angle);
      final y = center.dy + radius * val * sin(angle);
      if (i == 0) {
        fillPath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
      }
    }
    fillPath.close();

    canvas.drawPath(fillPath, Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill);
    canvas.drawPath(fillPath, Paint()
      ..color = AppColors.primary.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // 4. Menggambar titik-titik ujung (Dots) & teks label (STR, AGI, dll)
    for (int i = 0; i < sides; i++) {
      final angle = (2 * pi * i / sides) - pi / 2;
      final val = values[i].clamp(0.05, 1.0);
      final dotX = center.dx + radius * val * cos(angle);
      final dotY = center.dy + radius * val * sin(angle);

      canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = colors[i]);

      final labelX = center.dx + (radius + 22) * cos(angle);
      final labelY = center.dy + (radius + 22) * sin(angle);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: colors[i].withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(labelX - tp.width / 2, labelY - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.values != values;
}






