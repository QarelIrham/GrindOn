# --- CATATAN: File ini adalah robot asisten berbahasa Python ---
# --- Semua teks dengan tanda pagar (#) adalah penjelasan/komentar ---

import re

# 1. BUKA FILE: Membuka statistic_screen.dart
with open('lib/screens/statistic_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 2. MENGGANTI HEADER: Mengubah kotak header profil menjadi ThemeCard
old_header = """    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),"""

new_header = """    return ThemeCard(
      padding: const EdgeInsets.all(20),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.cardBorder,
      borderWidth: 1.5,"""

if old_header in code:
    code = code.replace(old_header, new_header)

# 3. MENGGANTI KARTU STATISTIK KECIL: (seperti XP, Gold, Level) menjadi ThemeCard
old_stat_card = """    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),"""

new_stat_card = """    return ThemeCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.cardBorder,
      borderWidth: 1.0,"""

if old_stat_card in code:
    code = code.replace(old_stat_card, new_stat_card)

# 4. MENGGANTI PAPAN PERINGKAT (LEADERBOARD): Mengubah Container utamanya menjadi ThemeCard
old_leaderboard = """    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),"""

new_leaderboard = """    return ThemeCard(
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.cardBorder,
      borderWidth: 1.5,"""

if old_leaderboard in code:
    code = code.replace(old_leaderboard, new_leaderboard)

# 5. SIMPAN KEMBALI
with open('lib/screens/statistic_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Selesai mengubah halaman Statistik menjadi tema komik!")
