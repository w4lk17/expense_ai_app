import 'package:dart_openai/dart_openai.dart';
import 'package:expense_ai_app/core/constants/api_keys.dart';

import '../../domain/services/ai_service.dart';

class GLMService implements AiService {
  GLMService() {
    OpenAI.apiKey = glmApiKey;
    OpenAI.baseUrl = glmBaseUrl;
  }

  @override
  Future<String?> suggestCategory(String inputText) async {
    if (glmApiKey.trim().isEmpty) return null;
    try {
      final systemInstruction = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Tu es un assistant comptable. Classe cette dÃ©pense dans l'une de ces catÃ©gories : "
            "'Alimentation', 'Transport', 'Logement', 'Loisirs', 'SantÃ©', 'Autre'. "
            "RÃ©ponds UNIQUEMENT par le nom de la catÃ©gorie.",
          ),
        ],
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(inputText),
        ],
      );

      final request = await OpenAI.instance.chat.create(
        model: glmModel,
        messages: [systemInstruction, userMessage],
        maxTokens: 10,
      );

      return request.choices.first.message.content?.first.text;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> analyzeExpenses(String expenseSummary) async {
    if (glmApiKey.trim().isEmpty) return null;
    try {
      final systemInstruction = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Tu es un conseiller financier expert. Analyse les dÃ©penses fournies. "
            "RÃ©ponds en 3 lignes courtes au format exact: Summary: ..., Watch: ..., Next: ...",
          ),
        ],
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            expenseSummary,
          ),
        ],
      );

      final request = await OpenAI.instance.chat.create(
        model: glmModel,
        messages: [systemInstruction, userMessage],
        maxTokens: 150,
      );

      return request.choices.first.message.content?.first.text;
    } catch (_) {
      return null;
    }
  }
}
