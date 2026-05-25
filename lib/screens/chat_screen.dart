import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/chat_repository.dart';
import '../state/app_scope.dart';
import '../widgets/chat_wallpaper.dart';
import '../widgets/empty_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/telegram_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({required this.chat, required this.user, super.key});

  final TelegramChat chat;
  final AppUser user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  ChatRepository? _repository;
  Stream<List<TelegramMessage>>? _messagesStream;
  bool _isSending = false;

  bool _showEmoji = false;
  bool _showAttach = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final repository = AppScope.of(context).chatRepository;
    if (_repository != repository) {
      _repository = repository;
      _messagesStream = repository.watchMessages(widget.chat.id);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff000000),
      appBar: AppBar(
        backgroundColor: const Color(0xff0b0b0d),
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: <Widget>[
            TelegramAvatar(
              label: widget.chat.title,
              color: widget.chat.avatarColor,
              radius: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    widget.chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.chat.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff8e8e93),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Call',
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.6),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, anim1, anim2) {
                  return _TelegramCallOverlay(
                    title: widget.chat.title,
                    avatarColor: widget.chat.avatarColor,
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatInfo(),
          ),
        ],
      ),
      body: ChatWallpaper(
        child: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder<List<TelegramMessage>>(
                stream: _messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Could not load messages',
                      message: snapshot.error.toString(),
                    );
                  }

                  final messages = snapshot.data ?? const <TelegramMessage>[];
                  if (messages.isEmpty) {
                    return const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No messages here yet',
                      message: 'Send the first message.',
                    );
                  }

                  _scheduleScrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderId == widget.user.id;
                      return MessageBubble(
                        message: message,
                        isMine: isMine,
                        onLongPress: () => _showMessageActions(message, isMine),
                      );
                    },
                  );
                },
              ),
            ),
            _Composer(
              controller: _messageController,
              isSending: _isSending,
              onSend: _sendMessage,
              onToggleEmoji: () {
                setState(() {
                  _showEmoji = !_showEmoji;
                  _showAttach = false;
                });
              },
              onToggleAttach: () {
                setState(() {
                  _showAttach = !_showAttach;
                  _showEmoji = false;
                });
              },
            ),
            if (_showEmoji) _buildEmojiDrawer(),
            if (_showAttach) _buildAttachDrawer(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiDrawer() {
    final emojis = [
      '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
      '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🥸', '🤩', '🥳',
      '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤',
      '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🫣', '🤭'
    ];
    return Container(
      height: 250,
      color: const Color(0xff1c1c1e),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              final text = _messageController.text;
              final selection = _messageController.selection;
              final cursorPosition = selection.baseOffset >= 0 ? selection.baseOffset : text.length;
              final newText = text.replaceRange(cursorPosition, cursorPosition, emojis[index]);
              _messageController.value = TextEditingValue(
                text: newText,
                selection: TextSelection.collapsed(offset: cursorPosition + emojis[index].length),
              );
            },
            child: Center(
              child: Text(
                emojis[index],
                style: const TextStyle(fontSize: 26),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachDrawer() {
    return Container(
      height: 120,
      color: const Color(0xff1c1c1e),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _attachItem(Icons.image, 'Фото', const Color(0xffbf5af2), _sendImageMessage),
          _attachItem(Icons.insert_drive_file, 'Файл', const Color(0xff0a84ff), _sendFileMessage),
          _attachItem(Icons.location_on, 'Локация', const Color(0xff30d158), _sendLocationMessage),
          _attachItem(Icons.person, 'Контакт', const Color(0xffff9f0a), _sendContactMessage),
        ],
      ),
    );
  }

  Widget _attachItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _sendCustomMessage(String text) async {
    setState(() {
      _showEmoji = false;
      _showAttach = false;
    });
    try {
      await AppScope.of(context).chatRepository.sendMessage(
        chatId: widget.chat.id,
        senderId: widget.user.id,
        senderName: widget.user.name,
        text: text,
      );
      _scheduleScrollToBottom();
    } on Object catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _sendImageMessage() => _sendCustomMessage('🖼️ Фотография: [Изображение]');
  void _sendFileMessage() => _sendCustomMessage('📁 Файл: Telegram_Options.pdf');
  void _sendLocationMessage() => _sendCustomMessage('📍 Геопозиция: [Москва, Красная Площадь]');
  void _sendContactMessage() => _sendCustomMessage('👤 Контакт: Mira Kasenova (+7 700 444-55-66)');

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      _showSnack('Message cannot be empty.');
      return;
    }

    setState(() {
      _isSending = true;
      _showEmoji = false;
      _showAttach = false;
    });

    try {
      await AppScope.of(context).chatRepository.sendMessage(
        chatId: widget.chat.id,
        senderId: widget.user.id,
        senderName: widget.user.name,
        text: text,
      );
      _messageController.clear();
      _scheduleScrollToBottom();
    } on Object catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _showMessageActions(TelegramMessage message, bool isMine) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xff1c1c1e),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text('Edit', style: TextStyle(color: Colors.white)),
              enabled: isMine,
              onTap: isMine
                  ? () {
                      Navigator.pop(context);
                      _editMessage(message);
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xffd43c3c),
              ),
              title: const Text(
                'Delete',
                style: TextStyle(color: Color(0xffd43c3c)),
              ),
              enabled: isMine,
              onTap: isMine
                  ? () {
                      Navigator.pop(context);
                      _deleteMessage(message);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMessage(TelegramMessage message) async {
    final controller = TextEditingController(text: message.text);
    final updatedText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Message'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (updatedText == null) {
      return;
    }
    if (updatedText.isEmpty) {
      _showSnack('Message cannot be empty.');
      return;
    }

    await _runAction(
      () => AppScope.of(context).chatRepository.updateMessage(
        chatId: widget.chat.id,
        messageId: message.id,
        text: updatedText,
      ),
    );
  }

  Future<void> _deleteMessage(TelegramMessage message) async {
    await _runAction(
      () => AppScope.of(context).chatRepository.deleteMessage(
        chatId: widget.chat.id,
        messageId: message.id,
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (error) {
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showChatInfo() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xff1c1c1e),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            children: <Widget>[
              TelegramAvatar(
                label: widget.chat.title,
                color: widget.chat.avatarColor,
                radius: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.chat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.chat.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xff8e8e93)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onToggleEmoji,
    required this.onToggleAttach,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onToggleEmoji;
  final VoidCallback onToggleAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0x00000000),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xff1c1c1e),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Emoji',
                      color: const Color(0xff8e8e93),
                      onPressed: onToggleEmoji,
                      icon: const Icon(Icons.emoji_emotions_outlined),
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        cursorColor: const Color(0xff3390ec),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Message',
                          hintStyle: TextStyle(color: Color(0xff8e8e93)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => onSend(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Attach',
                      color: const Color(0xff8e8e93),
                      onPressed: onToggleAttach,
                      icon: const Icon(Icons.attach_file),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 46,
              height: 46,
              child: FilledButton(
                onPressed: isSending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                  backgroundColor: const Color(0xff3390ec),
                ),
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TelegramCallOverlay extends StatefulWidget {
  const _TelegramCallOverlay({required this.title, this.avatarColor = 0xff54a9eb});

  final String title;
  final int avatarColor;

  @override
  State<_TelegramCallOverlay> createState() => _TelegramCallOverlayState();
}

class _TelegramCallOverlayState extends State<_TelegramCallOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Timer? _timer;
  int _seconds = 0;
  bool _connected = false;
  bool _muted = false;
  bool _speaker = false;
  bool _video = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _connected = true;
        });
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      const Color(0xff54a9eb),
      const Color(0xff40b97c),
      const Color(0xfff59b42),
      const Color(0xffe56b6f),
      const Color(0xff8e77ed),
      const Color(0xff19a7a8),
    ];
    final color = colors[widget.title.hashCode.abs() % colors.length];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withOpacity(0.4),
                    Colors.black87,
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.black26),
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    children: <Widget>[
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _connected ? _formatDuration(_seconds) : 'Звонок...',
                        style: TextStyle(
                          color: _connected ? const Color(0xff32d74b) : Colors.white60,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_connected)
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 130 + (50 * _pulseController.value),
                                  height: 130 + (50 * _pulseController.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color.withOpacity(0.15 * (1 - _pulseController.value)),
                                  ),
                                ),
                                Container(
                                  width: 130 + (100 * _pulseController.value),
                                  height: 130 + (100 * _pulseController.value),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color.withOpacity(0.08 * (1 - _pulseController.value)),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      TelegramAvatar(
                        label: widget.title,
                        color: widget.avatarColor,
                        radius: 65,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _CallActionButton(
                            icon: _muted ? Icons.mic_off : Icons.mic,
                            label: 'Звук',
                            isActive: _muted,
                            onTap: () {
                              setState(() {
                                _muted = !_muted;
                              });
                            },
                          ),
                          _CallActionButton(
                            icon: _speaker ? Icons.volume_up : Icons.volume_down,
                            label: 'Динамик',
                            isActive: _speaker,
                            onTap: () {
                              setState(() {
                                _speaker = !_speaker;
                              });
                            },
                          ),
                          _CallActionButton(
                            icon: _video ? Icons.videocam : Icons.videocam_off,
                            label: 'Видео',
                            isActive: _video,
                            onTap: () {
                              setState(() {
                                _video = !_video;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 50),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xffff453a),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x66ff453a),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.call_end,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white12,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
