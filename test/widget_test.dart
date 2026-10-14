// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gameproject/main.dart';

void main() {
  testWidgets('brick breaker renders and starts', (WidgetTester tester) async {
    await tester.pumpWidget(const BrickBreakerApp());

    expect(find.text('BRICK BREAKER'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-board')), findsOneWidget);
    expect(find.text('Start game'), findsOneWidget);

    await tester.tap(find.text('Start game'));
    await tester.pump();

    expect(find.text('Pause'), findsOneWidget);
  });
}
