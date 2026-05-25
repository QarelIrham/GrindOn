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
    # 1. Update app_theme.dart Anime text colors
    app_theme_path = r'c:\Users\qarel\SDK\daily_development\lib\theme\app_theme.dart'
    process_file(app_theme_path, [
        (r'textPrimary = const Color\(0xFF5D5D5D\);', r'textPrimary = const Color(0xFF2D2D2D);'),
        (r'textOnPrimary = const Color\(0xFF5D5D5D\);', r'textOnPrimary = const Color(0xFF2D2D2D);'),
        (r'textSecondary = const Color\(0xFF8E8E8E\);', r'textSecondary = const Color(0xFF555555);'),
        (r'textHint = const Color\(0xFFBDBDBD\);', r'textHint = const Color(0xFF888888);'),
    ])

    # 2. Fix history_screen.dart background colors
    history_path = r'c:\Users\qarel\SDK\daily_development\lib\screens\history_screen.dart'
    process_file(history_path, [
        (r'final Color bgDark = const Color\(0xFF13131A\);', r'Color get bgDark => AppColors.background;'),
        (r'final Color cardDark = const Color\(0xFF1C1C26\);', r'Color get cardDark => AppColors.cardBackground;'),
    ])

    # 3. Fix custom_navbar.dart gradient
    navbar_path = r'c:\Users\qarel\SDK\daily_development\lib\widget\custom_navbar.dart'
    process_file(navbar_path, [
        (r'colors: \[AppColors\.primary, Color\(0xFF5B21B6\)\],', r'colors: AppColors.primaryGradient,'),
    ])

if __name__ == '__main__':
    main()
