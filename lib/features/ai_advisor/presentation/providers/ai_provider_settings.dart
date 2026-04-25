import 'package:expense_ai_app/core/constants/api_keys.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _aiProviderKey = 'active_ai_provider';

class AiProviderSettingsNotifier extends StateNotifier<AiProvider> {
  AiProviderSettingsNotifier() : super(defaultAiProvider) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValue = prefs.getString(_aiProviderKey);
    if (storedValue == null) return;

    state = AiProvider.values.firstWhere(
      (provider) => provider.name == storedValue,
      orElse: () => defaultAiProvider,
    );
  }

  Future<void> setProvider(AiProvider provider) async {
    state = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aiProviderKey, provider.name);
  }
}

final aiProviderSettingsProvider =
    StateNotifierProvider<AiProviderSettingsNotifier, AiProvider>((ref) {
      return AiProviderSettingsNotifier();
    });
