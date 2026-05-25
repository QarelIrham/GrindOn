import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

// ── Theme Card Wrapper ─────────────────────────────────────────
// Komponen cerdas yang membungkus konten dengan border sesuai tema.
// Jika tema Comic Monochrome aktif, border akan digambar ala sketsa tangan (hatching).
// Jika tema lain, akan menggunakan BoxDecoration biasa.

class ThemeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const ThemeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.isCircle = false,
    this.borderWidth = 1.5,
    this.borderColor,
    this.backgroundColor,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    // Mengecek apakah kita sedang berada di tema Comic
    final themeType = Provider.of<ThemeService>(context, listen: true).currentThemeType;
    final bool isComic = themeType == AppThemeType.comicMonochrome;
    final Color actualBorderColor = borderColor ?? AppColors.cardBorder;
    final Color actualBgColor = backgroundColor ?? AppColors.cardBackground;
    final BorderRadius actualRadius = borderRadius ?? BorderRadius.circular(16);

    // Jika tema biasa, kembalikan Container ber-BoxDecoration standar
    if (!isComic) {
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: actualBgColor,
          gradient: gradient,
          borderRadius: isCircle ? null : actualRadius,
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          border: Border.all(color: actualBorderColor, width: borderWidth),
          boxShadow: boxShadow,
        ),
        child: child,
      );
    }

    // Jika tema Komik, kita gunakan CustomPainter untuk menggambar border sketsa
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: actualBgColor,
        gradient: gradient,
        borderRadius: isCircle ? null : actualRadius,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: boxShadow,
      ),
      child: CustomPaint(
        painter: ComicSketchPainter(
          color: actualBorderColor,
          strokeWidth: borderWidth,
          isCircle: isCircle,
          borderRadius: actualRadius,
        ),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

// ── Custom Painter untuk Garis Sketsa Komik (Hatching) ─────────
class ComicSketchPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isCircle;
  final BorderRadius borderRadius;

  ComicSketchPainter({
    required this.color,
    required this.strokeWidth,
    required this.isCircle,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path basePath = Path();

    // Membentuk path dasar (Lingkaran atau Kotak Melengkung)
    if (isCircle) {
      basePath.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      basePath.addRRect(
        borderRadius.toRRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    final Random random = Random(42); // Seed tetap agar garisnya tidak bergetar-getar tiap frame

    // Mengubah path utuh menjadi garis putus-putus dengan gaya acak (Hatching)
    final Path sketchPath = Path();
    for (final PathMetric metric in basePath.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        // Panjang garis acak (10 hingga 30) untuk memberi kesan goresan manual
        double dashLength = 10.0 + random.nextDouble() * 20.0;
        // Jarak antar garis acak (2 hingga 8) sebagai celah
        double dashSpace = 2.0 + random.nextDouble() * 6.0;

        // Kadang kita buat garis ekstra panjang
        if (random.nextDouble() > 0.8) {
          dashLength += 20.0;
        }

        // Ambil potongan garis dari path
        final double end = (distance + dashLength < metric.length) 
            ? distance + dashLength 
            : metric.length;
            
        sketchPath.addPath(metric.extractPath(distance, end), Offset.zero);
        
        distance += dashLength + dashSpace;
      }
    }

    // Gambar bayangan/tumpukan garis tipis kedua (efek sketsa kotor)
    final Paint shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = strokeWidth * 0.5
      ..style = PaintingStyle.stroke;

    canvas.save();
    // Geser sedikit dan rotasi sangat kecil untuk efek tumpukan tinta
    canvas.translate(1.0, 1.0);
    canvas.drawPath(sketchPath, shadowPaint);
    canvas.restore();

    // Gambar garis sketsa utama
    canvas.drawPath(sketchPath, paint);
    
    // Tambahkan garis-garis silang kecil (Hatching aksen) di sekitar sudut
    _drawCornerHatching(canvas, size, paint, random);
  }

  // Fungsi khusus untuk menggambar arsiran (hatching) di area sudut
  void _drawCornerHatching(Canvas canvas, Size size, Paint paint, Random random) {
    if (isCircle) return; // Tidak perlu hatching sudut untuk lingkaran

    final double hatchLength = 8.0;
    final Paint hatchPaint = Paint()
      ..color = paint.color
      ..strokeWidth = strokeWidth * 0.7
      ..style = PaintingStyle.stroke;

    void drawHatch(double x, double y, bool isVertical) {
      if (random.nextDouble() > 0.3) { // 70% peluang digambar
        final double offset = random.nextDouble() * 4 - 2;
        if (isVertical) {
          canvas.drawLine(Offset(x + offset, y - hatchLength/2), Offset(x + offset, y + hatchLength/2), hatchPaint);
        } else {
          canvas.drawLine(Offset(x - hatchLength/2, y + offset), Offset(x + hatchLength/2, y + offset), hatchPaint);
        }
      }
    }

    // Sudut Kiri Atas
    drawHatch(10, 0, true);
    drawHatch(0, 10, false);
    
    // Sudut Kanan Atas
    drawHatch(size.width - 10, 0, true);
    drawHatch(size.width, 10, false);
    
    // Sudut Kiri Bawah
    drawHatch(10, size.height, true);
    drawHatch(0, size.height - 10, false);
    
    // Sudut Kanan Bawah
    drawHatch(size.width - 10, size.height, true);
    drawHatch(size.width, size.height - 10, false);
  }

  @override
  bool shouldRepaint(covariant ComicSketchPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.isCircle != isCircle ||
           oldDelegate.borderRadius != borderRadius;
  }
}
