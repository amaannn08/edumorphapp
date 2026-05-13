import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/em_button.dart';

class LearningBattleScreen extends StatefulWidget {
  const LearningBattleScreen({super.key});

  @override
  State<LearningBattleScreen> createState() => _LearningBattleScreenState();
}

class _LearningBattleScreenState extends State<LearningBattleScreen>
    with TickerProviderStateMixin {
  int _questionIndex = 0;
  int? _selectedAnswer;
  bool _answered = false;
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 20;
  bool _gameOver = false;
  Timer? _timer;

  late AnimationController _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 20;
    _progressAnim
      ..reset()
      ..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 0) {
        t.cancel();
        _handleAnswer(null); // time out = wrong
        return;
      }
      setState(() => _timeLeft--);
    });
  }

  void _handleAnswer(int? choice) {
    if (_answered) return;
    _timer?.cancel();
    final correct = mockQuizQuestions[_questionIndex].correctIndex;
    setState(() {
      _selectedAnswer = choice;
      _answered = true;
      if (choice == correct) {
        _score += 10 + _streak * 2;
        _streak++;
      } else {
        _streak = 0;
      }
    });
  }

  void _next() {
    if (_questionIndex >= mockQuizQuestions.length - 1) {
      setState(() => _gameOver = true);
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedAnswer = null;
      _answered = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    if (_gameOver) return _GameOverScreen(score: _score, total: mockQuizQuestions.length * 10);

    final question = mockQuizQuestions[_questionIndex];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Top Bar ──────────────────────────────────────────
              Row(
                children: [
                  Text('⚔️ Battle Mode',
                      style: AppTextStyles.headlineSm()),
                  const Spacer(),
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.primaryContainer, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_score XP',
                          style: AppTextStyles.labelMd(
                              color: AppColors.primaryContainer),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Question counter
              Text(
                'Question ${_questionIndex + 1} of ${mockQuizQuestions.length}',
                style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              // ── Timer Bar ────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressAnim,
                      builder: (_, __) {
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.outlineVariant,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (1 - _progressAnim.value).clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: _timeLeft > 8
                                        ? [AppColors.primaryContainer, AppColors.primary]
                                        : [Colors.red.shade700, Colors.red.shade400],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: AppTextStyles.headlineSm(
                      color: _timeLeft <= 5 ? Colors.red : AppColors.onSurface,
                    ),
                    child: Text('$_timeLeft'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Streak ───────────────────────────────────────────
              if (_streak > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🔥 $_streak-answer streak! +${_streak * 2} bonus XP',
                    style: AppTextStyles.labelMd(color: Color(0xFFF57F17)),
                  ),
                ),

              // ── Question Card ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  question.question,
                  style: AppTextStyles.headlineSm(),
                ),
              ),
              const SizedBox(height: 20),

              // ── Options ──────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    Color bgColor;
                    Color borderColor;
                    Color textColor = AppColors.onSurface;

                    if (_answered) {
                      if (i == question.correctIndex) {
                        bgColor = const Color(0xFFE8F5E9);
                        borderColor = const Color(0xFF2E7D32);
                        textColor = const Color(0xFF2E7D32);
                      } else if (i == _selectedAnswer) {
                        bgColor = const Color(0xFFFFEBEE);
                        borderColor = AppColors.error;
                        textColor = AppColors.error;
                      } else {
                        bgColor = AppColors.surfaceContainerLow;
                        borderColor = AppColors.outlineVariant;
                        textColor = AppColors.onSurfaceVariant;
                      }
                    } else if (_selectedAnswer == i) {
                      bgColor = AppColors.primaryFixed;
                      borderColor = AppColors.primaryContainer;
                    } else {
                      bgColor = AppColors.surfaceContainerLowest;
                      borderColor = AppColors.cardBorder;
                    }

                    return GestureDetector(
                      onTap: _answered ? null : () => _handleAnswer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: borderColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + i), // A B C D
                                  style: AppTextStyles.labelMd(color: borderColor),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.options[i],
                                style: AppTextStyles.bodyMd(color: textColor),
                              ),
                            ),
                            if (_answered)
                              Icon(
                                i == question.correctIndex
                                    ? Icons.check_circle_rounded
                                    : (i == _selectedAnswer
                                        ? Icons.cancel_rounded
                                        : null),
                                color: i == question.correctIndex
                                    ? const Color(0xFF2E7D32)
                                    : AppColors.error,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Next Button ──────────────────────────────────────
              if (_answered) ...[
                const SizedBox(height: 16),
                EmButton(
                  label: _questionIndex == mockQuizQuestions.length - 1
                      ? 'See Results →'
                      : 'Next Question →',
                  onPressed: _next,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameOverScreen extends StatelessWidget {
  final int score;
  final int total;

  const _GameOverScreen({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = score / total;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pct >= 0.8 ? '🏆' : pct >= 0.5 ? '⭐' : '💪',
                style: const TextStyle(fontSize: 72),
              ),
              const SizedBox(height: 20),
              Text(
                pct >= 0.8
                    ? 'Excellent!'
                    : pct >= 0.5
                        ? 'Good Job!'
                        : 'Keep Practicing!',
                style: AppTextStyles.headlineLg(),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $score / $total XP',
                style: AppTextStyles.bodyLg(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 48),
              EmButton(
                label: 'Play Again',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LearningBattleScreen()),
                ),
              ),
              const SizedBox(height: 16),
              EmButton(
                label: 'Back to Home',
                variant: EmButtonVariant.ghost,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
