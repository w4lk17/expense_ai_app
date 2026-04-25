import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../domain/services/ai_service.dart';

class GeminiService implements AiService {
  final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? "";

  @override
  Future<String?> suggestCategory(String inputText) async {
    if (apiKey.trim().isEmpty) return null;
    try {
      final String apiUrl =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey";

      final prompt =
          "Tu es un assistant comptable. Classe cette dÃ©pense dans l'une de ces catÃ©gories : "
          "'Alimentation', 'Transport', 'Logement', 'Loisirs', 'SantÃ©', 'Autre'. "
          "RÃ©ponds UNIQUEMENT par le nom de la catÃ©gorie. "
          "DÃ©pense: $inputText";

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text.trim();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> analyzeExpenses(String expenseSummary) async {
    if (apiKey.trim().isEmpty) return null;
    try {
      final String apiUrl =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$apiKey";

      final prompt =
          "Tu es un conseiller financier expert. Voici le rÃ©sumÃ© des dÃ©penses d'un utilisateur pour ce mois :\n\n"
          "$expenseSummary\n\n"
          "RÃ©ponds en EXACTEMENT 3 lignes courtes au format:\n"
          "Summary: ...\n"
          "Watch: ...\n"
          "Next: ...\n"
          "Sois encourageant, concret et liÃ© aux chiffres.";

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text.trim();
    } catch (_) {
      return null;
    }
  }
}
