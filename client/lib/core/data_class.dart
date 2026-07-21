import 'package:equatable/equatable.dart';

/// {@template json_equatable}
/// Default [DataClass] model
/// This model uses Equatable for equality overrides and provides [debugName] getter and [toJson], [copyWith] methods.
/// It also incapsulates the [json] to show the original json returned from API for easier debugging
/// {@endtemplate}
abstract class DataClass<T extends Object> extends Equatable {
  /// {@macro json_equatable}
  const DataClass({required this.json});

  /// Serves as initial json from API for easier debug
  final Map<String, Object?>? json;

  String get debugName => runtimeType.toString();

  T copyWith();

  Map<String, Object?> toJson();
}
