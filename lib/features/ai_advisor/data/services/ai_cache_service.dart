import 'package:shared_preferences/shared_preferences.dart';

class AiCacheService {
  static const String _analysisKey = 'ai_analysis_cache';
  static const String _dateKey = 'ai_analysis_date';

  // Sauvegarder l'analyse
  Future<void> saveAnalysis(String analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String();

    await prefs.setString(_analysisKey, analysis);
    await prefs.setString(_dateKey, today);
  }

  // Récupérer l'analyse si elle existe et si elle date d'aujourd'hui
  Future<String?> getTodayAnalysis() async {
    final prefs = await SharedPreferences.getInstance();

    final dateStr = prefs.getString(_dateKey);
    if (dateStr == null) return null;

    final savedDate = DateTime.parse(dateStr);
    final now = DateTime.now();

    // Si l'analyse date d'aujourd'hui (même jour)
    if (savedDate.year == now.year && savedDate.month == now.month && savedDate.day == now.day) {
      return prefs.getString(_analysisKey);
    }

    return null;
  }
}
