# Flutter Developer Test Assignment

**Format:** Vibe Coding
**Estimated Time:** 5–6 hours
**Deadline:** 3 days

## Technology

* Flutter
* Dart
* Any pub.dev packages of your choice

## Objective

Build a small mobile application called **Language Cards** for learning foreign vocabulary through swipeable flashcards.

---

# Screen 1: Cards (Main Screen)

Display a stack of vocabulary cards, one card at a time.

Each card contains:

* A foreign word
* A Russian translation

Example:

* Doll → кукла
* Ball → стол
* Window → окно
* Chair → дерево

Some translations should be correct and some intentionally incorrect.

Provide at least **20 hardcoded cards**.

## Swipe Mechanics

### Swipe Right

Represents a correct translation.

### Swipe Left

Represents an incorrect translation.

### Insufficient Swipe Velocity

The card should return to its original position with a snap-back animation.

## Streak Logic

Track the number of consecutive correct answers.

Rules:

* Correct answer → streak increases
* Any mistake → streak resets to zero

The current streak must be visible on the card screen.

## UX Enhancements

Implement the following:

* Card rotation during drag
* Green overlay when dragging right
* Red overlay when dragging left
* Fly-away animation on successful swipe
* Haptic feedback for correct and incorrect answers
* Streak growth animation
* Empty state when all cards are completed
* "Start Again" button in the empty state

---

# Screen 2: Progress

Provide navigation from the card screen using either:

* A button
* Bottom navigation

Display:

* Current streak
* Best streak during the session
* Number of correct answers
* Number of incorrect answers
* Accuracy percentage

## Progress Visualization

Include any visual representation of progress.

Examples:

* Circular progress indicator
* Progress bar
* Charts

## UX Enhancements

Implement the following:

* Animated counters when the screen appears
* Motivational message based on accuracy
* History of the last 10 answers using ✓ and ✗ indicators

---

# Expectations

We expect:

* Functional swipe mechanics with physics
* Proper snap-back behavior
* Correct streak logic
* Thoughtful UX decisions where requirements are unspecified
* Clean architecture of your choice
* Explanation of architecture decisions in README

README should include:

* What was implemented
* What was intentionally simplified
* What would be improved with more time

---

# Out of Scope

The following are not required:

* Backend
* Authentication
* Persistence between sessions
* Pixel-perfect design

---

# Submission

Provide:

1. GitHub repository
2. Loom video (2–3 minutes)

In the video:

* Demonstrate the working application
* Explain one non-trivial technical decision you made during implementation

If any requirement is unclear, clarify it before starting development.
