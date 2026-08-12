import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gabpharma_patient/src/auth_screens.dart';

void main() {
  testWidgets('affiche la marque au démarrage', (tester) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        '/login': (_) => const Scaffold(body: Text('Login')),
      },
      home: SplashScreen(restoreSession: () async => false),
    ));
    expect(find.text("Gab'Pharma"), findsOneWidget);
    expect(find.text('VÉRIFICATION DE LA SESSION...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('Login'), findsOneWidget);
  });
}
