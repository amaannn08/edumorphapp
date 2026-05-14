import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../shared/widgets/em_button.dart';

class BattleQuizScreen extends StatefulWidget {
  final String attemptId;
  final List<Map<String, dynamic>> questions;

  const BattleQuizScreen({
    super.key,
    required this.attemptId,
    required this.questions,
  });

  @override
  State<BattleQuizScreen> createState() => _BattleQuizScreenState();
}

class _BattleQuizScreenState extends State<BattleQuizScreen>
    with TickerProviderStateMixin {
  int _qIndex = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0;
  int _streak = 0;
  int _timeLeft = 20;
  bool _done = false;
  Timer? _timer;
  late AnimationController _progressAnim;

  List<Map<String, dynamic>> get _questions => widget.questions;

  @override
  void initState() {
    super.initState();
    _progressAnim = AnimationController(vsync: this, duration: const Duration(seconds: 20))..forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 20;
    _progressAnim..reset()..forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 0) { t.cancel(); _handleAnswer(null); return; }
      setState(() => _timeLeft--);
    });
  }

  void _handleAnswer(int? choice) {
    if (_answered || _questions.isEmpty) return;
    _timer?.cancel();
    final q = _questions[_qIndex];
    final correct = (q['correct_index'] as num?)?.toInt() ?? -1;
    setState(() {
      _selected = choice;
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
    if (_qIndex >= _questions.length - 1) {
      setState(() => _done = true);
      return;
    }
    setState(() {
      _qIndex++;
      _selected = null;
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
    if (_done) return _ResultScreen(score: _score, total: _questions.length, onRestart: () => context.pop());
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No questions available', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 24),
            EmButton(label: 'Go Back', onPressed: () => context.pop()),
          ],
        )),
      );
    }

    final pad = context.pagePadding;
    final q   = _questions[_qIndex];
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    final correct = (q['correct_index'] as num?)?.toInt() ?? -1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Top bar
              Row(children: [
                Text('⚔️ Battle Mode', style: AppTextStyles.headlineSm()),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: AppColors.primaryContainer, size: 16),
                    const SizedBox(width: 4),
                    Text('$_score XP', style: AppTextStyles.labelMd(color: AppColors.primaryContainer)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Text('Question ${_qIndex + 1} of ${_questions.length}', style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),

              // Timer bar
              Row(children: [
                Expanded(
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => Stack(children: [
                      Container(height: 8, decoration: BoxDecoration(color: AppColors.outlineVariant, borderRadius: BorderRadius.circular(999))),
                      FractionallySizedBox(
                        widthFactor: (1 - _progressAnim.value).clamp(0.0, 1.0),
                        child: Container(height: 8, decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(colors: _timeLeft > 8
                              ? [AppColors.primaryContainer, AppColors.primary]
                              : [Colors.red.shade700, Colors.red.shade400]),
                        )),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: AppTextStyles.headlineSm(color: _timeLeft <= 5 ? Colors.red : AppColors.onSurface),
                  child: Text('$_timeLeft'),
                ),
              ]),
              const SizedBox(height: 24),

              // Streak banner
              if (_streak > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(8)),
                  child: Text('🔥 $_streak-answer streak! +${_streak * 2} bonus XP',
                      style: AppTextStyles.labelMd(color: Color(0xFFF57F17))),
                ),

              // Question card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Text(q['question'] as String? ?? '', style: AppTextStyles.headlineSm()),
              ),
              const SizedBox(height: 20),

              // Answer options
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    Color bg, border, text = AppColors.onSurface;
                    if (_answered) {
                      if (i == correct)      { bg = const Color(0xFFE8F5E9); border = const Color(0xFF2E7D32); text = const Color(0xFF2E7D32); }
                      else if (i == _selected) { bg = const Color(0xFFFFEBEE); border = AppColors.error; text = AppColors.error; }
                      else { bg = AppColors.surfaceContainerLow; border = AppColors.outlineVariant; text = AppColors.onSurfaceVariant; }
                    } else if (_selected == i) {
                      bg = AppColors.primaryFixed; border = AppColors.primaryContainer;
                    } else {
                      bg = AppColors.surfaceContainerLowest; border = AppColors.cardBorder;
                    }

                    return GestureDetector(
                      onTap: _answered ? null : () => _handleAnswer(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)),
                        child: Row(children: [
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(color: border.withValues(alpha: 0.15), shape: BoxShape.circle),
                            child: Center(child: Text(String.fromCharCode(65 + i), style: AppTextStyles.labelMd(color: border))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(options[i], style: AppTextStyles.bodyMd(color: text))),
                          if (_answered)
                            Icon(i == correct ? Icons.check_circle_rounded : (i == _selected ? Icons.cancel_rounded : null),
                                color: i == correct ? const Color(0xFF2E7D32) : AppColors.error, size: 20),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              if (_answered) ...[
                const SizedBox(height: 16),
                EmButton(
                  label: _qIndex == _questions.length - 1 ? 'See Results →' : 'Next Question →',
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

class _ResultScreen extends StatelessWidget {
  final int score, total;
  final VoidCallback onRestart;
  const _ResultScreen({required this.score, required this.total, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? score / (total * 10) : 0.0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(pct >= 0.8 ? '🏆' : pct >= 0.5 ? '⭐' : '💪', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(pct >= 0.8 ? 'Excellent!' : pct >= 0.5 ? 'Good Job!' : 'Keep Practicing!', style: AppTextStyles.headlineLg()),
              const SizedBox(height: 8),
              Text('You scored $score / ${total * 10} XP', style: AppTextStyles.bodyLg(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 48),
              EmButton(label: 'Back to Battlefield', onPressed: onRestart),
            ],
          ),
        ),
      ),
    );
  }
}
