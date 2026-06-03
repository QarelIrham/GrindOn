import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:daily_development/screens/login_screen.dart';
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    
    if (!mounted) return;
    
    // Setelah onboarding selesai, arahkan ke halaman Login/Register
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
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
          // Lapis 1: Latar belakang wallpaper RPG
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: SizedBox.expand(
                key: ValueKey<int>(_currentPage),
                child: Image.asset(
                  _getBackgroundImage(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Overlay gelap agar teks terbaca
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
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
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0F0C1B),
                              border: Border.all(color: const Color(0xFF7E57C2), width: 1.5),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF673AB7).withValues(alpha: 0.5), blurRadius: 8),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset('lib/assets/logo/Logo_GrindOn.png', fit: BoxFit.contain),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'GrindOn',
                            style: GoogleFonts.nunito(
                              color: const Color(0xFFE1BEE7),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              fontSize: 18,
                              shadows: [
                                const Shadow(color: Color(0xFF673AB7), blurRadius: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Tombol loncat (Skip)
                      TextButton(
                        onPressed: _finishOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.4),
                        ),
                        child: Text(
                          l.btnSkip,
                          style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
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
                            // Cek jika halaman ke-3, teksnya beda
                            child: Text(
                              _currentPage == 2 
                                ? (l.isEn ? 'Start Adventure' : 'Mulai Petualangan')
                                : (l.isEn ? 'Continue' : 'Lanjutkan'),
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

  // Fungsi untuk mengatur wallpaper latar berdasarkan halaman
  String _getBackgroundImage() {
    switch (_currentPage) {
      case 0:
        return 'lib/assets/wallpaper/wallpaper hutan.png';
      case 1:
        return 'lib/assets/wallpaper/wallpaper_towerdragon.png';
      case 2:
        return 'lib/assets/wallpaper/wallpaper castle dark.png';
      default:
        return 'lib/assets/wallpaper/wallpaper hutan.png';
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
      title: l.isEn ? 'Turn Daily Life\nInto an RPG' : 'Ubah Keseharian\nMenjadi RPG',
      subtitle: l.isEn ? 'Begin the Adventure' : 'Mulai Petualangan',
      description: l.isEn 
        ? 'Make every daily task an epic quest. Here, every productivity you achieve is a step to strengthen your character.'
        : 'Jadikan setiap tugas harianmu sebagai quest epik. Di sini, setiap produktivitas yang kamu lakukan adalah langkah untuk memperkuat karaktermu.',
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
      title: l.isEn ? 'Claim Epic\nLoot & Rewards' : 'Raih Loot &\nHadiah Epik',
      subtitle: l.isEn ? 'Legendary Equipment' : 'Kustomisasi Karakter',
      description: l.isEn
        ? 'Gather gold from your successes. Exchange it for legendary equipment, pets, and customize your character to your heart\'s content.'
        : 'Kumpulkan gold dari setiap keberhasilanmu. Tukarkan dengan equipment legendaris, peliharaan, dan kustomisasi karakter sesuka hatimu.',
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
      title: l.isEn ? 'Conquer the\nLaziness Monster' : 'Taklukkan Monster\nKemalasan',
      subtitle: l.isEn ? 'Defeat the Boss' : 'Kalahkan Bos',
      description: l.isEn
        ? 'Don\'t let tasks pile up or the monster will attack you! Complete your missions, defeat the laziness boss, and achieve the highest rank.'
        : 'Jangan biarkan tugas terbengkalai atau monster akan menyerangmu! Selesaikan misimu, kalahkan bos kemalasan, dan raih peringkat tertinggi.',
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
        color: const Color(0xFF0F0C1B), // Dark stone
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMythic ? const Color(0xFFFFD700) : const Color(0xFF311B92),
          width: isMythic ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isMythic ? const Color(0xFFFFD700).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.7),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          if (isMythic)
            BoxShadow(color: const Color(0xFFFFD700).withValues(alpha: 0.2), blurRadius: 30, spreadRadius: -5),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF7E57C2).withValues(alpha: 0.3), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
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
                // Subjudul (Warna Emas)
                Text(
                  subtitle.toUpperCase(),
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFFFD700), // Emas
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    shadows: [const Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
                SizedBox(height: 12),
                // Judul Besar
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFF3E5F5),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    shadows: [
                      const Shadow(color: Color(0xFF673AB7), blurRadius: 15),
                      const Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // Deskripsi Kecil
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFD7CCC8),
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    shadows: [const Shadow(color: Colors.black, blurRadius: 2)],
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
