import 'dart:convert';
import '../../../core/network/api_client.dart';

class ChatRepository {
  static Future<Map<String, dynamic>?> getOrCreateConversation(
      int userId, int ownerId, int? fieldId) async {
    try {
      final response = await ApiClient.post(
        '/api/chat/conversations',
        body: jsonEncode({
          "userId": userId,
          "ownerId": ownerId,
          "fieldId": fieldId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print('Error creating conversation: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getConversationsForUser(int userId) async {
    try {
      final response = await ApiClient.get('/api/chat/conversations/user/$userId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting conversations: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getConversationsForOwner(int ownerId) async {
    try {
      final response = await ApiClient.get('/api/chat/conversations/owner/$ownerId');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting owner conversations: $e');
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getConversationsForOwnerByEmail(String email) async {
    try {
      final response = await ApiClient.get('/api/chat/conversations/owner/email/$email');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting owner conversations by email: $e');
    }
    return [];
  }

  static Future<int?> getOwnerIdByEmail(String email) async {
    try {
      final response = await ApiClient.get('/api/chat/owner-id/$email');
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['ownerId'];
      }
    } catch (e) {
      print('Error getting owner ID: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    try {
      final response = await ApiClient.get('/api/chat/conversations/$conversationId/messages');
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error getting messages: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>?> sendMessage(
      int conversationId, String senderType, int senderId, String content) async {
    try {
      final response = await ApiClient.post(
        '/api/chat/messages',
        body: jsonEncode({
          "conversationId": conversationId,
          "senderType": senderType,
          "senderId": senderId,
          "content": content,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print('Error sending message: $e');
    }
    return null;
  }

  static Future<bool> markMessagesAsRead(int conversationId, String readerType) async {
    try {
      final response = await ApiClient.post(
        '/api/chat/conversations/$conversationId/read',
        body: jsonEncode({"readerType": readerType}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
}
