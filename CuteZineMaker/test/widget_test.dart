import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petal_press/layout.dart';
import 'package:petal_press/main.dart';
import 'package:petal_press/persist/zine_store.dart';
import 'package:petal_press/theme.dart';

void main() {
  testWidgets('project shelf shows empty state', (tester) async {
    await tester.pumpWidget(PetalPressApp(store: ZineStore.memory()));
    await tester.pumpAndSettle();
    expect(find.text(AppDisplay.name), findsOneWidget);
    expect(find.text('No zines yet'), findsOneWidget);
    expect(find.text('Make a zine'), findsOneWidget);
  });

  test('wide chrome uses shortest-side or width breakpoint', () {
    expect(EditorLayout.isWide(const Size(390, 844)), isFalse);
    expect(EditorLayout.isWide(const Size(500, 900)), isFalse);
    expect(EditorLayout.isWide(const Size(1280, 800)), isTrue);
    expect(EditorLayout.isWide(const Size(840, 500)), isTrue);
    expect(EditorLayout.isWide(const Size(700, 700)), isTrue);
  });
}
