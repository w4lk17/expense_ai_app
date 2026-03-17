import 'package:dart_openai/dart_openai.dart';
import 'package:expense_ai_app/core/constants/api_keys.dart';
import '../../domain/services/ai_service.dart';

class GLMService implements AiService {
  GLMService() {
    // On configure OpenAI SDK pour pointer vers les serveurs de GLM
    OpenAI.apiKey = glmApiKey;
    OpenAI.baseUrl = glmBaseUrl;
  }

  @override
  Future<String?> suggestCategory(String inputText) async {
    try {
      final systemInstruction = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Tu es un assistant comptable. Classe cette dépense dans l'une de ces catégories : "
            "'Alimentation', 'Transport', 'Logement', 'Loisirs', 'Santé', 'Autre'. "
            "Réponds UNIQUEMENT par le nom de la catégorie.",
          ),
        ],
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(inputText)],
      );

      final request = await OpenAI.instance.chat.create(
        model: glmModel, // Défini dans les constantes
        messages: [systemInstruction, userMessage],
        maxTokens: 10,
      );

      return request.choices.first.message.content?.first.text;
    } catch (e) {
      print("Erreur GLM: $e");
      return null;
    }
  }

  @override
  Future<String?> analyzeExpenses(String expenseSummary) async {
    try {
      final systemInstruction = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
            "Tu es un conseiller financier expert. Analyse les dépenses fournies. "
            "Donne un point fort et un conseil d'amélioration en 2 phrases max.",
          ),
        ],
      );

      final userMessage = OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(expenseSummary)],
      );

      final request = await OpenAI.instance.chat.create(
        model: glmModel,
        messages: [systemInstruction, userMessage],
        maxTokens: 150,
      );

      return request.choices.first.message.content?.first.text;
    } catch (e) {
      print("Erreur GLM: $e");
      return null;
    }
  }
}
