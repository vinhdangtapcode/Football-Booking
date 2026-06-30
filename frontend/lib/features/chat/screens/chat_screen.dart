import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../../../models/conversation.dart';
import '../../../models/message.dart';
import '../../../services/theme_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int? conversationId;
  int? currentUserId;
  String? currentUserType; // "USER" or "OWNER"
  String? otherPartyName;
  String? fieldName;
  
  List<Message> messages = [];
  bool isLoading = true;
  bool isSending = false;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    conversationId = args['conversationId'];
    currentUserId = args['currentUserId'];
    currentUserType = args['currentUserType'];
    otherPartyName = args['otherPartyName'];
    fieldName = args['fieldName'];
    
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    // Poll for new messages every 3 seconds
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        _loadMessages(silent: true);
      }
    });
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent) {
      setState(() => isLoading = true);
    }
    
    try {
      final chatProvider = context.read<ChatProvider>();
      final previousMessageCount = messages.length;
      await chatProvider.loadMessages(conversationId!);
      
      if (mounted) {
        final newMessages = chatProvider.messages.map((json) => Message.fromJson(json)).toList();
        final hasNewMessages = newMessages.length > previousMessageCount;
        
        setState(() {
          messages = newMessages;
          isLoading = false;
        });
        
        // Mark messages as read
        chatProvider.markMessagesAsRead(conversationId!, currentUserType!);
        
        // Scroll to bottom when:
        // 1. Initial load (!silent)
        // 2. New messages arrived during polling
        if (messages.isNotEmpty && (!silent || hasNewMessages)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || isSending) return;

    setState(() => isSending = true);
    _messageController.clear();

    try {
      final chatProvider = context.read<ChatProvider>();
      final result = await chatProvider.sendMessage(
        conversationId!,
        currentUserType!,
        currentUserId!,
        content,
      );
      
      if (result != null && mounted) {
        await _loadMessages(silent: true);
        _scrollToBottom();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể gửi tin nhắn'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isModern = themeProvider.isModernMode;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherPartyName ?? 'Chat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isModern ? Colors.white : Colors.black),
            ),
            if (fieldName != null)
              Text(
                fieldName!,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: isModern ? Colors.white70 : Colors.black87),
              ),
          ],
        ),
        backgroundColor: isModern ? Colors.black : Colors.amber,
        iconTheme: IconThemeData(color: isModern ? Colors.white : Colors.black),
        elevation: isModern ? 0 : 2,
        bottom: isModern ? PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(color: Colors.white24, height: 1.0),
        ) : null,
      ),
      backgroundColor: isModern ? Colors.black : null,
      body: Container(
        decoration: BoxDecoration(
          color: isModern ? Colors.black : null,
          gradient: isModern ? null : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.shade50, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: isModern ? Colors.white : Colors.amber))
                  : messages.isEmpty
                      ? _buildEmptyState(isModern)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final isMe = message.senderType == currentUserType;
                            final showDateHeader = index == 0 || 
                                !_isSameDay(messages[index - 1].sentAt, message.sentAt);
                            
                            return Column(
                              children: [
                                if (showDateHeader) _buildDateHeader(message.sentAt, isModern),
                                _buildMessageBubble(message, isMe, isModern),
                              ],
                            );
                          },
                        ),
            ),
            
            // Input area
            _buildInputArea(isModern),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isModern) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: isModern ? Colors.white24 : Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Chưa có tin nhắn',
            style: TextStyle(fontSize: 18, color: isModern ? Colors.white70 : Colors.grey[500]),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy gửi tin nhắn đầu tiên!',
            style: TextStyle(fontSize: 14, color: isModern ? Colors.white54 : Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date, bool isModern) {
    final now = DateTime.now();
    String dateStr;
    
    if (_isSameDay(date, now)) {
      dateStr = 'Hôm nay';
    } else if (_isSameDay(date, now.subtract(Duration(days: 1)))) {
      dateStr = 'Hôm qua';
    } else {
      dateStr = DateFormat('dd/MM/yyyy').format(date);
    }
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isModern ? Colors.white12 : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dateStr,
          style: TextStyle(fontSize: 12, color: isModern ? Colors.white70 : Colors.grey[600]),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe, bool isModern) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 60 : 0,
          right: isMe ? 0 : 60,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? (isModern ? Colors.white : Colors.amber) : (isModern ? Color(0xFF1A1A1A) : Colors.white),
          border: (!isMe && isModern) ? Border.all(color: Colors.white24) : null,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
            bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
          ),
          boxShadow: isModern ? null : [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                color: isMe ? (isModern ? Colors.black : Colors.white) : (isModern ? Colors.white : Colors.black87),
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.sentAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? (isModern ? Colors.black54 : Colors.white70) : (isModern ? Colors.white54 : Colors.grey[500]),
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? (isModern ? Colors.black87 : Colors.white) : (isModern ? Colors.black54 : Colors.white70),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isModern) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isModern ? Colors.black : Colors.white,
        border: isModern ? Border(top: BorderSide(color: Colors.white24, width: 0.5)) : null,
        boxShadow: isModern ? null : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isModern ? Color(0xFF1A1A1A) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: isModern ? Border.all(color: Colors.white24) : null,
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(color: isModern ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Nhập tin nhắn...',
                    hintStyle: TextStyle(color: isModern ? Colors.white54 : Colors.grey[400]),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: isModern ? Colors.white : Colors.amber,
                shape: BoxShape.circle,
                boxShadow: isModern ? null : [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isModern ? Colors.black : Colors.white,
                        ),
                      )
                    : Icon(Icons.send, color: isModern ? Colors.black : Colors.white),
                onPressed: isSending ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
