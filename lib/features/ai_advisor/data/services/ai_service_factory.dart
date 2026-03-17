import 'package:expense_ai_app/core/constants/api_keys.dart';
import '../../domain/services/ai_service.dart';
import 'glm_service.dart';
import 'gemini_service.dart';

// Cette classe agit comme un "Provider" de service
class OpenAIService implements AiService {
  late final AiService _activeService;

  OpenAIService() {
    switch (activeAiProvider) {
      case AiProvider.gemini:
        _activeService = GeminiService();
        break;
      case AiProvider.glm:
        _activeService = GLMService();
        break;
      default:
        _activeService = MockService(); // On garde le mock en fallback
        break;
    }
  }

  @override
  Future<String?> suggestCategory(String inputText) {
    return _activeService.suggestCategory(inputText);
  }

  @override
  Future<String?> analyzeExpenses(String expenseSummary) {
    return _activeService.analyzeExpenses(expenseSummary);
  }
}

// On déplace le Mock ici pour la fallback
class MockService implements AiService {
  @override
  Future<String?> suggestCategory(String inputText) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (inputText.toLowerCase().contains('uber')) return 'Transport';
    if (inputText.toLowerCase().contains('carrefour')) return 'Alimentation';
    return 'Autre';
  }

    @override
  Future<String?> analyzeExpenses(String expenseSummary) async {
    await Future.delayed(const Duration(seconds: 1));
    return "Analyse simulée : \n\n✅ Point fort : Vous dépensez peu en transport.\n⚠️ À surveiller : Vos dépenses en loisirs sont élevées ce mois-ci.";
  }
}
