import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/services/api_service.dart';

/// The Vault is a 3-level drill-down:
///   Level 0 — Subject grid
///   Level 1 — Chapter list (for a selected subject)
///   Level 2 — Content tabs (for a selected chapter)
class MyLearningVaultScreen extends StatefulWidget {
  /// When provided (e.g. navigated from Home), jumps straight to Level 1.
  final String? initialSubject;
  const MyLearningVaultScreen({super.key, this.initialSubject});

  @override
  State<MyLearningVaultScreen> createState() => _MyLearningVaultScreenState();
}

class _MyLearningVaultScreenState extends State<MyLearningVaultScreen>
    with SingleTickerProviderStateMixin {
  // ── State machine ────────────────────────────────────────────────────────────
  int _level = 0;
  SubjectModel? _selectedSubject;
  ChapterModel? _selectedChapter;

  // ── Data ─────────────────────────────────────────────────────────────────────
  List<SubjectModel> _subjects = [];
  List<ChapterModel> _chapters = [];
  List<ContentItemModel> _content = [];
  bool _isLoading = true;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadSubjects();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ── Loaders ──────────────────────────────────────────────────────────────────

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.instance.get('/subjects');
      final rows = (res['data'] as List).cast<Map<String, dynamic>>();
      _subjects = rows.map(SubjectModel.fromJson).toList();
    } catch (_) {
      _subjects = mockSubjects;
    }
    // If initialSubject provided, find it and jump to level 1
    if (widget.initialSubject != null) {
      final match = _subjects.firstWhere(
        (s) => s.name == widget.initialSubject,
        orElse: () => _subjects.first,
      );
      _selectedSubject = match;
      await _loadChapters(match);
      return;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadChapters(SubjectModel subject) async {
    setState(() { _isLoading = true; _selectedSubject = subject; });
    try {
      final res = await ApiService.instance.get('/subjects/${subject.id}/chapters');
      final rows = (res['data'] as List).cast<Map<String, dynamic>>();
      _chapters = rows.map(ChapterModel.fromJson).toList();
    } catch (_) {
      _chapters = mockChapters[subject.id] ?? [];
    }
    if (mounted) setState(() { _isLoading = false; _level = 1; });
  }

  Future<void> _loadContent(ChapterModel chapter) async {
    setState(() { _isLoading = true; _selectedChapter = chapter; });
    try {
      final res = await ApiService.instance.get('/chapters/${chapter.id}/content');
      final rows = (res['data'] as List).cast<Map<String, dynamic>>();
      _content = rows.map(ContentItemModel.fromJson).toList();
    } catch (_) {
      _content = mockContent[chapter.id] ?? [];
    }
    _tabCtrl.animateTo(0);
    if (mounted) setState(() { _isLoading = false; _level = 2; });
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  void _goBack() {
    setState(() {
      if (_level == 2) { _level = 1; _selectedChapter = null; }
      else if (_level == 1) { _level = 0; _selectedSubject = null; _chapters = []; }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(children: [
          // Header
          _VaultHeader(
            level: _level,
            subject: _selectedSubject,
            chapter: _selectedChapter,
            onBack: _level > 0 ? _goBack : null,
            onClose: widget.initialSubject != null ? () => context.pop() : null,
          ),
          // Content
          Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
            : _buildLevel(pad),
          ),
        ]),
      ),
    );
  }

  Widget _buildLevel(double pad) {
    switch (_level) {
      case 0: return _SubjectGrid(subjects: _subjects, pad: pad, onTap: _loadChapters);
      case 1: return _ChapterList(chapters: _chapters, pad: pad, onTap: _loadContent);
      case 2: return _ContentView(content: _content, tabCtrl: _tabCtrl, pad: pad);
      default: return const SizedBox();
    }
  }
}

// ── Vault Header ──────────────────────────────────────────────────────────────

class _VaultHeader extends StatelessWidget {
  final int level;
  final SubjectModel? subject;
  final ChapterModel? chapter;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  const _VaultHeader({required this.level, this.subject, this.chapter, this.onBack, this.onClose});

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    String title, subtitle;
    if (level == 0) { title = 'Vault'; subtitle = 'Browse your learning library'; }
    else if (level == 1) { title = subject?.name ?? 'Chapters'; subtitle = '${subject?.icon ?? ''} Select a chapter'; }
    else { title = chapter?.title ?? 'Content'; subtitle = subject?.name ?? ''; }

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
      child: Row(children: [
        if (onBack != null) ...[
          IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: onBack, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
          const SizedBox(width: 8),
        ],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyles.headlineSm()),
          Text(subtitle, style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
        ])),
        if (onClose != null)
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: onClose),
      ]),
    );
  }
}

// ── Level 0: Subject Grid ─────────────────────────────────────────────────────

class _SubjectGrid extends StatelessWidget {
  final List<SubjectModel> subjects;
  final double pad;
  final void Function(SubjectModel) onTap;
  const _SubjectGrid({required this.subjects, required this.pad, required this.onTap});

  Color _hex(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2,
        ),
        itemCount: subjects.length,
        itemBuilder: (_, i) {
          final s = subjects[i];
          final c = _hex(s.colorHex);
          return GestureDetector(
            onTap: () => onTap(s),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [c.withValues(alpha: 0.18), c.withValues(alpha: 0.06)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.withValues(alpha: 0.3)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s.icon, style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  _CountBadge(label: '${s.chapterCount} ch', color: c),
                ]),
                const Spacer(),
                Text(s.name, style: AppTextStyles.headlineSm(), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(children: [
                  _ContentStat(icon: Icons.play_circle_outline_rounded, count: s.videoCount, color: c),
                  const SizedBox(width: 6),
                  _ContentStat(icon: Icons.description_outlined, count: s.noteCount, color: c),
                  const SizedBox(width: 6),
                  _ContentStat(icon: Icons.schema_outlined, count: s.mindmapCount, color: c),
                  const SizedBox(width: 6),
                  _ContentStat(icon: Icons.functions_rounded, count: s.formulaCount, color: c),
                ]),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ── Level 1: Chapter List ─────────────────────────────────────────────────────

class _ChapterList extends StatelessWidget {
  final List<ChapterModel> chapters;
  final double pad;
  final void Function(ChapterModel) onTap;
  const _ChapterList({required this.chapters, required this.pad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) {
      return const _EmptyState(icon: '📚', message: 'No chapters available yet.');
    }
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 4,
        crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.9,
      ),
      itemCount: chapters.length,
      itemBuilder: (_, i) {
        final ch = chapters[i];
        return GestureDetector(
          onTap: () => onTap(ch),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('${i + 1}', style: AppTextStyles.headlineSm(color: AppColors.primaryContainer))),
              ),
              const Spacer(),
              Text(ch.title, style: AppTextStyles.labelMd(), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6, runSpacing: 6,
                children: [
                  if (ch.videosCount > 0) _CountPill(icon: Icons.play_circle_outline_rounded, count: ch.videosCount, label: 'Vid'),
                  if (ch.notesCount > 0) _CountPill(icon: Icons.description_outlined, count: ch.notesCount, label: 'Doc'),
                  if (ch.mindMapsCount > 0) _CountPill(icon: Icons.schema_outlined, count: ch.mindMapsCount, label: 'Map'),
                  if (ch.formulasCount > 0) _CountPill(icon: Icons.functions_rounded, count: ch.formulasCount, label: 'Fml'),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ── Level 2: Content Tabs ─────────────────────────────────────────────────────

class _ContentView extends StatelessWidget {
  final List<ContentItemModel> content;
  final TabController tabCtrl;
  final double pad;
  const _ContentView({required this.content, required this.tabCtrl, required this.pad});

  List<ContentItemModel> _filter(ContentType type) => content.where((c) => c.type == type).toList();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tab bar
      Padding(
        padding: EdgeInsets.fromLTRB(pad, 16, pad, 0),
        child: Container(
          height: 40,
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
          child: TabBar(
            controller: tabCtrl,
            indicator: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(999)),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            labelStyle: AppTextStyles.labelSm(),
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: '🎬 Videos'), Tab(text: '📝 Notes'), Tab(text: '🗺️ Maps'), Tab(text: '📐 Formulas')],
          ),
        ),
      ),
      // Tab views
      Expanded(child: TabBarView(
        controller: tabCtrl,
        children: [
          _ContentList(items: _filter(ContentType.video),   pad: pad, emptyIcon: '🎬', emptyMsg: 'No video lectures for this chapter yet.'),
          _ContentList(items: _filter(ContentType.note),    pad: pad, emptyIcon: '📝', emptyMsg: 'No revision notes yet.'),
          _ContentList(items: _filter(ContentType.mindmap), pad: pad, emptyIcon: '🗺️', emptyMsg: 'No mind maps yet.'),
          _ContentList(items: _filter(ContentType.formula), pad: pad, emptyIcon: '📐', emptyMsg: 'No formula sheets yet.'),
        ],
      )),
    ]);
  }
}

class _ContentList extends StatelessWidget {
  final List<ContentItemModel> items;
  final double pad;
  final String emptyIcon, emptyMsg;
  const _ContentList({required this.items, required this.pad, required this.emptyIcon, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyState(icon: emptyIcon, message: emptyMsg);
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(pad, 16, pad, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _ContentCard(item: items[i]),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final ContentItemModel item;
  const _ContentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == ContentType.video;
    return GestureDetector(
      onTap: isVideo ? () => context.push('/lecture/${item.id}') : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail / icon
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            child: item.thumbnailUrl != null
              ? Image.network(item.thumbnailUrl!, width: 90, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _TypeIcon(type: item.type))
              : _TypeIcon(type: item.type),
          ),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: AppTextStyles.labelMd(), maxLines: 2, overflow: TextOverflow.ellipsis),
              if (item.durationMin != null) ...[
                const SizedBox(height: 4),
                Text('${item.durationMin} min', style: AppTextStyles.caption().copyWith(color: AppColors.onSurfaceVariant)),
              ],
              if (item.content != null && item.content!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(item.content!, style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          )),
          if (isVideo)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.play_circle_fill_rounded, color: AppColors.primaryContainer, size: 28),
            ),
        ]),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final ContentType type;
  const _TypeIcon({required this.type});

  IconData get _icon {
    switch (type) {
      case ContentType.video:   return Icons.play_circle_fill_rounded;
      case ContentType.note:    return Icons.description_outlined;
      case ContentType.mindmap: return Icons.account_tree_outlined;
      case ContentType.formula: return Icons.functions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 90, height: 80,
    color: AppColors.primaryFixed,
    child: Icon(_icon, color: AppColors.primaryContainer, size: 32),
  );
}

// ── Shared Helpers ────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final String label; final Color color;
  const _CountBadge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
    child: Text(label, style: AppTextStyles.labelSm(color: color)),
  );
}

class _ContentStat extends StatelessWidget {
  final IconData icon; final int count; final Color color;
  const _ContentStat({required this.icon, required this.count, required this.color});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 11, color: color.withValues(alpha: 0.8)),
    const SizedBox(width: 2),
    Text('$count', style: AppTextStyles.caption().copyWith(color: color.withValues(alpha: 0.8))),
  ]);
}

class _CountPill extends StatelessWidget {
  final IconData icon; final int count; final String label;
  const _CountPill({required this.icon, required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: AppColors.onSurfaceVariant),
      const SizedBox(width: 2),
      Text('$count', style: AppTextStyles.caption().copyWith(color: AppColors.onSurfaceVariant)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final String icon, message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(icon, style: const TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(message, style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
    ]),
  );
}
