# Architecture

## Goal
Feature-first structure with strict import boundaries and clear ownership.

## Data Flow
- `data_source` (optional) -> `repo` -> `controller (Cubit)` -> `UI`.
- Repos obtain data only.
- Cubits transform state based on user input.
- UI renders cubit state and triggers cubit actions.

## Layers
- `lib/features/`: app features.
- `lib/core/`: app-level constants and cross-feature infrastructure.
- `lib/widgets/`: reusable UI primitives shared across all features.

## Theme
- Theme is controlled by root `ThemeController` (Stateful + Inherited).
- Default mode is `ThemeMode.system` on each app start.
- Theme toggle is runtime-only and not persisted.

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
- `home`: app shell with app bar and right drawer.
- `cards`: swipe flow and card session domain.
- `progress`: session statistics and progress visualization.

## Dependency Rules
- Register all repos in `Dependencies.init()`.
- Register abstract repo type with concrete realization value.
- Obtain repos only via `Dependencies.of(context).repo<T>()`.

## Notes From Spec
- State flow is designed for Cubit-based feature state.
- Swipe behavior remains custom (no swipe package).
- Data is in-memory and hardcoded for this assignment.
- Restart reloads random 10-card subset from repo.
- Streak resets on each loaded deck.
- Streak grows only on correct swipe decision.
- Drawer shows recent swipe history entries.
- Correct choice uses light haptic, wrong uses heavy.
- Streak stays visible until restart tap.
- Streak pulses orange on increment.
- Drawer shows all-session best and answer totals.
- Deck-complete confetti scales with final streak.
- Streak ring fills from 0 to 10.
- Streak ring animates clockwise with inner spacing.
- Progress drawer has animated success ring.
- Progress drawer shows tiered motivational quotes.
- Quotes refresh randomly on each drawer open.
- Retry state uses completion summary card.
