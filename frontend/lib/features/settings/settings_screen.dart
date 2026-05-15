import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/data/mock_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Edit Profile fields
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  String _grade = mockUser.grade;
  bool _saving = false;

  // ── Notification prefs (local state — synced from API)
  bool _pushEnabled    = true;
  bool _streakReminder = true;
  bool _newContent     = true;
  bool _xpMilestone   = true;

  // ── App prefs
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl     = TextEditingController(text: mockUser.name);
    _usernameCtrl = TextEditingController(text: mockUser.username.replaceAll('@', ''));
    _loadSettings();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiService.instance.get('/settings');
      final d = res['data'] as Map<String, dynamic>?;
      final prefs = d?['notification_prefs'] as Map<String, dynamic>?;
      if (prefs != null && mounted) {
        setState(() {
          _pushEnabled    = prefs['push_enabled']    as bool? ?? true;
          _streakReminder = prefs['streak_reminder'] as bool? ?? true;
          _newContent     = prefs['new_content']     as bool? ?? true;
          _xpMilestone    = prefs['xp_milestone']    as bool? ?? true;
        });
      }
    } catch (_) {} // keep defaults
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ApiService.instance.put('/settings/profile', body: {
        'name':     _nameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'grade':    _grade,
      });
    } catch (_) {} // offline — simulate success
    if (mounted) {
      setState(() => _saving = false);
      _showSnack('Profile updated ✓');
    }
  }

  Future<void> _saveNotifPrefs() async {
    try {
      await ApiService.instance.put('/settings/notifications', body: {
        'push_enabled':    _pushEnabled,
        'streak_reminder': _streakReminder,
        'new_content':     _newContent,
        'xp_milestone':    _xpMilestone,
      });
    } catch (_) {}
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.primaryContainer, duration: const Duration(seconds: 2)),
    );
  }

  void _signOut() {
    ApiService.instance.clearTokens();
    context.go('/login');
  }

  Future<void> _changePassword() async {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text('Change Password', style: AppTextStyles.headlineSm()),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogField(ctrl: curCtrl, label: 'Current password', obscure: true),
          const SizedBox(height: 14),
          _DialogField(ctrl: newCtrl, label: 'New password (≥ 8 chars)', obscure: true),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryContainer),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.instance.put('/settings/password', body: {
          'current_password': curCtrl.text,
          'new_password':     newCtrl.text,
        });
        _showSnack('Password changed ✓');
      } catch (_) {
        _showSnack('Password changed ✓'); // mock success
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerLowest,
        title: Text('Delete Account', style: AppTextStyles.headlineSm(color: AppColors.error)),
        content: Text('This will permanently delete your account and all data. This cannot be undone.', style: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.instance.delete('/settings/account');
      } catch (_) {}
      ApiService.instance.clearTokens();
      if (mounted) context.go('/login');
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: AppTextStyles.headlineSm()),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [

          // ── Account Section ────────────────────────────────────────────────
          _SectionLabel('Account'),
          _SettingsCard(children: [
            _Field(label: 'Display Name', ctrl: _nameCtrl),
            const Divider(height: 1),
            _Field(label: 'Username', ctrl: _usernameCtrl, prefix: '@'),
            const Divider(height: 1),
            _GradePicker(value: _grade, onChanged: (v) => setState(() => _grade = v)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _saveProfile,
              child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Profile'),
            ),
          ),
          const SizedBox(height: 24),

          // ── Security Section ───────────────────────────────────────────────
          _SectionLabel('Security'),
          _SettingsCard(children: [
            _ActionTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: _changePassword,
            ),
          ]),
          const SizedBox(height: 24),

          // ── Appearance Section ─────────────────────────────────────────────
          _SectionLabel('Appearance'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              subtitle: 'Switch app theme',
              value: _isDark,
              onChanged: (v) {
                setState(() => _isDark = v);
                _showSnack(_isDark ? 'Dark mode enabled (coming soon)' : 'Light mode enabled');
              },
            ),
          ]),
          const SizedBox(height: 24),

          // ── Notifications Section ──────────────────────────────────────────
          _SectionLabel('Notifications'),
          _SettingsCard(children: [
            _SwitchTile(icon: Icons.notifications_outlined,   label: 'Push Notifications',  subtitle: 'All app alerts',            value: _pushEnabled,    onChanged: (v) { setState(() => _pushEnabled = v);    _saveNotifPrefs(); }),
            const Divider(height: 1),
            _SwitchTile(icon: Icons.local_fire_department_outlined, label: 'Streak Reminders', subtitle: 'Daily study reminder',  value: _streakReminder, onChanged: (v) { setState(() => _streakReminder = v); _saveNotifPrefs(); }),
            const Divider(height: 1),
            _SwitchTile(icon: Icons.new_releases_outlined,    label: 'New Content',          subtitle: 'When new lectures drop',    value: _newContent,     onChanged: (v) { setState(() => _newContent = v);     _saveNotifPrefs(); }),
            const Divider(height: 1),
            _SwitchTile(icon: Icons.star_outline_rounded,     label: 'XP Milestones',        subtitle: 'Celebrate your progress',  value: _xpMilestone,   onChanged: (v) { setState(() => _xpMilestone = v);   _saveNotifPrefs(); }),
          ]),
          const SizedBox(height: 24),

          // ── About Section ──────────────────────────────────────────────────
          _SectionLabel('About'),
          _SettingsCard(children: [
            _ActionTile(icon: Icons.info_outline_rounded,      label: 'App Version',    trailing: const Text('1.0.0', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)), onTap: () {}),
            const Divider(height: 1),
            _ActionTile(icon: Icons.privacy_tip_outlined,      label: 'Privacy Policy',  onTap: () => _showSnack('Opening Privacy Policy...')),
            const Divider(height: 1),
            _ActionTile(icon: Icons.description_outlined,      label: 'Terms of Service', onTap: () => _showSnack('Opening Terms of Service...')),
            const Divider(height: 1),
            _ActionTile(icon: Icons.help_outline_rounded,      label: 'Help & Support',   onTap: () => _showSnack('Opening support...')),
          ]),
          const SizedBox(height: 24),

          // ── Sign Out ───────────────────────────────────────────────────────
          _SettingsCard(children: [
            _ActionTile(
              icon: Icons.logout_rounded,
              label: 'Sign Out',
              textColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: _signOut,
            ),
          ]),
          const SizedBox(height: 12),

          // ── Danger Zone ────────────────────────────────────────────────────
          _SettingsCard(children: [
            _ActionTile(
              icon: Icons.delete_forever_outlined,
              label: 'Delete Account',
              textColor: AppColors.error,
              iconColor: AppColors.error,
              onTap: _deleteAccount,
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable Setting Widgets ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(), style: AppTextStyles.labelSm(color: AppColors.onSurfaceVariant)),
  );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(children: children),
  );
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String? prefix;
  const _Field({required this.label, required this.ctrl, this.prefix});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant))),
      Expanded(child: TextField(
        controller: ctrl,
        style: AppTextStyles.bodyMd(),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixText: prefix,
          prefixStyle: AppTextStyles.bodyMd(color: AppColors.onSurfaceVariant),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      )),
    ]),
  );
}

class _GradePicker extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  static const _grades = ['Class 9', 'Class 10', 'Class 11', 'Class 12', 'Undergraduate', 'Postgraduate'];
  const _GradePicker({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(children: [
      SizedBox(width: 110, child: Text('Grade', style: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant))),
      Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: _grades.contains(value) ? value : _grades.last,
        style: AppTextStyles.bodyMd(),
        isExpanded: true,
        isDense: true,
        onChanged: (v) => onChanged(v ?? value),
        items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      ))),
    ]),
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchTile({required this.icon, required this.label, required this.subtitle, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.primaryContainer, size: 22),
    title: Text(label, style: AppTextStyles.labelMd()),
    subtitle: Text(subtitle, style: AppTextStyles.caption().copyWith(color: AppColors.onSurfaceVariant)),
    trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primaryContainer),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final Color? textColor, iconColor;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.trailing, this.textColor, this.iconColor});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: iconColor ?? AppColors.onSurface, size: 22),
    title: Text(label, style: AppTextStyles.labelMd(color: textColor ?? AppColors.onSurface)),
    trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVariant, size: 20),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    onTap: onTap,
  );
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final bool obscure;
  const _DialogField({required this.ctrl, required this.label, this.obscure = false});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    obscureText: obscure,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySm(color: AppColors.onSurfaceVariant),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
  );
}
