import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../services/chat_repository.dart';
import '../state/app_scope.dart';
import '../widgets/chat_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/telegram_avatar.dart';
import 'chat_screen.dart' as chat_ui;
import 'contacts_screen.dart' as contacts_ui;

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  ChatRepository? _repository;
  Stream<List<TelegramChat>>? _chatsStream;

  int _selectedTab = 2;
  String _query = '';
  bool _didSeed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final repository = AppScope.of(context).chatRepository;

    if (_repository != repository) {
      _repository = repository;
      _chatsStream = repository.watchChats(widget.user.id);
    }

    if (!_didSeed) {
      _didSeed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _seedDemoData(repository);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _TgColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            IndexedStack(
              index: _selectedTab,
              children: [
                _ContactsTab(
                  user: widget.user,
                  bottomPadding: bottomPadding + 100,
                  onOpenChat: _openChat,
                ),
                _CallsTab(bottomPadding: bottomPadding + 100),
                _ChatsTab(
                  chatsStream: _chatsStream,
                  searchController: _searchController,
                  query: _query,
                  bottomPadding: bottomPadding + 100,
                  onSearchChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                  onOpenChat: _openChat,
                  onOpenContacts: _openContacts,
                  onLongPressChat: _showChatActions,
                ),
                _SettingsTab(
                  user: widget.user,
                  bottomPadding: bottomPadding + 100,
                ),
              ],
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: bottomPadding + 12,
              child: _TelegramTabBar(
                selectedIndex: _selectedTab,
                onChanged: (index) {
                  setState(() {
                    _selectedTab = index;
                    if (index != 2) {
                      _query = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDemoData(ChatRepository repository) async {
    try {
      await repository.seedDemoData(widget.user.id);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _openChat(TelegramChat chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => chat_ui.ChatScreen(chat: chat, user: widget.user),
      ),
    );
  }

  void _openContacts() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => contacts_ui.ContactsScreen(user: widget.user),
      ),
    );
  }

  Future<void> _showChatActions(TelegramChat chat) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _TgColors.card,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: Colors.white,
                ),
                title: Text(
                  chat.isPinned ? 'Unpin' : 'Pin',
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  try {
                    await AppScope.of(context).chatRepository.updateChat(
                      chat.copyWith(isPinned: !chat.isPinned),
                    );
                  } catch (e) {
                    _showSnack(e.toString().replaceFirst('Exception: ', ''));
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Color(0xffff453a),
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xffff453a)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDeleteChat(chat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteChat(TelegramChat chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _TgColors.card,
          title: Text(
            'Delete ${chat.title}?',
            style: const TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This chat will be removed.',
            style: TextStyle(color: _TgColors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffff453a),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await AppScope.of(context).chatRepository.deleteChat(chat.id);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _TgColors.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  const _ChatsTab({
    required this.chatsStream,
    required this.searchController,
    required this.query,
    required this.bottomPadding,
    required this.onSearchChanged,
    required this.onOpenChat,
    required this.onOpenContacts,
    required this.onLongPressChat,
  });

  final Stream<List<TelegramChat>>? chatsStream;
  final TextEditingController searchController;
  final String query;
  final double bottomPadding;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<TelegramChat> onOpenChat;
  final VoidCallback onOpenContacts;
  final ValueChanged<TelegramChat> onLongPressChat;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
          title: 'Чаты',
          left: _TopPill(label: 'Изм.', onTap: () {}),
          right: _RoundToolbar(
            children: [
              IconButton(
                tooltip: 'Contacts',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onOpenContacts,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _DarkSearchField(
            controller: searchController,
            hintText: 'Поиск',
            onChanged: onSearchChanged,
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TelegramChat>>(
            stream: chatsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load chats',
                  message: snapshot.error.toString(),
                );
              }

              final chats = (snapshot.data ?? const <TelegramChat>[])
                  .where(
                    (chat) =>
                        query.isEmpty ||
                        chat.title.toLowerCase().contains(query) ||
                        chat.lastMessage.toLowerCase().contains(query),
                  )
                  .toList();

              if (chats.isEmpty) {
                return const EmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'No chats',
                  message: 'Create or open a contact to start messaging.',
                );
              }

              return ListView.separated(
                padding: EdgeInsets.only(bottom: bottomPadding),
                itemCount: chats.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 86,
                  color: _TgColors.divider,
                ),
                itemBuilder: (context, index) {
                  final chat = chats[index];

                  return ChatTile(
                    chat: chat,
                    onTap: () => onOpenChat(chat),
                    onLongPress: () => onLongPressChat(chat),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactsTab extends StatefulWidget {
  const _ContactsTab({
    required this.user,
    required this.bottomPadding,
    required this.onOpenChat,
  });

  final AppUser user;
  final double bottomPadding;
  final ValueChanged<TelegramChat> onOpenChat;

  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  final TextEditingController _searchController = TextEditingController();

  Stream<List<AppUser>>? _contactsStream;
  ChatRepository? _repository;
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final repository = AppScope.of(context).chatRepository;

    if (_repository != repository) {
      _repository = repository;
      _contactsStream = repository.watchContacts(widget.user.id);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(
          title: 'Контакты',
          left: _TopPill(label: 'Изм.', onTap: () {}),
          right: _RoundToolbar(
            children: [
              IconButton(
                tooltip: 'Find contact',
                icon: const Icon(Icons.person_add_alt_1_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          contacts_ui.ContactsScreen(user: widget.user),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: _DarkSearchField(
            controller: _searchController,
            hintText: 'Поиск контактов',
            onChanged: (value) {
              setState(() {
                _query = value.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: _contactsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Could not load contacts',
                  message: snapshot.error.toString(),
                );
              }

              final contacts = (snapshot.data ?? const <AppUser>[])
                  .where(
                    (contact) =>
                        _query.isEmpty ||
                        contact.name.toLowerCase().contains(_query) ||
                        contact.contactLabel.toLowerCase().contains(_query),
                  )
                  .toList();

              if (contacts.isEmpty) {
                return const EmptyState(
                  icon: Icons.person_outline,
                  title: 'No contacts',
                  message: 'Find a user by phone number.',
                );
              }

              return ListView.separated(
                padding: EdgeInsets.only(bottom: widget.bottomPadding),
                itemCount: contacts.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 82,
                  color: _TgColors.divider,
                ),
                itemBuilder: (context, index) {
                  final contact = contacts[index];

                  return ListTile(
                    minLeadingWidth: 52,
                    leading: TelegramAvatar(
                      label: contact.name,
                      color: contact.avatarColor ?? 0xff54a9eb,
                      radius: 27,
                    ),
                    title: Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      contact.contactLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _TgColors.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                    onTap: () => _openDirectChat(contact),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openDirectChat(AppUser contact) async {
    try {
      final chat = await _repository!.createDirectChat(
        currentUser: widget.user,
        contact: contact,
      );

      widget.onOpenChat(chat);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: _TgColors.card,
        ),
      );
    }
  }
}

class _CallsTab extends StatelessWidget {
  const _CallsTab({required this.bottomPadding});

  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final calls = [
      _CallData(
        title: 'Telegram User',
        subtitle: 'исходящий, сегодня',
        icon: Icons.call_made,
        missed: false,
      ),
      _CallData(
        title: 'Design Room',
        subtitle: 'пропущенный, вчера',
        icon: Icons.call_missed,
        missed: true,
      ),
      _CallData(
        title: 'Mira Kasenova',
        subtitle: 'входящий, вчера',
        icon: Icons.call_received,
        missed: false,
      ),
    ];

    return Column(
      children: [
        _Header(
          title: 'Звонки',
          left: _TopPill(label: 'Изм.', onTap: () {}),
          right: _RoundToolbar(
            children: [
              IconButton(
                tooltip: 'New call',
                icon: const Icon(Icons.phone_forwarded_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.only(bottom: bottomPadding),
            itemCount: calls.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 82, color: _TgColors.divider),
            itemBuilder: (context, index) {
              final call = calls[index];

              return ListTile(
                leading: TelegramAvatar(
                  label: call.title,
                  color: call.missed ? 0xffff453a : 0xff54a9eb,
                  radius: 27,
                ),
                title: Text(
                  call.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      call.icon,
                      size: 15,
                      color: call.missed
                          ? const Color(0xffff453a)
                          : _TgColors.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      call.subtitle,
                      style: const TextStyle(color: _TgColors.secondaryText),
                    ),
                  ],
                ),
                trailing: const Icon(
                  Icons.info_outline,
                  color: _TgColors.accent,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.user, required this.bottomPadding});

  final AppUser user;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding),
      children: [
        _Header(
          title: user.name,
          left: _TopIconButton(icon: Icons.qr_code_2_rounded, onPressed: () {}),
          right: _TopPill(label: 'Изм.', onTap: () {}),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          children: [
            ListTile(
              leading: TelegramAvatar(
                label: user.name,
                color: user.avatarColor ?? 0xff54a9eb,
                radius: 32,
              ),
              title: Text(
                user.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                user.contactLabel,
                style: const TextStyle(color: _TgColors.secondaryText),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: Icons.bookmark,
              iconColor: const Color(0xff0a84ff),
              title: 'Избранное',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.phone,
              iconColor: const Color(0xff30d158),
              title: 'Недавние звонки',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.devices_rounded,
              iconColor: const Color(0xffffb340),
              title: 'Устройства',
              trailingText: '4',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.folder_rounded,
              iconColor: const Color(0xff64d2ff),
              title: 'Папки с чатами',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: Icons.notifications_active,
              iconColor: const Color(0xffff453a),
              title: 'Уведомления и звуки',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.lock,
              iconColor: const Color(0xff8e8e93),
              title: 'Конфиденциальность',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.storage,
              iconColor: const Color(0xff30d158),
              title: 'Данные и память',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.language,
              iconColor: const Color(0xff0a84ff),
              title: 'Язык',
              trailingText: 'Русский',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 18),
        _SettingsCard(
          children: [
            _SettingsRow(
              icon: scope.usesFirebase
                  ? Icons.cloud_done
                  : Icons.cloud_off_rounded,
              iconColor: scope.usesFirebase
                  ? const Color(0xff30d158)
                  : const Color(0xffff9f0a),
              title: scope.usesFirebase
                  ? 'Firebase подключён'
                  : 'Локальный режим',
              subtitle: scope.usesFirebase
                  ? 'Auth и чаты синхронизируются через Firebase'
                  : 'Demo mode без Firebase',
              onTap: () {},
            ),
            _SettingsRow(
              icon: Icons.logout,
              iconColor: const Color(0xffff453a),
              title: 'Выйти',
              danger: true,
              onTap: () async {
                await scope.authService.signOut();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.left, required this.right});

  final String title;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          left,
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          right,
        ],
      ),
    );
  }
}

class _TelegramTabBar extends StatelessWidget {
  const _TelegramTabBar({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      const _TabItemData(Icons.person, 'Контакты'),
      const _TabItemData(Icons.phone, 'Звонки'),
      const _TabItemData(Icons.chat_bubble, 'Чаты'),
      const _TabItemData(Icons.settings, 'Настройки'),
    ];

    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: const Color(0xe61d1d1f),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: const Color(0xff313133)),
        boxShadow: const [BoxShadow(color: Color(0x70000000), blurRadius: 20)],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          final item = items[index];

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(32),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xff3a3a3c)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      color: selected ? _TgColors.accent : Colors.white,
                      size: 25,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? _TgColors.accent : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabItemData {
  const _TabItemData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _DarkSearchField extends StatelessWidget {
  const _DarkSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 17),
        cursorColor: _TgColors.accent,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: _TgColors.secondaryText),
          prefixIcon: const Icon(
            Icons.search,
            color: _TgColors.secondaryText,
            size: 22,
          ),
          filled: true,
          fillColor: _TgColors.surface,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _TopPill extends StatelessWidget {
  const _TopPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: onTap,
      child: Container(
        height: 46,
        constraints: const BoxConstraints(minWidth: 70),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _TgColors.surface,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xff323234)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(23),
      onTap: onPressed,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _TgColors.surface,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xff323234)),
        ),
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }
}

class _RoundToolbar extends StatelessWidget {
  const _RoundToolbar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: _TgColors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xff323234)),
      ),
      child: IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _TgColors.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          final child = children[index];

          if (index == children.length - 1) {
            return child;
          }

          return Column(
            children: [
              child,
              const Divider(
                height: 1,
                indent: 74,
                endIndent: 30,
                color: _TgColors.divider,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: Colors.white, size: 23),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: danger ? const Color(0xffff453a) : Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(
                color: _TgColors.secondaryText,
                fontSize: 13,
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                trailingText!,
                style: const TextStyle(
                  color: _TgColors.secondaryText,
                  fontSize: 16,
                ),
              ),
            ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: _TgColors.chevron),
        ],
      ),
    );
  }
}

class _CallData {
  const _CallData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.missed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool missed;
}

class _TgColors {
  static const Color canvas = Color(0xff000000);
  static const Color card = Color(0xff1c1c1e);
  static const Color surface = Color(0xff19191b);
  static const Color accent = Color(0xff3390ec);
  static const Color secondaryText = Color(0xff8e8e93);
  static const Color chevron = Color(0xff636366);
  static const Color divider = Color(0xff2c2c2e);
}
