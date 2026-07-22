# App Entry & Shell

## User story
As a user, I want to open the app and immediately see the main card screen with a top bar giving me access to theme switching and my progress, so I can start practicing and track my session.

## Actions flow
1. Launch the app.
2. Expect the home screen to be visible with a top bar.
3. Expect the top bar to show a theme toggle control and a menu control.
4. Expect the cards screen to load: a brief loading indicator, then a card deck appears.
5. Expect a streak counter labeled "Streak" showing value "0".

### Theme toggle
1. Tap the theme toggle control in the top bar.
2. Expect the app to switch between light and dark theme immediately.
3. Expect the toggle icon to swap (sun <-> moon).

### Open progress drawer
1. Tap the menu control in the top bar.
2. Expect a drawer to slide in from the right.
3. Expect the progress view to be visible with metrics, a success ring, a quote, and a history list.
4. Close the drawer (swipe or tap outside).
5. Expect the cards screen to remain visible.