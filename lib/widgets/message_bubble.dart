import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.isMine,
    required this.onLongPress,
    super.key,
  });

  final TelegramMessage message;
  final bool isMine;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? const Color(0xff2b8ae8)
        : const Color(0xff1f2933);
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMine ? 14 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 14),
    );

    return Align(
      alignment: alignment,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            left: isMine ? 58 : 8,
            right: isMine ? 8 : 58,
            top: 3,
            bottom: 3,
          ),
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 5),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: radius,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x42000000),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      message.senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xff64d2ff),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (message.isEdited)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Text(
                            'edited',
                            style: TextStyle(
                              color: Color(0xbfffffff),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      Text(
                        DateFormat('HH:mm').format(message.sentAt),
                        style: const TextStyle(
                          color: Color(0xbfffffff),
                          fontSize: 11,
                        ),
                      ),
                      if (isMine)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: Icon(
                            Icons.done_all,
                            size: 15,
                            color: Color(0xddffffff),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
