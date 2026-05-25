import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_task_screen.dart';
import '../models/app_schema.dart';
import '../services/notification_service.dart';
import '../widget/theme_card.dart';
import '../theme/rpg_theme.dart';
import '../theme/app_theme.dart';


// ── Tampilan Khusus per Kategori Misi (Task Screen) ───────────────
// Layar ini muncul jika user menekan tombol nama kategori (misal: "Strength") 
// di layar utama (home_screen). Berfungsi untuk melihat seluruh misi khusus kategori tersebut.
class TaskScreen extends StatefulWidget {
  final String category; // Menyimpan nama kategori (contoh: "Strength")
  const TaskScreen({super.key, required this.category});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  Color get _color => RPGColors.catColors[widget.category] ?? RPGColors.accent;
  IconData get _icon => RPGIcons.catIcons[widget.category] ?? Icons.star_rounded;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _filter = 'all';

  // ── Fungsi Aksi ──────────────────────────────────────────────────
  // Mengubah status misi dari belum selesai menjadi selesai (atau sebaliknya)
  Future<void> _toggleDone(String taskId, bool current) async {
    if (_uid == null) return;
    HapticFeedback.lightImpact();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId)
        .update({'done': !current});
  }

  // Menghapus misi dari database secara permanen
  Future<void> _deleteTask(String taskId) async {
    if (_uid == null) return;
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Helper: Mencegah error jika data "difficulty" di database dulunya berupa tulisan (String),
  // sekarang dikonversi menjadi angka (int) dari 1 sampai 4.
  int _parseDiff(dynamic raw) {
    if (raw is int) return raw.clamp(1, 4);
    return 1; // default Easy untuk data lama
  }

  // ── Warna & Tingkat Kesulitan ────────────────────────────────────
  // Memberikan warna khusus untuk setiap tingkat kesulitan (Difficulty)
  Color _difficultyColor(int diff) {
    switch (diff) {
      case 1:
        return const Color(0xFF10B981);
      case 2:
        return const Color(0xFF3B82F6);
      case 3:
        return const Color(0xFFF59E0B);
      case 4:
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  // Menerjemahkan angka kesulitan menjadi tulisan
  String _difficultyLabel(int diff) {
    switch (diff) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      case 4:
        return 'Extreme';
      default:
        return '?';
    }
  }

  // Menentukan berapa banyak EXP (XP) yang didapatkan saat misi ini selesai
  int _xpReward(int diff) => [0, 20, 40, 80, 150][diff.clamp(0, 4)];

  // Menampilkan lembar bawah (bottom sheet) untuk menambahkan misi baru
  void _openAddTask() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskSheet(
        initialCategory: widget.category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0D0D1A),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildFilterChips()),
          _buildTaskList(),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _openAddTask,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color,
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded, color: AppColors.textPrimary, size: 28),
        ),
      ),
    );
  }

  // ── Header Kategori (Sliver App Bar) ──────────────────────────────
  // Bagian atas layar yang bisa mengecil saat di-scroll ke bawah.
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: Color(0xFF0D0D1A),
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color.withValues(alpha: 0.25), Color(0xFF0D0D1A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _color.withValues(alpha: 0.4)),
                    ),
                    child: Icon(_icon, color: _color, size: 24),
                  ),
                  SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.category,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        RPGDescriptions.catDesc[widget.category] ?? '',
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary.withValues(alpha: 0.54),
                          fontSize: 13,
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
    );
  }

  // ── Tab Filter ───────────────────────────────────────────────────
  // Menampilkan tombol "Semua", "Belum", "Selesai" untuk menyaring daftar
  Widget _buildFilterChips() {
    final filters = [
      ('all', 'Semua'),
      ('pending', 'Belum'),
      ('done', 'Selesai'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: filters.map((f) {
          final active = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _filter = f.$1);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? _color.withValues(alpha: 0.2)
                      : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? _color.withValues(alpha: 0.6)
                        : Color(0xFF2D2D44),
                  ),
                ),
                child: Text(
                  f.$2,
                  style: GoogleFonts.nunito(
                    color: active ? _color : AppColors.textPrimary.withValues(alpha: 0.54),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Daftar Misi (List View) ──────────────────────────────────────
  // Mengambil data dari Firebase lalu menampilkannya sebagai daftar kartu ke bawah
  Widget _buildTaskList() {
    if (_uid == null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Text(
            'Silakan login dulu',
            style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54)),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('tasks')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: CircularProgressIndicator(color: _color),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        var docs = snapshot.data!.docs;

        // Filter by category client-side (avoid needing Firestore composite index)
        docs = docs
            .where((d) =>
                (d.data() as Map)['category'] == widget.category)
            .toList();

        if (_filter == 'pending') {
          docs = docs.where((d) => (d.data() as Map)['done'] != true).toList();
        } else if (_filter == 'done') {
          docs = docs.where((d) => (d.data() as Map)['done'] == true).toList();
        }

        if (docs.isEmpty) return SliverToBoxAdapter(child: _buildEmptyState());

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _TaskCard(
              doc: docs[i],
              color: _color,
              onToggle: _toggleDone,
              onDelete: _deleteTask,
              parseDiff: _parseDiff,
              diffColor: _difficultyColor,
              diffLabel: _difficultyLabel,
              xpReward: _xpReward,
            ),
            childCount: docs.length,
          ),
        );
      },
    );
  }

  // ── Tampilan Kosong (Empty State) ────────────────────────────────
  // Muncul jika daftar misi di kategori ini masih kosong
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(_icon, color: _color.withValues(alpha: 0.3), size: 64),
          SizedBox(height: 16),
          Text(
            'Belum ada task',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary.withValues(alpha: 0.38),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambah task baru lewat tombol + di bawah',
            style: GoogleFonts.nunito(color: AppColors.textDisabled, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Kartu Misi (Task Card) ─────────────────────────────────────────
// Komponen (Widget) yang menggambar satu kotak/kartu misi pada daftar
class _TaskCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Color color;
  final Future<void> Function(String, bool) onToggle;
  final Future<void> Function(String) onDelete;
  final int Function(dynamic) parseDiff;
  final Color Function(int) diffColor;
  final String Function(int) diffLabel;
  final int Function(int) xpReward;

  const _TaskCard({
    required this.doc,
    required this.color,
    required this.onToggle,
    required this.onDelete,
    required this.parseDiff,
    required this.diffColor,
    required this.diffLabel,
    required this.xpReward,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final String taskId = widget.doc.id;
    final String title = data['title'] ?? 'Untitled';
    final String notes = data['notes'] ?? '';
    final int diff = widget.parseDiff(data['difficulty']); // ✅ FIX
    final bool done = data['done'] == true;
    final Timestamp? deadline = data['deadline'] as Timestamp?;
    final Color dColor = widget.diffColor(diff);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Dismissible(
          key: Key(taskId),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFEF4444).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFFEF4444).withValues(alpha: 0.4),
              ),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              Icons.delete_rounded,
              color: Color(0xFFEF4444),
              size: 26,
            ),
          ),
          confirmDismiss: (_) async => await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Hapus Task?',
                style: GoogleFonts.nunito(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                '"$title" akan dihapus permanen.',
                style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Hapus',
                    style: GoogleFonts.nunito(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (_) => widget.onDelete(taskId),
          // Menggunakan ThemeCard untuk kartu tugas agar efek komik bekerja //
          child: ThemeCard(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            backgroundColor: done
                ? AppColors.cardBackground.withValues(alpha: 0.5)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            borderColor: done
                ? Color(0xFF2D2D44).withValues(alpha: 0.4)
                : widget.color.withValues(alpha: 0.2),
            borderWidth: AppColors.borderWidth,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 80,
                  decoration: BoxDecoration(
                    color: done
                        ? Colors.grey.withValues(alpha: 0.3)
                        : widget.color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: () => widget.onToggle(taskId, done),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: done
                          ? widget.color.withValues(alpha: 0.8)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: done ? widget.color : Color(0xFF3D3D5A),
                        width: 2,
                      ),
                    ),
                    child: done
                        ? Icon(
                            Icons.check_rounded,
                            color: AppColors.textPrimary,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                            color: done ? AppColors.textPrimary.withValues(alpha: 0.38) : AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.textPrimary.withValues(alpha: 0.38),
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          SizedBox(height: 3),
                          Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary.withValues(alpha: 0.38),
                              fontSize: 12,
                            ),
                          ),
                        ],
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: dColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: dColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ...List.generate(
                                    diff,
                                    (_) => Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: dColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    widget.diffLabel(diff),
                                    style: GoogleFonts.nunito(
                                      color: dColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color(
                                  0xFFF59E0B,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '+${widget.xpReward(diff)} XP',
                                style: GoogleFonts.nunito(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (deadline != null) ...[
                              SizedBox(width: 8),
                              Icon(
                                Icons.schedule_rounded,
                                size: 11,
                                color: AppColors.textPrimary.withValues(alpha: 0.38),
                              ),
                              SizedBox(width: 3),
                              Text(
                                _formatDeadline(deadline),
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
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDeadline(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return 'Hari ini ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
