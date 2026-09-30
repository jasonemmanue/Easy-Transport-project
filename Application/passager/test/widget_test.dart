import 'package:flutter_test/flutter_test.dart';

import 'package:carlinq_passager/main.dart';

void main() {
  testWidgets('Splash passager puis accueil', (WidgetTester tester) async {
    await tester.pumpWidget(const CarlinqPassagerApp());
    expect(find.text('Carlinq'), findsWidgets);
    // Laisse le splash naviguer vers l'accueil (delai 1,6 s).
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Creer un compte'), findsOneWidget);
  });
}
