# Architecture

## Goal
Feature-first structure with strict import boundaries and clear ownership.

## Layers
- `lib/features/`: app features.
- `lib/core/`: app-level constants and cross-feature infrastructure.
- `lib/widgets/`: reusable UI primitives shared across all features.

## Feature Contract
Each feature lives in `lib/features/<feature_name>/` and contains:
- `<feature_name>.dart` (barrel file).
- `controllers/`
- `models/`
- `repos/`
- `screens/`
- `widgets/`

Example:
- `lib/features/cards/cards.dart`

## Import Rules
- Inside a feature: local relative imports only, for example `../widgets/cards_view.dart`.
- Outside a feature: import only through the barrel file, for example `import 'features/cards/cards.dart';`.
- Cross-feature internal imports are not allowed. Shared code belongs in `lib/core/` or `lib/widgets/`.

## Current Feature Set
- `cards`: swipe flow and card session domain.
- `progress`: session statistics and progress visualization.

## Notes From Spec
- State flow is designed for Cubit-based feature state.
- Swipe behavior remains custom (no swipe package).
- Data is in-memory and hardcoded for this assignment.
