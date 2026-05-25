class TelegramMessage {
  const TelegramMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    required this.isEdited,
    required this.isRead,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool isEdited;
  final bool isRead;

  TelegramMessage copyWith({
    String? text,
    DateTime? sentAt,
    bool? isEdited,
    bool? isRead,
  }) {
    return TelegramMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      isEdited: isEdited ?? this.isEdited,
      isRead: isRead ?? this.isRead,
    );
  }
}
