// lib/core/constants/api_keys.dart

// Configuration active : Choisis quel service utiliser ici
enum AiProvider { gemini, glm, mock }

const AiProvider activeAiProvider = AiProvider.gemini; // Change ici pour switcher

// Clés API
const String geminiApiKey = 'AIzaSyBTSfySS3Jm-b42NkPqpcZ2oQtavXcq15Q';
const String glmApiKey = 'TA_CLE_GLM_ICI'; // Souvent appelée API Key Zhipu AI

// Configuration GLM (Endpoint spécifique si nécessaire)
const String glmBaseUrl = "https://open.bigmodel.cn/api/paas/v4/"; // URL standard GLM-4
const String glmModel = "glm-4"; // ou "glm-3-turbo"
