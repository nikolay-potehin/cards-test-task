import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';

import 'test_app.dart';

void main() {
  patrolWidgetTest('deck loads with 10 cards and streak at 0', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Streak counter shows 0
    expect($('Streak'), findsOneWidget);
    expect($('0'), findsOneWidget);

    // The deck has loaded (swipeable card is visible, no loading state)
    expect($(#swipeableCard), findsOneWidget);
  });

  patrolWidgetTest('swipe right marks card correct and increments streak', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // The first card in the stub deck is "Doll / кукла" with isCorrect: true
    // Swiping right on a correct card → streak increments
    final cardFinder = find.byKey(const ValueKey('swipeableCard'));
    final cardRect = $.tester.getRect(cardFinder);
    await $.tester.drag(cardFinder, Offset(cardRect.width, 0));
    await $.pumpAndSettle();

    // Streak should now be 1
    expect($('1'), findsOneWidget);
  });

  patrolWidgetTest('swipe left marks card incorrect and resets streak', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Swipe left on first card ("Doll / кукла", isCorrect: true)
    // Swiping left on a correct card → answer is wrong → streak resets to 0
    final cardFinder = find.byKey(const ValueKey('swipeableCard'));
    final cardRect = $.tester.getRect(cardFinder);
    await $.tester.drag(cardFinder, Offset(-cardRect.width, 0));
    await $.pumpAndSettle();

    // Streak stays at 0 (wrong answer resets)
    expect($('0'), findsOneWidget);
  });

  patrolWidgetTest('insufficient swipe snaps card back with no state change', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Small drag — below the swipe threshold of 90px
    await $.tester.drag(find.byKey(const ValueKey('swipeableCard')), const Offset(20, 0));
    await $.pumpAndSettle();

    // Streak remains 0 — no swipe was triggered
    expect($('0'), findsOneWidget);
  });

  patrolWidgetTest('backtrack cancels swipe', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    final cardFinder = find.byKey(const ValueKey('swipeableCard'));

    // Start a gesture, drag right past the swipe threshold, then drag back
    // left past the backtrack threshold — all in one continuous gesture.
    final gesture = await $.tester.startGesture($.tester.getCenter(cardFinder));
    await gesture.moveBy(const Offset(150, 0));
    await $.pump();
    await gesture.moveBy(const Offset(-200, 0));
    await $.pump();
    await gesture.up();
    await $.pumpAndSettle();

    // No swipe triggered — streak stays 0
    expect($('0'), findsOneWidget);
  });

  patrolWidgetTest('deck complete shows retry panel after swiping all cards', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Swipe through all 10 cards to the right
    for (var i = 0; i < 10; i++) {
      final cardFinder = find.byKey(const ValueKey('swipeableCard'));
      final cardRect = $.tester.getRect(cardFinder);
      await $.tester.drag(cardFinder, Offset(cardRect.width, 0));
      await $.pumpAndSettle();
    }

    // Deck complete panel should appear
    expect($('Deck complete'), findsOneWidget);
    expect($(#restartDeckButton), findsOneWidget);
  });

  patrolWidgetTest('restart deck loads a new deck and resets streak', (PatrolTester $) async {
    await $.pumpWidgetAndSettle(await buildTestApp());

    // Swipe through all 10 cards to the right (all correct → streak 10)
    for (var i = 0; i < 10; i++) {
      final cardFinder = find.byKey(const ValueKey('swipeableCard'));
      final cardRect = $.tester.getRect(cardFinder);
      await $.tester.drag(cardFinder, Offset(cardRect.width, 0));
      await $.pumpAndSettle();
    }

    // Deck complete panel
    expect($('Deck complete'), findsOneWidget);

    // Tap restart
    await $(#restartDeckButton).tap();
    await $.pumpAndSettle();

    // New deck loaded — streak reset to 0
    expect($('0'), findsOneWidget);
    expect($('Deck complete'), findsNothing);
  });
}
