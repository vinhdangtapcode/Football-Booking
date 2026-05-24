class Message {
  final int? id;
  final int? conversationId;
  final String senderType; // "USER" or "OWNER"
  final int senderId;
  final String? senderName;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  Message({
    this.id,
    this.conversationId,
    required this.senderType,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversationId'],
      senderType: json['senderType'] ?? 'USER',
      senderId: json['senderId'] ?? 0,
      senderName: json['senderName'],
      content: json['content'] ?? '',
      sentAt: json['sentAt'] != null 
          ? DateTime.parse(json['sentAt']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderType': senderType,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
    };
  }
}
