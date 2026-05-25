# --- CATATAN: File ini adalah robot asisten berbahasa Python ---
# --- Semua teks dengan tanda pagar (#) adalah penjelasan/komentar ---

import re

# 1. BUKA FILE: Robot akan membuka file daily_screen.dart
with open('lib/screens/daily_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 2. GANTI KOTAK STATISTIK USER: Mengubah Container biasa menjadi ThemeCard
old_container = """    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column("""

new_container = """    return ThemeCard(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(20),
      borderColor: AppColors.cardBorder,
      borderWidth: 1.5,
      child: Column("""

if old_container in code:
    code = code.replace(old_container, new_container)

# 3. GANTI BINGKAI AVATAR: Mengubah Container Avatar menjadi ThemeCard
old_avatar = """              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: AppColors.borderWidth * 2),
                  boxShadow: [
                    BoxShadow(
                      color: isSSR ? glowColor : AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: isSSR ? 12 : 8,
                      spreadRadius: isSSR ? 2 : 0,
                    ),
                  ],
                ),
                child: AvatarPreview("""

new_avatar = """              SizedBox(
                width: 64,
                height: 64,
                child: ThemeCard(
                  backgroundColor: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  borderColor: AppColors.primary,
                  borderWidth: AppColors.borderWidth * 2,
                  boxShadow: [
                    BoxShadow(
                      color: isSSR ? glowColor : AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: isSSR ? 12 : 8,
                      spreadRadius: isSSR ? 2 : 0,
                    ),
                  ],
                  child: AvatarPreview("""

if old_avatar in code:
    code = code.replace(old_avatar, new_avatar)
    
    # Perbaiki tanda kurung tutup karena kita menambahkan SizedBox
    old_avatar_end = """                  baseBody: _baseBody,
                ),
              ),
              SizedBox(width: 12),"""
    new_avatar_end = """                  baseBody: _baseBody,
                ),
              ),
              ),
              SizedBox(width: 12),"""
              
    code = code.replace(old_avatar_end, new_avatar_end)

# 4. SIMPAN PERUBAHAN
with open('lib/screens/daily_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("Selesai mengubah header Daily Screen menjadi tema komik!")
