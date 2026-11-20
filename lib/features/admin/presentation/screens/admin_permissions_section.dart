import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';

/// «الصلاحيات» (administrators only): pick a user and switch individual
/// permissions on or off. Saved to Supabase with the «حفظ» button.
class AdminPermissionsSection extends ConsumerStatefulWidget {
  const AdminPermissionsSection({super.key});

  @override
  ConsumerState<AdminPermissionsSection> createState() =>
      _AdminPermissionsSectionState();
}

class _AdminPermissionsSectionState
    extends ConsumerState<AdminPermissionsSection> {
  DashboardUser? _user;
  Set<String> _granted = {};
  Set<String> _saved = {};
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isAdminTarget => _user?.isAdmin ?? false;
  bool get _dirty => !_isAdminTarget && !_sameSet(_granted, _saved);

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _select(DashboardUser user) async {
    setState(() {
      _user = user;
      _loading = true;
      _error = null;
    });
    try {
      final keys = user.isAdmin
          ? AdminPermission.allKeys
          : await ref.read(systemAdminServiceProvider).permissionsOf(user.id);
      if (!mounted || _user?.id != user.id) return;
      setState(() {
        _granted = {...keys};
        _saved = {...keys};
        _loading = false;
      });
    } catch (error) {
      if (!mounted || _user?.id != user.id) return;
      setState(() {
        _error = describeAdminError(error);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(systemAdminServiceProvider)
          .setPermissions(user.id, _granted);
      if (!mounted) return;
      setState(() {
        _saved = {..._granted};
        _saving = false;
      });
      ref.invalidate(myPermissionsProvider);
      showAdminSnack(context, 'تم حفظ الصلاحيات');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAdminSnack(context, describeAdminError(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Defence in depth: the menu already hides this section.
    if (!ref.watch(isRealAdminProvider)) {
      return const AdminLockedSection(
          message: 'هذا القسم متاح للمدير فقط');
    }
    final palette = context.palette;
    final users = ref.watch(adminDashboardUsersProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(title: 'الصلاحيات'),
          Expanded(
            child: users.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => AdminMessage(describeAdminError(error),
                  icon: Icons.error_outline),
              data: (list) {
                if (list.isEmpty) {
                  return const AdminMessage('لا يوجد مستخدمون',
                      icon: Icons.people_outline);
                }
                final userList = _UserPicker(
                  users: list,
                  selectedId: _user?.id,
                  onSelect: _select,
                );
                final editor = _buildEditor(palette);
                return LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth >= 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: userList),
                        const SizedBox(width: 12),
                        Expanded(flex: 6, child: editor),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      SizedBox(height: 180, child: userList),
                      const SizedBox(height: 12),
                      Expanded(child: editor),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(AppPalette palette) {
    final user = _user;
    Widget body;
    if (user == null) {
      body = const AdminMessage('اختر موظفاً لتعديل صلاحياته',
          icon: Icons.admin_panel_settings_outlined);
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = AdminMessage(_error!, icon: Icons.error_outline);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text('صلاحيات ${user.title}',
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          ),
          if (_isAdminTarget)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('المدير يملك كل الصلاحيات دائماً',
                  key: const Key('permissions-admin-note'),
                  style: TextStyle(color: palette.muted)),
            ),
          Expanded(
            child: ListView(
              children: [
                for (final permission in AdminPermission.values)
                  SwitchListTile(
                    key: Key('permission-${permission.key}'),
                    title: Text(permission.label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    value: _granted.contains(permission.key),
                    onChanged: _isAdminTarget || _saving
                        ? null
                        : (on) => setState(() {
                              if (on) {
                                _granted.add(permission.key);
                              } else {
                                _granted.remove(permission.key);
                              }
                            }),
                  ),
              ],
            ),
          ),
          if (!_isAdminTarget)
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                key: const Key('permissions-save'),
                onPressed: _dirty && !_saving ? _save : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: const Text('حفظ الصلاحيات'),
              ),
            ),
        ],
      );
    }
    return Container(
      key: const Key('permissions-editor'),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(type: MaterialType.transparency, child: body),
    );
  }
}

class _UserPicker extends StatelessWidget {
  const _UserPicker({
    required this.users,
    required this.selectedId,
    required this.onSelect,
  });

  final List<DashboardUser> users;
  final String? selectedId;
  final ValueChanged<DashboardUser> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('permissions-users'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            key: Key('permission-user-${user.id}'),
            selected: user.id == selectedId,
            selectedTileColor: palette.accent.withValues(alpha: 0.1),
            leading: Icon(
                user.isAdmin ? Icons.shield_rounded : Icons.person_rounded),
            title: Text(user.title),
            subtitle: Text(
                DashboardUserRole.fromValue(user.role)?.label ?? user.role),
            onTap: () => onSelect(user),
          );
        },
        ),
      ),
    );
  }
}
