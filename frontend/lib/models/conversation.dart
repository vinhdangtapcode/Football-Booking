class Conversation {
  final int? id;
  final int userId;
  final String? userName;
  final String? userPictureUrl;
  final int ownerId;
  final String? ownerName;
  final int? fieldId;
  final String? fieldName;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final DateTime? createdAt;

  Conversation({
    this.id,
    required this.userId,
    this.userName,
    this.userPictureUrl,
    required this.ownerId,
    this.ownerName,
    this.fieldId,
    this.fieldName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      userId: json['userId'] ?? 0,
      userName: json['userName'],
      userPictureUrl: json['userPictureUrl'],
      ownerId: json['ownerId'] ?? 0,
      ownerName: json['ownerName'],
      fieldId: json['fieldId'],
      fieldName: json['fieldName'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? DateTime.parse(json['lastMessageTime']) 
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPictureUrl': userPictureUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
