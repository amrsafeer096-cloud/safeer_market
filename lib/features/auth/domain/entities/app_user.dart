class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String? email;

  /// From sign-up / provider metadata; `profiles` is the source of truth when
  /// available.
  final String? fullName;

  /// Local Egyptian format (`01xxxxxxxxx`) when known.
  final String? phone;
  final String? avatarUrl;
}
