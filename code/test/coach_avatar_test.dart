import 'package:coach_app/ui/coach_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coach card shows the coach face', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CoachCard(label: 'Dein Coach · heute', text: 'Starker Tag.'),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('coach-avatar')), findsOneWidget);
    expect(find.bySemanticsLabel('Dein Coach'), findsOneWidget);
  });
}
