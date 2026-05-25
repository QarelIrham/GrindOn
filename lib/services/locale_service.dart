import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_locale.dart';

/// Manages the active app language.
/// Persists the user's choice to SharedPreferences.
class LocaleService extends ChangeNotifier {
  static const String _prefKey = 'app_language';

  AppLang _lang = AppLang.id;

  AppLang get lang => _lang;

  /// The current locale helper (use this in widgets).
  L get l => L(_lang);

  bool get isEnglish => _lang == AppLang.en;

  /// Load saved language from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved == 'en') {
      _lang = AppLang.en;
    } else {
      _lang = AppLang.id;
    }
    notifyListeners();
  }

  /// Switch to the given language and persist.
  Future<void> setLang(AppLang newLang) async {
    if (_lang == newLang) return;
    _lang = newLang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLang == AppLang.en ? 'en' : 'id');
  }

  /// Toggle between ID and EN.
  Future<void> toggle() async {
    await setLang(_lang == AppLang.id ? AppLang.en : AppLang.id);
  }
}

/// Shortcut to access the current locale helper from any BuildContext.
extension LocaleContext on BuildContext {
  L get l => Provider.of<LocaleService>(this, listen: false).l;
  L get lw => Provider.of<LocaleService>(this, listen: true).l;
}

