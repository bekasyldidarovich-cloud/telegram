class TelegramChat {
  const TelegramChat({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.avatarColor,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isPinned,
    required this.members,
    this.type = 'group',
    this.memberNames = const <String, String>{},
    this.memberPhones = const <String, String>{},
    this.memberColors = const <String, int>{},
  });

  final String id;
  final String title;
  final String subtitle;
  final int avatarColor;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isPinned;
  final List<String> members;
  final String type;
  final Map<String, String> memberNames;
  final Map<String, String> memberPhones;
  final Map<String, int> memberColors;

  TelegramChat copyWith({
    String? title,
    String? subtitle,
    int? avatarColor,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isPinned,
    List<String>? members,
    String? type,
    Map<String, String>? memberNames,
    Map<String, String>? memberPhones,
    Map<String, int>? memberColors,
  }) {
    return TelegramChat(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      avatarColor: avatarColor ?? this.avatarColor,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      members: members ?? this.members,
      type: type ?? this.type,
      memberNames: memberNames ?? this.memberNames,
      memberPhones: memberPhones ?? this.memberPhones,
      memberColors: memberColors ?? this.memberColors,
    );
  }
}
