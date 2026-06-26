import 'package:expense_ai_app/features/expense/presentation/providers/expense_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('budget alert thresholds', () {
    test('below 70 percent creates no alert', () {
      expect(budgetAlertLevelFor(0.69), isNull);
    });

    test('70 percent creates warning70', () {
      expect(budgetAlertLevelFor(0.70), BudgetAlertLevel.warning70);
    });

    test('90 percent creates warning90', () {
      expect(budgetAlertLevelFor(0.90), BudgetAlertLevel.warning90);
    });

    test('100 percent creates over100', () {
      expect(budgetAlertLevelFor(1.00), BudgetAlertLevel.over100);
    });

    test('priority increases with severity', () {
      expect(
        budgetAlertPriority(BudgetAlertLevel.over100),
        greaterThan(budgetAlertPriority(BudgetAlertLevel.warning90)),
      );
      expect(
        budgetAlertPriority(BudgetAlertLevel.warning90),
        greaterThan(budgetAlertPriority(BudgetAlertLevel.warning70)),
      );
    });
  });
}
