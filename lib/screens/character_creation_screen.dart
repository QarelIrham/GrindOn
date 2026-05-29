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
        // Latar Belakang Wallpaper RPG
        Positioned.fill(
          child: Image.asset(
            'lib/assets/wallpaper/wallpaper_celestial.png',
            fit: BoxFit.cover,
          ),
        ),
        // Overlay Gelap agar teks terbaca
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.75),
          ),
        ),
        
        // Lapisan Paling Atas: Konten (Tergantung nilai _step: 0 atau 1)
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
        Text(l.charCreateSubtitle.toUpperCase(), style: GoogleFonts.nunito(
          color: const Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5,
          shadows: [const Shadow(color: Colors.black, blurRadius: 4)])),
        SizedBox(height: 6),
        Text(l.charSelectGender, style: GoogleFonts.nunito(
          color: const Color(0xFFF3E5F5), fontSize: 32, fontWeight: FontWeight.w900,
          shadows: [
            const Shadow(color: Color(0xFF673AB7), blurRadius: 15),
            const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
          ])),
        SizedBox(height: 8),
        Text(l.charGenderHint, style: GoogleFonts.nunito(
          color: const Color(0xFFD7CCC8), fontSize: 14, fontWeight: FontWeight.bold,
          shadows: [const Shadow(color: Colors.black, blurRadius: 2)])),
        Spacer(flex: 1), // Mendorong sisa layar ke bawah
        
        // Deretan Tombol Ikon (Pria & Wanita)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _genderIconCard('male', '♂', l.charMale, Color(0xFF60A5FA)),
          SizedBox(width: 24),
          _genderIconCard('female', '♀', l.charFemale, Color(0xFFF472B6)),
        ]),
        Spacer(flex: 2), // Mendorong sisa layar ke bawah
        
        // Tombol Lanjut (Pilih Gaya Kepala)
        GestureDetector(
          onTap: _goToHeadSelection,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFFD500F9), Color(0xFF6A1B9A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: const Color(0xFF311B92), width: 3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFD500F9).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Text(
                l.charSelectHeadBtn,
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
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
        Text(l.charSelectStyle.toUpperCase(), style: GoogleFonts.nunito(
          color: const Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5,
          shadows: [const Shadow(color: Colors.black, blurRadius: 4)])),
        SizedBox(height: 4),
        Text(l.charHead, style: GoogleFonts.nunito(
          color: const Color(0xFFF3E5F5), fontSize: 32, fontWeight: FontWeight.w900,
          shadows: [
            const Shadow(color: Color(0xFF673AB7), blurRadius: 15),
            const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
          ])),
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
        GestureDetector(
          onTap: _isSaving ? null : _saveCharacter,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: _isSaving 
                  ? [const Color(0xFF4A148C), const Color(0xFF311B92)]
                  : [const Color(0xFFD500F9), const Color(0xFF6A1B9A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(color: const Color(0xFF311B92), width: 3),
              boxShadow: [
                if (!_isSaving) BoxShadow(color: const Color(0xFFD500F9).withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(
                    l.charStartAdventure,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
            ),
          ),
        ),
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
