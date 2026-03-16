
class OpenAIService {
  // Pas besoin de clé API pour le Mock
  // OpenAIService() {
  //   OpenAI.apiKey = openAIApiKey;
  // }

  Future<String?> suggestCategory(String inputText) async {
    // On simule un délai réseau pour que ça fasse "vrai"
    await Future.delayed(const Duration(milliseconds: 500));

    final text = inputText.toLowerCase();

    // Logique simple basée sur des mots-clés (Mock)
    if (text.contains('uber') || text.contains('taxi') || text.contains('essence') || text.contains('train')) {
      return 'Transport';
    }
    if (text.contains('carrefour') ||
        text.contains('courses') ||
        text.contains('restaurant') ||
        text.contains('mcdo') ||
        text.contains('pizza')) {
      return 'Alimentation';
    }
    if (text.contains('loyer') || text.contains('electricité') || text.contains('eau')) {
      return 'Logement';
    }
    if (text.contains('cinéma') || text.contains('netflix') || text.contains('jeu')) {
      return 'Loisirs';
    }
    if (text.contains('médecin') || text.contains('pharmacie')) {
      return 'Santé';
    }

    // Par défaut
    return 'Autre';
  }
}
