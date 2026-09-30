import 'package:flutter_test/flutter_test.dart';

import 'package:carlinq/main.dart';

void main() {
  testWidgets('Splash screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const CarlinqApp());
    expect(find.text('Carlinq'), findsWidgets);
    // Laisse le splash naviguer vers l'accueil (delai 1,6 s).
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
