import '../../../../core/l10n/l10n.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.phone,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email ?? L10n.current.safeerCustomer;
  }
}
