import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat.dart';
import 'telegram_avatar.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({
    required this.chat,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final TelegramChat chat;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
        child: Row(
          children: <Widget>[
            TelegramAvatar(
              label: chat.title,
              color: chat.avatarColor,
              radius: 31,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (chat.isPinned)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.push_pin,
                            size: 17,
                            color: Color(0xff8e8e93),
                          ),
                        ),
                      Text(
                        _formattedTime(chat.lastMessageAt),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff8e8e93),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff8e8e93),
                            fontSize: 17,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          height: 28,
                          constraints: const BoxConstraints(minWidth: 28),
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 9),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xff3390ec),
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                          ),
                          child: Text(
                            chat.unreadCount > 99
                                ? '99+'
                                : '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedTime(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    if (sameDay) {
      return DateFormat('HH:mm').format(value);
    }
    return DateFormat('MMM d').format(value);
  }
}
