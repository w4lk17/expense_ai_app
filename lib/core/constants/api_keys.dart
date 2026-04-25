import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AiProvider { gemini, glm, mock }

const AiProvider defaultAiProvider = AiProvider.gemini;
const String defaultGlmBaseUrl = 'https://open.bigmodel.cn/api/paas/v4/';
const String defaultGlmModel = 'glm-4';

String get glmApiKey => _optionalEnv('GLM_API_KEY');

String get glmBaseUrl =>
    _optionalEnv('GLM_BASE_URL', fallback: defaultGlmBaseUrl);

String get glmModel => _optionalEnv('GLM_MODEL', fallback: defaultGlmModel);

String aiProviderLabel(AiProvider provider) {
  switch (provider) {
    case AiProvider.gemini:
      return 'Gemini';
    case AiProvider.glm:
      return 'GLM';
    case AiProvider.mock:
      return 'Mock';
  }
}

String _optionalEnv(String key, {String fallback = ''}) {
  final value = dotenv.env[key]?.trim();
  if (value == null || value.isEmpty) {
    return fallback;
  }
  return value;
}
