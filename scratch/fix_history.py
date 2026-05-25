# --- CATATAN: File ini adalah robot asisten berbahasa Python ---
# --- Semua teks dengan tanda pagar (#) adalah penjelasan/komentar ---

import re

# 1. BUKA FILE: Membuka history_screen.dart
with open('lib/screens/history_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 2. MENGGANTI KARTU RIWAYAT: Mengubah Container biasa menjadi ThemeCard
old_card = """    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncome ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
        ),
      ),"""

new_card = """    return ThemeCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(16),
      borderColor: isIncome ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3),
      borderWidth: 1.0,"""

if old_card in code:
    code = code.replace(old_card, new_card)

# 3. SIMPAN KEMBALI
with open('lib/screens/history_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Selesai mengubah halaman Riwayat menjadi tema komik!")
