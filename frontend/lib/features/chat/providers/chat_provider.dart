import 'package:flutter/material.dart';
import '../repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get conversations => _conversations;
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> loadConversationsForUser(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await ChatRepository.getConversationsForUser(userId);
      _conversations = list;
    } catch (e) {
      print("Error in loadConversationsForUser: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversationsForOwner(int ownerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await ChatRepository.getConversationsForOwner(ownerId);
      _conversations = list;
    } catch (e) {
      print("Error in loadConversationsForOwner: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadConversationsForOwnerByEmail(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await ChatRepository.getConversationsForOwnerByEmail(email);
      _conversations = list;
    } catch (e) {
      print("Error in loadConversationsForOwnerByEmail: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int conversationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final list = await ChatRepository.getMessages(conversationId);
      _messages = list;
    } catch (e) {
      print("Error in loadMessages: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> sendMessage(
      int conversationId, String senderType, int senderId, String content) async {
    try {
      final message = await ChatRepository.sendMessage(conversationId, senderType, senderId, content);
      if (message != null) {
        _messages.add(message);
        notifyListeners();
        return message;
      }
    } catch (e) {
      print("Error in sendMessage provider: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> getOrCreateConversation(
      int userId, int ownerId, int? fieldId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final conv = await ChatRepository.getOrCreateConversation(userId, ownerId, fieldId);
      return conv;
    } catch (e) {
      print("Error in getOrCreateConversation: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> markMessagesAsRead(int conversationId, String readerType) async {
    try {
      await ChatRepository.markMessagesAsRead(conversationId, readerType);
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
}
