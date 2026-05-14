import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/em_button.dart';

/// Battlefield Hub — leaderboard, open rooms, special ops, countdown.
/// The quiz game is in BattleQuizScreen (/battle/quiz).
class LearningBattlefieldScreen extends StatefulWidget {
  const LearningBattlefieldScreen({super.key});

  @override
  State<LearningBattlefieldScreen> createState() => _LearningBattlefieldState();
}

class _LearningBattlefieldState extends State<LearningBattlefieldScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _rooms       = [];
  List<Map<String, dynamic>> _specialOps  = [];
  int _countdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadBattle();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBattle() async {
    setState(() => _isLoading = true);
    try {
      final r = await ApiService.instance.get('/battle');
      final data = r['data'] as Map<String, dynamic>;
      setState(() {
        _leaderboard     = (data['leaderboard']     as List?)?.cast<Map<String, dynamic>>() ?? [];
        _rooms           = (data['open_rooms']       as List?)?.cast<Map<String, dynamic>>() ?? [];
        _specialOps      = (data['special_ops']      as List?)?.cast<Map<String, dynamic>>() ?? [];
        _countdownSeconds = (data['countdown_seconds'] as num?)?.toInt() ?? 0;
      });
      _startCountdown();
    } catch (_) {
      setState(() {
        _leaderboard = [
          {'name': 'Amann', 'xp': 4500, 'rank': 1, 'avatar_url': 'https://i.pravatar.cc/150?img=11'},
          {'name': 'Claude', 'xp': 4200, 'rank': 2, 'avatar_url': 'https://i.pravatar.cc/150?img=12'},
        ];
        _rooms = [
          {'id': 'r1', 'name': 'Physics Ninjas', 'subject': 'Physics', 'player_count': 2, 'max_players': 4, 'xp_reward': 500},
        ];
        _specialOps = [
          {'id': 'op1', 'title': 'Quantum Mechanics', 'difficulty': 'Hard', 'xp_reward': 500, 'cta_label': 'Attack!', 'cta_color': 'primary', 'is_active': true},
        ];
        _countdownSeconds = 3600;
      });
      _startCountdown();
    }
    setState(() => _isLoading = false);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdownSeconds <= 0) { _countdownTimer?.cancel(); return; }
      setState(() => _countdownSeconds--);
    });
  }

  String _fmtCountdown(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _joinRoom(String roomId) async {
    try {
      await ApiService.instance.post('/battle/rooms/$roomId/join');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined room!')));
      _loadBattle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _startSpecialOp(String opId) async {
    try {
      final r = await ApiService.instance.post('/battle/special-ops/$opId/start');
      final data = r['data'] as Map<String, dynamic>;
      if (!mounted) return;
      context.push('/battle/quiz', extra: data);
    } catch (e) {
      if (!mounted) return;
      // Mock data fallback for UI testing
      final mockData = {
        'attempt_id': 'mock_attempt',
        'questions': [
          {
            'question': 'What is the SI unit of Force?',
            'options': ['Joule', 'Newton', 'Watt', 'Pascal'],
            'correct_index': 1,
          },
          {
            'question': 'Which equation represents Newton\'s Second Law?',
            'options': ['E=mc^2', 'v=u+at', 'F=ma', 'W=Fd'],
            'correct_index': 2,
          },
        ]
      };
      context.push('/battle/quiz', extra: mockData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primaryContainer,
          onRefresh: _loadBattle,
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
              : CustomScrollView(
                  slivers: [
                    // ── Hero header ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(pad, 20, pad, 0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚔️', style: TextStyle(fontSize: 36)),
                            const SizedBox(height: 8),
                            Text('Learning Battlefield', style: AppTextStyles.headlineSm(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('Next tournament in', style: AppTextStyles.bodySm(color: Colors.white54)),
                            const SizedBox(height: 8),
                            Text(_fmtCountdown(_countdownSeconds),
                                style: const TextStyle(color: Color(0xFFE8B923), fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 3)),
                          ],
                        ),
                      ),
                    ),

                    // ── Special Ops ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, 24, pad, 8),
                        child: Text('⚡ Special Ops', style: AppTextStyles.headlineSm()),
                      ),
                    ),
                    if (_specialOps.isEmpty)
                      SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: pad), child: Text('No active ops.', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)))),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final op = _specialOps[i];
                          final color = op['cta_color'] == 'amber' ? const Color(0xFFF59E0B) : AppColors.primaryContainer;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.local_fire_department_rounded, color: color),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(op['title'] as String? ?? '', style: AppTextStyles.labelMd()),
                                      Text('${op['xp_reward']} XP • ${op['difficulty'] ?? 'Medium'}',
                                          style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                                    ]),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _startSpecialOp(op['id'] as String),
                                    style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, minimumSize: const Size(80, 36)),
                                    child: Text(op['cta_label'] as String? ?? 'Start', style: const TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: _specialOps.length,
                      ),
                    ),

                    // ── Quick battle (use mockQuiz) ────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
                        child: Text('🏆 Open Rooms', style: AppTextStyles.headlineSm()),
                      ),
                    ),
                    if (_rooms.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: pad),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('No open rooms right now.', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 12),
                              EmButton(
                                label: '+ Create Room',
                                onPressed: () => _showCreateRoom(context),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final room = _rooms[i];
                            final players = (room['player_count'] as num?)?.toInt() ?? 0;
                            final max = (room['max_players'] as num?)?.toInt() ?? 4;
                            return Padding(
                              padding: EdgeInsets.fromLTRB(pad, 0, pad, 12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.cardBorder),
                                ),
                                child: Row(children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(room['name'] as String? ?? '', style: AppTextStyles.labelMd()),
                                    Text('${room['subject']} · $players/$max players · ${room['xp_reward']} XP',
                                        style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                                  ])),
                                  OutlinedButton(
                                    onPressed: () => _joinRoom(room['id'] as String),
                                    style: OutlinedButton.styleFrom(minimumSize: const Size(80, 36)),
                                    child: const Text('Join'),
                                  ),
                                ]),
                              ),
                            );
                          },
                          childCount: _rooms.length,
                        ),
                      ),

                    // ── Leaderboard ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, 24, pad, 8),
                        child: Text('🥇 Global Leaderboard', style: AppTextStyles.headlineSm()),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          final user = _leaderboard[i];
                          final rank = (user['rank'] as num?)?.toInt() ?? i + 1;
                          final rankEmoji = rank == 1 ? '🥇' : rank == 2 ? '🥈' : rank == 3 ? '🥉' : '#$rank';
                          return Padding(
                            padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
                            child: Row(children: [
                              SizedBox(width: 36, child: Text(rankEmoji, style: AppTextStyles.labelMd(), textAlign: TextAlign.center)),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primaryFixed,
                                backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url'] as String) : null,
                                child: user['avatar_url'] == null ? Text((user['name'] as String? ?? 'U')[0]) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(user['name'] as String? ?? '', style: AppTextStyles.labelMd())),
                              Text('${user['xp']} XP', style: AppTextStyles.labelSm(color: AppColors.primaryContainer)),
                            ]),
                          );
                        },
                        childCount: _leaderboard.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
        ),
      ),
    );
  }

  void _showCreateRoom(BuildContext ctx) {
    final nameCtrl    = TextEditingController();
    String subject    = 'Physics';
    const subjects    = ['Physics', 'Mathematics', 'Chemistry', 'Biology'];

    showModalBottomSheet(
      context: ctx,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bCtx) => StatefulBuilder(
        builder: (bCtx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Battle Room', style: AppTextStyles.headlineSm()),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Room name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: subject,
                items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setModalState(() => subject = v!),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.isNotEmpty) {
                      await ApiService.instance.post('/battle/rooms', body: {'name': nameCtrl.text, 'subject': subject});
                      if (bCtx.mounted) Navigator.pop(bCtx);
                      _loadBattle();
                    }
                  },
                  child: const Text('Create Room'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
