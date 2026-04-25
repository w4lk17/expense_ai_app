import 'package:expense_ai_app/core/themes/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('App theme uses Material 3 and defines both modes', () {
    expect(AppTheme.lightTheme.useMaterial3, isTrue);
    expect(AppTheme.darkTheme.useMaterial3, isTrue);
    expect(AppTheme.lightTheme.colorScheme.primary, isNotNull);
    expect(AppTheme.darkTheme.colorScheme.primary, isNotNull);
  });
}
