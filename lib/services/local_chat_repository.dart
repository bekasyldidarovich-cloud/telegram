import 'dart:async';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'chat_repository.dart';

class LocalChatRepository implements ChatRepository {
  final List<TelegramChat> _chats = <TelegramChat>[];
  final Map<String, List<TelegramMessage>> _messages =
      <String, List<TelegramMessage>>{};
  final _chatsController = StreamController<List<TelegramChat>>.broadcast();
  final Map<String, StreamController<List<TelegramMessage>>>
  _messageControllers = <String, StreamController<List<TelegramMessage>>>{};
  final List<AppUser> _demoContacts = const <AppUser>[
    AppUser(
      id: 'local-contact-alex',
      email: '',
      name: 'Alex Johnson',
      phoneNumber: '+77001112233',
      avatarColor: 0xff54a9eb,
    ),
    AppUser(
      id: 'local-contact-mira',
      email: '',
      name: 'Mira Kasenova',
      phoneNumber: '+77004445566',
      avatarColor: 0xff40b97c,
    ),
    AppUser(
      id: 'local-contact-design',
      email: '',
      name: 'Design Room',
      phoneNumber: '+77007778899',
      avatarColor: 0xfff59b42,
    ),
  ];

  bool _seeded = false;

  @override
  Stream<List<TelegramChat>> watchChats(String userId) async* {
    yield _sortedChats();
    yield* _chatsController.stream;
  }

  @override
  Stream<List<AppUser>> watchContacts(String userId) async* {
    yield List<AppUser>.unmodifiable(_demoContacts);
  }

  @override
  Stream<List<TelegramMessage>> watchMessages(String chatId) async* {
    yield List<TelegramMessage>.unmodifiable(_messages[chatId] ?? const []);
    yield* _controllerFor(chatId).stream;
  }

  @override
  Future<void> seedDemoData(String userId) async {
    if (_seeded) {
      return;
    }
    _seeded = true;

    final now = DateTime.now();
    final savedMessages = TelegramChat(
      id: 'saved',
      title: 'Saved Messages',
      subtitle: 'personal cloud',
      avatarColor: 0xff54a9eb,
      lastMessage: 'Your notes and links are here',
      lastMessageAt: now.subtract(const Duration(minutes: 4)),
      unreadCount: 0,
      isPinned: true,
      members: <String>[userId],
    );
    final classChat = TelegramChat(
      id: 'class-chat',
      title: 'Class QA Chat',
      subtitle: 'online',
      avatarColor: 0xff40b97c,
      lastMessage: 'Create, edit, and delete messages here',
      lastMessageAt: now.subtract(const Duration(minutes: 14)),
      unreadCount: 3,
      isPinned: false,
      members: <String>[userId],
    );
    final designRoom = TelegramChat(
      id: 'design-room',
      title: 'Flutter Design Room',
      subtitle: 'last seen recently',
      avatarColor: 0xfff59b42,
      lastMessage: 'The chat list now looks close to Telegram',
      lastMessageAt: now.subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isPinned: false,
      members: <String>[userId],
    );

    _chats.addAll(<TelegramChat>[savedMessages, classChat, designRoom]);
    _messages[savedMessages.id] = <TelegramMessage>[
      TelegramMessage(
        id: 'saved-1',
        chatId: savedMessages.id,
        senderId: userId,
        senderName: 'Me',
        text: 'Your notes and links are here',
        sentAt: savedMessages.lastMessageAt,
        isEdited: false,
        isRead: true,
      ),
    ];
    _messages[classChat.id] = <TelegramMessage>[
      TelegramMessage(
        id: 'class-1',
        chatId: classChat.id,
        senderId: 'teacher',
        senderName: 'Teacher',
        text: 'Can you show real-time sync on two phones?',
        sentAt: now.subtract(const Duration(minutes: 18)),
        isEdited: false,
        isRead: true,
      ),
      TelegramMessage(
        id: 'class-2',
        chatId: classChat.id,
        senderId: userId,
        senderName: 'Me',
        text: 'Yes, Firebase streams update both screens instantly.',
        sentAt: classChat.lastMessageAt,
        isEdited: false,
        isRead: true,
      ),
    ];
    _messages[designRoom.id] = <TelegramMessage>[
      TelegramMessage(
        id: 'design-1',
        chatId: designRoom.id,
        senderId: 'ux',
        senderName: 'UX Lead',
        text: 'The chat list now looks close to Telegram',
        sentAt: designRoom.lastMessageAt,
        isEdited: false,
        isRead: true,
      ),
    ];

    _emitChats();
    for (final chat in _chats) {
      _emitMessages(chat.id);
    }
  }

  @override
  Future<TelegramChat> createChat({
    required String ownerId,
    required String title,
    required String subtitle,
  }) async {
    final now = DateTime.now();
    final chat = TelegramChat(
      id: 'chat-${now.microsecondsSinceEpoch}',
      title: title.trim(),
      subtitle: subtitle.trim().isEmpty ? 'online' : subtitle.trim(),
      avatarColor: _colorFor(title),
      lastMessage: 'No messages yet',
      lastMessageAt: now,
      unreadCount: 0,
      isPinned: false,
      members: <String>[ownerId],
    );
    _chats.add(chat);
    _messages[chat.id] = <TelegramMessage>[];
    _emitChats();
    _emitMessages(chat.id);
    return chat;
  }

  @override
  Future<TelegramChat> createDirectChat({
    required AppUser currentUser,
    required AppUser contact,
  }) async {
    final ids = <String>[currentUser.id, contact.id]..sort();
    final chatId = 'direct-${ids.join('-')}';
    final existing = _chats.where((chat) => chat.id == chatId);
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final now = DateTime.now();
    final chat = TelegramChat(
      id: chatId,
      title: contact.name,
      subtitle: contact.contactLabel,
      avatarColor: contact.avatarColor ?? _colorFor(contact.name),
      lastMessage: 'No messages yet',
      lastMessageAt: now,
      unreadCount: 0,
      isPinned: false,
      members: ids,
      type: 'direct',
      memberNames: <String, String>{
        currentUser.id: currentUser.name,
        contact.id: contact.name,
      },
      memberPhones: <String, String>{
        if (currentUser.phoneNumber != null)
          currentUser.id: currentUser.phoneNumber!,
        if (contact.phoneNumber != null) contact.id: contact.phoneNumber!,
      },
      memberColors: <String, int>{
        currentUser.id: currentUser.avatarColor ?? _colorFor(currentUser.name),
        contact.id: contact.avatarColor ?? _colorFor(contact.name),
      },
    );
    _chats.add(chat);
    _messages[chat.id] = <TelegramMessage>[];
    _emitChats();
    _emitMessages(chat.id);
    return chat;
  }

  @override
  Future<AppUser?> findUserByPhone(String phoneNumber) async {
    final key = _phoneSearchKey(phoneNumber);
    for (final contact in _demoContacts) {
      if (_phoneSearchKey(contact.phoneNumber ?? '') == key) {
        return contact;
      }
    }
    return null;
  }

  @override
  Future<void> updateChat(TelegramChat chat) async {
    final index = _chats.indexWhere((item) => item.id == chat.id);
    if (index == -1) {
      return;
    }

    _chats[index] = chat;
    _emitChats();
  }

  @override
  Future<void> deleteChat(String chatId) async {
    _chats.removeWhere((chat) => chat.id == chatId);
    _messages.remove(chatId);
    _emitChats();
    _emitMessages(chatId);
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    final now = DateTime.now();
    final message = TelegramMessage(
      id: 'message-${now.microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      text: trimmed,
      sentAt: now,
      isEdited: false,
      isRead: true,
    );
    final messages = _messages.putIfAbsent(chatId, () => <TelegramMessage>[]);
    messages.add(message);

    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(
        lastMessage: trimmed,
        lastMessageAt: now,
        unreadCount: senderId == 'teacher' ? _chats[index].unreadCount + 1 : 0,
      );
    }

    _emitMessages(chatId);
    _emitChats();
  }

  @override
  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    final messages = _messages[chatId];
    if (messages == null) {
      return;
    }

    final index = messages.indexWhere((message) => message.id == messageId);
    if (index == -1) {
      return;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    messages[index] = messages[index].copyWith(text: trimmed, isEdited: true);
    _syncLastMessage(chatId);
    _emitMessages(chatId);
    _emitChats();
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    final messages = _messages[chatId];
    if (messages == null) {
      return;
    }

    messages.removeWhere((message) => message.id == messageId);
    _syncLastMessage(chatId);
    _emitMessages(chatId);
    _emitChats();
  }

  void dispose() {
    _chatsController.close();
    for (final controller in _messageControllers.values) {
      controller.close();
    }
  }

  void _syncLastMessage(String chatId) {
    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index == -1) {
      return;
    }

    final messages = _messages[chatId] ?? <TelegramMessage>[];
    final latest = messages.isEmpty ? null : messages.last;
    _chats[index] = _chats[index].copyWith(
      lastMessage: latest?.text ?? 'No messages yet',
      lastMessageAt: latest?.sentAt ?? DateTime.now(),
      unreadCount: messages.isEmpty ? 0 : _chats[index].unreadCount,
    );
  }

  List<TelegramChat> _sortedChats() {
    final copy = List<TelegramChat>.of(_chats);
    copy.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.lastMessageAt.compareTo(a.lastMessageAt);
    });
    return List<TelegramChat>.unmodifiable(copy);
  }

  StreamController<List<TelegramMessage>> _controllerFor(String chatId) {
    return _messageControllers.putIfAbsent(
      chatId,
      () => StreamController<List<TelegramMessage>>.broadcast(),
    );
  }

  void _emitChats() {
    if (!_chatsController.isClosed) {
      _chatsController.add(_sortedChats());
    }
  }

  void _emitMessages(String chatId) {
    final controller = _controllerFor(chatId);
    if (!controller.isClosed) {
      controller.add(
        List<TelegramMessage>.unmodifiable(
          _messages[chatId] ?? const <TelegramMessage>[],
        ),
      );
    }
  }

  int _colorFor(String input) {
    const colors = <int>[
      0xff54a9eb,
      0xff40b97c,
      0xfff59b42,
      0xffe56b6f,
      0xff8e77ed,
      0xff19a7a8,
    ];
    return colors[input.hashCode.abs() % colors.length];
  }

  String _phoneSearchKey(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
