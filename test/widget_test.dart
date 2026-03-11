import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:example/main.dart';

void main() {
  testWidgets('PeerEval app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PeerEvalApp());
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}
