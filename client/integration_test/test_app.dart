import 'package:flutter/material.dart';
import 'package:test_task_cards/core/theme_controller.dart';
import 'package:test_task_cards/dependencies.dart';
import 'package:test_task_cards/features/cards/repos/cards_repo.dart';
import 'package:test_task_cards/features/progress/repos/progress_repo.dart';
import 'package:test_task_cards/features/home/widgets/home_screen.dart';

/// Builds the app with stubbed repositories so integration tests
/// run fully offline without a server.
///
/// Each call creates a fresh [_TestDependencies] with new repo instances,
/// so tests start with clean state.
Future<Widget> buildTestApp({ThemeMode initialThemeMode = ThemeMode.light}) async {
  final deps = _TestDependencies();
  await deps.init();
  return ThemeController(
    child: _TestApp(deps: deps, initialThemeMode: initialThemeMode),
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.deps, required this.initialThemeMode});

  final Dependencies deps;
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.of(context);
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: controller.themeMode,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => InheritedDependencies(dependencies: deps, child: child!),
      home: const HomeScreen(),
    );
  }
}

class _TestDependencies extends Dependencies {
  @override
  Future<void> init() async {
    putRepo<CardsRepo>(const CardsRepo$Stub());
    putRepo<ProgressRepo>(ProgressRepo$Stub());
  }
}
