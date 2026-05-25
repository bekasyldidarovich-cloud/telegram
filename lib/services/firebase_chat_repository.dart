import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'chat_repository.dart';

class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<List<TelegramChat>> watchChats(String userId) {
    return _chats.where('members', arrayContains: userId).snapshots().map((
      snapshot,
    ) {
      final chats = snapshot.docs
          .map((doc) => _chatFromDoc(doc, viewerId: userId))
          .toList();
      chats.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.lastMessageAt.compareTo(a.lastMessageAt);
      });
      return chats;
    });
  }

  @override
  Stream<List<AppUser>> watchContacts(String userId) {
    return _users.orderBy('displayName').snapshots().map((snapshot) {
      return snapshot.docs
          .map(_userFromDoc)
          .where((user) => user.id != userId)
          .toList();
    });
  }

  @override
  Stream<List<TelegramMessage>> watchMessages(String chatId) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_messageFromDoc).toList());
  }

  @override
  Future<void> seedDemoData(String userId) async {
    final existing = await _chats
        .where('members', arrayContains: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final now = DateTime.now();
    final starterChats = <TelegramChat>[
      TelegramChat(
        id: 'class-chat',
        title: 'Class QA Chat',
        subtitle: 'online',
        avatarColor: 0xff40b97c,
        lastMessage: 'Firebase is ready for two-phone sync',
        lastMessageAt: now.subtract(const Duration(minutes: 6)),
        unreadCount: 1,
        isPinned: true,
        members: <String>[userId],
      ),
      TelegramChat(
        id: 'flutter-design',
        title: 'Flutter Design Room',
        subtitle: 'last seen recently',
        avatarColor: 0xff54a9eb,
        lastMessage: 'Edit or delete a message from the menu',
        lastMessageAt: now.subtract(const Duration(minutes: 28)),
        unreadCount: 0,
        isPinned: false,
        members: <String>[userId],
      ),
    ];

    final batch = _firestore.batch();
    for (final chat in starterChats) {
      final doc = _chats.doc(chat.id);
      batch.set(doc, _chatToMap(chat, createdBy: userId));
      final messageDoc = doc.collection('messages').doc();
      batch.set(messageDoc, <String, dynamic>{
        'chatId': chat.id,
        'senderId': userId,
        'senderName': 'Telegram Clone',
        'text': chat.lastMessage,
        'sentAt': Timestamp.fromDate(chat.lastMessageAt),
        'isEdited': false,
        'isRead': true,
      });
    }
    await batch.commit();
  }

  @override
  Future<TelegramChat> createChat({
    required String ownerId,
    required String title,
    required String subtitle,
  }) async {
    final now = DateTime.now();
    final doc = _chats.doc();
    final chat = TelegramChat(
      id: doc.id,
      title: title.trim(),
      subtitle: subtitle.trim().isEmpty ? 'online' : subtitle.trim(),
      avatarColor: _colorFor(title),
      lastMessage: 'No messages yet',
      lastMessageAt: now,
      unreadCount: 0,
      isPinned: false,
      members: <String>[ownerId],
    );
    await doc.set(_chatToMap(chat, createdBy: ownerId));
    return chat;
  }

  @override
  Future<TelegramChat> createDirectChat({
    required AppUser currentUser,
    required AppUser contact,
  }) async {
    if (currentUser.id == contact.id) {
      throw Exception('You cannot start a chat with yourself.');
    }

    final memberIds = <String>[currentUser.id, contact.id]..sort();
    final chatId = 'direct_${memberIds.join('_')}';
    final chatRef = _chats.doc(chatId);
    final now = DateTime.now();
    final currentColor = currentUser.avatarColor ?? _colorFor(currentUser.name);
    final contactColor = contact.avatarColor ?? _colorFor(contact.name);
    final memberNames = <String, String>{
      currentUser.id: currentUser.name,
      contact.id: contact.name,
    };
    final memberPhones = <String, String>{
      if ((currentUser.phoneNumber ?? '').isNotEmpty)
        currentUser.id: currentUser.phoneNumber!,
      if ((contact.phoneNumber ?? '').isNotEmpty)
        contact.id: contact.phoneNumber!,
    };
    final memberColors = <String, int>{
      currentUser.id: currentColor,
      contact.id: contactColor,
    };

    final snapshot = await chatRef.get();
    if (snapshot.exists) {
      await chatRef.set(<String, dynamic>{
        'memberNames': memberNames,
        'memberPhones': memberPhones,
        'memberColors': memberColors,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return _chatFromDoc(await chatRef.get(), viewerId: currentUser.id);
    }

    final chat = TelegramChat(
      id: chatId,
      title: contact.name,
      subtitle: contact.contactLabel,
      avatarColor: contactColor,
      lastMessage: 'No messages yet',
      lastMessageAt: now,
      unreadCount: 0,
      isPinned: false,
      members: memberIds,
      type: 'direct',
      memberNames: memberNames,
      memberPhones: memberPhones,
      memberColors: memberColors,
    );

    await chatRef.set(_chatToMap(chat, createdBy: currentUser.id));
    return chat;
  }

  @override
  Future<AppUser?> findUserByPhone(String phoneNumber) async {
    final key = _phoneSearchKey(phoneNumber);
    if (key.isEmpty) {
      return null;
    }

    final snapshot = await _users
        .where('phoneSearchKey', isEqualTo: key)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return _userFromDoc(snapshot.docs.first);
  }

  @override
  Future<void> updateChat(TelegramChat chat) {
    return _chats.doc(chat.id).update(<String, dynamic>{
      'title': chat.title,
      'subtitle': chat.subtitle,
      'avatarColor': chat.avatarColor,
      'isPinned': chat.isPinned,
      'members': chat.members,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final messages = await _chats.doc(chatId).collection('messages').get();
    final batch = _firestore.batch();
    for (final message in messages.docs) {
      batch.delete(message.reference);
    }
    batch.delete(_chats.doc(chatId));
    await batch.commit();
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

    final chatRef = _chats.doc(chatId);
    final messageRef = chatRef.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(messageRef, <String, dynamic>{
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'text': trimmed,
      'sentAt': FieldValue.serverTimestamp(),
      'isEdited': false,
      'isRead': true,
    });
    batch.update(chatRef, <String, dynamic>{
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  @override
  Future<void> updateMessage({
    required String chatId,
    required String messageId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty.');
    }

    await _chats.doc(chatId).collection('messages').doc(messageId).update(
      <String, dynamic>{
        'text': trimmed,
        'isEdited': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await _syncLastMessage(chatId);
  }

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _chats.doc(chatId).collection('messages').doc(messageId).delete();
    await _syncLastMessage(chatId);
  }

  Future<void> _syncLastMessage(String chatId) async {
    final latest = await _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (latest.docs.isEmpty) {
      await _chats.doc(chatId).update(<String, dynamic>{
        'lastMessage': 'No messages yet',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });
      return;
    }

    final message = _messageFromDoc(latest.docs.first);
    await _chats.doc(chatId).update(<String, dynamic>{
      'lastMessage': message.text,
      'lastMessageAt': Timestamp.fromDate(message.sentAt),
    });
  }

  TelegramChat _chatFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String viewerId,
  }) {
    final data = doc.data() ?? <String, dynamic>{};
    final members = List<String>.from(
      data['members'] as List<dynamic>? ?? const [],
    );
    final type = data['type'] as String? ?? 'group';
    final memberNames = _stringMap(data['memberNames']);
    final memberPhones = _stringMap(data['memberPhones']);
    final memberColors = _intMap(data['memberColors']);
    String? otherMemberId;
    for (final memberId in members) {
      if (memberId != viewerId) {
        otherMemberId = memberId;
        break;
      }
    }
    final directTitle = otherMemberId == null
        ? null
        : memberNames[otherMemberId] ?? (data['title'] as String?);
    final directSubtitle = otherMemberId == null
        ? null
        : memberPhones[otherMemberId] ?? 'online';
    final directColor = otherMemberId == null
        ? null
        : memberColors[otherMemberId];

    return TelegramChat(
      id: doc.id,
      title: type == 'direct'
          ? directTitle ?? 'Telegram User'
          : data['title'] as String? ?? 'Untitled',
      subtitle: type == 'direct'
          ? directSubtitle ?? 'online'
          : data['subtitle'] as String? ?? 'online',
      avatarColor: type == 'direct'
          ? directColor ?? 0xff54a9eb
          : (data['avatarColor'] as int? ?? 0xff54a9eb),
      lastMessage: data['lastMessage'] as String? ?? 'No messages yet',
      lastMessageAt: _dateFrom(data['lastMessageAt']),
      unreadCount: data['unreadCount'] as int? ?? 0,
      isPinned: data['isPinned'] as bool? ?? false,
      members: members,
      type: type,
      memberNames: memberNames,
      memberPhones: memberPhones,
      memberColors: memberColors,
    );
  }

  AppUser _userFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final name = data['displayName'] as String? ?? 'Telegram User';
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: name,
      phoneNumber: data['phoneNumber'] as String?,
      photoUrl: data['photoUrl'] as String?,
      avatarColor: data['avatarColor'] as int? ?? _colorFor(name),
    );
  }

  TelegramMessage _messageFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return TelegramMessage(
      id: doc.id,
      chatId: data['chatId'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Telegram User',
      text: data['text'] as String? ?? '',
      sentAt: _dateFrom(data['sentAt']),
      isEdited: data['isEdited'] as bool? ?? false,
      isRead: data['isRead'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _chatToMap(
    TelegramChat chat, {
    required String createdBy,
  }) {
    return <String, dynamic>{
      'title': chat.title,
      'subtitle': chat.subtitle,
      'avatarColor': chat.avatarColor,
      'lastMessage': chat.lastMessage,
      'lastMessageAt': Timestamp.fromDate(chat.lastMessageAt),
      'unreadCount': chat.unreadCount,
      'isPinned': chat.isPinned,
      'members': chat.members,
      'type': chat.type,
      'memberNames': chat.memberNames,
      'memberPhones': chat.memberPhones,
      'memberColors': chat.memberColors,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DateTime _dateFrom(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.now();
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

  Map<String, String> _stringMap(Object? value) {
    if (value is! Map) {
      return const <String, String>{};
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  Map<String, int> _intMap(Object? value) {
    if (value is! Map) {
      return const <String, int>{};
    }
    return value.map((key, item) {
      if (item is int) {
        return MapEntry(key.toString(), item);
      }
      if (item is num) {
        return MapEntry(key.toString(), item.toInt());
      }
      return MapEntry(key.toString(), _colorFor(key.toString()));
    });
  }

  String _phoneSearchKey(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
