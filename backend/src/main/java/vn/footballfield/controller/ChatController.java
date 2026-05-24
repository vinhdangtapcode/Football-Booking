package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.dto.ConversationDTO;
import vn.footballfield.dto.MessageDTO;
import vn.footballfield.entity.Conversation;
import vn.footballfield.service.ChatService;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chat")
public class ChatController {

    @Autowired
    private ChatService chatService;

    /**
     * Get or create a conversation
     * POST /api/chat/conversations
     * Body: { "userId": 1, "ownerId": 2, "fieldId": 3 }
     */
    @PostMapping("/conversations")
    public ResponseEntity<?> getOrCreateConversation(@RequestBody Map<String, Integer> request) {
        try {
            Integer userId = request.get("userId");
            Integer ownerId = request.get("ownerId");
            Integer fieldId = request.get("fieldId");

            if (userId == null || ownerId == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "userId and ownerId are required"));
            }

            Conversation conversation = chatService.getOrCreateConversation(userId, ownerId, fieldId);

            return ResponseEntity.ok(Map.of(
                    "id", conversation.getId(),
                    "userId", conversation.getUser().getId(),
                    "ownerId", conversation.getOwner().getId(),
                    "fieldId", conversation.getField() != null ? conversation.getField().getId() : null));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Get conversations for a user
     * GET /api/chat/conversations/user/{userId}
     */
    @GetMapping("/conversations/user/{userId}")
    public ResponseEntity<List<ConversationDTO>> getConversationsForUser(@PathVariable Integer userId) {
        List<ConversationDTO> conversations = chatService.getConversationsForUser(userId);
        return ResponseEntity.ok(conversations);
    }

    /**
     * Get conversations for an owner
     * GET /api/chat/conversations/owner/{ownerId}
     */
    @GetMapping("/conversations/owner/{ownerId}")
    public ResponseEntity<List<ConversationDTO>> getConversationsForOwner(@PathVariable Integer ownerId) {
        List<ConversationDTO> conversations = chatService.getConversationsForOwner(ownerId);
        return ResponseEntity.ok(conversations);
    }

    /**
     * Get conversations for an owner by email
     * GET /api/chat/conversations/owner/email/{email}
     */
    @GetMapping("/conversations/owner/email/{email}")
    public ResponseEntity<List<ConversationDTO>> getConversationsForOwnerByEmail(@PathVariable String email) {
        List<ConversationDTO> conversations = chatService.getConversationsForOwnerByEmail(email);
        return ResponseEntity.ok(conversations);
    }

    /**
     * Get owner ID by email
     * GET /api/chat/owner-id/{email}
     */
    @GetMapping("/owner-id/{email}")
    public ResponseEntity<?> getOwnerIdByEmail(@PathVariable String email) {
        Integer ownerId = chatService.getOwnerIdByEmail(email);
        if (ownerId == null) {
            return ResponseEntity.ok(Map.of("ownerId", (Object) null));
        }
        return ResponseEntity.ok(Map.of("ownerId", ownerId));
    }

    /**
     * Get messages for a conversation
     * GET /api/chat/conversations/{conversationId}/messages
     */
    @GetMapping("/conversations/{conversationId}/messages")
    public ResponseEntity<List<MessageDTO>> getMessages(@PathVariable Long conversationId) {
        List<MessageDTO> messages = chatService.getMessages(conversationId);
        return ResponseEntity.ok(messages);
    }

    /**
     * Send a message
     * POST /api/chat/messages
     * Body: { "conversationId": 1, "senderType": "USER", "senderId": 1, "content":
     * "Hello" }
     */
    @PostMapping("/messages")
    public ResponseEntity<?> sendMessage(@RequestBody Map<String, Object> request) {
        try {
            Long conversationId = Long.valueOf(request.get("conversationId").toString());
            String senderType = (String) request.get("senderType");
            Integer senderId = Integer.valueOf(request.get("senderId").toString());
            String content = (String) request.get("content");

            if (conversationId == null || senderType == null || senderId == null || content == null) {
                return ResponseEntity.badRequest().body(Map.of("error", "Missing required fields"));
            }

            MessageDTO message = chatService.sendMessage(conversationId, senderType, senderId, content);
            return ResponseEntity.ok(message);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    /**
     * Mark messages as read
     * POST /api/chat/conversations/{conversationId}/read
     * Body: { "readerType": "USER" }
     */
    @PostMapping("/conversations/{conversationId}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long conversationId, @RequestBody Map<String, String> request) {
        try {
            String readerType = request.get("readerType");
            chatService.markAsRead(conversationId, readerType);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }
}
