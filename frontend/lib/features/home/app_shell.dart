import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined,      activeIcon: Icons.home_rounded,          label: 'Home',     route: '/home'),
    _TabItem(icon: Icons.sports_esports_outlined, activeIcon: Icons.sports_esports_rounded, label: 'Game Zone', route: '/home/battle'),
    _TabItem(icon: Icons.play_circle_outline, activeIcon: Icons.play_circle_rounded,  label: 'Shorts',   route: '/home/shorts'),
    _TabItem(icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories_rounded, label: 'Vault',  route: '/home/vault'),
    _TabItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded,    label: 'Profile',  route: '/home/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = _tabs.indexWhere((t) => t.route == location);
    if (currentIndex < 0) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 64,
            child: Row(
              children: _tabs.asMap().entries.map((e) {
                final i = e.key;
                final tab = e.value;
                final selected = currentIndex == i;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go(tab.route),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            selected ? tab.activeIcon : tab.icon,
                            key: ValueKey(selected),
                            size: 22,
                            color: selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: AppTextStyles.caption().copyWith(
                            color: selected ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.route});
}
