import 'package:flutter_test/flutter_test.dart';
import 'package:gabpharma_patient/src/app.dart';

void main() {
  testWidgets('affiche la marque au démarrage', (tester) async {
    await tester.pumpWidget(const GabPharmaPatientApp());
    expect(find.text("Gab'Pharma"), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Bonjour 👋'), findsOneWidget);
  });
}
