import 'package:shared_preferences/shared_preferences.dart';

/// Local chrome preferences (not zine documents).
abstract final class ChromePrefs {
  static const sideToolsKey = 'cute_zine_side_tools_open';

  static Future<bool> sideToolsOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(sideToolsKey) ?? true;
  }

  static Future<void> setSideToolsOpen(bool open) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sideToolsKey, open);
  }
}
