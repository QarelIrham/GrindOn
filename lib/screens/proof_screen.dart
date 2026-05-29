import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_schema.dart';
import '../services/audio_service.dart';
import '../widget/avatar_preview.dart';
import '../theme/rpg_theme.dart';
import '../models/avatar_data.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';


class ProofScreen extends StatefulWidget {
  final String taskId;
  final String uid;
  final String title;
  final String category;
  final String proofType;
  final int xpReward;
  final int goldReward;

  const ProofScreen({
    super.key,
    required this.taskId,
    required this.uid,
    required this.title,
    required this.category,
    required this.proofType,
    required this.xpReward,
    required this.goldReward,
  });

  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  static Map<String, Color> get catColors => RPGColors.catColors;

  final _textCtrl = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  String _userName = 'User';
  int _level = 1;
  Map<String, String> _equippedItems = {};

  Color get _color => catColors[widget.category] ?? const Color(0xFF7C3AED);

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.proofType == TaskSchema.proofTypeNone) {
      _isLoading = true;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _submit();
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
      maxWidth: 800,
    );
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  // --- FUNGSI MENGIRIM BUKTI TUGAS & MENGHITUNG HADIAH ---
  Future<void> _submit() async {
    // 1. Validasi Input: Pastikan user tidak mengirim form kosong
    final l = context.l;
    if (widget.proofType == TaskSchema.proofTypePhoto && _imageFile == null) {
      _showSnack(l.proofNeedPhoto); // Harus ada foto jika disuruh foto
      return;
    }
    if (widget.proofType == TaskSchema.proofTypeText &&
        _textCtrl.text.trim().isEmpty) {
      _showSnack(l.proofNeedText); // Harus ada teks jika disuruh nulis
      return;
    }

    // Tampilkan animasi loading
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact(); // Efek getar

    try {
      String proofUrl = '';

      // 2. PENYIMPANAN FOTO (BASE64 ENCODING)
      // Catatan Sidang: Mengapa pakai Base64? 
      // Karena kuota penyimpanan (Storage) Firebase gratisan sangat kecil (5GB).
      // Mengubah gambar menjadi teks Base64 memungkinkan kita menyimpannya langsung di Firestore (Database)
      // sehingga tidak memakan kuota Storage, menghemat biaya (Cost Optimization).
      if (_imageFile != null) {
        try {
          final bytes = _imageFile!.readAsBytesSync();
          final base64String = base64Encode(bytes); // Gambar diubah jadi kode teks panjang
          proofUrl = 'data:image/jpeg;base64,$base64String';
        } catch (e) {
          proofUrl = 'local_path_fallback';
        }
      }

      // 3. UPDATE STATUS TASK DI FIREBASE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('tasks')
          .doc(widget.taskId)
          .update({
            TaskSchema.done: true, // Tandai selesai
            TaskSchema.isVerified: true, // Tandai sudah ada bukti
            TaskSchema.proofUrl: proofUrl, // Masukkan kode gambar base64
            TaskSchema.proofText: _textCtrl.text.trim(),
            TaskSchema.completedAt: FieldValue.serverTimestamp(),
            TaskSchema.timerStatus: TaskSchema.timerCompleted, // Matikan status timer
          });

      // 4. MENGHITUNG REWARD (HADIAH XP & GOLD) DENGAN RUMUS RPG
      // Tarik data profil user saat ini untuk mengecek HP dan Streak
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      final userData = userDoc.data() ?? {};
      final currentHp = userData[UserSchema.hp] ?? 100;
      final maxHp = userData[UserSchema.maxHp] ?? 100;
      final currentStreak = userData[UserSchema.streak] ?? 0;

      // Ambil XP dasar dari widget
      int finalXp = widget.xpReward;

      // A. Cek Item Aktif (XP Scroll)
      // Jika user pernah beli item 'Double XP' di toko, kalikan XP-nya 2x lipat
      final xpBonusUntil = userData[UserSchema.xpBonusUntil] as Timestamp?;
      if (xpBonusUntil != null && xpBonusUntil.toDate().isAfter(DateTime.now())) {
        finalXp *= 2;
      }

      // B. Cek Status Tubuh (HP Penalty)
      // Jika HP user sekarat (misal < 20%), XP yang didapat akan dikurangi (hukuman)
      finalXp = RankSystem.effectiveXp(finalXp, currentHp);
      
      // C. Cek Konsistensi (Streak Bonus)
      // Semakin banyak hari berturut-turut user mengerjakan task, XP ditambah sekian persen
      finalXp = RankSystem.streakBonusXp(finalXp, currentStreak);

      // D. Cek Pakaian Avatar (Passive Boosts)
      // Baju/Helm/Pet tertentu (seperti Mahkota atau Naga) memberikan persenan tambahan XP/Gold
      final equipped = Map<String, String>.from(userData[UserSchema.equippedItems] ?? {});
      final passiveStats = AvatarData.getEquippedStats(equipped);
      final xpBoost = passiveStats['xpBoost'] ?? 0.0; // Misal 0.15 (15% tambahan XP)
      final goldBoost = passiveStats['goldBoost'] ?? 0.0;

      // Hitung hasil final sesudah ditambah bonus baju
      finalXp = (finalXp * (1.0 + xpBoost)).round();
      final int finalGold = (widget.goldReward * (1.0 + goldBoost)).round();

      // Setiap selesai task, HP (Darah) akan terisi sedikit (Healing)
      final int newHp = (currentHp + RankSystem.hpGainOnTaskComplete).clamp(0, maxHp);

      // 5. UPDATE SEMUA HADIAH KE DATABASE SECARA BERSAMAAN (ATOMIC)
      final catXpField = _categoryXpField(widget.category);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
            UserSchema.xp: FieldValue.increment(finalXp), // Tambah XP
            UserSchema.gold: FieldValue.increment(finalGold), // Tambah Gold
            UserSchema.hp: newHp, // Set darah baru
            if (catXpField != null) catXpField: FieldValue.increment(finalXp), // Tambah XP ke kategori spesifik (misal: Strength)
            UserSchema.totalTasksDone: FieldValue.increment(1),
          });

      // 6. Cek apakah ini hari baru (Perpanjang Rekor Streak)
      await _updateStreak();

      // 7. Cek apakah XP yang baru didapat cukup untuk NAIK LEVEL
      await _checkLevelUp();

      if (!mounted) return;
      
      // Memperbarui tampilan UI layar
      final currentLevel = userData[UserSchema.level] ?? 1;
      setState(() {
        _userName = userData['name'] ?? 'User';
        _level = currentLevel;
        if (userData[UserSchema.equippedItems] != null) {
          _equippedItems = Map<String, String>.from(userData[UserSchema.equippedItems]);
        }
      });

      // 8. Tampilkan Layar Perayaan Selesai!
      _showQuestCompleteDialog(widget.title, widget.category, finalXp, finalGold);
    } catch (e) {
      _showSnack(context.l.proofSaveFailed('$e'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mengambil kolom XP spesifik berdasarkan kategori (contoh: Strength -> strengthXp)
  String? _categoryXpField(String category) {
    switch (category) {
      case 'Strength':
        return UserSchema.strengthXp;
      case 'Defense':
        return UserSchema.defenseXp;
      case 'Intelligence':
        return UserSchema.intelligenceXp;
      case 'Vitality':
        return UserSchema.vitalityXp;
      case 'Agility':
        return UserSchema.agilityXp;
      default:
        return null;
    }
  }

  // Fungsi untuk memperbarui Rekor Beruntun (Streak)
  // Dipanggil setiap kali user berhasil menyelesaikan setidaknya 1 tugas pada hari itu
  Future<void> _updateStreak() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    final lastActive = data[UserSchema.lastActiveDate] as String? ?? '';
    final today = _dateString(DateTime.now());
    final yesterday = _dateString(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    int currentStreak = data[UserSchema.streak] ?? 0;
    int longestStreak = data[UserSchema.longestStreak] ?? 0;

    if (lastActive == today) return; // Sudah update hari ini
    if (lastActive == yesterday) {
      currentStreak += 1; // Lanjut rekor dari kemarin
    } else {
      currentStreak = 1; // Terputus, mulai dari 1 lagi
    }

    if (currentStreak > longestStreak) longestStreak = currentStreak;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .update({
          UserSchema.streak: currentStreak,
          UserSchema.longestStreak: longestStreak,
          UserSchema.lastActiveDate: today,
        });
  }

  // Fungsi untuk Mengecek dan Menaikkan Level
  // Terus loop hingga XP saat ini tidak lagi melebihi batas XP yang dibutuhkan
  Future<void> _checkLevelUp() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    if (!userDoc.exists) return;

    final data = userDoc.data()!;
    int xp = data[UserSchema.xp] ?? 0;
    int level = data[UserSchema.level] ?? 1;

    int xpNeeded = RankSystem.xpForLevel(level);
    while (xp >= xpNeeded) {
      level++;
      xpNeeded = RankSystem.xpForLevel(level);
    }

    // Set peringkat baru (misal Level 10 jadi Peringkat B, dll)
    final newRank = RankSystem.calculateRank(level);
    await FirebaseFirestore.instance.collection('users').doc(widget.uid).update(
      {UserSchema.level: level, UserSchema.rank: newRank},
    );
  }

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  // Menampilkan Layar Perayaan Selesai! (Mirip Gacha / Reward Screen)
  void _showQuestCompleteDialog(String title, String category, int xp, int gold) {
    final l = context.l;
    AudioService.playSuccess();
    final ScreenshotController questScrenshot = ScreenshotController();
    final color = catColors[category] ?? const Color(0xFF7C3AED);
    final catLabel = l.catName(category);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Screenshot(
              controller: questScrenshot,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Color(0xFF13131A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.proofQuestComplete, style: GoogleFonts.nunito(
                      color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2,
                    )),
                    SizedBox(height: 16),
                    Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 64),
                    SizedBox(height: 16),
                    Text(title, textAlign: TextAlign.center, style: GoogleFonts.nunito(
                      color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold,
                    )),
                    SizedBox(height: 8),
                    Text(catLabel, style: GoogleFonts.nunito(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _rewardChip('+$xp XP', Color(0xFFF59E0B), Icons.bolt_rounded),
                        SizedBox(width: 12),
                        _rewardChip('+$gold Gold', Color(0xFFFFD700), Icons.monetization_on_rounded),
                      ],
                    ),
                    SizedBox(height: 24),
                    // Mini Avatar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: 40, height: 40,
                            color: AppColors.textPrimary.withValues(alpha: 0.10),
                            child: AvatarPreview(equippedItems: _equippedItems, size: 40),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('$_userName • Lv.$_level', style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary.withValues(alpha: 0.10),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l.btnClose, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final image = await questScrenshot.capture();
                      if (image != null) {
                        final dir = await getTemporaryDirectory();
                        final file = await File('${dir.path}/quest_complete.png').create();
                        await file.writeAsBytes(image);
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: '${l.proofShareText}$title${l.proofShareHashtags}',
                        );
                      }
                    },
                    icon: Icon(Icons.share_rounded, size: 18, color: AppColors.textPrimary),
                    label: Text('Share', style: GoogleFonts.nunito(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.nunito(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.lw;
    return Scaffold(
      backgroundColor: Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.proofTitle,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          widget.title,
                          style: GoogleFonts.nunito(
                            color: AppColors.textPrimary.withValues(alpha: 0.54),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              if (widget.proofType == TaskSchema.proofTypePhoto) ...[
                Text(
                  l.proofUploadPhoto,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  l.proofPhotoHint,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary.withValues(alpha: 0.38),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: _imageFile != null ? 220 : 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _imageFile != null
                            ? _color.withValues(alpha: 0.5)
                            : AppColors.textPrimary.withValues(alpha: 0.12),
                        width: _imageFile != null ? 1.5 : 1,
                      ),
                      image: _imageFile != null
                          ? DecorationImage(
                              image: FileImage(_imageFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imageFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: _color.withValues(alpha: 0.5),
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                l.proofTapCamera,
                                style: GoogleFonts.nunito(
                                  color: AppColors.textPrimary.withValues(alpha: 0.38),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageFile = null),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.textSecondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: AppColors.textPrimary,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ] else if (widget.proofType == TaskSchema.proofTypeText) ...[
                Text(
                  l.proofWriteSummary,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  l.proofSummaryHint,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary.withValues(alpha: 0.38),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: _textCtrl,
                  maxLines: 6,
                  style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: l.proofSummaryFieldHint,
                    hintStyle: GoogleFonts.nunito(
                      color: AppColors.textDisabled,
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.textDisabled),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.textDisabled),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: _color, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ] else ...[
                // proofType == none → loading spinner (auto submit)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 80),
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          color: RPGColors.accent,
                          strokeWidth: 4.0,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        l.proofVerifying,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        l.proofVerifyingHint,
                        style: GoogleFonts.nunito(
                          color: AppColors.textPrimary.withValues(alpha: 0.38),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ],

              SizedBox(height: 32),

              if (widget.proofType != TaskSchema.proofTypeNone)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _color,
                      disabledBackgroundColor: _color.withValues(alpha: 0.5),
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
                              color: AppColors.textPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            l.proofSubmitBtn,
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary,
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
    );
  }
}
