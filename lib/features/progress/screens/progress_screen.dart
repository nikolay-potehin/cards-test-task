import 'package:flutter/material.dart';

import '../widgets/progress_view.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: ProgressView());
  }
}
