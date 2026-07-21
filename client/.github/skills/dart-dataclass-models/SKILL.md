---
name: dart-dataclass-models
description: Create Dart DataClass models that follow the project dataclass serialization and copyWith conventions.
license: MIT
metadata:
  author: polka
  version: '1.0'
---

Create or update Dart model classes using the project DataClass pattern.

Use this skill when the user asks to create a model/dataclass, implement model serialization, or align existing model classes with repository conventions.

## Required output contract

For a model class `ClassName`:

1. Class declaration
   - Must extend `DataClass<ClassName>`.
   - Constructor must include explicit required `super.json`.

2. `fromJson`
   - Must be a factory: `factory ClassName.fromJson(Map<String, Object?> json)`.
   - JSON keys must be `snake_case`.
   - Keys in `fromJson` and `toJson` must match exactly.

3. `props`
   - Must override `List<Object?> get props`.
   - Include every class field except `json`.

4. `copyWith`
   - Must override `copyWith`.
   - Every field parameter must be optional and typed as:
     - non-nullable: `Defaulted<T> field = const Omit()`
     - nullable: `Defaulted<T?> field = const Omit()`
   - Assignment pattern must be exactly:
     - `field: field is Omit ? this.field : field as T`
     - nullable variant: `field as T?`

5. `toJson`
   - Must override `Map<String, Object> toJson()`.
   - Use `snake_case` keys matching `fromJson`.
   - Nullable keys must use `?`-entry syntax so null entries are removed, e.g.:
     - `'replied_at': ?repliedAt?.toJson(),`

6. Documentation comments
   - Add one-line, short, comprehensive doc comments for:
     - the class
     - every public method except `props`
   - Add template block directly above class definition:
     - `/// {@template class_name}`
     - `/// One-liner doc goes here with [ClassName] reference`
     - `/// {@endtemplate}`
   - Add macro line directly above constructor:
     - `/// {@macro class_name}`

## Serialization rules

- If a field is built-in (`int`, `double`, `num`, `bool`, `String`, `List`, `Map`), parse directly with safe typing as needed.
- If a field is not built-in (e.g. `DateTime`, enum-like model, nested model/json object), you must use explicit serialization methods:
  - parse with that type's `fromJson` or equivalent constructor/parser
  - write with that type's `toJson`
- Import required extension files when serialization helpers are extension-based (for example DateTime JSON extensions).

## Clarification rule (mandatory)

If a non-built-in type used in the model does not have a known/explicit `fromJson` and `toJson` contract in the codebase, stop and ask the user for serialization details before implementing.

## Style constraints

- Keep changes minimal and focused on the requested model.
- Follow existing repository formatting and naming.
- Use single quotes for string literals.
- When a class has multiple fields of the same type, declare them in a single line (e.g. `final String a, b, c;`) instead of separate declarations (`final String a; final String b; final String c;`).
- Avoid unnecessary comments beyond requested doc comments.

## Implementation checklist

- [ ] `extends DataClass<ClassName>` and `required super.json`
- [ ] `factory ClassName.fromJson(Map<String, Object?> json)`
- [ ] `props` contains all fields except `json`
- [ ] `copyWith` uses `Defaulted<...> = const Omit()` for all fields
- [ ] `copyWith` assignments follow `is Omit ? this.field : field as Type`
- [ ] `toJson` returns `Map<String, Object>`
- [ ] nullable entries in `toJson` use `?`-entry syntax
- [ ] `snake_case` keys and exact `fromJson`/`toJson` key parity
- [ ] non-built-in fields use explicit `fromJson`/`toJson`
- [ ] required class/method docs + template/macro lines
