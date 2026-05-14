import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/em_button.dart';

class MyLearningVaultScreen extends StatefulWidget {
  const MyLearningVaultScreen({super.key});

  @override
  State<MyLearningVaultScreen> createState() => _MyLearningVaultScreenState();
}

class _MyLearningVaultScreenState extends State<MyLearningVaultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isLoading = true;

  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _doubts = [];
  List<Map<String, dynamic>> _mindMaps = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadVault();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVault() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.instance.get('/vault');
      final data = result['data'] as Map<String, dynamic>;
      setState(() {
        _notes    = (data['notes']     as List?)?.cast<Map<String, dynamic>>() ?? [];
        _doubts   = (data['doubts']    as List?)?.cast<Map<String, dynamic>>() ?? [];
        _mindMaps = (data['mind_maps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      });
    } catch (_) {
      setState(() {
        _notes = [
          {'id': 'n1', 'title': 'Laws of Motion', 'body': 'Newton\'s three laws are the foundation of classical mechanics.', 'subject': 'Physics'},
          {'id': 'n2', 'title': 'Chemical Bonding', 'body': 'Ionic and covalent bonds.', 'subject': 'Chemistry'},
        ];
        _doubts = [
          {'id': 'd1', 'question': 'Why is sky blue?', 'status': 'resolved'},
          {'id': 'd2', 'question': 'What is quantum entanglement?', 'status': 'pending'},
        ];
        _mindMaps = [
          {'id': 'm1', 'title': 'Thermodynamics overview'},
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _createNote() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl  = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: bodyCtrl, decoration: const InputDecoration(hintText: 'Content...'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true && titleCtrl.text.isNotEmpty) {
      await ApiService.instance.post('/vault/notes', body: {'title': titleCtrl.text, 'body': bodyCtrl.text});
      _loadVault();
    }
  }

  Future<void> _deleteNote(String id) async {
    await ApiService.instance.delete('/vault/notes/$id');
    _loadVault();
  }

  Future<void> _aiSummary(List<String> noteIds) async {
    if (noteIds.isEmpty) return;
    final sm = ScaffoldMessenger.of(context);
    sm.showSnackBar(const SnackBar(content: Text('Generating AI summary...')));
    try {
      final r = await ApiService.instance.post('/vault/ai-summary', body: {'note_ids': noteIds});
      final summary = (r['data'] as Map)['summary'] as String? ?? '';
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('AI Summary'),
          content: SingleChildScrollView(child: Text(summary)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    } catch (e) {
      sm.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Learning Vault', style: AppTextStyles.headlineSm()),
                        Text('Notes, doubts & mind maps', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _createNote,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab bar ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.onSurfaceVariant,
                  labelStyle: AppTextStyles.labelSm(),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: 'Notes (${_notes.length})'),
                    Tab(text: 'Doubts (${_doubts.length})'),
                    Tab(text: 'Mind Maps'),
                  ],
                ),
              ),
            ),

            // ── Tab content ──────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Notes tab
                        _notes.isEmpty
                            ? _EmptyState(icon: '📝', message: 'No notes yet. Tap + to create one.')
                            : RefreshIndicator(
                                onRefresh: _loadVault,
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: pad),
                                  itemCount: _notes.length + 1,
                                  itemBuilder: (_, i) {
                                    if (i == _notes.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        child: EmButton(
                                          label: '✨ AI Summary (${_notes.length} notes)',
                                          onPressed: () => _aiSummary(_notes.map((n) => n['id'] as String).toList()),
                                        ),
                                      );
                                    }
                                    final n = _notes[i];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceContainerLowest,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.cardBorder),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(n['title'] as String? ?? '', style: AppTextStyles.labelMd()),
                                                if ((n['body'] as String?)?.isNotEmpty == true) ...[
                                                  const SizedBox(height: 4),
                                                  Text(n['body'] as String, style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ],
                                                if (n['subject'] != null) ...[
                                                  const SizedBox(height: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(4)),
                                                    child: Text(n['subject'] as String, style: AppTextStyles.caption().copyWith(color: AppColors.chipText)),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.onSurfaceVariant),
                                            onPressed: () => _deleteNote(n['id'] as String),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                        // Doubts tab
                        _doubts.isEmpty
                            ? _EmptyState(icon: '❓', message: 'No doubts logged yet.')
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: pad),
                                itemCount: _doubts.length,
                                itemBuilder: (_, i) {
                                  final d = _doubts[i];
                                  final resolved = d['status'] == 'resolved';
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: Text(d['question'] as String? ?? '', style: AppTextStyles.bodyMd())),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: resolved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            resolved ? 'Resolved' : 'Pending',
                                            style: AppTextStyles.caption().copyWith(
                                              color: resolved ? const Color(0xFF2E7D32) : const Color(0xFFF57F17),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),

                        // Mind maps tab
                        _mindMaps.isEmpty
                            ? _EmptyState(icon: '🗺️', message: 'No mind maps yet.')
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: pad),
                                itemCount: _mindMaps.length,
                                itemBuilder: (_, i) {
                                  final m = _mindMaps[i];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.cardBorder),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40, height: 40,
                                          decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.account_tree_outlined, color: AppColors.primaryContainer, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(m['title'] as String? ?? '', style: AppTextStyles.labelMd())),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String icon, message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
