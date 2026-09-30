import 'package:flutter_test/flutter_test.dart';

import 'package:carlinq_chauffeur/main.dart';

void main() {
  testWidgets('Splash chauffeur puis accueil', (WidgetTester tester) async {
    await tester.pumpWidget(const CarlinqChauffeurApp());
    expect(find.text('Carlinq Chauffeur'), findsWidgets);
    // Laisse le splash naviguer vers l'accueil (delai 1,6 s).
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Conduisez avec Carlinq'), findsOneWidget);
  });
}
