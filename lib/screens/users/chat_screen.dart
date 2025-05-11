import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zoom_way/data/api/passengers_api_service.dart';

class ChatScreen extends StatefulWidget {
  final int rideId;
  final int senderId;
  final int receiverId;
  final String senderType;
  final String receiverType;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverName,
    required this.rideId,
    required this.senderId,
    required this.receiverId,
    required this.senderType,
    required this.receiverType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  String? _authToken;
  bool _isInitialLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    _authToken = await _getAuthToken();
    if (_authToken == null) return;

    debugPrint('[CHAT] Token: $_authToken');
    await _fetchMessages();
    _startPolling();

    if (!_isDisposed) setState(() => _isInitialLoading = false);
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isDisposed) _fetchMessages();
    });
  }

  Future<void> _fetchMessages() async {
    debugPrint('[API] Fetching messages for ride ${widget.rideId}');
    try {
      final result = await ApiService.getChatMessages(widget.rideId);
      debugPrint('[API RESPONSE] $result');
      if (result['success'] == true) {
        _updateMessages(result['data']['messages']);
      } else {}
    } catch (e) {}
  }

  void _updateMessages(List<dynamic> data) {
    final newMessages =
        data.map((e) => ChatMessage.fromJson(e)).toList().reversed.toList();
    if (!_areMessagesEqual(_messages, newMessages)) {
      setState(() {
        _messages
          ..clear()
          ..addAll(newMessages);
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final temp = _createTempMessage(text);
    _addTempMessage(temp);

    try {
      debugPrint('[SEND] API body: $text');
      final result = await ApiService.sendMessage(
        rideId: widget.rideId,
        message: text,
        senderType: widget.senderType,
        receiverType: widget.receiverType,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
      );
      debugPrint('[SEND RESPONSE] $result');
      if (result['success'] == true) {
        _replaceTempWithSentMessage(temp, result['data']['data']);
      } else {}
    } catch (e) {
    } finally {
      if (!_isDisposed) setState(() => _isSending = false);
    }
  }

  ChatMessage _createTempMessage(String text) => ChatMessage(
        id: -1,
        message: text,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        senderType: widget.senderType,
        receiverType: widget.receiverType,
        rideId: widget.rideId,
        createdAt: DateTime.now(),
        status: MessageStatus.sending,
      );

  void _addTempMessage(ChatMessage message) {
    setState(() {
      _messages.insert(0, message);
      _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();
  }

  void _replaceTempWithSentMessage(
      ChatMessage temp, Map<String, dynamic> data) {
    if (_isDisposed) return;
    setState(() {
      _messages.remove(temp);
      _messages.insert(0, ChatMessage.fromJson(data));
    });
  }

  void _handleSendError(String error) {
    if (_isDisposed) return;
    _showErrorSnackbar(error);
    setState(() => _messages.removeWhere((m) => m.id == -1));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _areMessagesEqual(List<ChatMessage> a, List<ChatMessage> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].message != b[i].message) return false;
    }
    return true;
  }

  void _showErrorSnackbar(String message) {
    if (!_isDisposed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.receiverName),
            Text(
              _isInitialLoading
                  ? 'Connecting...'
                  : '${_messages.length} messages',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isInitialLoading)
      return const Center(child: CircularProgressIndicator());
    if (_messages.isEmpty) return const Center(child: Text('No messages yet'));

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => ChatBubble(
        message: _messages[i].message,
        isMe: _messages[i].senderId == widget.senderId,
        time: _messages[i].createdAt,
        status: _messages[i].status,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Color(0xFF33B9A0)),
            onPressed: _isSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime time;
  final MessageStatus status;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.time,
    this.status = MessageStatus.sent,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF33B9A0) : const Color(0xFFEFEFF4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == MessageStatus.sending)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                Text(
                  '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final int id;
  final String message;
  final int senderId;
  final int receiverId;
  final String senderType;
  final String receiverType;
  final int rideId;
  final DateTime createdAt;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.message,
    required this.senderId,
    required this.receiverId,
    required this.senderType,
    required this.receiverType,
    required this.rideId,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: int.tryParse(json['id'].toString()) ?? -1,
        message: json['message'],
        senderId: int.tryParse(json['sender_id'].toString()) ?? -1,
        receiverId: int.tryParse(json['receiver_id'].toString()) ?? -1,
        senderType: json['sender_type'],
        receiverType: json['receiver_type'],
        rideId: int.tryParse(json['ride_id'].toString()) ?? -1,
        createdAt: DateTime.parse(json['created_at']),
      );
}

enum MessageStatus { sending, sent }
