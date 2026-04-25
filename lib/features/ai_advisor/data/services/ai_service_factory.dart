import 'package:expense_ai_app/core/constants/api_keys.dart';

import '../../domain/services/ai_service.dart';
import 'gemini_service.dart';
import 'glm_service.dart';

class OpenAIService implements AiService {
  late final AiService _activeService;

  OpenAIService({AiProvider provider = defaultAiProvider}) {
    switch (provider) {
      case AiProvider.gemini:
        _activeService = GeminiService();
        break;
      case AiProvider.glm:
        _activeService = GLMService();
        break;
      case AiProvider.mock:
        _activeService = MockService();
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
    return "Summary: Spending looks stable overall this month.\n"
        "Watch: Leisure is rising faster than essentials.\n"
        "Next: Set a cap there for the remaining days.";
  }
}
