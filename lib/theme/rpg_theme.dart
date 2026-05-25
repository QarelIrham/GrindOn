import 'package:flutter/material.dart';

// ── Tema Khusus RPG (RPG Theme) ──────────────────────────────────
// Menyimpan konstanta warna, ikon, dan deskripsi khusus untuk elemen-elemen RPG.
class RPGColors {
  static const Color background = Color(0xFF0D0D1A);
  static const Color card = Color(0xFF1A1A2E);
  static const Color cardBorder = Color(0xFF2D2D44);
  static const Color accent = Color(0xFF7C3AED);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Map<String, Color> catColors = {
    'Strength': Color(0xFFEF4444),
    'Defense': Color(0xFF8B5CF6),
    'Intelligence': Color(0xFF3B82F6),
    'Vitality': Color(0xFF10B981),
    'Agility': Color(0xFFF59E0B),
  };
}

class RPGIcons {
  static const Map<String, IconData> catIcons = {
    'Strength': Icons.fitness_center_rounded,
    'Defense': Icons.shield_rounded,
    'Intelligence': Icons.menu_book_rounded,
    'Vitality': Icons.favorite_rounded,
    'Agility': Icons.directions_run_rounded,
  };
}

class RPGDescriptions {
  static const Map<String, String> catDesc = {
    'Strength': 'Fisik & Olahraga',
    'Defense': 'Mental & Refleksi',
    'Intelligence': 'Belajar & Pengetahuan',
    'Vitality': 'Kesehatan & Tidur',
    'Agility': 'Kecepatan & Kegesitan',
  };
}
