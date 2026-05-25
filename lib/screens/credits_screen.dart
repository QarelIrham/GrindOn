import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../widget/theme_card.dart';

// ── Halaman Kredit Rahasia (Hidden Credits Screen) ────────────────
// Menggabungkan gaya teks berjalan ala ending RPG klasik dengan kartu SSR.
class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _cardAnimController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;

  bool _showCard = false;
  bool _isScrolling = true;

  // Teks sejarah (Lore) yang diminta
  final String _loreText = """
"Oh, seorang petualang tersesat sampai ke ruang rahasia ini? 
Aku adalah xqvx The Creator, sang Grand Architect dunia ini..."

Ketahuilah, semesta ini tidak tercipta dalam semalam.
Ia dibangun dari ribuan baris mantra kode yang rumit, malam-malam tanpa tidur,
serta satu ambisi besar: mengubah rutinitas manusia yang membosankan
menjadi sebuah petualangan magis tanpa akhir.

Misi kita: Menghancurkan bayang-bayang kemalasan di dunia nyata.
Visi kita: Memastikan setiap langkah kecil yang kau ambil
bernilai XP untuk membentuk dirimu menjadi sosok yang epik.

Terima kasih telah melangkah masuk ke dalam *realm* ini.
Pintu gerbang telah terbuka, dan takdirmu kini ada di tanganmu sendiri.
Perjalananmu baru saja dimulai...
""";

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Animasi untuk memunculkan kartu SSR dan Peti Lisensi
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _cardScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.elasticOut),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardAnimController, curve: Curves.easeIn),
    );

    // Mulai scrolling teks setelah 1 detik
    Future.delayed(const Duration(seconds: 1), _startAutoScroll);
  }

  void _startAutoScroll() async {
    if (!mounted) return;
    // Asumsi teks butuh waktu 10 detik untuk scroll
    await _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 15),
      curve: Curves.linear,
    );
    
    // Setelah scroll selesai, tunggu 2 detik, lalu tampilkan kartu SSR
    if (mounted) {
      await Future.delayed(const Duration(seconds: 2));
      _showSSRCard();
    }
  }

  void _showSSRCard() {
    if (_showCard) return; // Mencegah pemanggilan ganda
    setState(() {
      _showCard = true;
      _isScrolling = false;
    });
    HapticFeedback.heavyImpact(); // Getaran saat kartu muncul
    _cardAnimController.forward(); // Jalankan animasi
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cardAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14), // Gelap, nuansa luar angkasa
      body: Stack(
        children: [
          // 1. Latar Belakang Bintang
          _buildStarryBackground(),
          
          // 2. Fase 1: Teks Berjalan
          if (!_showCard) _buildScrollingText(),

          // 3. Fase 2: Kartu SSR dan Lisensi
          if (_showCard) _buildSSRPhase(),

          // 4. Tombol Lewati (Skip) jika masih di tahap 1
          if (!_showCard)
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: _showSSRCard,
                child: Text(
                  'Skip',
                  style: GoogleFonts.nunito(
                    color: Colors.white54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
          // 5. Tombol Kembali
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bagian Latar Belakang (Kosmik/Bintang) ────────────────────
  Widget _buildStarryBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Color(0xFF1F1C36),
            Color(0xFF0D0D14),
          ],
        ),
      ),
      child: Stack(
        children: List.generate(30, (index) {
          final math.Random rnd = math.Random(index);
          return Positioned(
            left: rnd.nextDouble() * 400,
            top: rnd.nextDouble() * 800,
            child: Icon(
              Icons.star,
              size: rnd.nextDouble() * 3 + 1,
              color: Colors.white.withValues(alpha: rnd.nextDouble() * 0.5 + 0.1),
            ),
          );
        }),
      ),
    );
  }

  // ── Bagian Scroll Text ─────────────────────────────────────────
  Widget _buildScrollingText() {
    return Center(
      child: SizedBox(
        width: 320,
        height: 500,
        child: ListView(
          controller: _scrollController,
          physics: const NeverScrollableScrollPhysics(), // User tak bisa scroll manual
          children: [
            const SizedBox(height: 500), // Spacing agar teks muncul perlahan dari bawah
            Text(
              _loreText,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: const Color(0xFFE2E2E2),
                fontSize: 15,
                height: 2.0,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 500),
          ],
        ),
      ),
    );
  }

  // ── Bagian Fase SSR Card & Ancient Licenses ────────────────────
  Widget _buildSSRPhase() {
    return Center(
      child: FadeTransition(
        opacity: _cardOpacity,
        child: ScaleTransition(
          scale: _cardScale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCard(),
              const SizedBox(height: 40),
              
              // ── Tombol Ancient Licenses (Diperbagus) ──
              GestureDetector(
                onTap: () {
                  // Membuka halaman lisensi bawaan Flutter
                  showLicensePage(
                    context: context,
                    applicationName: 'RPG Task World',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Crafted with passion by The Creator.',
                  );
                },
                // ── Menggunakan ThemeCard untuk tombol peti lisensi ──
                child: ThemeCard(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: const Color(0xFF2B2516), // Cokelat gelap kayu
                  borderRadius: BorderRadius.circular(12),
                  borderColor: const Color(0xFFD4AF37).withValues(alpha: 0.5),
                  borderWidth: 2,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_rounded, color: Color(0xFFD4AF37), size: 24), // Ikon Peti
                      const SizedBox(width: 10),
                      Text(
                        'Ancient Licenses',
                        style: GoogleFonts.cinzel(
                          color: const Color(0xFFFDE68A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Pembuatan Kartu SSR Status Lucu ────────────────────────────
  Widget _buildCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE68A), Color(0xFFD4AF37), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header Kartu (Gelar SSR)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SSR',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFFDE68A),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (_) => const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 16)),
                  ),
                ],
              ),
            ),
            
            // Avatar The Creator
            // Avatar The Creator menggunakan ThemeCard
            ThemeCard(
              isCircle: true,
              borderColor: const Color(0xFFD4AF37),
              borderWidth: 3,
              child: Container(
                width: 120,
                height: 120,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFF3B2F5C), Color(0xFF140D26)],
                  ),
                ),
                child: const Center(
                  child: Text('🎭', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
            
            // Nama
            Text(
              'xqvx The Creator',
              style: GoogleFonts.cinzel(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Class
            Text(
              'Class: Code Paladin',
              style: GoogleFonts.nunito(
                color: const Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            
            // Bagian Status Lucu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F0F15),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildStatRow('☕ HP', 'Bergantung pada Kopi'),
                  const SizedBox(height: 8),
                  _buildStatRow('🐛 Bugs Slain', '10,000+'),
                  const SizedBox(height: 8),
                  _buildStatRow('⏳ Sleep Remaining', '1%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi utilitas membuat baris stat (Kiri Label, Kanan Value)
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: const Color(0xFFFDE68A),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
