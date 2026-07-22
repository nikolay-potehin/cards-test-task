# Progress

## User story
As a user, I want to open a progress panel from the home screen to review my session statistics — best and current streak, correct and incorrect counts, success rate, and a recent history of my swipes — so I can track how I'm doing over time.

## Actions flow
### View progress (empty)
1. Open the progress drawer from the home screen.
2. Expect the progress view to load.
3. Expect all metrics (best streak, current streak, right count, wrong count) to show 0.
4. Expect the success rate ring to show 0.0%.
5. Expect an empty history state ("No choices yet").
6. Expect a motivational quote to be visible.

### View progress after swipes
1. Swipe several cards (some correct, some wrong).
2. Open the progress drawer.
3. Expect "Best streak" to show the maximum streak reached.
4. Expect "Current" to show the current streak (0 if the last swipe was wrong, or the ongoing streak).
5. Expect "Right" to show the correct count and "Wrong" to show the incorrect count.
6. Expect the success rate ring to animate to the accuracy percentage.
7. Expect the recent choices list to show the last swipes with a correct (✓) or incorrect (✗) indicator.
8. Expect each history item to show the word and translation, and the swipe direction.
9. Expect the quote to reflect the accuracy tier.

### Progress updates across restarts
1. Swipe several cards and note the metrics.
2. Close the drawer and restart the deck.
3. Swipe more cards.
4. Open the drawer.
5. Expect the correct/incorrect counts to accumulate across the session.
6. Expect the best streak to persist.
7. Expect the current streak to have reset on restart and reflect the new deck's swipes.