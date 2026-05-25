# --- CATATAN: File ini adalah robot asisten berbahasa Python ---
# --- Semua teks dengan tanda pagar (#) adalah penjelasan/komentar ---

import re

# 1. PERBAIKI file rpg_tutorial_overlay.dart
# Pertama, kita buka file tersebut untuk dibaca ('r' artinya read)
with open('lib/widget/rpg_tutorial_overlay.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 2. Siapkan teks/kode yang BENAR (tanda kurungnya lengkap)
good_end = """          Positioned(
            bottom: 5,
            left: 5,
            child: Icon(
              Icons.star_rounded,
              color: _accent.withValues(alpha: 0.6),
              size: 8,
            ),
          ),
        ],
      ),
      ),
    );
  }"""

# 3. Siapkan teks/kode yang RUSAK (tanda kurungnya kurang)
bad_end = """          Positioned(
            bottom: 5,
            left: 5,
            child: Icon(
              Icons.star_rounded,
              color: _accent.withValues(alpha: 0.6),
          ),
        ],
      ),
      ),
    );
  }"""

# 4. Jika ada kode yang rusak di dalam file, ganti dengan yang benar
if bad_end in code:
    code = code.replace(bad_end, good_end)

# 5. Simpan kembali perubahannya ('w' artinya write/tulis)
with open('lib/widget/rpg_tutorial_overlay.dart', 'w', encoding='utf-8') as f:
    f.write(code)


# 6. PERBAIKI file credits_screen.dart dengan cara yang sama
with open('lib/screens/credits_screen.dart', 'r', encoding='utf-8') as f:
    code2 = f.read()

# Siapkan kode rusak (Center tidak ditutup dengan benar)
bad_credit = """                child: const Center(
                child: Text('🎭', style: TextStyle(fontSize: 64)),
              ),
            ),
            
            // Nama"""

# Siapkan kode yang benar
good_credit = """                child: const Center(
                  child: Text('🎭', style: TextStyle(fontSize: 64)),
                ),
              ),
            ),
            
            // Nama"""

# Ganti dan Simpan
if bad_credit in code2:
    code2 = code2.replace(bad_credit, good_credit)

with open('lib/screens/credits_screen.dart', 'w', encoding='utf-8') as f:
    f.write(code2)

print("Selesai memperbaiki semua syntax error!")
