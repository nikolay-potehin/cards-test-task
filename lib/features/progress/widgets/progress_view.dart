import 'package:flutter/material.dart';
import 'package:test_task_cards/dependencies.dart';
import 'package:test_task_cards/features/progress/models/progress_model.dart';
import 'package:test_task_cards/features/progress/repos/progress_repo.dart';

typedef _ProgressDrawerData = ({ProgressModel progress, List<CardSwipeChoice> history});

const _quotesByRateTier = <List<String>>[
  [
    'Every expert was once a beginner. Keep going.',
    'Small wins today build big wins tomorrow.',
    'Progress starts when you decide not to quit.',
    'You are training consistency, not perfection.',
    'One correct answer is already momentum.',
  ],
  [
    'You are getting traction. Stay steady.',
    'Your effort is turning into measurable growth.',
    'This is the stage where persistence pays off.',
    'You are stronger than your last mistake.',
    'Keep stacking correct choices, one by one.',
  ],
  [
    'Solid rhythm. Keep sharpening your focus.',
    'You are past random luck. This is skill.',
    'Halfway and rising. Great control so far.',
    'Consistency is becoming your advantage.',
    'You are building a reliable learning pace.',
  ],
  [
    'Excellent form. You are in command.',
    'High accuracy comes from disciplined reps.',
    'You are close to elite territory.',
    'Strong performance. Stay calm and precise.',
    'This level reflects serious commitment.',
  ],
  [
    'Outstanding work. You are operating at a high level.',
    'Top-tier focus. Keep that standard.',
    'You are turning preparation into mastery.',
    'Elite accuracy. Maintain the pressure.',
    'This is championship-level consistency.',
  ],
];

class ProgressView extends StatelessWidget {
  const ProgressView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Dependencies.of(context).repo<ProgressRepo>();
    return FutureBuilder<_ProgressDrawerData>(
      future: _loadDrawerData(repo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Failed to load history'));
        }

        final progress = data.progress;
        final history = data.history;
        final successRate = progress.accuracy.clamp(0.0, 1.0);
        final successRateLabel = '${(successRate * 100).toStringAsFixed(1)}%';
        final quote = _quoteForSuccessRate(successRate: successRate);
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Best streak',
                    value: '${progress.bestStreak}',
                    icon: Icons.local_fire_department,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(title: 'Current', value: '${progress.currentStreak}', icon: Icons.bolt),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Right',
                    value: '${progress.correctCount}',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricCard(
                    title: 'Wrong',
                    value: '${progress.incorrectCount}',
                    icon: Icons.cancel,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: _SuccessRateRing(key: ValueKey(successRateLabel), progress: successRate, label: successRateLabel),
            ),
            const SizedBox(height: 20),
            _QuoteBlock(quote: quote),
            const SizedBox(height: 16),
            Text('Recent choices', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No choices yet'))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final choice = history[index];
                    final wasCorrect = choice.isRightSwipe == choice.card.isCorrect;
                    return _HistoryItem(choice: choice, wasCorrect: wasCorrect);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<_ProgressDrawerData> _loadDrawerData(ProgressRepo repo) async {
    final progressResult = await repo.readProgress();
    final historyResult = await repo.loadHistory();

    return (
      progress: progressResult.when(
        ok: (data) => data,
        err: (_, _) =>
            const ProgressModel(json: null, currentStreak: 0, bestStreak: 0, correctCount: 0, incorrectCount: 0),
      ),
      history: historyResult.when(ok: (data) => data, err: (_, _) => const <CardSwipeChoice>[]),
    );
  }

  String _quoteForSuccessRate({required double successRate}) {
    final percent = successRate * 100;
    final tier = (percent ~/ 20).clamp(0, _quotesByRateTier.length - 1);
    final tierQuotes = List.of(_quotesByRateTier[tier])..shuffle();
    return tierQuotes.first;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.icon, this.color});

  final String title, value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRateRing extends StatelessWidget {
  const _SuccessRateRing({super.key, required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) {
              return Transform.flip(
                flipX: true,
                child: CircularProgressIndicator(
                  value: value,
                  strokeCap: StrokeCap.round,
                  strokeWidth: 10,
                  constraints: BoxConstraints.tight(const Size.square(120)),
                  backgroundColor: Colors.red.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.headlineSmall),
              Text('win rate', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.quote});

  final String quote;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Text('"$quote"', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.choice, required this.wasCorrect});

  final CardSwipeChoice choice;
  final bool wasCorrect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(wasCorrect ? Icons.check_circle : Icons.cancel, color: wasCorrect ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${choice.card.word} → ${choice.card.translation}', style: theme.textTheme.bodyMedium),
                Text(choice.isRightSwipe ? 'Swiped right' : 'Swiped left', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// # Generated by Copilot
