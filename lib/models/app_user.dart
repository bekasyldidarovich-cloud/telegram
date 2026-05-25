class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.photoUrl,
    this.avatarColor,
  });

  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? photoUrl;
  final int? avatarColor;

  String get contactLabel {
    final phone = phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) {
      return phone;
    }
    if (email.isNotEmpty) {
      return email;
    }
    return 'online';
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }

    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}
