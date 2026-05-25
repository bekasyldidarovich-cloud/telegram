import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../widgets/telegram_avatar.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({required this.user, super.key});

  final AppUser user;

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  final List<_DemoContact> _contacts = const [
    _DemoContact(
      name: 'Mira Kasenova',
      phone: '+7 700 444-55-66',
      status: 'была недавно',
      avatarColor: 0xff54a9eb,
    ),
    _DemoContact(
      name: 'Telegram User',
      phone: '+7 701 222-33-44',
      status: 'онлайн',
      avatarColor: 0xff30d158,
    ),
    _DemoContact(
      name: 'Design Room',
      phone: '+7 777 888-99-00',
      status: 'группа',
      avatarColor: 0xffbf5af2,
    ),
    _DemoContact(
      name: 'Aruzhan',
      phone: '+7 747 123-45-67',
      status: 'была вчера',
      avatarColor: 0xffff9f0a,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _contacts.where((contact) {
      final query = _query.toLowerCase();

      return query.isEmpty ||
          contact.name.toLowerCase().contains(query) ||
          contact.phone.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xff000000),
      appBar: AppBar(
        backgroundColor: const Color(0xff000000),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Контакты',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Добавить контакт',
            icon: const Icon(Icons.person_add_alt_1_outlined),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 17),
              cursorColor: const Color(0xff3390ec),
              decoration: InputDecoration(
                hintText: 'Поиск',
                hintStyle: const TextStyle(color: Color(0xff8e8e93)),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xff8e8e93),
                ),
                filled: true,
                fillColor: const Color(0xff1c1c1e),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: filteredContacts.isEmpty
                ? const Center(
                    child: Text(
                      'Контакты не найдены',
                      style: TextStyle(
                        color: Color(0xff8e8e93),
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredContacts.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 82,
                      color: Color(0xff2c2c2e),
                    ),
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];

                      return ListTile(
                        minLeadingWidth: 52,
                        leading: TelegramAvatar(
                          label: contact.name,
                          color: contact.avatarColor,
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
                          '${contact.status} • ${contact.phone}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff8e8e93),
                            fontSize: 15,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xff636366),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1c1c1e),
          title: const Text(
            'Добавить контакт',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  labelStyle: TextStyle(color: Color(0xff8e8e93)),
                ),
              ),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  labelStyle: TextStyle(color: Color(0xff8e8e93)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Контакт добавлен в демо-режиме'),
                  ),
                );
              },
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }
}

class _DemoContact {
  const _DemoContact({
    required this.name,
    required this.phone,
    required this.status,
    required this.avatarColor,
  });

  final String name;
  final String phone;
  final String status;
  final int avatarColor;
}
