---
name: create-repo
description: 'Create Dart data repositories. Use when generating subject_repo.dart, sealed SubjectRepo contracts, and SubjectRepo$Stub plus SubjectRepo$Rest or SubjectRepo$Stub implementations with Future<Result<T>> methods and @template/@macro docs.'
argument-hint: 'Subject name, methods, and optional extra realizations (example: bookings, getById/cancel, Rest+Stub)'
---

# Create Repo

Create a short, consistent Dart repository file using the project repo convention.

## When to Use
- User asks to create a new data repo.
- User asks to refactor Repository naming into Repo naming.
- User asks for Rest or Stub repo variants in one file.
- User asks for Result-based async repo contracts.

## Required Output
- File name is `subject_repo.dart`.
- Main type is `sealed class SubjectRepo`.
- Main methods are abstract and return `Future<Result<T>>` unless explicitly requested otherwise.
- Concrete realizations are in the same file and named `SubjectRepo$Clarification`.
- Stub realization is always included as `SubjectRepo$Stub`.
- Main sealed class is documented with `@template` and `@macro`.
- Every concrete realization adds `@macro` from the main repo plus a short realization note.

## Procedure
1. Gather inputs.
   - Subject name in singular or plural form.
   - Method list and each success payload type.
  - Optional extra realizations required (for example Rest, Local).
   - Any explicit sync or non-Result exception from default contract.
2. Normalize naming.
   - Convert file to `subject_repo.dart`.
   - Convert base type to `SubjectRepo`.
   - Keep `Repo` short, never `Repository`.
3. Create sealed contract.
   - Add template docs above base class.
   - Add abstract method signatures.
   - Default all methods to `Future<Result<T>>`.
4. Add concrete realizations.
  - Always include `SubjectRepo$Stub`.
   - Place in the same file.
  - Use `final class SubjectRepo$Stub extends SubjectRepo` style.
   - Implement each method from the contract.
   - Add docs: `@macro` plus one concrete clarification sentence.
5. Validate quality.
   - Naming, docs, return types, and method coverage all match.

## Decision Points
- If user explicitly requests sync methods:
  - Allow non-Future signatures only for those methods.
- If user explicitly requests non-Result return:
  - Follow request for that method and keep others default.
- If user provides no realization list:
  - Generate `SubjectRepo$Stub` by default and ask whether to add `SubjectRepo$Rest`, `SubjectRepo$Local`, or other.

## Documentation Pattern
```dart
/// {@template bookings_repo}
/// Defines booking data access contract through [BookingsRepo].
/// {@endtemplate}
sealed class BookingsRepo {
  /// {@macro bookings_repo}
  Future<Result<Booking>> getById(int id);
}

/// {@macro bookings_repo}
/// Stub realization for placeholder implementation wiring.
final class BookingsRepo$Stub extends BookingsRepo {
  @override
  Future<Result<Booking>> getById(int id) async {
    // Implementation
  }
}

/// {@macro bookings_repo}
/// REST realization for network-backed booking access.
final class BookingsRepo$Rest extends BookingsRepo {
  @override
  Future<Result<Booking>> getById(int id) async {
    // Implementation
  }
}
```

## Completion Checklist
- [ ] File is named `subject_repo.dart`.
- [ ] Base class is `sealed class SubjectRepo`.
- [ ] No `Repository` naming remains.
- [ ] Base methods are abstract and return `Future<Result<T>>` by default.
- [ ] `SubjectRepo$Stub` is always included.
- [ ] Realizations use `SubjectRepo$Clarification` naming.
- [ ] Realizations are in the same file.
- [ ] Main docs include `@template` and `@macro`.
- [ ] Concrete docs include `@macro` plus realization-specific note.
- [ ] All methods are implemented in each realization.
