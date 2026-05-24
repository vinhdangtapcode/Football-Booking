import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../services/api_service.dart';

class OwnerMessagesScreen extends StatefulWidget {
  @override
  _OwnerMessagesScreenState createState() => _OwnerMessagesScreenState();
}

class _OwnerMessagesScreenState extends State<OwnerMessagesScreen> {
  List<Conversation> conversations = [];
  bool isLoading = true;
  int? ownerId;
  String? ownerEmail;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadOwnerProfile();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted && ownerId != null) {
        _loadConversationsSilent();
      }
    });
  }

  Future<void> _loadOwnerProfile() async {
    final profile = await ApiService.getProfile();
    if (profile != null && profile.email != null) {
      ownerEmail = profile.email;
      // Lấy Owner ID theo email vì User ID và Owner ID khác nhau
      final ownerIdResult = await ApiService.getOwnerIdByEmail(profile.email!);
      if (ownerIdResult != null) {
        ownerId = ownerIdResult;
        await _loadConversations();
        _startPolling(); // Bắt đầu polling sau khi load xong
      } else {
        print('Owner not found for email: ${profile.email}');
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadConversations() async {
    if (ownerId == null) return;
    
    setState(() => isLoading = true);
    
    try {
      final data = await ApiService.getConversationsForOwner(ownerId!);
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

  // Load conversations silently (không hiển thị loading) - dùng cho polling
  Future<void> _loadConversationsSilent() async {
    if (ownerId == null) return;
    
    try {
      final data = await ApiService.getConversationsForOwner(ownerId!);
      if (mounted) {
        setState(() {
          conversations = data.map((json) => Conversation.fromJson(json)).toList();
        });
      }
    } catch (e) {
      // Silent error - không hiển thị lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tin nhắn từ khách hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.amber,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadConversations,
            tooltip: 'Làm mới',
          ),
        ],
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
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 80, color: Colors.amber.shade300),
          ),
          SizedBox(height: 24),
          Text(
            'Chưa có tin nhắn',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Khi khách hàng nhắn tin cho bạn,\ntin nhắn sẽ xuất hiện ở đây',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    final userName = conversation.userName ?? 'Khách hàng';
    final hasUnread = conversation.unreadCount > 0;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: hasUnread ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChat(conversation),
        child: Container(
          decoration: hasUnread ? BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade300, width: 2),
          ) : null,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(28),
                        image: conversation.userPictureUrl != null
                            ? DecorationImage(
                                image: NetworkImage(conversation.userPictureUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: conversation.userPictureUrl == null
                          ? Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (hasUnread)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
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
                              userName,
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
                        Row(
                          children: [
                            Icon(Icons.sports_soccer, size: 14, color: Colors.grey[500]),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                conversation.fieldName!,
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                
                // Arrow
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} phút trước';
    } else if (diff.inDays == 0) {
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
        'currentUserId': ownerId,
        'currentUserType': 'OWNER',
        'otherPartyName': conversation.userName ?? 'Khách hàng',
        'fieldName': conversation.fieldName,
      },
    ).then((_) => _loadConversations()); // Refresh khi quay lại
  }
}
