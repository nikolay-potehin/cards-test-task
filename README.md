# Language Cards

A Flutter mini-application for learning foreign vocabulary through swipeable cards.

## Features

### Card Screen

* Swipe right for a correct translation
* Swipe left for an incorrect translation
* Snap-back animation when swipe velocity is insufficient
* Card rotation during drag
* Green/red swipe hints
* Fly-away animation on confirmed swipe
* Haptic feedback for correct and incorrect answers
* Current streak display with animation
* Empty state with restart option

### Progress Screen

* Current streak
* Best streak
* Correct answers count
* Incorrect answers count
* Accuracy percentage
* Progress visualization
* Animated counters
* Last 10 answers history
* Accuracy-based motivational message

## Technical Decisions

### State Management

The application uses Cubit from flutter_bloc because it provides simple and predictable state management while keeping the implementation lightweight.

### Swipe Implementation

Card swiping is implemented manually using GestureDetector, Transform, and AnimationController instead of third-party swipe packages. This provides full control over drag behavior, velocity detection, snap-back physics, rotation, and swipe animations.

### Data Source

Cards are hardcoded in memory as required by the assignment. No backend or persistence layer is included.

## Project Structure

lib/
├── core/
│   └── app_constants.dart
├── widgets/
│   └── app_section_title.dart
├── features/
│   ├── cards/
│   │   ├── cards.dart
│   │   ├── controllers/
│   │   ├── models/
│   │   ├── repos/
│   │   ├── screens/
│   │   └── widgets/
│   └── progress/
│       ├── progress.dart
│       ├── controllers/
│       ├── models/
│       ├── repos/
│       ├── screens/
│       └── widgets/
└── main.dart

### Import Rules

* Inside each feature, use local relative imports (for example `../widgets/...`).
* Outside a feature, import only the feature barrel file (for example `import 'features/cards/cards.dart';`).
* Shared cross-feature code belongs in `core/` or top-level `widgets/`.

## Packages

* flutter_bloc
* animated_flip_counter

## Intentional Simplifications

* No backend integration
* No persistent storage
* Single predefined card deck
* Session statistics reset after app restart

## Future Improvements

* Local persistence
* Multiple language decks
* Spaced repetition algorithm
* Difficulty levels
* User profiles and cloud sync
* Detailed learning analytics

## Running the Project

```bash
flutter pub get
flutter run
```
