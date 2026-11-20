import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/system_admin_service.dart';
import '../../domain/admin_permissions.dart';
import '../providers/system_admin_providers.dart';
import '../widgets/admin_section_widgets.dart';

/// «المستخدمين»: the accounts that use the dashboard. Adding one gives an
/// existing app account a staff role; «تعطيل» switches it off until it is
/// enabled again.
class AdminUsersSection extends ConsumerWidget {
  const AdminUsersSection({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String done,
  ) async {
    try {
      await action();
      ref.invalidate(adminDashboardUsersProvider);
      if (context.mounted) showAdminSnack(context, done);
    } catch (error) {
      if (context.mounted) {
        showAdminSnack(context, describeAdminError(error), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final allowed = ref.watch(adminCanProvider(AdminPermission.manageUsers));
    if (!allowed) {
      return ref.watch(myPermissionsProvider).isLoading
          ? const Center(child: CircularProgressIndicator())
          : const AdminLockedSection(
              message: 'لا تملك صلاحية إدارة المستخدمين');
    }

    final isAdmin = ref.watch(isRealAdminProvider);
    final myId = ref.watch(currentUserProvider)?.id;
    final users = ref.watch(adminDashboardUsersProvider);
    final service = ref.read(systemAdminServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeader(
            title: 'المستخدمين',
            actions: [
              FilledButton.icon(
                key: const Key('users-add'),
                onPressed: () async {
                  final result = await showDialog<_UserChange>(
                    context: context,
                    builder: (_) => _UserDialog(allowAdminRole: isAdmin),
                  );
                  if (result == null || !context.mounted) return;
                  await _run(
                    context,
                    ref,
                    () => service.setUserRole(
                      userId: result.userId,
                      role: result.role,
                      fullName: result.name,
                    ),
                    'تمت إضافة المستخدم',
                  );
                },
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('إضافة مستخدم'),
              ),
            ],
          ),
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
                return ListView.separated(
                  key: const Key('users-list'),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    final self = user.id == myId;
                    // Only administrators touch administrators.
                    final locked = self || (user.isAdmin && !isAdmin);
                    final role = DashboardUserRole.fromValue(user.role);
                    return Container(
                      key: Key('user-${user.id}'),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: palette.card,
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (user.disabled
                                    ? Colors.grey
                                    : palette.accent)
                                .withValues(alpha: 0.15),
                            child: Icon(
                              user.disabled
                                  ? Icons.person_off_rounded
                                  : Icons.badge_rounded,
                              color:
                                  user.disabled ? Colors.grey : palette.accent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.title + (self ? ' (أنت)' : ''),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: user.disabled ? palette.muted : null,
                                  ),
                                ),
                                Text(
                                  [
                                    role?.label ?? user.role,
                                    if (user.phone != null) user.phone!,
                                    if (user.email != null) user.email!,
                                  ].join(' • '),
                                  style: TextStyle(
                                      fontSize: 12, color: palette.muted),
                                ),
                              ],
                            ),
                          ),
                          if (user.disabled)
                            Container(
                              key: Key('user-disabled-${user.id}'),
                              margin: const EdgeInsetsDirectional.only(end: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text('معطّل',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          if (!locked) ...[
                            IconButton(
                              key: Key('user-edit-${user.id}'),
                              tooltip: 'تعديل',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                final result = await showDialog<_UserChange>(
                                  context: context,
                                  builder: (_) => _UserDialog(
                                    existing: user,
                                    allowAdminRole: isAdmin,
                                  ),
                                );
                                if (result == null || !context.mounted) return;
                                await _run(
                                  context,
                                  ref,
                                  () => service.setUserRole(
                                    userId: user.id,
                                    role: result.role,
                                    fullName: result.name,
                                    disabled: user.disabled,
                                  ),
                                  'تم حفظ التعديل',
                                );
                              },
                            ),
                            IconButton(
                              key: Key('user-toggle-${user.id}'),
                              tooltip: user.disabled ? 'تفعيل' : 'تعطيل',
                              icon: Icon(
                                user.disabled
                                    ? Icons.check_circle_outline
                                    : Icons.block_rounded,
                                color:
                                    user.disabled ? Colors.green : Colors.red,
                              ),
                              onPressed: () async {
                                if (!user.disabled) {
                                  final ok = await confirmAdminAction(
                                    context,
                                    title: 'تعطيل المستخدم',
                                    message:
                                        'لن يتمكن «${user.title}» من استخدام لوحة التحكم حتى يُعاد تفعيله.',
                                    confirmLabel: 'تعطيل',
                                  );
                                  if (!ok || !context.mounted) return;
                                }
                                await _run(
                                  context,
                                  ref,
                                  () => service.setUserRole(
                                    userId: user.id,
                                    role: user.role,
                                    disabled: !user.disabled,
                                  ),
                                  user.disabled
                                      ? 'تم تفعيل المستخدم'
                                      : 'تم تعطيل المستخدم',
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserChange {
  const _UserChange({required this.userId, required this.role, this.name});

  final String userId;
  final String role;
  final String? name;
}

/// Add (find an account, pick a role) or edit (name, role) a dashboard user.
class _UserDialog extends ConsumerStatefulWidget {
  const _UserDialog({this.existing, required this.allowAdminRole});

  final DashboardUser? existing;
  final bool allowAdminRole;

  @override
  ConsumerState<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<_UserDialog> {
  final _search = TextEditingController();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  Timer? _debounce;
  List<AccountMatch> _matches = const [];
  bool _searching = false;
  String? _searchError;
  AccountMatch? _picked;
  late String _role = widget.existing?.role ?? DashboardUserRole.cashier.value;

  bool get _editing => widget.existing != null;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _name.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _find(text));
  }

  Future<void> _find(String text) async {
    if (text.trim().length < 2) {
      setState(() => _matches = const []);
      return;
    }
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final matches =
          await ref.read(systemAdminServiceProvider).findAccounts(text.trim());
      if (mounted) {
        setState(() {
          _matches = matches;
          _searching = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _searchError = describeAdminError(error);
          _searching = false;
        });
      }
    }
  }

  void _submit() {
    final userId = widget.existing?.id ?? _picked?.id;
    if (userId == null) return;
    Navigator.pop(
      context,
      _UserChange(userId: userId, role: _role, name: _name.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      for (final role in DashboardUserRole.values)
        if (role != DashboardUserRole.admin || widget.allowAdminRole ||
            _role == DashboardUserRole.admin.value)
          role,
    ];

    return AlertDialog(
      title: Text(_editing ? 'تعديل المستخدم' : 'إضافة مستخدم',
          style: const TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_editing) ...[
                const Text(
                  'ابحث عن حساب مسجّل في التطبيق (بالاسم أو الهاتف أو البريد) '
                  'لمنحه دوراً في لوحة التحكم.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('user-find'),
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'بحث عن حساب',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: LinearProgressIndicator(),
                  ),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(_searchError!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                for (final match in _matches)
                  ListTile(
                    key: Key('user-match-${match.id}'),
                    dense: true,
                    selected: _picked?.id == match.id,
                    title: Text(match.title),
                    subtitle: Text(
                      [
                        if (match.phone != null) match.phone!,
                        if (match.email != null) match.email!,
                      ].join(' • '),
                    ),
                    onTap: () => setState(() {
                      _picked = match;
                      _name.text = match.name ?? '';
                    }),
                  ),
                const SizedBox(height: 8),
              ],
              TextField(
                key: const Key('user-name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const Key('user-role'),
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'الدور'),
                items: [
                  for (final role in roles)
                    DropdownMenuItem(value: role.value, child: Text(role.label)),
                ],
                onChanged: (v) => setState(() => _role = v ?? _role),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          key: const Key('user-save'),
          onPressed: _editing || _picked != null ? _submit : null,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
