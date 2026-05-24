import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

class ConversationListScreen extends StatefulWidget {
  final String userType; // "USER" or "OWNER"
  final int userId;

  const ConversationListScreen({
    Key? key,
    required this.userType,
    required this.userId,
  }) : super(key: key);

  @override
  _ConversationListScreenState createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<Conversation> conversations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => isLoading = true);
    
    try {
      List<Map<String, dynamic>> data;
      if (widget.userType == "USER") {
        data = await ApiService.getConversationsForUser(widget.userId);
      } else {
        data = await ApiService.getConversationsForOwner(widget.userId);
      }
      
      if (mounted) {
        setState(() {
          conversations = data.map((json) => Conversation.fromJson(json)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.amber.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.amber))
            : conversations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    color: Colors.amber,
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      itemCount: conversations.length,
                      itemBuilder: (context, index) {
                        return _buildConversationItem(conversations[index]);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            'Chưa có cuộc hội thoại',
            style: TextStyle(fontSize: 18, color: Colors.grey[500]),
          ),
          SizedBox(height: 8),
          Text(
            widget.userType == "USER"
                ? 'Nhắn tin với chủ sân từ trang chi tiết sân'
                : 'Khách hàng sẽ nhắn tin cho bạn',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final otherName = widget.userType == "USER"
        ? conversation.ownerName ?? 'Chủ sân'
        : conversation.userName ?? 'Người dùng';
    
    final hasUnread = conversation.unreadCount > 0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: hasUnread ? 3 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChat(conversation),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            otherName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageTime != null)
                          Text(
                            _formatTime(conversation.lastMessageTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? Colors.amber.shade800 : Colors.grey[500],
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    if (conversation.fieldName != null)
                      Text(
                        conversation.fieldName!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage ?? 'Bắt đầu cuộc hội thoại...',
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread ? Colors.black87 : Colors.grey[600],
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              conversation.unreadCount.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'vi').format(time);
    } else {
      return DateFormat('dd/MM').format(time);
    }
  }

  void _openChat(Conversation conversation) {
    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'conversationId': conversation.id,
        'currentUserId': widget.userId,
        'currentUserType': widget.userType,
        'otherPartyName': widget.userType == "USER"
            ? conversation.ownerName
            : conversation.userName,
        'fieldName': conversation.fieldName,
      },
    ).then((_) => _loadConversations()); // Refresh khi quay lại
  }
}
