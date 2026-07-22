import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'test_app.dart';

void main() {
  patrolWidgetTest('app starts in light theme with dark_mode icon', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Light mode → icon shows dark_mode (indicating "switch to dark")
    expect($(#themeToggle), findsOneWidget);
    expect($(Icons.dark_mode), findsOneWidget);
    expect($(Icons.light_mode), findsNothing);
  });

  patrolWidgetTest('tapping toggle switches to dark theme and swaps icon', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Tap theme toggle
    await $(#themeToggle).tap();
    await $.pumpAndSettle();

    // Now in dark mode → icon shows light_mode
    expect($(Icons.light_mode), findsOneWidget);
    expect($(Icons.dark_mode), findsNothing);
  });

  patrolWidgetTest('tapping toggle twice returns to light theme', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // First toggle → dark
    await $(#themeToggle).tap();
    await $.pumpAndSettle();
    expect($(Icons.light_mode), findsOneWidget);

    // Second toggle → light
    await $(#themeToggle).tap();
    await $.pumpAndSettle();
    expect($(Icons.dark_mode), findsOneWidget);
  });

  patrolWidgetTest('theme toggle works while cards are visible', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Cards screen is visible
    expect($('Streak'), findsOneWidget);

    // Toggle theme
    await $(#themeToggle).tap();
    await $.pumpAndSettle();

    // Cards screen still visible after theme change
    expect($('Streak'), findsOneWidget);
    expect($(Icons.light_mode), findsOneWidget);
  });

  patrolWidgetTest('theme toggle works from progress drawer', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Open drawer
    await $(#menuButton).tap();
    await $.pumpAndSettle();
    expect($('Progress'), findsOneWidget);

    // Close drawer by swiping it to the right
    await $.tester.drag(find.byType(Drawer), const Offset(500, 0));
    await $.pumpAndSettle();

    // Toggle theme
    await $(#themeToggle).tap();
    await $.pumpAndSettle();
    expect($(Icons.light_mode), findsOneWidget);
  });
}
