import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/avatar_data.dart';

// --- MESIN RENDER AVATAR (AVATAR PREVIEW) ---
/// Widget ini berfungsi menyatukan gambar-gambar terpisah (background, badan, baju, celana, kepala, dan pet)
/// menjadi satu kesatuan utuh karakter 2D.
/// Data baju apa yang dipakai dikirim melalui `equippedItems`.
class AvatarPreview extends StatelessWidget {
  // Map yang berisi ID barang yang sedang dipakai. Contoh: {'head': 'head_samurai', 'clothes': 'armor_knight'}
  final Map<String, String> equippedItems;
  
  // Ukuran kotak render avatar (default 140x140 pixel)
  final double size;
  
  // Apakah mau menampilkan background hutan/kastil di belakangnya?
  final bool showBackground;
  
  // Baju dasar bawaan (contoh: cowok/cewek) jika user belum pakai armor
  final String? baseBody; 

  const AvatarPreview({
    super.key,
    required this.equippedItems,
    this.size = 140,
    this.showBackground = true,
    this.baseBody,
  });

  // Fungsi Kamus: Mengubah ID (teks pendek dari Firestore) menjadi alamat path file PNG sungguhan.
  String _getAssetPath(String category, String id) {
    if (id.isEmpty || id == 'none' || id == 'default' || id.startsWith('none_')) return '';
    try {
      final item = AvatarData.allItems.firstWhere((e) => e.id == id);
      return item.imagePath ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Persiapan pengambilan path gambar untuk masing-masing tipe
    final bgPath = _getAssetPath('background', equippedItems['background'] ?? 'default');
    final headPath = _getAssetPath('head', equippedItems['head'] ?? 'none');
    final clothesPath = _getAssetPath('clothes', equippedItems['clothes'] ?? 'none');
    final pantsPath = _getAssetPath('pants', equippedItems['pants'] ?? 'none');
    final petPath = _getAssetPath('pet', equippedItems['pet'] ?? 'none');

    return Container(
      width: size,
      height: size,
      // clipBehavior antiAlias memastikan gambar yang melewati batas kotak bundar dipotong dengan rapi
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // Jika tidak ada background wallpaper, sesuaikan dengan tema aktif
        color: showBackground && bgPath.isEmpty ? AppColors.textPrimary.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(size * 0.15),
        border: showBackground
            ? Border.all(color: AppColors.cardBorder, width: AppColors.borderWidth)
            : null,
      ),
      // --- INI RAHASIANYA (STACK Z-INDEX) ---
      // Stack adalah widget yang memungkinkan kita menumpuk berlapis-lapis gambar
      // Yang dipanggil duluan akan berada di posisi paling bawah
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lapis 1 (Terbawah): Wallpaper Background
          if (showBackground && bgPath.isNotEmpty)
            Positioned.fill(
              child: Image.asset(
                bgPath,
                fit: BoxFit.cover,
                // Menggelapkan wallpaper sedikit agar karakternya lebih menonjol
                color: AppColors.textPrimary.withValues(alpha: 0.4),
                colorBlendMode: BlendMode.darken,
              ),
            ),

          // Lapis 2: Tubuh Dasar (Selalu body.png)
          // File png ini berisi bentuk siluet badan polos yang harus selalu ada
          Image.asset(
            'lib/assets/Body1Set/body.png',
            width: size * 0.9,
            height: size * 0.9,
            fit: BoxFit.contain, // Contain memastikan gambarnya tidak penyok
            // Jika gambarnya tidak sengaja terhapus, render kotak kosong saja agar tidak error
            errorBuilder: (context, error, stackTrace) => const SizedBox(),
          ),

          // Lapis 3, 4, 5: Celana, Baju, Wajah
          // Celana dipanggil dulu agar pinggangnya tertutup oleh baju jika bajunya panjang.
          // Kepala dipanggil terakhir agar rambutnya/helmnya menutupi kerah baju.
          if (pantsPath.isNotEmpty) _buildLayer(pantsPath, size * 0.9),
          if (clothesPath.isNotEmpty) _buildLayer(clothesPath, size * 0.9),
          if (headPath.isNotEmpty) _buildLayer(headPath, size * 0.9),

          // Lapis 6 (Teratas): Peliharaan (Pet)
          // Pet menggunakan skala yang sama karena filenya (seperti armadillo_spebles.png)
          // sudah diatur posisi X dan Y aslinya agar berada di sebelah karakter.
          if (petPath.isNotEmpty) _buildLayer(petPath, size * 0.9),
        ],
      ),
    );
  }

  // Fungsi pembantu untuk memanggil widget Image
  Widget _buildLayer(String path, double layerSize) {
    return Image.asset(
      path,
      width: layerSize,
      height: layerSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox(),
    );
  }
}
