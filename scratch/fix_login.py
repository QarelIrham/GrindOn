# --- CATATAN: File ini adalah robot asisten berbahasa Python ---
# --- Semua teks dengan tanda pagar (#) adalah penjelasan/komentar ---

import os
import re

def process_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    new_content = content
    for pattern, repl in replacements:
        new_content = re.sub(pattern, repl, new_content, flags=re.MULTILINE)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        print(f"No changes in {filepath}")

def main():
    # 6. Fix login_screen.dart
    process_file(r'c:\Users\qarel\SDK\daily_development\lib\screens\login_screen.dart', [
        (r'color: AppColors\.textPrimary, strokeWidth: 2', r'color: AppColors.textOnPrimary, strokeWidth: 2'),
        (r'color: AppColors\.textPrimary, fontSize: 16', r'color: AppColors.textOnPrimary, fontSize: 16'),
        (r'color: AppColors\.textPrimary, fontWeight: FontWeight\.w600', r'color: AppColors.textOnPrimary, fontWeight: FontWeight.w600'),
    ])

    # 7. Check register screen (if exists) and fix it
    if os.path.exists(r'c:\Users\qarel\SDK\daily_development\lib\screens\register_screen.dart'):
        process_file(r'c:\Users\qarel\SDK\daily_development\lib\screens\register_screen.dart', [
            (r'color: AppColors\.textPrimary, strokeWidth: 2', r'color: AppColors.textOnPrimary, strokeWidth: 2'),
            (r'color: AppColors\.textPrimary, fontSize: 16', r'color: AppColors.textOnPrimary, fontSize: 16'),
        ])

if __name__ == '__main__':
    main()
