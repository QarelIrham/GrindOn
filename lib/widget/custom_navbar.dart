import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/audio_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

// --- CUSTOM NAVBAR WIDGET ---
/// Ini adalah bilah navigasi bawah (Bottom Navigation Bar) buatan sendiri.
/// Kenapa tidak pakai bawaan Flutter? Karena bawaan Flutter kotak kaku.
/// Aplikasi ini butuh lekukan dinamis (Bezier Curve) di atas ikon yang sedang aktif.
class CustomNavbar extends StatefulWidget {
  // Menyimpan posisi tab mana yang sedang aktif (0: Home, 1: Daily, 2: Stats, 3: Profile)
  final int currentIndex;
  
  // Fungsi yang akan dijalankan ketika salah satu tab diklik
  final Function(int) onTap;
  
  final VoidCallback? onTaskAdded;
  
  // Fungsi yang akan dijalankan ketika tombol tambah (Add) di tengah diklik
  final VoidCallback? onAddPressed;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onTaskAdded,
    this.onAddPressed,
  });

  @override
  State<CustomNavbar> createState() => _CustomNavbarState();
}

// SingleTickerProviderStateMixin dibutuhkan agar animasi (seperti loncatan ikon) bisa selaras dengan FPS layar
class _CustomNavbarState extends State<CustomNavbar> with SingleTickerProviderStateMixin {
  // Mengontrol animasi saat user berpindah tab
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Durasi animasi transisi lekukan adalah 300 milidetik
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _ctrl.forward(); // Jalankan animasi
  }

  @override
  void didUpdateWidget(CustomNavbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jika tab aktif berubah, putar ulang animasinya dari awal
    if (oldWidget.currentIndex != widget.currentIndex) {
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    // Matikan controller agar RAM tidak bocor
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    // Membagi lebar layar menjadi 5 bagian sama rata (karena ada 4 tab + 1 tombol add di tengah)
    final double itemWidth = size.width / 5;
    final l = context.lw; // Kamus bahasa

    return Container(
      height: 85, // Tinggi navbar
      color: Colors.transparent, // Background transparan karena kita akan menggambar canvas kustom
      child: Stack(
        // clipBehavior.none membiarkan ikon yang melompat keluar dari batas 85px tidak terpotong
        clipBehavior: Clip.none,
        children: [
          
          // --- 1. MENGGAMBAR LATAR BELAKANG MELENGKUNG (CANVAS) ---
          CustomPaint(
            size: Size(size.width, 85),
            // _CurvedPainter adalah pelukisnya (kode ada di bagian paling bawah)
            painter: _CurvedPainter(
              selectedIndex: widget.currentIndex,
              itemWidth: itemWidth,
            ),
          ),

          // --- 2. LINGKARAN IKON AKTIF YANG MELAYANG ---
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOutBack, // Memberikan efek ayunan saat lingkaran berhenti bergeser
            // _getCircleLeft menghitung secara matematis di mana lingkaran ini harus mendarat
            left: _getCircleLeft(widget.currentIndex, itemWidth),
            top: -15, // Ditarik ke atas sedikit agar keluar dari navbar
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                // Warna gradient mengikuti tema dinamis (AppColors)
                gradient: LinearGradient(colors: AppColors.primaryGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                // Bayangan bersinar (glow) di bawah lingkaran
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _getIcon(widget.currentIndex), // Mengambil ikon mana yang harus tampil di dalam lingkaran
                color: AppColors.textOnPrimary, // Menggunakan warna khusus agar tidak tabrakan di tema Komik
                size: 24,
              ),
            ),
          ),

          // --- 3. DERETAN IKON & TEKS NAVBAR ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItem(0, Icons.home_rounded, l.navHome, itemWidth),
                _buildItem(1, Icons.check_circle_outline_rounded, l.navDaily, itemWidth),
                
                // TOMBOL TAMBAH (Add Button) - Sengaja ditaruh statis di tengah
                GestureDetector(
                  onTap: widget.onAddPressed,
                  child: SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Icon(Icons.add_box_rounded, color: AppColors.primary, size: 30),
                         SizedBox(height: 2),
                         Text(l.isEn ? 'Add' : 'Tambah', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),

                _buildItem(2, Icons.bar_chart_rounded, l.navStats, itemWidth),
                _buildItem(3, Icons.person_outline_rounded, l.navProfile, itemWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA KALKULASI POSISI LINGKARAN ---
  double _getCircleLeft(int index, double width) {
    // index 0 dan 1 normal. Tapi karena di tengah ada tombol Add,
    // maka index 2 dan 3 harus digeser posisinya meloncati posisi tombol Add.
    int pos = index < 2 ? index : index + 1;
    // Rumus matematika: (Posisi blok * lebar) + setengah lebar blok - setengah lebar lingkaran (25px)
    return (pos * width) + (width / 2) - 25;
  }

  // Mengembalikan ikon yang sesuai berdasarkan index yang aktif
  IconData _getIcon(int index) {
    switch (index) {
      case 0: return Icons.home_rounded;
      case 1: return Icons.check_circle_outline_rounded;
      case 2: return Icons.bar_chart_rounded;
      case 3: return Icons.person_rounded;
      default: return Icons.home_rounded;
    }
  }

  // Merender satu blok item (Ikon abu-abu dan teks di bawah)
  Widget _buildItem(int index, IconData icon, String label, double width) {
    final bool active = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        // HapticFeedback = Memberikan efek getaran HP saat ikon ditekan
        HapticFeedback.lightImpact();
        // Memutar efek suara klik dari AudioService
        AudioService.playClick();
        widget.onTap(index);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Jika status aktif, sembunyikan ikon abu-abu ini (karena sudah digantikan oleh lingkaran warna di atas)
            Opacity(
              opacity: active ? 0 : 1,
              child: Icon(icon, color: Colors.grey[500], size: 22),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.nunito(
                color: active ? AppColors.primary : Colors.grey[500],
                fontSize: 9,
                // Jika aktif ditebalkan, jika tidak biasa saja
                fontWeight: active ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PELUKIS KANVAS (CUSTOM PAINTER) - LOGIKA BEZIER CURVE
// ═══════════════════════════════════════════════════════════
class _CurvedPainter extends CustomPainter {
  final int selectedIndex;
  final double itemWidth;

  _CurvedPainter({required this.selectedIndex, required this.itemWidth});

  @override
  void paint(Canvas canvas, Size size) {
    // Mempersiapkan "Kuas" untuk mewarnai badan Navbar
    final paint = Paint()
      ..color = AppColors.cardBackground
      ..style = PaintingStyle.fill; // Diisi blok warna

    // Mempersiapkan Path (Jalur Menggambar)
    final path = Path();
    
    // Menghitung titik tengah dari tab yang sedang diklik
    int pos = selectedIndex < 2 ? selectedIndex : selectedIndex + 1;
    double centerX = (pos * itemWidth) + (itemWidth / 2);

    // Mulai menggambar dari kiri atas (titik Y diturunkan 20px)
    path.moveTo(0, 20); 
    
    // Tarik garis lurus sampai mendekati batas ikon yang diklik (dikurangi 45px)
    path.lineTo(centerX - 45, 20);
    
    // Ini kuncinya: MENGGAMBAR LENGKUNGAN MANGKUK (Cubic Bezier)
    // Parameter: (Titik Kontrol 1 X, Y), (Titik Kontrol 2 X, Y), (Titik Akhir X, Y)
    path.cubicTo(
      centerX - 25, 20, 
      centerX - 25, 55, // Turun sedalam 55px
      centerX, 55,      // Titik terdalam persis di tengah ikon
    );
    // Menggambar lengkungan naik kembali
    path.cubicTo(
      centerX + 25, 55, 
      centerX + 25, 20, 
      centerX + 45, 20,
    );

    // Lanjutkan garis lurus ke pojok kanan atas
    path.lineTo(size.width, 20); 
    // Tarik ke pojok kanan bawah
    path.lineTo(size.width, size.height); 
    // Tarik ke pojok kiri bawah
    path.lineTo(0, size.height); 
    // Tutup jalurnya kembali ke titik awal
    path.close();

    // Gambar bayangan navbar terlebih dahulu
    canvas.drawShadow(path, AppColors.textPrimary.withValues(alpha: 0.2), 10, true);
    // Gambar hasil jalur mangkuknya dengan kuas
    canvas.drawPath(path, paint);
    
    // --- MENGGAMBAR GARIS TEPI (BORDER) ---
    // Diperlukan khususnya untuk Tema Komik agar garis outline hitam/putih terlihat jelas
    final borderPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.1) // Jika mode komik, border diset manual di app_theme
      ..style = PaintingStyle.stroke // Hanya menggambar garis luar (stroke)
      ..strokeWidth = AppColors.borderWidth;
    
    final borderPath = Path();
    borderPath.moveTo(0, 20);
    borderPath.lineTo(centerX - 45, 20);
    borderPath.cubicTo(centerX - 25, 20, centerX - 25, 55, centerX, 55);
    borderPath.cubicTo(centerX + 25, 55, centerX + 25, 20, centerX + 45, 20);
    borderPath.lineTo(size.width, 20);
    
    // Terapkan kuas garis tepi ke kanvas
    canvas.drawPath(borderPath, borderPaint);
  }

  // Fungsi ini dipanggil terus-menerus oleh Flutter. 
  // Jika index berubah, beritahu Flutter untuk menggambar ulang mangkuknya.
  @override
  bool shouldRepaint(covariant _CurvedPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}
