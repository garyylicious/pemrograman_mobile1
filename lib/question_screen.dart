import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'view_model.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  late final QuizViewModel viewModel = QuizViewModel(
    onGameOver: _handleGameOver,
  );
  VoidCallback? _showGameOverScreen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            actions: [
              TextButton(
                onPressed:
                    viewModel.hasNextQuestion && viewModel.didAnswerQuestion
                    ? () {
                        viewModel.getNextQuestion();
                      }
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
          body: Center(
            child: Column(
              children: [
                QuestionCard(
                  onChangeOpenContainer: _handleChangeOpenContainer,
                  question: viewModel.currentQuestion?.question,
                  viewModel: viewModel,
                ),
                Spacer(),
                AnswerCards(
                  onTapped: (index) {
                    viewModel.checkAnswer(index);
                  },
                  answers: viewModel.currentQuestion?.possibleAnswers ?? [],
                  correctAnswer: viewModel.didAnswerQuestion
                      ? viewModel.currentQuestion?.correctAnswer
                      : null,
                ),
                StatusBar(viewModel: viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleChangeOpenContainer(VoidCallback openContainer) {
    _showGameOverScreen = openContainer;
  }

  void _handleGameOver() {
    if (_showGameOverScreen != null) {
      _showGameOverScreen!();
    }
  }
}

class GameOverScreen extends StatelessWidget {
  final QuizViewModel viewModel;

  const GameOverScreen({required this.viewModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < viewModel.totalQuestions; i++)
                  AnimatedScoreIcon(isActive: i < viewModel.score),
              ],
            ),
            Text('You Win!', style: Theme.of(context).textTheme.displayLarge),
            Text(
              'Score: ${viewModel.score} / ${viewModel.totalQuestions}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final String? question;
  final ValueChanged<VoidCallback> onChangeOpenContainer;
  final QuizViewModel viewModel;

  const QuestionCard({
    required this.onChangeOpenContainer,
    required this.question,
    required this.viewModel,
    super.key,
  });

  static const _backgroundColor = Color(0xfff2f3fa);

  @override
  Widget build(BuildContext context) {
    return PageTransitionSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      child: OpenContainer(
        key: ValueKey(question),
        tappable: false,
        closedColor: _backgroundColor,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12.0)),
        ),
        closedElevation: 4,
        closedBuilder: (context, openContainer) {
          onChangeOpenContainer(openContainer);
          return ColoredBox(
            color: _backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                question ?? '',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
          );
        },
        openBuilder: (context, closeContainer) {
          return GameOverScreen(viewModel: viewModel);
        },
      ),
    );
  }
}

class AnswerCards extends StatelessWidget {
  final List<String> answers;
  final ValueChanged<int> onTapped;
  final int? correctAnswer;

  const AnswerCards({
    required this.answers,
    required this.onTapped,
    required this.correctAnswer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 5 / 2,
      children: List.generate(answers.length, (index) {
        var color = Theme.of(context).colorScheme.primaryContainer;
        if (correctAnswer == index) {
          color = Theme.of(context).colorScheme.tertiaryContainer;
        }
        final isCorrect = correctAnswer == index;
        return CardFlipEffect(
          delayAmount: index.toDouble() / 2,
          duration: const Duration(milliseconds: 300),
          child: AnswerFeedbackAnimation(
            key: ValueKey(answers[index]),
          isSelected: correctAnswer != null,
          isCorrect: isCorrect,
          child: Card.filled(
            key: ValueKey(answers[index]),
              color: color,
              elevation: 2,
              margin: EdgeInsets.all(8),
              clipBehavior: Clip.hardEdge,
              child: InkWell(
                onTap: () => onTapped(index),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      answers.length > index ? answers[index] : '',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class StatusBar extends StatelessWidget {
  final QuizViewModel viewModel;

  const StatusBar({required this.viewModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < viewModel.totalQuestions; i++)
              AnimatedScoreIcon(isActive: i < viewModel.score),
          ],
        ),
      ),
    );
  }
}

class AnimatedScoreIcon extends StatelessWidget {
  final bool isActive;
  final Duration _duration = const Duration(milliseconds: 1000);
  final Curve _curve = Curves.elasticOut;

  AnimatedScoreIcon({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.0 : 0.5,
      curve: _curve,
      duration: _duration,
      child: TweenAnimationBuilder<Color?>(
        curve: _curve,
        duration: _duration,
        tween: ColorTween(
          begin: Colors.grey.shade400,
          end: isActive ? Colors.teal : Colors.grey.shade400,
        ),
        builder: (context, Color? value, child) {
          return Icon(Icons.emoji_events, size: 50, color: value);
        },
      ),
    );
  }
}

class CardFlipEffect extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double delayAmount;

  const CardFlipEffect({
    super.key,
    required this.child,
    required this.duration,
    required this.delayAmount,
  });

  @override
  State<CardFlipEffect> createState() => _CardFlipEffectState();
}

class _CardFlipEffectState extends State<CardFlipEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  Widget? _previousChild;
  late final Animation<double> _animationWithDelay;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration * (widget.delayAmount + 1),
    );
    _animationController.addListener(() {
      if (_animationController.value == 1) {
        _animationController.reset();
      }
    });
    _animationWithDelay = TweenSequence<double>([
      if (widget.delayAmount > 0)
        TweenSequenceItem(
          tween: ConstantTween<double>(0.0),
          weight: widget.delayAmount,
        ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        weight: 1.0,
      ),
    ]).animate(_animationController);
  }

  @override
  void didUpdateWidget(covariant CardFlipEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child.key != oldWidget.child.key) {
      _handleChildChanged(widget.child, oldWidget.child);
    }
  }

  void _handleChildChanged(Widget newChild, Widget previousChild) {
    _previousChild = previousChild;
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationWithDelay,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..rotateX(_animationWithDelay.value * math.pi),
          child: _animationController.isAnimating
              ? _animationWithDelay.value < 0.5
                  ? _previousChild
                  : Transform.flip(flipY: true, child: child)
              : child,
        );
      },
      child: widget.child,
    );
  }
}

class AnswerFeedbackAnimation extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool isCorrect;

  const AnswerFeedbackAnimation({
    super.key,
    required this.child,
    required this.isSelected,
    required this.isCorrect,
  });

  @override
  State<AnswerFeedbackAnimation> createState() =>
      _AnswerFeedbackAnimationState();
}

class _AnswerFeedbackAnimationState extends State<AnswerFeedbackAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(covariant AnswerFeedbackAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        if (!widget.isSelected || _controller.isDismissed) {
          return child!;
        }
        if (widget.isCorrect) {
          // Efek membal (scale spring bounce) untuk jawaban benar
          final scale = 1.0 + (0.08 * math.sin(_controller.value * math.pi));
          return Transform.scale(scale: scale, child: child);
        } else {
          // Efek bergoyang (horizontal shake) untuk jawaban salah
          final offset =
              6.0 * math.sin(_controller.value * math.pi * 4) * (1 - _controller.value);
          return Transform.translate(offset: Offset(offset, 0), child: child);
        }
      },
      child: widget.child,
    );
  }
}
