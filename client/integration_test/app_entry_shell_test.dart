import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'test_app.dart';

void main() {
  patrolWidgetTest('app launches and shows home screen with top bar', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Top bar is visible
    expect($(AppBar), findsOneWidget);

    // Theme toggle control is present (starts in light mode → dark_mode icon)
    expect($(#themeToggle), findsOneWidget);
    expect($(Icons.dark_mode), findsOneWidget);

    // Menu control is present
    expect($(#menuButton), findsOneWidget);
    expect($(Icons.menu), findsOneWidget);
  });

  patrolWidgetTest('cards screen loads and shows streak counter at 0', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Streak label and value 0 are visible
    expect($('Streak'), findsOneWidget);
    expect($('0'), findsOneWidget);

    // Streak counter widget is present
    expect($(#streakCounter), findsOneWidget);
  });

  patrolWidgetTest('theme toggle switches between light and dark', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Starts in light mode → icon is dark_mode (tap to go dark)
    expect($(Icons.dark_mode), findsOneWidget);

    await $(#themeToggle).tap();

    // After toggle → dark mode active → icon is light_mode
    expect($(Icons.light_mode), findsOneWidget);

    await $(#themeToggle).tap();

    // Back to light mode → icon is dark_mode again
    expect($(Icons.dark_mode), findsOneWidget);
  });

  patrolWidgetTest('opening progress drawer shows progress view', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Tap the menu control
    await $(#menuButton).tap();

    // Drawer slides in with the progress view
    expect($(#progressView), findsOneWidget);
    expect($('Progress'), findsOneWidget);

    // Metrics are visible
    expect($('Best streak'), findsOneWidget);
    expect($('Current'), findsOneWidget);
    expect($('Right'), findsOneWidget);
    expect($('Wrong'), findsOneWidget);

    // Empty history state
    expect($('No choices yet'), findsOneWidget);
  });

  patrolWidgetTest('closing the drawer returns to cards screen', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Open drawer
    await $(#menuButton).tap();
    expect($('Progress'), findsOneWidget);

    // Close drawer by swiping it to the right (drawer slides off-screen)
    await $.tester.drag(find.byType(Drawer), const Offset(500, 0));
    await $.pumpAndSettle();

    // Cards screen should still be visible — streak counter present
    expect($('Streak'), findsOneWidget);
  });
}
