import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/app_schema.dart';
import '../widget/rpg_tutorial_overlay.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../theme/rpg_theme.dart';

// ── Form Tambah Tugas (Add Task Sheet) ──────────────────────────────
// Muncul dari bawah saat user menekan tombol '+' (Bottom Sheet).
// Memungkinkan pengguna untuk membuat misi baru beserta pengaturannya (tanggal, kesulitan, tipe bukti, dll).
class AddTaskSheet extends StatefulWidget {
  final VoidCallback? onTaskAdded;
  final String? initialCategory;
  final String? initialTitle;

  const AddTaskSheet({
    super.key,
    this.onTaskAdded,
    this.initialCategory,
    this.initialTitle,
  });

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  // Use dynamic colors from RPGColors
  static Map<String, Color> get categoryColors => RPGColors.catColors;

  static const Map<String, IconData> categoryIcons = {
    'Strength': Icons.fitness_center,
    'Defense': Icons.shield,
    'Intelligence': Icons.menu_book,
    'Vitality': Icons.favorite,
    'Agility': Icons.bolt,
  };

  static const Map<String, String> categoryDefaultProof = {
    'Strength': TaskSchema.proofTypePhoto,
    'Defense': TaskSchema.proofTypeText,
    'Intelligence': TaskSchema.proofTypeText,
    'Vitality': TaskSchema.proofTypePhoto,
    'Agility': TaskSchema.proofTypePhoto,
  };

  // categoryIdeas will be replaced by l.questIdeas(category) dynamically

  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  late String _selectedCategory;
  int _selectedDiff = 0; // 0-based index
  int _durationMinutes = 0; // 0 = no timer
  late String _proofType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  String _frequency = TaskSchema.freqDaily;

  // Tutorial
  bool _showTutorial = false;

  // Tutorial steps will be loaded from l.tutorialAddTask dynamically

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Strength';
    _proofType =
        categoryDefaultProof[_selectedCategory] ?? TaskSchema.proofTypeNone;
    if (widget.initialTitle != null) {
      _titleCtrl.text = widget.initialTitle!;
    }
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final tutorialsCompleted =
        data['tutorialsCompleted'] as Map<String, dynamic>? ?? {};
    final isDone = tutorialsCompleted['addTask'] as bool? ?? false;
    if (!isDone && mounted) {
      setState(() => _showTutorial = true);
    }
  }

  Future<void> _markTutorialDone() async {
    setState(() => _showTutorial = false);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'tutorialsCompleted.addTask': true});
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();

    super.dispose();
  }

  int get _diffLevel => _selectedDiff + 1; // 1-4
  int get _xpReward => RankSystem.xpReward(_diffLevel);
  int get _goldReward => RankSystem.goldReward(_diffLevel);
  Color get _catColor => categoryColors[_selectedCategory] ?? AppColors.primary;

  // Memunculkan kalender untuk memilih tanggal tenggat waktu
  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _selectedDate = d);
  }

  // Memunculkan pemilih jam untuk mengatur berapa lama durasi misi ini dikerjakan (opsional)
  Future<void> _pickDuration() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _durationMinutes ~/ 60,
        minute: _durationMinutes % 60,
      ),
      helpText: 'SET DURASI (JAM : MENIT)',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: AppColors.textPrimary,
            surface: AppColors.cardBackground,
            onSurface: AppColors.textPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: AppColors.cardBackground,
            hourMinuteColor: AppColors.surface,
            hourMinuteTextColor: AppColors.textPrimary,
            dayPeriodColor: AppColors.surface,
            dayPeriodTextColor: AppColors.textPrimary,
            dialBackgroundColor: AppColors.surface,
            dialHandColor: AppColors.primary,
            dialTextColor: AppColors.textPrimary,
            entryModeIconColor: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) {
      setState(() {
        _durationMinutes = t.hour * 60 + t.minute;
      });
    }
  }

  // Memunculkan jam untuk memilih jam tenggat waktu (deadline)
  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (t != null && mounted) setState(() => _selectedTime = t);
  }

  // --- FUNGSI MENYIMPAN TUGAS BARU (CREATE TASK) ---
  Future<void> _submit() async {
    final l = context.l;
    final title = _titleCtrl.text.trim();
    
    // 1. Validasi Input: Judul tidak boleh kosong
    if (title.isEmpty) {
      _showSnack(l.isEn ? 'Task title cannot be empty' : 'Judul task tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Ambil ID User yang sedang login
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User tidak ditemukan');

      // 3. Buat ID unik acak (UUID v4) untuk task ini agar tidak bentrok dengan task lain
      final taskId = const Uuid().v4();
      
      // 4. Gabungkan input Tanggal (Date) dan Jam (Time) menjadi satu Waktu Tenggat (Deadline)
      final deadline = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 5. Kirim (Set) struktur data lengkap ke koleksi 'tasks' milik user ini di Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .set({
            // Data Dasar
            TaskSchema.id: taskId,
            TaskSchema.uid: uid,
            TaskSchema.title: title,
            TaskSchema.notes: _notesCtrl.text.trim(),
            TaskSchema.category: _selectedCategory,
            
            // Atribut Hadiah (Berdasarkan tingkat kesulitan 1-4 bintang)
            TaskSchema.difficulty: _diffLevel,
            TaskSchema.xp: _xpReward,
            TaskSchema.goldReward: _goldReward,
            TaskSchema.duration: _durationMinutes, // 0 = Bebas waktu (Tidak butuh timer mundur)
            TaskSchema.proofType: _proofType, // Jenis Bukti: Teks, Foto, atau Tanpa Bukti

            // Status awal saat baru dibuat
            TaskSchema.done: false,
            TaskSchema.timerStatus: TaskSchema.timerIdle,
            TaskSchema.timerStartAt: null,
            TaskSchema.completedAt: null,
            TaskSchema.failedAt: null,

            // Proof awal (Kosong, akan diisi dari proof_screen.dart nanti)
            TaskSchema.proofUrl: '',
            TaskSchema.proofText: '',
            TaskSchema.isVerified: false,

            // Sistem Hukuman (Cursed System)
            // Catatan Sidang: Secara default task normal adalah 'false'.
            // Namun jika lewat tengah malam (besoknya) belum selesai, DailyScreen akan merubahnya jadi 'true' (Terkutuk).
            TaskSchema.isCursed: false,
            TaskSchema.cursedMultiplier: 1.0,

            // Frekuensi (Harian/Mingguan)
            TaskSchema.frequency: _frequency,

            // Waktu & Pembuatan
            TaskSchema.deadline: Timestamp.fromDate(deadline),
            TaskSchema.createdAt: FieldValue.serverTimestamp(), // Ambil waktu asli dari server Firebase, bukan waktu HP
          });

      // Beritahu layar sebelumnya (Home) bahwa ada task baru masuk
      widget.onTaskAdded?.call();
      
      // Tutup modal popup Tambah Tugas
      if (mounted) Navigator.pop(context);
      
      // Tampilkan pesan sukses
      _showSnack(
        l.isEn 
          ? 'Task added! +$_xpReward XP & +$_goldReward 🪙 awaits!'
          : 'Task ditambahkan! +$_xpReward XP & +$_goldReward 🪙 menanti!',
      );
    } catch (e) {
      _showSnack(l.isEn ? 'Failed to save task: $e' : 'Gagal menyimpan task: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false); // Matikan loading
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardH = MediaQuery.of(context).viewInsets.bottom;
    final l = context.lw;

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: keyboardH),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              l.addTaskTitle,
              style: GoogleFonts.nunito(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            // ── Judul ──────────────────────────────────────
            _label(l.addTaskTitleField),
            _inputField(controller: _titleCtrl, hint: l.addTaskTitleHint),
            const SizedBox(height: 10),
            
            // --- Quest Ideas ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: l.questIdeas(_selectedCategory).map((idea) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _titleCtrl.text = idea);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _catColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _catColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          idea,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppColors.textPrimary.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // ── Notes ──────────────────────────────────────
            _label(l.addTaskNotes),
            _inputField(
              controller: _notesCtrl,
              hint: l.addTaskNotesHint,
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            // ── Kategori ───────────────────────────────────
            _label(l.addTaskCategory),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categoryColors.keys.map((cat) {
                final bool active = _selectedCategory == cat;
                final Color c = categoryColors[cat]!;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedCategory = cat;
                      _proofType =
                          categoryDefaultProof[cat] ?? TaskSchema.proofTypeNone;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? c.withValues(alpha: 0.2)
                          : AppColors.textPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? c : AppColors.textPrimary.withValues(alpha: 0.24),
                        width: active ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          categoryIcons[cat]!,
                          color: active ? c : AppColors.textPrimary.withValues(alpha: 0.38),
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          l.catName(cat),
                          style: GoogleFonts.nunito(
                            color: active ? c : AppColors.textPrimary.withValues(alpha: 0.60),
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // ── Difficulty ─────────────────────────────────
            _label(l.addTaskDifficulty),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (i) {
                final bool active = _selectedDiff == i;
                final int lvl = i + 1;
                final Color dotColor = active ? _catColor : AppColors.textPrimary.withValues(alpha: 0.24);
                final labels = l.difficultyLabels;
                final xp = RankSystem.xpReward(lvl);
                final gold = RankSystem.goldReward(lvl);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDiff = i);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? _catColor.withValues(alpha: 0.15)
                          : AppColors.textPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: dotColor, width: 1.2),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            lvl,
                            (_) => Container(
                              width: 5,
                              height: 5,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: BoxDecoration(
                                color: active ? _catColor : AppColors.textPrimary.withValues(alpha: 0.38),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          labels[i],
                          style: GoogleFonts.nunito(
                            color: active ? _catColor : AppColors.textPrimary.withValues(alpha: 0.54),
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          '+$xp XP',
                          style: GoogleFonts.nunito(
                            color: active
                                ? _catColor.withValues(alpha: 0.8)
                                : AppColors.textPrimary.withValues(alpha: 0.30),
                            fontSize: 9,
                          ),
                        ),
                        Text(
                          '+$gold 🪙',
                          style: GoogleFonts.nunito(
                            color: active
                                ? Color(0xFFF59E0B)
                                : AppColors.textPrimary.withValues(alpha: 0.24),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // ── Frekuensi ─────────────────────────────────
            _label(l.addTaskFrequency),
            const SizedBox(height: 8),
            Row(
              children: [TaskSchema.freqDaily, TaskSchema.freqWeekly].map((f) {
                final active = _frequency == f;
                final isDaily = f == TaskSchema.freqDaily;
                final ic = isDaily
                    ? Icons.today_rounded
                    : Icons.date_range_rounded;
                final lbl = isDaily ? l.freqDaily : l.freqWeekly;
                final sub = isDaily ? l.freqDailyDesc : l.freqWeeklyDesc;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _frequency = f);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                        right: isDaily ? 8 : 0,
                        left: isDaily ? 0 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? _catColor.withValues(alpha: 0.15)
                            : AppColors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? _catColor : AppColors.textPrimary.withValues(alpha: 0.24),
                          width: active ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            ic,
                            color: active ? _catColor : AppColors.textPrimary.withValues(alpha: 0.38),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lbl,
                                style: GoogleFonts.nunito(
                                  color: active ? _catColor : AppColors.textPrimary.withValues(alpha: 0.60),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                sub,
                                style: GoogleFonts.nunito(
                                  color: active
                                      ? _catColor.withValues(alpha: 0.6)
                                      : AppColors.textPrimary.withValues(alpha: 0.30),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 14),

            _label(l.addTaskDuration),
            SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDuration,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _durationMinutes > 0
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.textPrimary.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                  boxShadow: _durationMinutes > 0
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      color: _durationMinutes > 0 ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.54),
                      size: 22,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _durationMinutes == 0
                                ? l.addTaskDurationNone
                                : '${_durationMinutes ~/ 60} ${l.isEn ? 'Hours' : 'Jam'} ${_durationMinutes % 60} ${l.isEn ? 'Minutes' : 'Menit'}',
                            style: GoogleFonts.nunito(
                              color: AppColors.textOnPrimary,
                            fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            l.addTaskDurationHint,
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary.withValues(alpha: 0.38),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_calendar_rounded,
                      color: AppColors.textDisabled,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),

            // ── Tipe Bukti ─────────────────────────────────
            _label(l.addTaskProof),
            SizedBox(height: 4),
            Text(
              l.addTaskProofHint,
              style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 11),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                _proofButton(
                  TaskSchema.proofTypeNone,
                  Icons.check_circle_outline_rounded,
                  l.proofNone,
                ),
                SizedBox(width: 8),
                _proofButton(
                  TaskSchema.proofTypePhoto,
                  Icons.camera_alt_rounded,
                  l.proofPhoto,
                ),
                SizedBox(width: 8),
                _proofButton(
                  TaskSchema.proofTypeText,
                  Icons.edit_note_rounded,
                  l.proofText,
                ),
              ],
            ),
            SizedBox(height: 14),

            // ── Deadline ───────────────────────────────────
            _label(l.addTaskDeadline),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _pickerButton(
                    icon: Icons.calendar_today_rounded,
                    label:
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    onTap: _pickDate,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _pickerButton(
                    icon: Icons.access_time_rounded,
                    label: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // ── Reward Preview ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.textDisabled),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _rewardChip(
                    Icons.bolt_rounded,
                    '+$_xpReward XP',
                    AppColors.xp,
                  ),
                  _rewardChip(
                    Icons.monetization_on_rounded,
                    '+$_goldReward Gold',
                    AppColors.gold,
                  ),
                  if (_durationMinutes > 0)
                    _rewardChip(
                      Icons.timer_rounded,
                      '$_durationMinutes menit',
                      AppColors.textPrimary.withValues(alpha: 0.54),
                    ),
                  _rewardChip(
                    _proofType == TaskSchema.proofTypePhoto
                        ? Icons.camera_alt_rounded
                        : _proofType == TaskSchema.proofTypeText
                        ? Icons.edit_note_rounded
                        : Icons.check_rounded,
                    _proofType == TaskSchema.proofTypePhoto
                        ? l.proofPhoto
                        : _proofType == TaskSchema.proofTypeText
                        ? l.proofText
                        : l.proofNone,
                    AppColors.textPrimary.withValues(alpha: 0.38),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ── Submit ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.textOnPrimary,
                            strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l.addTaskSubmit,
                        style: GoogleFonts.nunito(
                          color: AppColors.textOnPrimary,
                            fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
        // ── xqvx The Creator tutorial overlay (inline) ──────────────────────
        if (_showTutorial)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: RpgTutorialOverlay(
                steps: l.tutorialAddTask,
                inline: false, // full dimmer inside the sheet
                accentColor: AppColors.primary,
                onCompleted: _markTutorialDone,
                onSkipped: _markTutorialDone,
              ),
            ),
          ),
      ],
    );
  }

  Widget _proofButton(String type, IconData icon, String label) {
    final bool active = _proofType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _proofType = type);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.textPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.primary.withValues(alpha: 0.7) : AppColors.textPrimary.withValues(alpha: 0.24),
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.38), size: 20),
              SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.nunito(
                  color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.38),
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardChip(IconData icon, String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 14),
      const SizedBox(width: 4),
      Text(
        label,
        style: GoogleFonts.nunito(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.nunito(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) => Container(
    margin: const EdgeInsets.only(top: 6),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 14),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textDisabled),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.textDisabled),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
    ),
  );

  Widget _pickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textDisabled),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.54), size: 16),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.nunito(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
