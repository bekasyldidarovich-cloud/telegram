import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/message.dart';

abstract class ChatRepository {
  Stream<List<TelegramChat>> watchChats(String userId);

  Stream<List<AppUser>> watchContacts(String userId);

  Stream<List<TelegramMessage>> watchMessages(String chatId);

  Future<void> seedDemoData(String userId);

  Future<TelegramChat> createChat({
    required String ownerId,
    required String title,
    required String subtitle,
  });

  Future<TelegramChat> createDirectChat({
    required AppUser currentUser,
    required AppUser contact,
  });

  Future<AppUser?> findUserByPhone(String phoneNumber);

  Future<void> updateChat(TelegramChat chat);

  Future<void> deleteChat(String chatId);

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  });

  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String text,
  });

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  });
}
