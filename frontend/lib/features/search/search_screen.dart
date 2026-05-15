import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  bool _isLoading = false;
  String _query = '';
  Map<String, dynamic> _results = {};

  // Mock recent searches
  final List<String> _recent = ['Newton Laws', 'Integration', 'Atomic Structure', 'Waves'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    if (val.trim().length < 2) {
      setState(() { _query = ''; _results = {}; _isLoading = false; });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(val.trim()));
  }

  Future<void> _search(String q) async {
    try {
      final res = await ApiService.instance.get('/search?q=$q');
      if (mounted) setState(() { _query = q; _results = res['data'] as Map<String, dynamic>? ?? {}; _isLoading = false; });
    } catch (_) {
      // Fall back to mock
      if (mounted) {
        final ql = q.toLowerCase();
        setState(() {
          _query = q;
          _isLoading = false;
          _results = {
            'subjects': mockSubjects.where((s) => s.name.toLowerCase().contains(ql)).map((s) => {'id': s.id, 'name': s.name, 'icon': s.icon, 'color_hex': s.colorHex, 'chapter_count': s.chapterCount}).toList(),
            'chapters': (mockChapters.values.expand((v) => v)).where((ch) => ch.title.toLowerCase().contains(ql)).map((ch) => {'id': ch.id, 'title': ch.title, 'subject_name': ''}).toList(),
            'content':  (mockContent.values.expand((v) => v)).where((c) => c.title.toLowerCase().contains(ql)).map((c) => {'id': c.id, 'title': c.title, 'type': c.type.apiKey, 'chapter_title': ''}).toList(),
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onChanged: _onChanged,
          style: AppTextStyles.bodyMd(),
          decoration: InputDecoration(
            hintText: 'Search subjects, topics, content...',
            hintStyle: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
            border: InputBorder.none,
            suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () { _ctrl.clear(); _onChanged(''); },
                )
              : null,
          ),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
        : _query.isEmpty
          ? _RecentSearches(recent: _recent, onTap: (s) { _ctrl.text = s; _onChanged(s); })
          : _SearchResults(results: _results, query: _query),
    );
  }
}

// ── Recent Searches ───────────────────────────────────────────────────────────

class _RecentSearches extends StatelessWidget {
  final List<String> recent;
  final void Function(String) onTap;
  const _RecentSearches({required this.recent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Recent Searches', style: AppTextStyles.labelMd(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 14),
        ...recent.map((s) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.history_rounded, color: AppColors.onSurfaceVariant, size: 20),
          title: Text(s, style: AppTextStyles.bodyMd()),
          trailing: const Icon(Icons.north_west_rounded, color: AppColors.onSurfaceVariant, size: 16),
          onTap: () => onTap(s),
        )),
        const SizedBox(height: 24),
        Text('Popular Topics', style: AppTextStyles.labelMd(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          'Physics', 'Integration', 'Genetics', 'Newton', 'Organic Chemistry', 'Limits',
        ].map((t) => GestureDetector(
          onTap: () => onTap(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.chipBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(t, style: AppTextStyles.labelSm(color: AppColors.primaryContainer)),
          ),
        )).toList()),
      ],
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  final Map<String, dynamic> results;
  final String query;
  const _SearchResults({required this.results, required this.query});

  @override
  Widget build(BuildContext context) {
    final subjects = (results['subjects'] as List?)?.cast<Map>() ?? [];
    final chapters = (results['chapters'] as List?)?.cast<Map>() ?? [];
    final content  = (results['content']  as List?)?.cast<Map>() ?? [];
    final total = subjects.length + chapters.length + content.length;

    if (total == 0) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🔍', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('No results for "$query"', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text('Try different keywords', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('$total result${total == 1 ? '' : 's'} for "$query"', style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
        const SizedBox(height: 16),
        if (subjects.isNotEmpty) ...[
          _SectionHeader(title: '📚 Subjects', count: subjects.length),
          ...subjects.map((s) => _SubjectTile(data: s)),
          const SizedBox(height: 16),
        ],
        if (chapters.isNotEmpty) ...[
          _SectionHeader(title: '📖 Chapters', count: chapters.length),
          ...chapters.map((c) => _ChapterTile(data: c)),
          const SizedBox(height: 16),
        ],
        if (content.isNotEmpty) ...[
          _SectionHeader(title: '🎬 Content', count: content.length),
          ...content.map((c) => _ContentTile(data: c)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title; final int count;
  const _SectionHeader({required this.title, required this.count});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Text(title, style: AppTextStyles.labelMd()),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.chipBackground, borderRadius: BorderRadius.circular(999)),
        child: Text('$count', style: AppTextStyles.labelSm(color: AppColors.primaryContainer)),
      ),
    ]),
  );
}

class _SubjectTile extends StatelessWidget {
  final Map data;
  const _SubjectTile({required this.data});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.primaryFixed, borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(data['icon'] ?? '📚', style: const TextStyle(fontSize: 22))),
    ),
    title: Text(data['name'] ?? '', style: AppTextStyles.labelMd()),
    subtitle: Text('${data['chapter_count'] ?? 0} chapters', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
    onTap: () => context.push('/vault', extra: {'subject': data['name']}),
  );
}

class _ChapterTile extends StatelessWidget {
  final Map data;
  const _ChapterTile({required this.data});
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.menu_book_rounded, color: AppColors.primaryContainer, size: 22),
    ),
    title: Text(data['title'] ?? '', style: AppTextStyles.labelMd()),
    subtitle: Text(data['subject_name'] ?? '', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
    onTap: () {},
  );
}

class _ContentTile extends StatelessWidget {
  final Map data;
  const _ContentTile({required this.data});

  IconData get _typeIcon {
    switch (data['type']) {
      case 'video':   return Icons.play_circle_outline_rounded;
      case 'mindmap': return Icons.account_tree_outlined;
      case 'formula': return Icons.functions_rounded;
      default:        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    leading: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
      child: Icon(_typeIcon, color: AppColors.primaryContainer, size: 22),
    ),
    title: Text(data['title'] ?? '', style: AppTextStyles.labelMd()),
    subtitle: Text(data['chapter_title'] ?? '', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant),
    onTap: data['type'] == 'video' ? () => context.push('/lecture/${data['id']}') : null,
  );
}
