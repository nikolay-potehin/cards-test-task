# Language Cards - Flutter Implementation Spec

## Tech Stack

State Management:
- flutter_bloc (Cubit)

Navigation:
- Material 3 NavigationBar

Animations:
- AnimationController
- AnimatedBuilder
- AnimatedSwitcher
- SlideTransition
- ScaleTransition

Platform Features:
- HapticFeedback

No swipe/card packages.

---

## Card Screen

### Card Stack

Technique:
- Stack
- Top card = active
- Second card = scaled preview (0.95)

Widgets:
- Stack
- Positioned
- Transform.scale

---

### Drag & Swipe

Technique:
- GestureDetector
- Track drag offset manually

Widgets:
- GestureDetector
- Transform.translate

State:
- Offset dragOffset

---

### Card Rotation

Technique:
- Rotation proportional to horizontal drag

Formula:
```dart
rotation = dragOffset.dx / 300 * 0.3;

Widgets:

Transform.rotate
Swipe Decision

Technique:

Velocity threshold

Rules:

velocity.dx > 500 → right swipe
velocity.dx < -500 → left swipe
otherwise → snap back

API:

DragEndDetails.velocity.pixelsPerSecond.dx
Snap Back Animation

Technique:

AnimationController
Tween<Offset>

Widgets:

AnimatedBuilder

Duration:

200–300ms
Fly Away Animation

Technique:

Tween current position → offscreen

Widgets:

SlideTransition
AnimatedBuilder

Duration:

250ms
Swipe Hints

Technique:

Overlay opacity based on drag distance

Widgets:

Stack
Opacity
Container

Colors:

Green = right
Red = left

Formula:

opacity = min(abs(dx) / 150, 1);
Streak Display

Logic:

Correct answer → streak++
Wrong answer → streak = 0
Track best streak separately

State:

currentStreak
bestStreak
Streak Animation

Technique:

AnimatedSwitcher
ScaleTransition

Duration:

300ms

Trigger:

Only when streak changes
Haptic Feedback

Correct:

HapticFeedback.lightImpact();

Wrong:

HapticFeedback.mediumImpact();
Empty State

Trigger:

No cards remaining

Widgets:

Center
Column
ElevatedButton
AnimatedSwitcher

Actions:

Restart session
Reset stats
Reload cards
Progress Screen
Metrics

Show:

Current streak
Best streak
Correct count
Incorrect count
Accuracy %

Formula:

accuracy =
correct / total * 100;
Animated Counters

Technique:

AnimatedFlipCounter package

Package:

animated_flip_counter

Use For:

All statistics
Accuracy Visualization

Technique:

CircularProgressIndicator

Alternative:

LinearProgressIndicator

Value:

accuracy / 100
Recent Answers

Store:

Last 10 results

Structure:

List<bool>

Widgets:

Wrap
Icon

Icons:

✓ -> check_circle
✗ -> cancel
Motivation Message

Rules:

< 50% → Keep practicing
50–80% → Good progress

80% → Excellent work

Display:

AnimatedSwitcher
Data Layer

Model:

class WordCard {
  String word;
  String translation;
  bool isCorrect;
}

Data:

Hardcoded list
Minimum 20 cards
Mixed correct/incorrect translations
Cubit State
class SessionState {
  List<WordCard> cards;

  int currentIndex;

  int streak;
  int bestStreak;

  int correctCount;
  int incorrectCount;

  List<bool> recentAnswers;
}
UX Requirements

Must Have:

Swipe physics
Velocity detection
Snap back
Fly away animation
Rotation while dragging
Color hints
Haptic feedback
Animated streak
Animated statistics
Empty state

Nice To Have:

Hero-like page transitions
Fade transitions
Subtle scale animation on card appearance
README Notes

Explain:

Why Cubit was chosen.
Why swipe was implemented manually instead of using packages.
What was intentionally simplified.
Future improvements:
persistence
backend sync
spaced repetition algorithm
multiple language decks