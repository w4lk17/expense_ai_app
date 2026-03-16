import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:expense_ai_app/core/constants/api_keys.dart';
import '../../domain/services/ai_service.dart';

class GeminiService implements AiService {
  @override
  Future<String?> suggestCategory(String inputText) async {
    try {
      // URL de l'API Gemini (REST)
      final String apiUrl =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$geminiApiKey";

      // Construction du prompt
      final prompt =
          "Tu es un assistant comptable. Classe cette dépense dans l'une de ces catégories : "
          "'Alimentation', 'Transport', 'Logement', 'Loisirs', 'Santé', 'Autre'. "
          "Réponds UNIQUEMENT par le nom de la catégorie. "
          "Dépense: $inputText";

      // Corps de la requête JSON
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      });

      // Appel HTTP POST
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        // Parsing de la réponse JSON
        final data = jsonDecode(response.body);
        // La structure de réponse Gemini est : candidates -> content -> parts -> text
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        return text.trim();
      } else {
        print("Erreur API Gemini: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception Gemini: $e");
      return null;
    }
  }
}
