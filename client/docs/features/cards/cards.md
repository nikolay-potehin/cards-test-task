# Cards

## User story
As a user, I want to swipe through a deck of word cards, swiping right to mark a card correct and left to mark it incorrect, so I can practice and build a streak of correct answers. When I finish the deck I want a summary and the option to start a new round.

## Actions flow
### Load cards
1. Launch the app (or restart the deck).
2. Expect a loading indicator to appear briefly.
3. Expect a deck of 10 cards to appear.
4. Expect the streak counter to show 0.
5. Expect the first card to be visible with a word and its translation.

### Swipe right (mark correct)
1. Drag the active card to the right past the swipe threshold (or with enough velocity).
2. Expect a green overlay to appear during the drag, increasing in opacity as the card moves right.
3. Release the card.
4. Expect the card to fly away to the right.
5. Expect haptic feedback (light if the answer is correct, heavy if wrong).
6. Expect the next card to become the active card.
7. If the answer was correct: expect the streak to increment and the streak counter to pulse with the ring filling more.
8. If the answer was wrong: expect the streak to reset to 0.

### Swipe left (mark incorrect)
1. Drag the active card to the left past the swipe threshold (or with enough velocity).
2. Expect a red overlay to appear during the drag, increasing in opacity as the card moves left.
3. Release the card.
4. Expect the card to fly away to the left.
5. Expect haptic feedback.
6. Expect the next card to become the active card.
7. Expect the streak to update based on correctness (increment if correct, reset to 0 if wrong).

### Snap back (insufficient swipe)
1. Drag the card a short distance (below the swipe threshold).
2. Release the card.
3. Expect the card to animate back to center.
4. Expect no state change and no haptic feedback.
5. Expect the overlay to fade to transparent.

### Backtrack cancels swipe
1. Drag the card right past the swipe threshold.
2. Drag it back left past the backtrack threshold.
3. Release the card.
4. Expect the card to snap back to center with no swipe triggered.

### Deck complete
1. Swipe through all 10 cards.
2. After the last card is swiped, expect a completion panel to appear.
3. If the final streak is greater than 0, expect confetti to burst from the left and right.
4. Expect the panel to show a "Deck complete" title, the final streak value, and a "Restart deck" button.

### Restart deck
1. From the deck complete state, tap the "Restart deck" button.
2. Expect a loading indicator, then a new 10-card deck to load.
3. Expect the streak to reset to 0.
4. Expect the first card of the new deck to be visible.