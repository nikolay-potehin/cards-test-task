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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _ProgressMetric(title: 'Best streak', value: '${progress.bestStreak}'),
            _ProgressMetric(title: 'Current streak', value: '${progress.currentStreak}'),
            _ProgressMetric(title: 'Right answers', value: '${progress.correctCount}'),
            _ProgressMetric(title: 'Wrong answers', value: '${progress.incorrectCount}'),
            const SizedBox(height: 8),
            Text('Success rate', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Center(
              child: _SuccessRateRing(key: ValueKey(successRateLabel), progress: successRate, label: successRateLabel),
            ),
            const SizedBox(height: 8),
            _QuoteBlock(quote: quote),
            const SizedBox(height: 12),
            Text('Recent choices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No choices yet'))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final choice = history[index];
                    final wasCorrect = choice.isRightSwipe == choice.card.isCorrect;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${choice.card.word} -> ${choice.card.translation}'),
                      subtitle: Text(choice.isRightSwipe ? 'Swipe: right' : 'Swipe: left'),
                      trailing: Icon(
                        wasCorrect ? Icons.check_circle : Icons.cancel,
                        color: wasCorrect ? Colors.green : Colors.red,
                      ),
                    );
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

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
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
    return SizedBox.square(
      dimension: 128,
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
                  strokeWidth: 8,
                  constraints: BoxConstraints.tight(const Size.square(76)),
                  backgroundColor: Colors.red.withValues(alpha: 0.32),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
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

// # Generated by Copilot
