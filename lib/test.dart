Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Color(0xFFF5F5F5),
    appBar: _buildAppBar(),
    body: Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: AnimatedList(
                key: _listKey,
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.only(top: 16, bottom: 80),
                initialItemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index, animation) {
                  print('🔵 [DEBUG] Building AnimatedList item at index: $index, total messages: ${_messages.length}');

                  // Handle loading indicator
                  if (index == _messages.length) {
                    return _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(child: Loader()),
                          )
                        : const SizedBox.shrink();
                  }

                  // Validate index
                  if (index < 0 || index >= _messages.length) {
                    print('🔴 [DEBUG] Invalid index: $index');
                    return const SizedBox.shrink();
                  }

                  final message = _messages[index];
                  final messageDate = DateFormat('dd MMMM yyyy').format(DateTime.parse(message['timestamp']));
                  final isFirstUnread = _unreadMessageIds.contains(message['id']?.toString()) &&
                      _messages.indexWhere((m) => _unreadMessageIds.contains(m['id']?.toString())) == index;
                  final showDateHeader = index == _messages.length - 1 ||
                      (index + 1 < _messages.length &&
                          DateFormat('dd MMMM yyyy')
                                  .format(DateTime.parse(_messages[index + 1]['timestamp'])) !=
                              messageDate);
                  final isSameSender = index < _messages.length - 1 &&
                      _messages[index + 1]['isMe'] == message['isMe'] &&
                      _messages[index + 1]['type'] != 'notification';

                  return SlideTransition(
                    position: animation.drive(
                      Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: FadeTransition(
                      opacity: animation,
                      child: Column(
                        children: [
                          if (showDateHeader)
                            Center(
                              key: ValueKey('date_$messageDate'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[800]!.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  messageDate,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          if (isFirstUnread && _hasUnreadMessages)
                            Container(
                              key: ValueKey('unread_divider_${_unreadMessageIds.length}'),
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Divider(color: primaryTwo)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'New Messages (${_unreadMessageIds.length})',
                                      style: TextStyle(color: primaryTwo, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: primaryTwo)),
                                ],
                              ),
                            ),
                          GestureDetector(
                            key: ValueKey(message['id']?.toString() ?? message['timestamp']),
                            onHorizontalDragEnd: (details) {
                              if (details.primaryVelocity! > 0 && message['type'] != 'notification') {
                                print('🔵 [ChatScreen] Setting reply from gesture: $message');
                                _setReplyMessage(message);
                              }
                            },
                            child: MessageChat(
                              senderAvatar: message['sender_avatar'] ?? '',
                              senderName: message['sender_name'] ?? 'Unknown',
                              senderRole: message['sender_role'] ?? 'member',
                              isMe: message['isMe'] == 1,
                              message: message['message'],
                              time: message['timestamp'],
                              isSameSender: isSameSender,
                              replyToId: message['reply_to_id']?.toString(),
                              replyTo: message['reply_to_message'],
                              isAudio: message['type'] == 'audio',
                              isImage: message['type'] == 'image',
                              isNotification: message['type'] == 'notification',
                              onPlayAudio: _playAudio,
                              isPlaying: _isPlayingMap[message['id'].toString()] ?? false,
                              audioDuration: _audioDurationMap[message['id'].toString()] ?? Duration.zero,
                              audioPosition: _audioPositionMap[message['id'].toString()] ?? Duration.zero,
                              messageId: message['id'].toString(),
                              onReply: (messageId, messageText) {
                                _setReplyMessage(message);
                              },
                              onReplyTap: (messageId) {
                                _scrollToMessage(messageId);
                              },
                              messageStatus: message['status'] ?? 'sent',
                              messageContent: _buildMessageContent(message),
                              isHighlighted: message['isHighlighted'] ?? false,
                              isUnread: message['isMe'] == 0 && message['status'] == 'unread',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildTypingIndicator(),
            _buildMessageInput(),
          ],
        ),
        // ... (other Positioned widgets like unread badge, floating date header)
      ],
    ),
  );
}