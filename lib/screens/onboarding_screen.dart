import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:daily_development/screens/character_creation_screen.dart';
import '../services/locale_service.dart';
import '../l10n/app_locale.dart';
import '../theme/app_theme.dart';

// Widget utama untuk Onboarding (Perkenalan Aplikasi)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Controller untuk menggeser halaman ke kiri dan kanan (slider)
  final PageController _pageCtrl = PageController();
  
  // Variabel untuk menyimpan halaman ke berapa kita sekarang (0, 1, atau 2)
  int _currentPage = 0;

  // Controller animasi untuk efek naik-turun (melayang) pada gambar
  late AnimationController _floatCtrl;
  
  // Controller animasi untuk efek muncul secara perlahan (fade in) teks
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    // Mengatur animasi melayang berdurasi 3 detik, dan diulang terus (repeat reverse)
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Mengatur animasi memudar berdurasi 800 milidetik, dijalankan sekali ke depan (forward)
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    // Mematikan controller saat layar ditutup agar tidak terjadi kebocoran memori (Memory Leak)
    _pageCtrl.dispose();
    _floatCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  // Fungsi yang dipanggil ketika user menekan tombol "Skip" atau "Mulai Petualangan"
  Future<void> _finishOnboarding() async {
    // Menyimpan data ke memori lokal HP bahwa user sudah melihat onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    
    if (!mounted) return;
    
    // Pindah ke layar Pembuatan Karakter dengan efek memudar (FadeTransition)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CharacterCreationScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  // Fungsi untuk menggeser ke halaman selanjutnya jika tombol di bawah ditekan
  void _nextPage() {
    if (_currentPage < 2) {
      // Geser halaman dengan animasi melengkung (easeOutCubic)
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic);
    } else {
      // Jika sudah di halaman terakhir (halaman ke-3), akhiri onboarding
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil bahasa saat ini (Indonesia/Inggris)
    final l = context.lw;
    
    return Scaffold(
      backgroundColor: Color(0xFF0F172A), // Warna dasar paling belakang
      body: Stack(
        children: [
          // Lapis 1: Latar belakang warna yang bisa berubah-ubah perlahan (AnimatedContainer)
          Positioned.fill(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 700), // Kecepatan transisi warna
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // Mengambil susunan warna sesuai halaman saat ini
                  colors: _getBackgroundColors(),
                ),
              ),
            ),
          ),
          
          // Lapis 2: Cahaya bulat (Orb) buatan dari kode matematika yang ditaruh di pojok
          Positioned(
            top: -100,
            left: -100,
            child: _buildGlowOrb(Color(0xFF8B5CF6), 300),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: _buildGlowOrb(Color(0xFF3B82F6), 400),
          ),

          // Lapis 3: Konten Utama yang aman dari poni layar HP (SafeArea)
          SafeArea(
            child: Column(
              children: [
                // --- BAGIAN ATAS: LOGO DAN TOMBOL SKIP ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield, color: AppColors.textSecondary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Daily Dev',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      // Tombol loncat (Skip)
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textPrimary.withValues(alpha: 0.60),
                        ),
                        child: Text(
                          l.btnSkip,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- BAGIAN TENGAH: ISI HALAMAN (SLIDER) ---
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (i) {
                      // Saat halaman digeser, perbarui nomor halaman dan reset animasi teks
                      setState(() => _currentPage = i);
                      _fadeCtrl.reset();
                      _fadeCtrl.forward();
                    },
                    children: [
                      // Memanggil kerangka halaman 1, 2, dan 3
                      _buildPage1(l),
                      _buildPage2(l),
                      _buildPage3(l),
                    ],
                  ),
                ),

                // --- BAGIAN BAWAH: INDIKATOR TITIK & TOMBOL LANJUT ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Mencetak 3 titik indikator secara otomatis
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) => _buildIndicator(index)),
                      ),
                      SizedBox(height: 32),
                      
                      // Tombol Lanjut berbentuk Kotak Bergradasi
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            // Efek bayangan di bawah tombol
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF6366F1).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            // Cek jika halaman ke-3, teksnya beda
                            child: Text(
                              _currentPage == 2 
                                ? (l.isEn ? 'Start Adventure' : 'Mulai Petualangan')
                                : (l.isEn ? 'Continue' : 'Lanjutkan'),
                              style: GoogleFonts.nunito(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mengatur warna gradien latar berdasarkan halaman
  List<Color> _getBackgroundColors() {
    switch (_currentPage) {
      case 0:
        return [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]; // Ungu Gelap -> Navy
      case 1:
        return [const Color(0xFF064E3B), const Color(0xFF0F172A)]; // Hijau Gelap -> Navy
      case 2:
        return [const Color(0xFF7F1D1D), const Color(0xFF0F172A)]; // Merah Gelap -> Navy
      default:
        return [const Color(0xFF1E1B4B), const Color(0xFF0F172A)];
    }
  }

  // Fungsi membuat efek cahaya buatan
  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Ini kuncinya: Radial Gradient memudarkan warna dari tengah (30%) ke pinggir (0%)
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  // Fungsi membuat titik-titik (indikator halaman)
  Widget _buildIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      // Jika aktif titiknya memanjang (24), jika tidak, titik bulat (8)
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [BoxShadow(color: AppColors.textPrimary.withValues(alpha: 0.5), blurRadius: 8)]
            : null,
      ),
    );
  }

  // --- HALAMAN 1 ---
  Widget _buildPage1(L l) {
    return _PageLayout(
      title: l.isEn ? 'Turn Life Into\nRPG Game' : 'Ubah Hidup Jadi\nGame RPG',
      subtitle: l.isEn ? 'Start Your Adventure' : 'Mulai Petualangan',
      description: l.isEn 
        ? 'Complete your daily habits like quests in a fantasy world. Boost productivity in a fun way.'
        : 'Selesaikan kebiasaan harianmu layaknya quest di dunia fantasy. Tingkatkan produktivitas dengan cara yang menyenangkan.',
      fadeAnim: _fadeCtrl,
      visual: Stack(
        alignment: Alignment.center,
        children: [
          _buildGlowOrb(const Color(0xFF8B5CF6), 250),
          // Menggunakan Stack untuk menumpuk 3 karakter
          SizedBox(
            height: 180,
            width: 320,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Cowok (Kiri) memanggil animasi melayang
                Positioned(
                  left: 20,
                  bottom: 0,
                  child: _buildFloatingChar('lib/assets/Body1Set/default_skinboy.png', 'lib/assets/Head/head_default_login_male1.png', 110, 0.5),
                ),
                // Cewek (Kanan) memanggil animasi melayang
                Positioned(
                  right: 20,
                  bottom: 0,
                  child: _buildFloatingChar('lib/assets/Body1Set/default_skingirl.png', 'lib/assets/Head/head_default_login_female1.png', 110, 1.0),
                ),
                // Hero Knight (Tengah Depan) memanggil animasi melayang
                Positioned(
                  bottom: 0,
                  child: _buildFloatingChar('lib/assets/armor/armor_knight.png', 'lib/assets/Head/head_knight.png', 170, 0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HALAMAN 2 ---
  Widget _buildPage2(L l) {
    return _PageLayout(
      title: l.isEn ? 'Collect Epic\nRewards' : 'Kumpulkan Hadiah\nEpik',
      subtitle: l.isEn ? 'Customize Character' : 'Kustomisasi Karakter',
      description: l.isEn
        ? 'Earn coins from every completed task. Buy equipment, pets, and change your appearance as you like.'
        : 'Dapatkan koin dari setiap tugas yang selesai. Beli equipment, peliharaan, dan ubah penampilan sesukamu.',
      fadeAnim: _fadeCtrl,
      visual: Stack(
        alignment: Alignment.center,
        children: [
          _buildGlowOrb(const Color(0xFF10B981), 250),
          SizedBox(
            height: 240,
            width: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Item Armor Tengah
                AnimatedBuilder(
                  animation: _floatCtrl,
                  builder: (_, child) {
                    // Matematika Sinus untuk naik-turun (Y axis)
                    return Transform.translate(
                      offset: Offset(0, math.sin(_floatCtrl.value * 2 * math.pi) * 8),
                      child: child,
                    );
                  },
                  child: _buildItemCard('lib/assets/armor/armor_red_mage.png', size: 100, isMythic: true),
                ),
                // Pet Kiri
                Positioned(
                  left: 40,
                  bottom: 30,
                  child: AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) {
                      return Transform.translate(
                        offset: Offset(0, math.cos(_floatCtrl.value * 2 * math.pi) * 6),
                        child: child,
                      );
                    },
                    child: _buildItemCard('lib/assets/pet/raven.png', size: 70),
                  ),
                ),
                // Head Kanan
                Positioned(
                  right: 40,
                  top: 30,
                  child: AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) {
                      return Transform.translate(
                        offset: Offset(0, math.sin((_floatCtrl.value + 0.5) * 2 * math.pi) * 10),
                        child: child,
                      );
                    },
                    child: _buildItemCard('lib/assets/Head/head_valkyrie.png', size: 80),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HALAMAN 3 ---
  Widget _buildPage3(L l) {
    return _PageLayout(
      title: l.isEn ? 'Defeat Laziness\nMonsters' : 'Taklukkan Monster\nKemalasan',
      subtitle: l.isEn ? 'Level Up' : 'Naikkan Levelmu',
      description: l.isEn
        ? 'Don\'t let tasks pile up! Defeat monsters by completing tasks and reach the highest rank.'
        : 'Jangan biarkan tugas menumpuk! Kalahkan monster dengan menyelesaikan tugas dan capai rank tertinggi.',
      fadeAnim: _fadeCtrl,
      visual: Stack(
        alignment: Alignment.center,
        children: [
          _buildGlowOrb(const Color(0xFFEF4444), 250),
          SizedBox(
            height: 260,
            width: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Monster Naga
                Positioned(
                  top: 0,
                  child: AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) {
                      return Transform.translate(
                        offset: Offset(0, math.sin(_floatCtrl.value * 2 * math.pi) * 5),
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'lib/assets/pet/obsidian_drake.png',
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_,__,___) => const SizedBox(),
                    ),
                  ),
                ),
                // Karakter Samurai (Kiri)
                Positioned(
                  bottom: 20,
                  left: 40,
                  child: _buildFloatingChar('lib/assets/Body1Set/skin_blue_flare.png', 'lib/assets/Head/head_samurai.png', 110, 0.2),
                ),
                // Karakter Demon (Kanan)
                Positioned(
                  bottom: 0,
                  right: 40,
                  child: _buildFloatingChar('lib/assets/Body1Set/skin_void.png', 'lib/assets/Head/head_demon.png', 120, 0.8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN BANTUAN ---
  // Membungkus sebuah karakter dengan algoritma melayang
  Widget _buildFloatingChar(String clothes, String head, double size, double offsetTime) {
    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) {
        // offsetTime bikin animasinya nggak gerak barengan semua (memberi jeda)
        return Transform.translate(
          offset: Offset(0, math.sin((_floatCtrl.value + offsetTime) * 2 * math.pi) * 8),
          child: child,
        );
      },
      child: _charStack(clothes, head, size),
    );
  }

  // Menggabungkan Body, Baju, dan Kepala menjadi satu karakter via Stack
  Widget _charStack(String clothesPath, String headPath, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Badan Dasar
          Image.asset('lib/assets/Body1Set/body.png', width: size, height: size, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.person, color: AppColors.textHint, size: size * 0.5)),
          // Baju
          Image.asset(clothesPath, width: size, height: size, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox()),
          // Kepala
          Image.asset(headPath, width: size, height: size, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox()),
        ],
      ),
    );
  }

  // Membuat bentuk kotak barang (Item Card) untuk halaman 2
  Widget _buildItemCard(String path, {required double size, bool isMythic = false}) {
    return Container(
      width: size + 30,
      height: size + 30,
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMythic ? Colors.amber.withValues(alpha: 0.7) : AppColors.textPrimary.withValues(alpha: 0.2),
          width: isMythic ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Center(
          child: Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_,__,___) => const SizedBox(),
          ),
        ),
      ),
    );
  }
}

// Kerangka standar untuk merender Judul, Subjudul, dan Deskripsi secara konsisten
class _PageLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final Widget visual;
  final Animation<double> fadeAnim; // Animasi pudarnya tulisan

  const _PageLayout({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.visual,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Spacer(flex: 2),
          // --- BAGIAN GAMBAR ---
          FadeTransition(
            opacity: fadeAnim,
            child: SizedBox(
              height: 280,
              child: visual,
            ),
          ),
          SizedBox(height: 40),
          
          // --- BAGIAN TEKS ---
          FadeTransition(
            opacity: fadeAnim,
            child: Column(
              children: [
                // Subjudul (Warna Ungu)
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Color(0xFFA78BFA),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 12),
                // Judul Besar
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 20),
                // Deskripsi Kecil
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
