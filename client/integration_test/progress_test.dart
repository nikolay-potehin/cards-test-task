import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'test_app.dart';

/// Helper: swipe the current card to the right by dragging its full width.
Future<void> swipeCardRight(PatrolTester $) async {
  final cardFinder = find.byKey(const ValueKey('swipeableCard'));
  final cardRect = $.tester.getRect(cardFinder);
  await $.tester.drag(cardFinder, Offset(cardRect.width, 0));
  await $.pumpAndSettle();
}

/// Helper: swipe the current card to the left by dragging its full width.
Future<void> swipeCardLeft(PatrolTester $) async {
  final cardFinder = find.byKey(const ValueKey('swipeableCard'));
  final cardRect = $.tester.getRect(cardFinder);
  await $.tester.drag(cardFinder, Offset(-cardRect.width, 0));
  await $.pumpAndSettle();
}

void main() {
  patrolWidgetTest('progress view shows empty state on first open', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Open the progress drawer
    await $(#menuButton).tap();
    await $.pumpAndSettle();

    // Progress title
    expect($('Progress'), findsOneWidget);

    // All metrics at 0
    expect($('Best streak'), findsOneWidget);
    expect($('Current'), findsOneWidget);
    expect($('Right'), findsOneWidget);
    expect($('Wrong'), findsOneWidget);

    // All metric values are 0
    // There are 4 metric cards showing "0", plus the streak counter behind
    // the drawer also shows "0" — verify at least 4.
    expect($('0'), findsAtLeastNWidgets(4));

    // Success rate ring shows 0.0%
    expect($('0.0%'), findsOneWidget);
    expect($('win rate'), findsOneWidget);

    // Empty history
    expect($('No choices yet'), findsOneWidget);

    // Recent choices label
    expect($('Recent choices'), findsOneWidget);
  });

  patrolWidgetTest('progress view shows metrics after swiping cards', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Swipe 3 cards right (correct answers → streak increments)
    for (var i = 0; i < 3; i++) {
      await swipeCardRight($);
    }

    // Open progress drawer
    await $(#menuButton).tap();
    await $.pumpAndSettle();

    // Best streak should be 3, current streak 3, right count 3, wrong count 0
    expect($('3'), findsAtLeastNWidgets(2)); // best streak + current + right count
  });

  patrolWidgetTest('progress view shows history items after swipes', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Swipe 2 cards right
    for (var i = 0; i < 2; i++) {
      await swipeCardRight($);
    }

    // Open progress drawer
    await $(#menuButton).tap();
    await $.pumpAndSettle();

    // History items should show "Swiped right" for each
    expect($('Swiped right'), findsNWidgets(2));

    // No empty state
    expect($('No choices yet'), findsNothing);
  });

  patrolWidgetTest('progress metrics accumulate across deck restart', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Swipe all 10 cards right (correct) to complete the deck
    for (var i = 0; i < 10; i++) {
      await swipeCardRight($);
    }

    // Restart deck
    expect($('Deck complete'), findsOneWidget);
    await $(#restartDeckButton).tap();
    await $.pumpAndSettle();

    // Swipe 2 more cards right
    for (var i = 0; i < 2; i++) {
      await swipeCardRight($);
    }

    // Open progress drawer
    await $(#menuButton).tap();
    await $.pumpAndSettle();

    // Right count should be 12 (10 + 2), best streak should persist
    expect($('12'), findsOneWidget);
  });
}
