import 'dart:async';

/// Default Type for copyWith methods
typedef Defaulted<T> = FutureOr<T>;

/// Sentinel value to omit a parameter from a copyWith call.
/// This is used to distinguish between a parameter being omitted and a parameter
/// being set to null.
/// See the original: https://github.com/dart-lang/language/issues/137#issuecomment-583783054
final class Omit<T> implements Future<T> {
  const Omit();

  // coverage:ignore-start
  @override
  noSuchMethod(Invocation invocation) => throw UnsupportedError('It is an error to attempt to use a Omit as a Future.');
  // coverage:ignore-end
}
