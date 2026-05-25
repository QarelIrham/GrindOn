import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';
import 'add_task_screen.dart';
import 'focus_timer_screen.dart';
import '../theme/rpg_theme.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';


// ── Layar Detail Kategori (Category Detail Screen) ────────────────
// Layar ini muncul saat user mengklik salah satu kategori (misal: "Strength") dari halaman Home.
// Layar ini berisi 3 tab: Informasi Kategori, Rekomendasi Tugas, dan Tugas Aktif.
class CategoryDetailScreen extends StatelessWidget {
  final String category;

  const CategoryDetailScreen({super.key, required this.category});

  // ─── Data per kategori ──────────────────────────────
  static Map<String, Color> get catColors => RPGColors.catColors;
  static Map<String, IconData> get catIcons => RPGIcons.catIcons;

  static const Map<String, String> catDesc = {
    'Strength':
        'Melatih kekuatan fisik dan membangun massa otot. Setiap sesi latihan beban, calisthenics, atau olahraga fisik berat akan meningkatkan atribut STR kamu secara langsung.\n\nKarakter dengan STR tinggi memiliki stamina kerja yang luar biasa dan mampu menghadapi tantangan fisik apapun.',
    'Defense':
        'Membangun ketahanan mental dan kestabilan emosional. Meditasi, journaling, dan refleksi diri adalah benteng terkuat yang bisa kamu bangun.\n\nKarakter dengan DEF tinggi tidak mudah burnout, mampu mengelola stres, dan memiliki mental yang tangguh dalam tekanan.',
    'Intelligence':
        'Mengasah kemampuan kognitif, skill teknis, dan literasi. Setiap jam yang dihabiskan untuk belajar, membaca, atau mengerjakan proyek kreatif meningkatkan atribut INT kamu.\n\nKarakter dengan INT tinggi belajar lebih cepat, memecahkan masalah lebih efektif, dan terus berkembang.',
    'Vitality':
        'Menjaga kualitas tidur, nutrisi, dan pemulihan tubuh. Tanpa VIT yang cukup, semua atribut lain akan melemah — ini adalah fondasi dari segalanya.\n\nKarakter dengan VIT tinggi memiliki energi yang stabil sepanjang hari dan pulih lebih cepat dari kelelahan.',
    'Agility':
        'Meningkatkan stamina kardiovaskular dan kelincahan tubuh. Olahraga cardio, HIIT, dan sport membangun AGI yang membuat kamu bergerak lebih gesit dan efisien.\n\nKarakter dengan AGI tinggi memiliki reaktivitas tinggi dan tidak mudah kehabisan tenaga.',
  };

  static const Map<String, List<Map<String, dynamic>>> catRec = {
    'Strength': [
      {'title': 'Chest Day', 'duration': 60, 'diff': 3},
      {'title': 'Leg Day', 'duration': 60, 'diff': 3},
      {'title': 'Calisthenics', 'duration': 45, 'diff': 2},
      {'title': 'Push-up 100x', 'duration': 15, 'diff': 2},
      {'title': 'Renang', 'duration': 60, 'diff': 2},
      {'title': 'Boxing / Muay Thai', 'duration': 60, 'diff': 4},
    ],
    'Intelligence': [
      {'title': 'Ngoding Flutter', 'duration': 120, 'diff': 3},
      {'title': 'Desain UI/UX', 'duration': 90, 'diff': 2},
      {'title': 'Baca Buku 30 Halaman', 'duration': 45, 'diff': 1},
      {'title': 'Belajar 5 Kosakata Baru', 'duration': 20, 'diff': 1},
      {'title': 'Main Catur / Sudoku', 'duration': 30, 'diff': 2},
    ],
    'Defense': [
      {'title': 'Meditasi 5 Menit', 'duration': 5, 'diff': 1},
      {'title': 'Journaling Malam', 'duration': 15, 'diff': 1},
      {'title': 'Latihan Kontrol Emosi', 'duration': 20, 'diff': 2},
      {'title': 'Digital Detox 1 Jam', 'duration': 60, 'diff': 2},
    ],
    'Agility': [
      {'title': 'Jogging 20 Menit', 'duration': 20, 'diff': 2},
      {'title': 'Badminton', 'duration': 60, 'diff': 2},
      {'title': 'Bersepeda', 'duration': 45, 'diff': 2},
      {'title': 'HIIT 15 Menit', 'duration': 15, 'diff': 3},
    ],
    'Vitality': [
      {'title': 'Tidur Sebelum Jam 10', 'duration': 0, 'diff': 1},
      {'title': 'Minum 2L Air', 'duration': 0, 'diff': 1},
      {'title': 'Makan Protein & Serat', 'duration': 0, 'diff': 1},
      {'title': 'Stretching / Yoga', 'duration': 20, 'diff': 1},
    ],
  };

  static const Map<String, String> catAttr = {
    'Strength': 'STR +XP setiap task selesai',
    'Defense': 'DEF +XP setiap task selesai',
    'Intelligence': 'INT +XP setiap task selesai',
    'Vitality': 'VIT +XP & Energy +10 setiap task selesai',
    'Agility': 'AGI +XP setiap task selesai',
  };

  static const Map<String, List<String>> catBenefits = {
    'Strength': [
      'Tubuh lebih kuat & bertenaga',
      'Massa otot meningkat',
      'Kepercayaan diri naik',
      'Metabolisme lebih baik',
    ],
    'Defense': [
      'Mental lebih stabil',
      'Tidak mudah burnout',
      'Pengelolaan emosi lebih baik',
      'Fokus & konsentrasi meningkat',
    ],
    'Intelligence': [
      'Kemampuan belajar lebih cepat',
      'Problem solving lebih tajam',
      'Skill teknis berkembang',
      'Kreativitas meningkat',
    ],
    'Vitality': [
      'Energi stabil sepanjang hari',
      'Pemulihan lebih cepat',
      'Imunitas tubuh kuat',
      'Mood selalu positif',
    ],
    'Agility': [
      'Stamina & daya tahan naik',
      'Tubuh lebih gesit',
      'Kardiovaskular sehat',
      'Refleks & kecepatan meningkat',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final color = catColors[category] ?? const Color(0xFF7C3AED);
    final icon = catIcons[category] ?? Icons.star_rounded;
    final l = context.lw;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: Color(0xFF0D0D1A),
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        Color(0xFF0D0D1A),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: Icon(icon, color: color, size: 32),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l.catName(category),
                                style: GoogleFonts.nunito(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                l.catAttrBonus(category),
                                style: GoogleFonts.nunito(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                labelColor: color,
                unselectedLabelColor: AppColors.textPrimary.withValues(alpha: 0.38),
                indicatorColor: color,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: GoogleFonts.nunito(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: [
                  Tab(text: l.catDetailInfo),
                  Tab(text: l.catDetailRecommendations),
                  Tab(text: l.catDetailActiveTasks),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _InfoTab(category: category, color: color),
              _RecTab(category: category, color: color),
              _ActiveTab(category: category, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
//  TAB 1 — Info (Informasi tentang Kategori ini)
// ══════════════════════════════════════════
class _InfoTab extends StatelessWidget {
  final String category;
  final Color color;
  const _InfoTab({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final l = context.l;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Deskripsi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: color, size: 16),
                    SizedBox(width: 6),
                    Text(
                      '${l.catDetailAbout} ${l.catName(category)}',
                      style: GoogleFonts.nunito(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  l.catDesc(category),
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Manfaat
          Text(
            l.catDetailBenefits,
            style: GoogleFonts.nunito(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          ...l.catBenefits(category).asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: GoogleFonts.nunito(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      e.value,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // XP Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Text('⚡', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.catDetailAttributeBonus,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l.catAttrBonus(category),
                      style: GoogleFonts.nunito(color: color, fontSize: 11),
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
}

// ══════════════════════════════════════════
//  TAB 2 — Rekomendasi (Ide tugas bawaan)
// ══════════════════════════════════════════
class _RecTab extends StatelessWidget {
  final String category;
  final Color color;
  const _RecTab({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final recs = CategoryDetailScreen.catRec[category] ?? [];
    final l = context.l;
    final diffLabels = l.difficultyLabels;
    final diffColors = [
      Colors.transparent,
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recs.length,
      itemBuilder: (_, i) {
        final rec = recs[i];
        final title = rec['title'] as String;
        final duration = rec['duration'] as int;
        final diff = rec['diff'] as int;
        final dColor = diffColors[diff.clamp(1, 4)];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CategoryDetailScreen.catIcons[category],
                  color: color,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: dColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            diffLabels[diff.clamp(1, 4) - 1],
                            style: GoogleFonts.nunito(
                              color: dColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (duration > 0) ...[
                          SizedBox(width: 6),
                          Icon(
                            Icons.timer_rounded,
                            color: AppColors.textPrimary.withValues(alpha: 0.38),
                            size: 11,
                          ),
                          Text(
                            ' ${duration}m',
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary.withValues(alpha: 0.38),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTaskSheet(
                    initialTitle: title,
                    initialCategory: category,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    l.catDetailAddTask,
                    style: GoogleFonts.nunito(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════
//  TAB 3 — Task Aktif (Tugas yang sedang berjalan)
// ══════════════════════════════════════════
class _ActiveTab extends StatelessWidget {
  final String category;
  final Color color;
  const _ActiveTab({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final l = context.l;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .where('category', isEqualTo: category)
          .where('done', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded, color: AppColors.textDisabled, size: 52),
                SizedBox(height: 10),
                Text(
                  l.catDetailNoActiveTasks(l.catName(category)),
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary.withValues(alpha: 0.38),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  l.catDetailOpenRecommendations,
                  style: GoogleFonts.nunito(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final id = docs[i].id;
            final title = data['title'] ?? 'Untitled';
            final diff = (data['difficulty'] ?? 1) as int;
            final durationMin = (data[TaskSchema.duration] ?? 0) as int;
            final proofType =
                data[TaskSchema.proofType] ?? TaskSchema.proofTypeNone;
            final isCursed = data[TaskSchema.isCursed] == true;
            final timerStatus =
                data[TaskSchema.timerStatus] ?? TaskSchema.timerIdle;
            final xp = (data[TaskSchema.xp] ?? 20) as int;
            final gold = (data[TaskSchema.goldReward] ?? 5) as int;

            final diffLabels = l.difficultyLabels;
            final diffColors = [
              Colors.transparent,
              const Color(0xFF10B981),
              const Color(0xFF3B82F6),
              const Color(0xFFF59E0B),
              const Color(0xFFEF4444),
            ];
            final dColor = diffColors[diff.clamp(1, 4)];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCursed
                      ? Color(0xFFEF4444).withValues(alpha: 0.6)
                      : color.withValues(alpha: 0.25),
                  width: isCursed ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isCursed)
                                Text(
                                  l.catDetailCursedTask,
                                  style: GoogleFonts.nunito(
                                    color: Color(0xFFEF4444),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              Text(
                                title,
                                style: GoogleFonts.nunito(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: dColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      diffLabels[diff.clamp(1, 4) - 1],
                                      style: GoogleFonts.nunito(
                                        color: dColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (durationMin > 0) ...[
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.timer_rounded,
                                      color: AppColors.textPrimary.withValues(alpha: 0.38),
                                      size: 11,
                                    ),
                                    Text(
                                      ' ${durationMin}m',
                                      style: GoogleFonts.nunito(
                                        color: AppColors.textPrimary.withValues(alpha: 0.38),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 11,
                                  ),
                                  Text(
                                    ' +$xp XP',
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFFF59E0B),
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.monetization_on_rounded,
                                    color: Color(0xFFF59E0B),
                                    size: 11,
                                  ),
                                  Text(
                                    ' +$gold',
                                    style: GoogleFonts.nunito(
                                      color: const Color(0xFFF59E0B),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Start button
                        timerStatus == TaskSchema.timerRunning
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_rounded,
                                      color: color,
                                      size: 14,
                                    ),
                                    Text(
                                      l.catDetailTimerRunning,
                                      style: GoogleFonts.nunito(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FocusTimerScreen(
                                      taskId: id,
                                      uid: uid,
                                      title: title,
                                      category: category,
                                      difficulty: diff,
                                      durationMinutes: durationMin,
                                      proofType: proofType,
                                      xpReward: xp,
                                      goldReward: gold,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: color.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        durationMin > 0
                                            ? Icons.play_arrow_rounded
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        color: color,
                                        size: 14,
                                      ),
                                      Text(
                                        durationMin > 0 ? l.catDetailStart : l.catDetailDone,
                                        style: GoogleFonts.nunito(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
