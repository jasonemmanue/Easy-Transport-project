import 'package:flutter_test/flutter_test.dart';

import 'package:easy_transport/main.dart';

void main() {
  testWidgets('Splash screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyTransportApp());
    expect(find.text('EasyTransport'), findsWidgets);
  });
}
