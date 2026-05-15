import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  List<_NItem> _items = [];
  int _unread = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.instance.get('/notifications');
      _items  = ((res['data'] as List).cast<Map<String,dynamic>>()).map(_NItem.fromJson).toList();
      _unread = (res['meta']?['unread'] as int?) ?? 0;
    } catch (_) {
      _items  = _mock;
      _unread = _items.where((n) => !n.isRead).length;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    try { await ApiService.instance.put('/notifications/read-all'); } catch (_) {}
    setState(() { _items = _items.map((n) => n.asRead()).toList(); _unread = 0; });
  }

  Future<void> _markRead(String id) async {
    try { await ApiService.instance.put('/notifications/$id/read'); } catch (_) {}
    setState(() {
      _items  = _items.map((n) => n.id == id ? n.asRead() : n).toList();
      _unread = _items.where((n) => !n.isRead).length;
    });
  }

  Future<void> _dismiss(String id) async {
    try { await ApiService.instance.delete('/notifications/$id'); } catch (_) {}
    setState(() { _items = _items.where((n) => n.id != id).toList(); _unread = _items.where((n) => !n.isRead).length; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('Notifications', style: AppTextStyles.headlineSm()),
          if (_unread > 0) Text('$_unread unread', style: AppTextStyles.labelSm(color: AppColors.primaryContainer)),
        ]),
        actions: [
          if (_unread > 0)
            TextButton(onPressed: _markAllRead, child: Text('Mark all read', style: AppTextStyles.labelSm(color: AppColors.primaryContainer))),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer))
        : _items.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔔', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 14),
              Text('All caught up!', style: AppTextStyles.headlineSm()),
              const SizedBox(height: 6),
              Text('No notifications yet.', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
            ]))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primaryContainer,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final n = _items[i];
                  return Dismissible(
                    key: Key(n.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: AppColors.errorContainer,
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    ),
                    onDismissed: (_) => _dismiss(n.id),
                    child: InkWell(
                      onTap: () => _markRead(n.id),
                      child: Container(
                        color: n.isRead ? null : AppColors.primaryFixed.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: _typeColor(n.type).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                            child: Center(child: Text(n.icon, style: const TextStyle(fontSize: 22))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(n.title, style: AppTextStyles.labelMd(), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              if (!n.isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primaryContainer, shape: BoxShape.circle)),
                            ]),
                            const SizedBox(height: 4),
                            Text(n.body, style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(_fmt(n.createdAt), style: AppTextStyles.caption().copyWith(color: AppColors.onSurfaceVariant)),
                          ])),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'streak':       return const Color(0xFFE65100);
      case 'xp_milestone': return const Color(0xFF7B1FA2);
      case 'new_content':  return AppColors.primaryContainer;
      case 'battle':       return AppColors.amber;
      default:             return AppColors.secondary;
    }
  }

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24)   return '${d.inHours}h ago';
    if (d.inDays < 7)     return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _NItem {
  final String id, type, title, body, icon;
  final bool isRead;
  final DateTime createdAt;
  const _NItem({required this.id, required this.type, required this.title, required this.body, required this.icon, required this.isRead, required this.createdAt});
  factory _NItem.fromJson(Map<String,dynamic> j) => _NItem(id: j['id'], type: j['type']??'system', title: j['title'], body: j['body']??'', icon: j['icon']??'🔔', isRead: j['is_read']??false, createdAt: DateTime.parse(j['created_at']));
  _NItem asRead() => _NItem(id: id, type: type, title: title, body: body, icon: icon, isRead: true, createdAt: createdAt);
}

final _mock = [
  _NItem(id: 'n1', type: 'streak',       title: '🔥 14-Day Streak!',          body: "You've been studying 14 days in a row. Keep it up!",              icon: '🔥', isRead: false, createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
  _NItem(id: 'n2', type: 'new_content',  title: 'New: Electrostatics Video',  body: "A new lecture on Coulomb's Law has been added to Physics.",        icon: '🎬', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 2))),
  _NItem(id: 'n3', type: 'xp_milestone', title: '⚡ 3000 XP Milestone!',      body: 'You crossed 3,000 XP. You are now in the top 15%.',               icon: '⚡', isRead: false, createdAt: DateTime.now().subtract(const Duration(hours: 5))),
  _NItem(id: 'n4', type: 'battle',       title: 'Battle Invitation',          body: 'Priya invited you to a Physics Warriors battle room.',             icon: '⚔️', isRead: true,  createdAt: DateTime.now().subtract(const Duration(days: 1))),
  _NItem(id: 'n5', type: 'new_content',  title: 'Integration — Full Guide',   body: 'New 52-min video added to Mathematics → Integration.',            icon: '📐', isRead: true,  createdAt: DateTime.now().subtract(const Duration(days: 2))),
  _NItem(id: 'n6', type: 'system',       title: 'Welcome to Shiksha Verse',   body: 'Your account is ready. Start exploring!',                         icon: '🎉', isRead: true,  createdAt: DateTime.now().subtract(const Duration(days: 7))),
];
