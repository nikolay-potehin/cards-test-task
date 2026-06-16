import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_task_cards/features/cards/controllers/cards_cubit.dart';
import 'package:test_task_cards/features/cards/models/card_model.dart';

class CardsView extends StatefulWidget {
  const CardsView({super.key});

  @override
  State<CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends State<CardsView> {
  static const _maxLeftDepthCards = 3;
  static const _swipeVelocity = 240.0;
  static const _swipeDistance = 90.0;
  static const _backtrackDistance = 30.0;
  static const _backtrackRatio = 0.25;
  static const _flyAwayDuration = Duration(milliseconds: 180);
  static const _backCardScale = 0.9;
  static const _maxOverlayOpacity = 0.3;

  Offset _dragOffset = Offset.zero;
  double _maxRightDx = 0;
  double _minLeftDx = 0;
  bool _isSwipeCompleting = false;
  bool _isInstantResetFrame = false;
  double _nextCardScale = _backCardScale;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardsCubit, CardsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!state.hasCards || state.currentCard == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No cards in deck'),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: () => context.read<CardsCubit>().restartDeck(), child: const Text('Restart')),
              ],
            ),
          );
        }

        final currentCard = state.currentCard!;
        final nextCard = state.nextCard;
        final leftDepthCount = _leftDepthCount(state);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardSize = Size(constraints.maxWidth * 0.7, constraints.maxHeight * 0.7);
              final dragOpacity = _overlayOpacity(_dragOffset, constraints.maxWidth);
              return Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ..._buildLeftDepthCards(count: leftDepthCount, cardSize: cardSize),
                    if (nextCard != null)
                      AnimatedScale(
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOut,
                        scale: _nextCardScale,
                        child: _CardTile(card: nextCard, size: cardSize),
                      ),
                    GestureDetector(
                      onPanStart: _isSwipeCompleting || _isInstantResetFrame ? null : (_) => _startDragTracking(),
                      onPanUpdate: _isSwipeCompleting || _isInstantResetFrame ? null : _onPanUpdate,
                      onPanEnd: _isSwipeCompleting || _isInstantResetFrame
                          ? null
                          : (details) => _onPanEnd(context, details),
                      child: AnimatedContainer(
                        duration: _isInstantResetFrame
                            ? Duration.zero
                            : _isSwipeCompleting
                            ? _flyAwayDuration
                            : const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        transform: Matrix4.identity()
                          ..translate(_dragOffset.dx, _dragOffset.dy)
                          ..rotateZ(_dragOffset.dx / 300 * 0.3),
                        child: Stack(
                          children: [
                            _CardTile(card: currentCard, size: cardSize),
                            Positioned.fill(
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _dragOffset.dx == 0
                                        ? Colors.transparent
                                        : _dragOffset.dx > 0
                                        ? Colors.green.withValues(alpha: dragOpacity)
                                        : Colors.red.withValues(alpha: dragOpacity),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
      _maxRightDx = _dragOffset.dx > _maxRightDx ? _dragOffset.dx : _maxRightDx;
      _minLeftDx = _dragOffset.dx < _minLeftDx ? _dragOffset.dx : _minLeftDx;
    });
  }

  Future<void> _onPanEnd(BuildContext context, DragEndDetails details) async {
    if (_isSwipeCompleting || _isInstantResetFrame) {
      return;
    }

    final velocityX = details.velocity.pixelsPerSecond.dx;
    final shouldSwipeRight = (velocityX > _swipeVelocity || _dragOffset.dx > _swipeDistance) && !_hasBacktrackedRight();
    if (shouldSwipeRight) {
      await _completeSwipe(context, isRight: true);
      return;
    }

    final shouldSwipeLeft = (velocityX < -_swipeVelocity || _dragOffset.dx < -_swipeDistance) && !_hasBacktrackedLeft();
    if (shouldSwipeLeft) {
      await _completeSwipe(context, isRight: false);
      return;
    }

    setState(() {
      _dragOffset = Offset.zero;
      _resetDragTracking();
    });
  }

  Future<void> _completeSwipe(BuildContext context, {required bool isRight}) async {
    final width = MediaQuery.of(context).size.width;
    setState(() {
      _isSwipeCompleting = true;
      _nextCardScale = 1;
      _dragOffset = Offset(isRight ? width : -width, _dragOffset.dy);
    });

    await Future<void>.delayed(_flyAwayDuration);
    if (!context.mounted) {
      return;
    }

    final cubit = context.read<CardsCubit>();
    if (isRight) {
      cubit.swipeRight();
    } else {
      cubit.swipeLeft();
    }

    setState(() {
      _isSwipeCompleting = false;
      _isInstantResetFrame = true;
      _dragOffset = Offset.zero;
      _nextCardScale = _backCardScale;
      _resetDragTracking();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInstantResetFrame = false;
      });
    });
  }

  double _overlayOpacity(Offset offset, double maxSwipeDistance) {
    if (offset == Offset.zero || maxSwipeDistance <= 0) {
      return 0;
    }
    final power = offset.distance;
    final halfMax = maxSwipeDistance * 0.5;
    final normalized = (power / halfMax).clamp(0.0, 1.0);
    return normalized * _maxOverlayOpacity;
  }

  void _startDragTracking() {
    _maxRightDx = _dragOffset.dx;
    _minLeftDx = _dragOffset.dx;
  }

  void _resetDragTracking() {
    _maxRightDx = 0;
    _minLeftDx = 0;
  }

  bool _hasBacktrackedRight() {
    if (_maxRightDx <= 0) {
      return false;
    }
    final retreat = _maxRightDx - _dragOffset.dx;
    return retreat > _backtrackDistance && retreat > _maxRightDx * _backtrackRatio;
  }

  bool _hasBacktrackedLeft() {
    if (_minLeftDx >= 0) {
      return false;
    }
    final retreat = _dragOffset.dx - _minLeftDx;
    return retreat > _backtrackDistance && retreat > _minLeftDx.abs() * _backtrackRatio;
  }

  int _leftDepthCount(CardsState state) {
    final remainingBehindNext = state.cards.length - state.currentIndex - 2;
    if (remainingBehindNext <= 0) {
      return 0;
    }
    return remainingBehindNext > _maxLeftDepthCards ? _maxLeftDepthCards : remainingBehindNext;
  }

  List<Widget> _buildLeftDepthCards({required int count, required Size cardSize}) {
    if (count <= 0) {
      return const [];
    }

    final cards = <Widget>[];
    for (var i = count - 1; i >= 0; i--) {
      final depth = i + 1;
      cards.add(
        Transform.translate(
          offset: Offset(-(8.0 + 4.5 * depth), depth * 0.8),
          child: Transform.rotate(
            angle: -0.04 * depth,
            child: _DeckDepthCard(size: Size(cardSize.width * _backCardScale, cardSize.height * _backCardScale)),
          ),
        ),
      );
    }
    return cards;
  }
}

class _DeckDepthCard extends StatelessWidget {
  const _DeckDepthCard({required this.size});

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.card, required this.size});

  final CardModel card;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      width: size.width,
      height: size.height,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.word, style: theme.headlineMedium),
          const SizedBox(height: 16),
          Text(card.translation, style: theme.headlineSmall),
        ],
      ),
    );
  }
}

// # Generated by Copilot
