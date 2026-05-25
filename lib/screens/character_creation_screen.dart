import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_schema.dart';
import '../l10n/app_locale.dart';
import '../services/locale_service.dart';
import 'home_screen.dart';
import 'interactive_tutorial_screen.dart';
import '../theme/app_theme.dart';

// Layar Pembuatan Karakter Pertama Kali
class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({super.key});
  @override
  State<CharacterCreationScreen> createState() => _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen>
    with TickerProviderStateMixin { // TickerProvider digunakan agar kita bisa memutar animasi (seperti detak jantung)
  
  // Variabel untuk menyimpan pilihan jenis kelamin ('male' atau 'female')
  String _gender = 'male';
  
  // Variabel untuk menyimpan indeks kepala mana yang dipilih (0 atau 1)
  int _selectedHead = 0;
  
  // Penanda apakah saat ini aplikasi sedang memuat/menyimpan data ke internet
  bool _isSaving = false;
  
  // Langkah saat ini. 0 = Layar pilih Gender, 1 = Layar pilih Kepala
  int _step = 0; 

  // Controller Animasi untuk efek pudar (Fade) dan membal (Bounce)
  late AnimationController _fadeCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _bounceAnim;

  // Daftar nama file (path) gambar kepala khusus pria
  static const _maleHeads = [
    'lib/assets/Head/head_default_login_male1.png',
    'lib/assets/Head/head_default_login_male2.png',
  ];
  
  // Daftar nama file (path) gambar kepala khusus wanita
  static const _femaleHeads = [
    'lib/assets/Head/head_default_login_female1.png',
    'lib/assets/Head/head_default_login_female2.png',
  ];

  // ID Kepala yang akan disimpan ke database Firestore (Bukan lokasinya, tapi namanya saja)
  static const _headIds = {
    'male': ['head_default_login_male1', 'head_default_login_male2'],
    'female': ['head_default_login_female1', 'head_default_login_female2'],
  };

  @override
  void initState() {
    super.initState();
    // Mempersiapkan durasi dan gaya kelengkungan animasi memudar
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward(); // Jalankan animasi memudar
    
    // Mempersiapkan durasi dan gaya kelengkungan animasi membal
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut); // elasticOut bikin efek membal karet
    _bounceCtrl.forward(); // Jalankan animasi membal
  }

  @override
  void dispose() { 
    // Jangan lupa hancurkan controller saat layar tertutup agar RAM tidak penuh
    _fadeCtrl.dispose(); 
    _bounceCtrl.dispose(); 
    super.dispose(); 
  }

  // --- FUNGSI LOGIKA (GETTER) ---
  // Fungsi otomatis untuk menentukan daftar kepala mana yang dipakai berdasarkan gender saat ini
  List<String> get _currentHeads => _gender == 'male' ? _maleHeads : _femaleHeads;
  
  // Fungsi otomatis untuk mendapatkan alamat file gambar kepala yang sedang diklik/dipilih
  String get _currentHeadPath => _currentHeads[_selectedHead];
  
  // Fungsi otomatis untuk menentukan baju apa yang dipakai berdasarkan gender
  String get _currentBodyPath => _gender == 'male'
      ? 'lib/assets/Body1Set/default_skinboy.png'
      : 'lib/assets/Body1Set/default_skingirl.png';

  // --- FUNGSI MENYIMPAN KE INTERNET (FIREBASE) ---
  Future<void> _saveCharacter() async {
    setState(() => _isSaving = true); // Munculkan icon loading berputar
    try {
      // Ambil ID Unik (UID) dari user yang sedang login saat ini
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return; // Jika gagal (tidak login), batalkan operasi

      // Tetapkan ID baju dan kepala yang akan dikirim
      final bodyId = _gender == 'male' ? 'default_skinboy' : 'default_skingirl';
      final headId = _headIds[_gender]![_selectedHead];

      // Tembak data (Update) ke Firestore di koleksi 'users' -> dokumen milik user tersebut
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        UserSchema.gender: _gender,                 // Simpan jenis kelamin
        UserSchema.baseBody: bodyId,                // Simpan bentuk badan dasar
        UserSchema.defaultHead: headId,             // Simpan kepala dasar
        
        // Simpan perlengkapan (Equipped Items) yang SEKARANG sedang ia pakai
        '${UserSchema.equippedItems}.head': headId,
        '${UserSchema.equippedItems}.clothes': bodyId,
      });

      if (!mounted) return;
      
      // Jika berhasil, pindahkan user ke InteractiveTutorialScreen
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const InteractiveTutorialScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ));
    } catch (e) {
      if (!mounted) return;
      // Jika ada error internet, munculkan pesan di bawah (SnackBar) warna merah
      final l = context.l;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.charSaveFailed('$e'), style: TextStyle(color: AppColors.textPrimary)),
        backgroundColor: const Color(0xFFEF4444)));
      setState(() => _isSaving = false);
    }
  }

  // Pindah dari layar pilih gender ke layar pilih wajah
  void _goToHeadSelection() {
    setState(() { _step = 1; _selectedHead = 0; });
    // Reset dan mainkan ulang animasinya biar segar
    _fadeCtrl.reset(); _fadeCtrl.forward();
    _bounceCtrl.reset(); _bounceCtrl.forward();
  }

  // Kembali dari layar pilih wajah ke layar pilih gender
  void _goBackToGender() {
    setState(() => _step = 0);
    // Reset dan mainkan ulang animasinya
    _fadeCtrl.reset(); _fadeCtrl.forward();
    _bounceCtrl.reset(); _bounceCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.lw; // Kamus Bahasa (Localization)
    return Scaffold(
      body: Stack(children: [
        // Lapisan 1 Terbawah: Latar Belakang Gradasi Ungu
        Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFF4C1D95)],
        ))),
        
        // Lapisan 2: Gambar Hutan transparan di bagian paling bawah
        Positioned(bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.22,
          child: Image.asset('lib/assets/wallpaper/wallpaper hutan.png', fit: BoxFit.cover,
            color: AppColors.textPrimary.withValues(alpha: 0.55), colorBlendMode: BlendMode.darken,
            errorBuilder: (_, __, ___) => const SizedBox())),
            
        // Lapisan 3: Efek bayangan gradasi (Shadow) agar menyatu dengan hutan
        Positioned(bottom: 0, left: 0, right: 0, height: MediaQuery.of(context).size.height * 0.28,
          child: Container(decoration: const BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF4C1D95), Colors.transparent], stops: [0.0, 0.45])))),
            
        // Lapisan 4 Paling Atas: Konten (Tergantung nilai _step: 0 atau 1)
        SafeArea(child: _step == 0 ? _buildGenderStep(l) : _buildHeadStep(l)),
      ]),
    );
  }

  // ─── TAMPILAN HALAMAN 1 (LANGKAH 1): GENDER ─────────────
  Widget _buildGenderStep(L l) {
    return FadeTransition(opacity: _fadeAnim, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(children: [
        SizedBox(height: 48),
        Text(l.charCreateSubtitle, style: GoogleFonts.nunito(
          color: AppColors.textPrimary.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text(l.charSelectGender, style: GoogleFonts.nunito(
          color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
        SizedBox(height: 8),
        Text(l.charGenderHint, style: GoogleFonts.nunito(
          color: AppColors.textPrimary.withValues(alpha: 0.45), fontSize: 13)),
        Spacer(flex: 1), // Mendorong sisa layar ke bawah
        
        // Deretan Tombol Ikon (Pria & Wanita)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _genderIconCard('male', '♂', l.charMale, Color(0xFF60A5FA)),
          SizedBox(width: 24),
          _genderIconCard('female', '♀', l.charFemale, Color(0xFFF472B6)),
        ]),
        Spacer(flex: 2), // Mendorong sisa layar ke bawah
        
        // Tombol Lanjut (Pilih Gaya Kepala)
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          onPressed: _goToHeadSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4C2A85),
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text(l.charSelectHeadBtn, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 40),
      ]),
    ));
  }

  // Kotak yang berisi ikon laki/perempuan yang bisa diklik
  Widget _genderIconCard(String gender, String symbol, String label, Color accentColor) {
    // Mengecek apakah kotak ini yang sedang dipilih
    final isSelected = _gender == gender; 
    return GestureDetector(
      // Ketika diklik, perbarui memori dengan pilihan user lalu mainkan animasi membal
      onTap: () {
        setState(() { _gender = gender; _selectedHead = 0; });
        _bounceCtrl.reset(); _bounceCtrl.forward();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        width: 140, height: 160,
        // Jika terpilih, kotaknya menjadi sedikit terang sesuai warna gen (Biru/Pink)
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.18) : AppColors.textPrimary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.textPrimary.withValues(alpha: 0.15),
            width: isSelected ? 2.5 : 1,
          ),
          // Beri bayangan yang berpendar (glowing shadow) jika terpilih
          boxShadow: isSelected ? [BoxShadow(color: accentColor.withValues(alpha: 0.35), blurRadius: 20, spreadRadius: 1)] : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Animasi Scale (Membal) untuk Ikon teks ♂ atau ♀
          ScaleTransition(scale: _bounceAnim, child: Text(symbol,
            style: TextStyle(fontSize: 56, color: isSelected ? accentColor : AppColors.textPrimary.withValues(alpha: 0.5)))),
          SizedBox(height: 8),
          Text(label, style: GoogleFonts.nunito(
            color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.5),
            fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // ─── TAMPILAN HALAMAN 2 (LANGKAH 2): PILIH KEPALA ─────────────────────────
  Widget _buildHeadStep(L l) {
    return FadeTransition(opacity: _fadeAnim, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(children: [
        SizedBox(height: 20),
        // Tombol Kembali (Panah Kiri)
        Align(alignment: Alignment.centerLeft, child: GestureDetector(
          onTap: _goBackToGender,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.15))),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 18),
          ),
        )),
        SizedBox(height: 16),
        Text(l.charSelectStyle, style: GoogleFonts.nunito(
          color: AppColors.textPrimary.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text(l.charHead, style: GoogleFonts.nunito(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.w900)),
        SizedBox(height: 24),

        // --- PREVIEW KARAKTER LENGKAP (Ini rahasia menggabungkan gambarnya) ---
        ScaleTransition(scale: _bounceAnim, child: Container(
          width: 220, height: 260,
          decoration: BoxDecoration(
            color: Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.textPrimary.withValues(alpha: 0.15), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.3), blurRadius: 20)],
          ),
          // Memakai Stack untuk Menumpuk 4 lapis gambar
          child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Gambar Latar Hutan
              Image.asset('lib/assets/wallpaper/wallpaper hutan.png', fit: BoxFit.cover, width: 220, height: 260,
                color: AppColors.textPrimary.withValues(alpha: 0.35), colorBlendMode: BlendMode.darken,
                errorBuilder: (_, __, ___) => Container(color: Color(0xFF1E1E2E))),
                
              // 2. Gambar Tubuh Dasar Polos (Selalu dipanggil)
              Image.asset('lib/assets/Body1Set/body.png', width: 180, height: 210, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => SizedBox()),
                
              // 3. Gambar Baju Sesuai Pilihan Gender (Pria/Wanita)
              Image.asset(_currentBodyPath, width: 180, height: 210, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => SizedBox()),
                
              // 4. Gambar Kepala Sesuai Kepala yang diklik
              Image.asset(_currentHeadPath, width: 180, height: 210, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => SizedBox()),
            ],
          )),
        )),
        SizedBox(height: 28),

        Text(l.charHeadStyleSection, style: GoogleFonts.nunito(
          color: AppColors.textPrimary.withValues(alpha: 0.54), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        SizedBox(height: 12),

        // Dua Kotak Pilihan Gaya Kepala (Index 0 dan Index 1)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _headOption(0, l), SizedBox(width: 20), _headOption(1, l),
        ]),
        Spacer(),

        // Tombol Konfirmasi Selesai
        SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
          // Jika sedang _isSaving (menyimpan ke internet), matikan fungsi tombol ini (null) agar tidak diklik dua kali
          onPressed: _isSaving ? null : _saveCharacter,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4C2A85),
            disabledBackgroundColor: Color(0xFF4C2A85).withValues(alpha: 0.5),
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isSaving
            // Munculkan bulatan muter-muter loading jika sedang _isSaving
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2.5))
            : Text(l.charStartAdventure, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 40),
      ]),
    ));
  }

  // Komponen kotak untuk memilih kepala
  Widget _headOption(int index, L l) {
    final isSelected = _selectedHead == index;
    final headPath = _currentHeads[index];
    return GestureDetector(
      onTap: () {
        setState(() => _selectedHead = index);
        _bounceCtrl.reset(); _bounceCtrl.forward();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        width: 130, height: 160,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary.withValues(alpha: 0.12) : AppColors.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.15), blurRadius: 12)] : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Gambar mini (Thumbnail) karakter di dalam kotak
          SizedBox(width: 90, height: 100, child: Stack(alignment: Alignment.center, children: [
            Image.asset('lib/assets/Body1Set/body.png', width: 90, height: 100, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox()),
            Image.asset(_currentBodyPath, width: 90, height: 100, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox()),
            Image.asset(headPath, width: 90, height: 100, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.face, color: AppColors.textHint, size: 40)),
          ])),
          SizedBox(height: 6),
          Text(l.charStyleLabel(index + 1), style: GoogleFonts.nunito(
            color: isSelected ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.54),
            fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
