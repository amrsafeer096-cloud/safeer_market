import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/mobile_frame.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context)!;

    return MobileFrame(
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(title: Text(l10n.personalData)),
        body: !signedIn
            ? Center(
                child: FilledButton(
                  onPressed: () => context.push(AppRoutes.auth),
                  child: Text(l10n.editProfileSignInPrompt),
                ),
              )
            : profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: FilledButton(
                    onPressed: () => ref.invalidate(userProfileProvider),
                    child: Text(l10n.retry),
                  ),
                ),
                data: (profile) => _EditProfileForm(
                  initialName: profile?.fullName ?? '',
                  initialPhone: profile?.phone ?? '',
                  email: profile?.email,
                ),
              ),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({
    required this.initialName,
    required this.initialPhone,
    this.email,
  });

  final String initialName;
  final String initialPhone;
  final String? email;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  static final _egyptianPhonePattern = RegExp(r'^01[0125]\d{8}$');

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late final _phone = TextEditingController(text: widget.initialPhone);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            userId: user.id,
            fullName: _name.text.trim(),
            phone: _phone.text.trim(),
          );
      if (router.canPop()) router.pop();
      ref.invalidate(userProfileProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(l10n.profileSavedSuccessfully),
          ),
        );
    } catch (error) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            backgroundColor: AppColors.secondary,
            content: Text(error.toString()),
          ),
        );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Container(
              width: 84,
              height: 84,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.secondary, width: 3),
              ),
              child: name.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: Colors.white,
                    )
                  : Text(
                      name.characters.first,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.profileFullNameLabel,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: (value) => (value ?? '').trim().length < 3
                ? l10n.profileEnterFullName
                : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.end,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.phoneNumber,
              hintText: '01xxxxxxxxx',
              hintTextDirection: TextDirection.ltr,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            validator: (value) =>
                _egyptianPhonePattern.hasMatch((value ?? '').trim())
                    ? null
                    : l10n.profileEnterValidPhone,
          ),
          if (widget.email case final email?) ...[
            const SizedBox(height: 14),
            TextFormField(
              initialValue: email,
              readOnly: true,
              enabled: false,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.end,
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.profileSaveChanges),
            ),
          ),
        ],
      ),
    );
  }
}
