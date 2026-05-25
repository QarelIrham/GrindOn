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
    # 1. Update AppColors to add textOnPrimary
    app_theme_path = r'c:\Users\qarel\SDK\daily_development\lib\theme\app_theme.dart'
    with open(app_theme_path, 'r', encoding='utf-8') as f:
        theme_content = f.read()

    if 'static Color textOnPrimary' not in theme_content:
        theme_content = theme_content.replace('static Color textPrimary = Colors.white;', 'static Color textPrimary = Colors.white;\n  static Color textOnPrimary = Colors.white;')
        
        # update dark mode
        theme_content = theme_content.replace('textPrimary = Colors.white;', 'textPrimary = Colors.white;\n    textOnPrimary = Colors.white;')
        
        # update light mode
        theme_content = theme_content.replace('textPrimary = const Color(0xFF1A1A2E);', 'textPrimary = const Color(0xFF1A1A2E);\n    textOnPrimary = Colors.white;')
        
        # update anime mode (pastel pink background -> dark text)
        theme_content = theme_content.replace('textPrimary = const Color(0xFF5D5D5D);', 'textPrimary = const Color(0xFF5D5D5D);\n    textOnPrimary = const Color(0xFF5D5D5D);')
        
        # update comic monochrome (black background -> white text)
        theme_content = theme_content.replace('textPrimary = Colors.black;', 'textPrimary = Colors.black;\n    textOnPrimary = Colors.white;')
        
        with open(app_theme_path, 'w', encoding='utf-8') as f:
            f.write(theme_content)
        print("Added textOnPrimary to app_theme.dart")

    # 2. Fix settings_sheet.dart
    process_file(r'c:\Users\qarel\SDK\daily_development\lib\widget\settings_sheet.dart', [
        (r'color: Color\(0xFF0D0D1A\)', r'color: AppColors.cardBackground'),
        (r'color: active \? AppColors\.textPrimary : AppColors\.textPrimary\.withValues\(alpha: 0\.54\)', r'color: active ? AppColors.textOnPrimary : AppColors.textPrimary.withValues(alpha: 0.54)')
    ])

    # 3. Fix custom_navbar.dart
    process_file(r'c:\Users\qarel\SDK\daily_development\lib\widget\custom_navbar.dart', [
        (r'canvas\.drawShadow\(path, AppColors\.textPrimary, 10, true\);', r'canvas.drawShadow(path, AppColors.textPrimary.withValues(alpha: 0.2), 10, true);'),
        (r'color: AppColors\.textPrimary,\s*size: 24,', r'color: AppColors.textOnPrimary,\n                size: 24,')
    ])

    # 4. Fix statistic_screen.dart
    process_file(r'c:\Users\qarel\SDK\daily_development\lib\screens\statistic_screen.dart', [
        (r'labelColor: AppColors\.textPrimary,', r'labelColor: AppColors.textOnPrimary,'),
        (r'icon: Icon\(Icons\.share_rounded, color: AppColors\.textPrimary, size: 18\),', r'icon: Icon(Icons.share_rounded, color: AppColors.textOnPrimary, size: 18),'),
        (r'color: AppColors\.textPrimary, fontWeight: FontWeight\.w800', r'color: AppColors.textOnPrimary, fontWeight: FontWeight.w800')
    ])

    # 5. Fix add_task_screen.dart
    process_file(r'c:\Users\qarel\SDK\daily_development\lib\screens\add_task_screen.dart', [
        (r'color: AppColors\.textPrimary,\s*strokeWidth: 2,', r'color: AppColors.textOnPrimary,\n                            strokeWidth: 2,'),
        (r'color: AppColors\.textPrimary,\s*fontSize: 15,', r'color: AppColors.textOnPrimary,\n                            fontSize: 15,')
    ])

if __name__ == '__main__':
    main()
