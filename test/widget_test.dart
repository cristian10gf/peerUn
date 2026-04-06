import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('PeerEval app smoke test resolves splash without pending timers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PeerEvalApp());

    expect(find.byType(GetMaterialApp), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for splash timeout to complete in fake test time.
    await tester.pump(const Duration(seconds: 9));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
