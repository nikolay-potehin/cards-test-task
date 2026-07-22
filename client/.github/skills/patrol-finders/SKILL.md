---
name: patrol-finders
description: Write Flutter widget and integration tests using patrol_finders. Prefer its fluent finder API for locating and interacting with widgets while using standard Flutter testing APIs whenever they better fit the scenario.
---

# patrol_finders

You are an expert in writing Flutter widget and integration tests using **patrol_finders**.

Write concise, readable, deterministic tests that use patrol_finders' fluent finder API.

---

# Imports

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol_finders/patrol_finders.dart';
```

Tests should use:

```dart
patrolWidgetTest(
  '...',
  ($) async {
    ...
  },
);
```

where `$` is a `PatrolTester`.

Standard Flutter testing APIs from `flutter_test` and `integration_test` may be used whenever patrol_finders does not provide an equivalent capability.

---

# Selector priority

When multiple selector strategies are possible, prefer the following order.

## Keys

```dart
$(#loginButton)

$(#emailField)

$(#passwordField)
```

Keys are the most stable selectors.

---

## Visible text

```dart
$('Login')

$('Continue')

$('Save')
```

---

## Icons

```dart
$(Icons.add)

$(Icons.arrow_back)

$(Icons.close)
```

---

## Widget type

```dart
$(TextField)

$(ElevatedButton)

$(Checkbox)

$(ListTile)
```

---

# Creating finders

## By key

```dart
$(#submitButton)
```

---

## By text

```dart
$('Continue')
```

---

## By widget type

```dart
$(TextField)

$(ElevatedButton)
```

---

## By icon

```dart
$(Icons.settings)
```

---

# Finder composition

## Descendant

Search inside another widget.

```dart
$(Card).$('Delete')
```

```dart
$(Container).$(TextField)
```

Multiple levels can be chained.

```dart
$(Scaffold)
    .$(ListView)
    .$('Settings')
```

---

## containing()

Find a widget that contains another widget.

```dart
$(Container)
    .containing(ElevatedButton)
```

```dart
$(ListTile)
    .containing(Text)
```

---

## which()

Filter widgets by inspecting their properties.

```dart
$(ElevatedButton)
    .which<ElevatedButton>(
      (button) => button.enabled,
    )
```

Example:

```dart
await $(ElevatedButton)
    .which<ElevatedButton>(
      (button) => button.enabled,
    )
    .tap();
```

---

## at()

Select by index.

```dart
$(TextField).at(0)

$(TextField).at(1)
```

---

## first

```dart
$(TextField).first
```

---

## last

```dart
$(TextField).last
```

---

## hitTestable()

Restrict matches to hit-testable widgets.

```dart
$(ElevatedButton)
    .hitTestable()
```

---

# Actions

## tap()

```dart
await $('Login').tap();
```

```dart
await $(#submitButton).tap();
```

---

## longPress()

```dart
await $('Item').longPress();
```

---

## enterText()

```dart
await $(TextField)
    .enterText('john@example.com');
```

```dart
await $(TextField)
    .at(1)
    .enterText('password');
```

---

## scrollTo()

Scroll until the widget becomes visible.

```dart
await $('Settings')
    .scrollTo();
```

```dart
await $(#targetWidget)
    .scrollTo();
```

---

# Waiting

## waitUntilExists()

```dart
await $('Loading')
    .waitUntilExists();
```

---

## waitUntilVisible()

```dart
await $('Continue')
    .waitUntilVisible();
```

---

# Properties

## exists

```dart
if ($('Login').exists) {
  ...
}
```

---

## visible

```dart
if ($('Login').visible) {
  ...
}
```

---

## text

Retrieve the widget's text.

```dart
final value = $('Username').text;
```

---

# Expectations

patrol_finders selectors work directly with Flutter expectations.

```dart
expect(
  $('Login'),
  findsOneWidget,
);
```

```dart
expect(
  $(TextField),
  findsNWidgets(2),
);
```

```dart
expect(
  $('Error'),
  findsNothing,
);
```

---

# Common patterns

Tap by text

```dart
await $('Continue').tap();
```

Tap by key

```dart
await $(#continueButton).tap();
```

Tap an enabled button

```dart
await $(ElevatedButton)
    .which<ElevatedButton>(
      (button) => button.enabled,
    )
    .tap();
```

Enter text

```dart
await $(TextField)
    .enterText('example');
```

Enter text into the second field

```dart
await $(TextField)
    .at(1)
    .enterText('example');
```

Tap text inside a container

```dart
await $(Container)
    .$('Continue')
    .tap();
```

Find a container containing a button

```dart
await $(Container)
    .containing(ElevatedButton)
    .tap();
```

Scroll to a widget

```dart
await $('Advanced settings')
    .scrollTo();
```

Wait until a widget becomes visible

```dart
await $('Home')
    .waitUntilVisible();
```

---

# Choosing selectors

When multiple approaches are available:

1. Key
2. Text
3. Icon
4. Widget type

Use finder composition (`$()`, `containing()`, `which()`) to narrow matches before selecting by position.

`at()`, `first`, and `last` are useful when multiple identical widgets are expected.

---

# Flutter testing APIs

patrol_finders focuses on expressive widget finding and interaction.

For capabilities outside its API surface, it is appropriate to use the standard APIs provided by `flutter_test` and `integration_test`, such as widget pumping, gestures, semantics, frame synchronization, custom finder logic, and other testing utilities.