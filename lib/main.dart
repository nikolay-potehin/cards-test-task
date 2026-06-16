import 'package:flutter/material.dart';
import 'package:test_task_cards/dependencies.dart';

import 'features/cards/cards.dart';
import 'features/progress/progress.dart';

Future<void> main() async {
  final deps = Dependencies();
  await deps.init();
  runApp(MainApp(deps: deps));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, required this.deps});

  final Dependencies deps;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const _screens = [CardsScreen(), ProgressScreen()];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => InheritedDependencies(dependencies: widget.deps, child: child!),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.style_outlined), label: 'Cards'),
            NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Progress'),
          ],
        ),
      ),
    );
  }
}
