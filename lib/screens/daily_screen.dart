import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';
import '../services/auth_service.dart';
import '../widget/theme_card.dart';
import '../widget/avatar_preview.dart';
import '../services/audio_service.dart';
import '../services/locale_service.dart';
import 'login_screen.dart';
import 'focus_timer_screen.dart';
import 'proof_screen.dart';
import '../widget/celebration_overlay.dart';
import '../theme/rpg_theme.dart';
import '../theme/app_theme.dart';
import '../widget/screen_header.dart';
import '../widget/active_buffs_widget.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  // Use dynamic AppColors
  static Map<String, Color> get _catColors => RPGColors.catColors;
  static Map<String, IconData> get _catIcons => RPGIcons.catIcons;

  String _uid = '';
  String _userName = 'User';
  String _username = '';
  int _xp = 0;
  int _level = 1;
  int _hp = 80;
  int _maxHp = 100;
  int _coin = 0;
  String _rank = 'F';
  Map<String, String> _equippedItems = {};
  String? _baseBody;
  Timestamp? _xpBonusUntil;
  Timestamp? _goldBonusUntil;

  String _filterCat = 'Semua';
  String _filterStatus = 'Semua';
  String _filterFreq = 'Semua'; // 'Semua' | 'daily' | 'weekly'
  String _searchQuery = '';
  bool _showSearch = false;

  // Filter constants
  static const String _filterAll = 'Semua';
  static const String _filterActive = 'Belum';
  static const String _filterDone = 'Selesai';

  final TextEditingController _searchCtrl = TextEditingController();
  StreamSubscription<DocumentSnapshot>? _userSub;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _checkCursedTasks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _uid = uid);
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted || !doc.exists) return;
      final d = doc.data()!;
    setState(() {
      _userName = d['name'] ?? 'User';
      _username = d['username'] ?? '';
      _xp = d['xp'] ?? 0;
      _level = d['level'] ?? 1;
      _hp = d[UserSchema.hp] ?? d['hp'] ?? 80;
      _maxHp = d[UserSchema.maxHp] ?? d['maxHp'] ?? 100;
      _coin = d[UserSchema.gold] ?? d['coin'] ?? 0;
      _rank = _getRank(d);
      if (d[UserSchema.equippedItems] != null) {
        _equippedItems = Map<String, String>.from(d[UserSchema.equippedItems]);
      }
      _baseBody = d[UserSchema.baseBody] as String?;
      _xpBonusUntil = d[UserSchema.xpBonusUntil] as Timestamp?;
      _goldBonusUntil = d[UserSchema.goldBonusUntil] as Timestamp?;
    });
  });
  }

  // --- SISTEM HUKUMAN (PUNISHMENT SYSTEM) ---
  /// Fungsi ini berjalan otomatis setiap kali layar ini dibuka.
  /// Tugasnya adalah mencari task dari kemarin yang BELUM SELESAI, 
  /// lalu mengubah statusnya menjadi "Terkutuk" (Cursed) dan memperberat durasi hukumannya (Fokus Timer).
  Future<void> _checkCursedTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Mengambil tanggal hari ini pada jam 00:00:00
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // 1. Tembak Query ke Firebase: 
    // Ambilkan semua task yang:
    // - done = false (Belum selesai)
    // - isCursed = false (Belum dikutuk sebelumnya, agar tidak dikutuk berkali-kali)
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('tasks')
        .where(TaskSchema.done, isEqualTo: false)
        .where(TaskSchema.isCursed, isEqualTo: false)
        .get();

    // 2. Looping (Periksa satu per satu) hasil query di atas
    for (final doc in snap.docs) {
      final data = doc.data();
      final createdAt = data[TaskSchema.createdAt];
      if (createdAt == null) continue; // Keamanan jika tanggal pembuatan error

      // Konversi format waktu Firebase (Timestamp) menjadi format Flutter (DateTime)
      final createdDate = (createdAt as Timestamp).toDate();
      
      // 3. LOGIKA DETEKSI KETERLAMBATAN:
      // Jika tanggal pembuatan (createdDate) terjadi SEBELUM hari ini (todayStart),
      // maka dipastikan task ini adalah sisa kemarin yang terbengkalai.
      if (createdDate.isBefore(todayStart)) {
        
        // Ambil durasi awal timer fokus (misal 20 menit)
        final currentDuration = (data[TaskSchema.duration] ?? 0) as int;
        
        // HUKUMAN: Waktu fokus ditambah 25% lebih lama (dikalikan 1.25). 
        // Menggunakan .ceil() agar selalu dibulatkan ke atas (misal 20.5 jadi 21 menit).
        final newDuration = currentDuration == 0
            ? 0
            : (currentDuration * 1.25).ceil();

        // 4. Update data ke database bahwa task ini resmi terkutuk
        await doc.reference.update({
          TaskSchema.isCursed: true,
          TaskSchema.cursedMultiplier: 1.25, // Disimpan sebagai riwayat bahwa dia dikalikan
          TaskSchema.duration: newDuration,
        });
      }
    }
  }

  String _getRank(Map<String, dynamic> d) => RankSystem.calculateRank(
    d['level'] ?? 1,
    str: d[UserSchema.strengthXp] ?? 0,
    def: d[UserSchema.defenseXp] ?? 0,
    intl: d[UserSchema.intelligenceXp] ?? 0,
    vit: d[UserSchema.vitalityXp] ?? 0,
    agi: d[UserSchema.agilityXp] ?? 0,
  );

  Color _rankColor(String rank) => Color(RankSystem.rankColorHex(rank));

  int _xpNext(int level) => 100 + (level - 1) * 50;

  // ✅ FIX: helper baca difficulty aman untuk data lama (String) & baru (int)
  int _parseDiff(dynamic raw) {
    if (raw is int) return raw.clamp(1, 4);
    if (raw is String) return int.tryParse(raw) ?? 1;
    return 1;
  }

  Stream<QuerySnapshot>? _taskStream() {
    if (_uid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- FUNGSI MENGUBAH STATUS TUGAS (CENTANG SELESAI) ---
  // Fungsi ini dipanggil ketika user menekan kotak centang pada suatu task.
  Future<void> _toggleDone(String taskId, bool current, int diff, String title, String category) async {
    // 1. Cek Keamanan: Pastikan user sedang login (ada UID-nya)
    if (_uid.isEmpty) return;
    
    // 2. Mainkan efek getar HP dan efek suara centang
    HapticFeedback.lightImpact();
    
    // 3. Tentukan target dokumen task mana yang mau diupdate di Firestore
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId);
        
    // 4. Siapkan paket data yang mau diupdate.
    // Membalik nilai status saat ini (jika false jadi true, jika true jadi false)
    final Map<String, dynamic> updates = {
      TaskSchema.done: !current,
    };
    
    // Jika task baru saja MAU DISELESAIKAN (bukan dibatalkan penyelesaiannya)
    if (!current) {
      // Simpan waktu penyelesaian menggunakan jam dari server Google (sangat akurat, anti-cheat)
      updates[TaskSchema.completedAt] = FieldValue.serverTimestamp();
    }
    
    // 5. Eksekusi pengiriman data status penyelesaian ke Firestore
    await ref.update(updates);
    
    // 6. --- LOGIKA HADIAH (REWARD SYSTEM) ---
    // Hanya berikan hadiah jika task diubah dari BELUM SELESAI menjadi SELESAI
    if (!current) {
      // Daftar hadiah XP berdasarkan tingkat kesulitan (Difficulty: 1, 2, 3, 4)
      // clamp(0,4) menjaga agar angka tidak pernah error (Out of bounds)
      final reward = [0, 20, 40, 80, 150][diff.clamp(0, 4)];
      
      // Update saldo XP pengguna secara "ATOMIC" (FieldValue.increment).
      // Kenapa tidak ambil saldo lama lalu ditambah manual? 
      // Karena increment menjamin data tidak akan dobel/hilang meskipun internet sedang lag.
      await FirebaseFirestore.instance.collection('users').doc(_uid).update({
        'xp': FieldValue.increment(reward),
      });
      
      // Jika aplikasi belum tertutup saat loading (mounted)
      if (mounted) {
        // Update angka XP di memori lokal agar tulisan di layar langsung berubah tanpa reload
        setState(() => _xp += reward);
        
        // Kalkulasi Hadiah Gold (Emas) -> Seperempat dari total XP yang didapat (dibungkus ke atas/ceil)
        final int goldReward = (reward / 4).ceil();
        
        // Update saldo Gold secara Atomic ke database
        await FirebaseFirestore.instance.collection('users').doc(_uid).update({
          UserSchema.gold: FieldValue.increment(goldReward),
        });
        
        // Jika UI masih aktif, panggil overlay animasi konfeti dan tampilkan hadiahnya di tengah layar
        if (mounted) {
          CelebrationOverlay.show(
            context,
            title: title,
            category: category,
            xp: reward,
            coin: goldReward,
            userName: _userName,
            level: _level,
            equippedItems: _equippedItems,
          );
        }
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    if (_uid.isEmpty) return;
    HapticFeedback.mediumImpact();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }





  @override
  Widget build(BuildContext context) {
    // ✅ FIX: hapus Scaffold wrapper, langsung Column
    return Column(
      children: [
        _buildTopBar(),
        _buildUserStats(),
        _buildFreqToggle(),
        _buildCatChips(),
        Expanded(child: _buildTaskList()),
      ],
    );
  }

  // ── Top Bar (Pencarian & Filter) ──────────────────────────────────
  // Bagian paling atas layar, menampilkan teks "Daily Task" atau kolom pencarian
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: _showSearch
          ? Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: GoogleFonts.nunito(color: AppColors.textPrimary),
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari task...',
                      hintStyle: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showSearch = false;
                      _searchQuery = '';
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.close, color: AppColors.textPrimary),
                  ),
                ),
              ],
            )
          : ScreenHeader(
              title: 'Daily Task',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showSearch = true),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.search, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showFilterSheet(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.filter_list_rounded, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ── Toggle Frekuensi (Harian/Mingguan) ─────────────────────────
  // Menampilkan 3 tombol (Semua, Harian, Mingguan) untuk menyaring daftar misi
  Widget _buildFreqToggle() {
    final l = context.l;
    final tabs = [_filterAll, 'daily', 'weekly'];
    final labels = [l.dailyFilterAll, l.freqDaily, l.freqWeekly];
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4), // Added top padding to prevent crowding
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final active = _filterFreq == tabs[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filterFreq = tabs[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: GoogleFonts.nunito(
                        color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.54),
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // Fungsi kecil pembuat tombol icon kotak dengan sudut membulat
  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 18),
        ),
      );

  // Menampilkan popup lembaran bawah (bottom sheet) untuk filter status (Selesai/Belum)
  void _showFilterSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        currentStatus: _filterStatus,
        onApply: (status) => setState(() => _filterStatus = status),
      ),
    );
  }

  // ── Kartu Profil Statistik Pemain ─────────────────────────────
  // Mirip dengan Header di Home, ini menampilkan Info Karakter (Avatar, Level, XP bar)
  Widget _buildUserStats() {
    // 1. Hitung total XP yang dibutuhkan untuk naik ke level berikutnya
    final xpNext = _xpNext(_level);
    
    // 2. Hitung persentase XP saat ini (untuk mengisi bar progress)
    final xpProg = (_xp % xpNext) / xpNext;
    
    // 3. Hitung persentase Darah (HP) saat ini
    final eProg = _hp / _maxHp;
    
    // 4. Dapatkan warna pangkat (misalnya SSR warna pelangi, A warna merah, dll)
    final rc = _rankColor(_rank);
    final isSSR = _rank == 'SSR';

    return ThemeCard(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
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
              SizedBox(
                width: 84,
                height: 84,
                child: ThemeCard(
                  backgroundColor: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  borderColor: AppColors.primary,
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
                    onTap: () async {
                      await AuthService().logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
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
                            'Logout',
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
            _xp % xpNext,
            xpNext,
            xpProg,
            AppColors.xp,
          ),
        ],
      ),
    );
  }

  // ── Bar (HP / XP) ───────────────────────────────────────────
  Widget _bar(
    String label, 
    IconData ic,  
    int val,      
    int mx,       
    double prog,  
    Color c,      
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
            width: double.infinity,
            color: c.withValues(alpha: 0.12),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
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

  // ── Filter Kategori (Chips) ───────────────────────────────────
  // Deretan tombol kategori (Strength, Agility, dsb) yang bisa di-scroll ke samping
  // Berguna untuk memfilter daftar misi berdasarkan kategori
  Widget _buildCatChips() {
    final l = context.l;
    final cats = [_filterAll, ..._catColors.keys];
    return SizedBox(
      height: 54, // Taller to fit description
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final active = _filterCat == cat;
          final color = i == 0 ? AppColors.primary : _catColors[cat]!;
          return GestureDetector(
            onTap: () {
              // AudioService.playClick();
              setState(() => _filterCat = cat);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: 0.2) : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? color.withValues(alpha: 0.7) : AppColors.cardBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i != 0) ...[
                    Icon(
                      _catIcons[cat],
                      size: 12,
                      color: active ? color : AppColors.textPrimary.withValues(alpha: 0.38),
                    ),
                    SizedBox(width: 5),
                  ],
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        i == 0 ? l.dailyFilterAll : l.catName(cat),
                        style: GoogleFonts.nunito(
                          color: active ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.38),
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                      if (i != 0)
                        Text(
                          l.catDesc(cat),
                          style: GoogleFonts.nunito(
                            color: active ? color.withValues(alpha: 0.8) : AppColors.textPrimary.withValues(alpha: 0.24),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Daftar Misi (Task List) ───────────────────────────────────
  // Mengambil data dari Firebase secara real-time (Stream) 
  // lalu menyaringnya berdasarkan tab kategori, status, kata kunci, dan frekuensi.
  Widget _buildTaskList() {
    if (_uid.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _taskStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        var docs = snap.data?.docs ?? [];

        if (_filterCat != 'Semua') {
          docs = docs
              .where((d) => (d.data() as Map)['category'] == _filterCat)
              .toList();
        }
        if (_filterStatus == _filterActive) {
          docs = docs.where((d) => (d.data() as Map)['done'] != true).toList();
        } else if (_filterStatus == _filterDone) {
          docs = docs.where((d) => (d.data() as Map)['done'] == true).toList();
        }
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final t = ((d.data() as Map)['title'] ?? '')
                .toString()
                .toLowerCase();
            return t.contains(_searchQuery.toLowerCase());
          }).toList();
        }
        if (_filterFreq != _filterAll) {
          docs = docs.where((d) {
            final freq =
                (d.data() as Map)[TaskSchema.frequency] ?? TaskSchema.freqDaily;
            return freq == _filterFreq;
          }).toList();
        }

        if (docs.isEmpty) return _buildEmpty();

        final total = docs.length;
        final done = docs
            .where((d) => (d.data() as Map)['done'] == true)
            .length;

        return Column(
          children: [
            _buildSummary(done, total),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                itemCount: docs.length,
                itemBuilder: (_, i) => DailyTaskCard(
                  doc: docs[i],
                  catColors: _catColors,
                  catIcons: _catIcons,
                  parseDiff: _parseDiff,
                  onToggle: _toggleDone,
                  onDelete: _deleteTask,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Ringkasan (Summary) ─────────────────────────────────────────
  // Menampilkan teks "Task" dan progress bar kecil (contoh: 2/5 Selesai)
  Widget _buildSummary(int done, int total) {
    final l = context.l;
    final pct = total == 0 ? 0.0 : done / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          Text(
            'Task',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Text(
            '$done/$total ${l.homeTasksDone}',
            style: GoogleFonts.nunito(color: AppColors.textPrimary.withValues(alpha: 0.38), fontSize: 12),
          ),
          SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 6, color: AppColors.primary.withValues(alpha: 0.15)),
                  FractionallySizedBox(
                    widthFactor: pct,
                    child: Container(height: 6, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_rounded, color: AppColors.textDisabled, size: 64),
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
          'Tambah lewat tombol + di bawah',
          style: GoogleFonts.nunito(color: AppColors.textDisabled, fontSize: 13),
        ),
      ],
    ),
  );
}

class DailyTaskCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, Color> catColors;
  final Map<String, IconData> catIcons;
  final int Function(dynamic) parseDiff;
  final Future<void> Function(String, bool, int, String, String) onToggle;
  final Future<void> Function(String) onDelete;

  const DailyTaskCard({
    super.key,
    required this.doc,
    required this.catColors,
    required this.catIcons,
    required this.parseDiff,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<DailyTaskCard> createState() => DailyTaskCardState();
}

class DailyTaskCardState extends State<DailyTaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openTimer(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
    Color color,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    HapticFeedback.mediumImpact();
    // AudioService.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusTimerScreen(
          taskId: id,
          uid: uid,
          title: data['title'] ?? 'Task',
          category: data['category'] ?? 'Strength',
          difficulty: (data[TaskSchema.difficulty] ?? 1) as int,
          durationMinutes: (data[TaskSchema.duration] ?? 0) as int,
          proofType: data[TaskSchema.proofType] ?? TaskSchema.proofTypeNone,
          xpReward: (data[TaskSchema.xp] ?? 20) as int,
          goldReward: (data[TaskSchema.goldReward] ?? 5) as int,
        ),
      ),
    );
  }

  void _openProof(
    BuildContext context,
    Map<String, dynamic> data,
    String id,
  ) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProofScreen(
          taskId: id,
          uid: uid,
          title: data['title'] ?? 'Task',
          category: data['category'] ?? 'Strength',
          proofType: data[TaskSchema.proofType] ?? TaskSchema.proofTypeNone,
          xpReward: (data[TaskSchema.xp] ?? 20) as int,
          goldReward: (data[TaskSchema.goldReward] ?? 5) as int,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final data = widget.doc.data() as Map<String, dynamic>;
    final id = widget.doc.id;
    final title = data['title'] ?? 'Untitled';
    final notes = data['notes'] ?? '';
    final cat = data['category'] ?? 'Strength';
    final int diff = widget.parseDiff(data['difficulty']);
    final bool done = data['done'] == true;
    final bool isCursed = data[TaskSchema.isCursed] == true;
    final String timerStatus =
        data[TaskSchema.timerStatus] ?? TaskSchema.timerIdle;
    final int durationMin = (data[TaskSchema.duration] ?? 0) as int;
    final Timestamp? deadline = data['deadline'] as Timestamp?;

    final color = widget.catColors[cat] ?? AppColors.primary;
    final icon = widget.catIcons[cat] ?? Icons.star_rounded;

    final diffColors = [
      null,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.error,
    ];
    final diffLabels = ['', 'Easy', 'Medium', 'Hard', 'Extreme'];
    final xpRewards = [0, 20, 40, 80, 150];
    final dColor = diffColors[diff.clamp(1, 4)]!;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(Icons.delete_rounded, color: AppColors.error),
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
                '"$title" akan dihapus.',
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
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (_) => widget.onDelete(id),
          // Menggunakan ThemeCard agar task harian juga ter-sketsa //
          child: ThemeCard(
            margin: const EdgeInsets.only(bottom: 10),
            backgroundColor: done
                ? AppColors.cardBackground.withValues(alpha: 0.5)
                : AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            borderColor: done
                ? AppColors.cardBorder.withValues(alpha: 0.3)
                : isCursed
                ? AppColors.error.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.2),
            borderWidth: isCursed && !done ? 1.5 : 1,
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: isCursed && !done ? 90 : 76,
                  decoration: BoxDecoration(
                    color: done
                        ? Colors.grey.withValues(alpha: 0.3)
                        : isCursed
                        ? AppColors.error
                        : color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 76,
                  alignment: Alignment.center,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: done
                          ? AppColors.textPrimary.withValues(alpha: 0.05)
                          : color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: done ? AppColors.textPrimary.withValues(alpha: 0.24) : color,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.nunito(
                            color: done ? AppColors.textPrimary.withValues(alpha: 0.38) : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            decorationColor: AppColors.textPrimary.withValues(alpha: 0.38),
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          SizedBox(height: 2),
                          Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: AppColors.textPrimary.withValues(alpha: 0.38),
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (isCursed && !done) ...[
                          SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                0xFFEF4444,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.error,
                                  size: 10,
                                ),
                                SizedBox(width: AppColors.borderWidth * 3),
                                Text(
                                  'CURSED  •  Durasi +25%  •  XP -50%',
                                  style: GoogleFonts.nunito(
                                    color: AppColors.error,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(
                              diff.clamp(1, 4),
                              (_) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: done ? AppColors.textPrimary.withValues(alpha: 0.24) : dColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            ...List.generate(
                              (4 - diff).clamp(0, 4),
                              (_) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.textDisabled,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              diffLabels[diff.clamp(1, 4)],
                              style: GoogleFonts.nunito(
                                color: done ? AppColors.textPrimary.withValues(alpha: 0.24) : dColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              '+${xpRewards[diff.clamp(0, 4)]} XP',
                              style: GoogleFonts.nunito(
                                color: done
                                    ? AppColors.textPrimary.withValues(alpha: 0.24)
                                    : AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (deadline != null) ...[
                              SizedBox(width: 8),
                              Icon(
                                Icons.schedule_rounded,
                                size: 10,
                                color: AppColors.textPrimary.withValues(alpha: 0.38),
                              ),
                              SizedBox(width: AppColors.borderWidth * 2),
                              Text(
                                _fmtDeadline(deadline),
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
                // Start button / status
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: done
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                        )
                      : timerStatus == TaskSchema.timerRunning
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timer_rounded, color: color, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Jalan',
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
                          onTap: () {
                            if (durationMin > 0) {
                              _openTimer(context, data, id, color);
                            } else {
                              final pType = data[TaskSchema.proofType] ?? TaskSchema.proofTypeNone;
                              if (!done && pType != TaskSchema.proofTypeNone) {
                                _openProof(context, data, id);
                              } else {
                                widget.onToggle(id, done, diff, title, cat);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  durationMin > 0
                                      ? Icons.play_arrow_rounded
                                      : Icons.check_circle_outline_rounded,
                                  color: color,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  durationMin > 0 ? 'Start' : 'Done',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDeadline(Timestamp ts) {
    final dt = ts.toDate();
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}';
  }
}

class _FilterSheet extends StatefulWidget {
  final String currentStatus;
  final Function(String status) onApply;

  const _FilterSheet({required this.currentStatus, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDisabled,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            l.isEn ? 'Filter Status' : 'Filter Status',
            style: GoogleFonts.nunito(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _DailyScreenState._filterAll,
              _DailyScreenState._filterActive,
              _DailyScreenState._filterDone
            ].map((s) {
              final active = _status == s;
              final label = s == _DailyScreenState._filterAll
                  ? l.dailyFilterAll
                  : s == _DailyScreenState._filterActive
                      ? l.dailyFilterActive
                      : l.dailyFilterDone;
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.textPrimary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.nunito(
                      color: active ? AppColors.primary : AppColors.textPrimary.withValues(alpha: 0.54),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                widget.onApply(_status);
                Navigator.pop(context);
              },
              child: Text(
                l.btnApply,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



