package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.footballfield.dto.ConversationDTO;
import vn.footballfield.dto.MessageDTO;
import vn.footballfield.entity.*;
import vn.footballfield.repository.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ChatService {

    @Autowired
    private ConversationRepository conversationRepository;

    @Autowired
    private MessageRepository messageRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private OwnerRepository ownerRepository;

    @Autowired
    private FieldRepository fieldRepository;

    /**
     * Get or create a conversation between user and owner
     */
    @Transactional
    public Conversation getOrCreateConversation(Integer userId, Integer ownerId, Integer fieldId) {
        // First try to find existing conversation
        Optional<Conversation> existing = conversationRepository.findByUserIdAndOwnerId(userId, ownerId);

        if (existing.isPresent()) {
            return existing.get();
        }

        // Create new conversation
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        Owner owner = ownerRepository.findById(ownerId)
                .orElseThrow(() -> new RuntimeException("Owner not found"));

        Conversation conversation = new Conversation();
        conversation.setUser(user);
        conversation.setOwner(owner);

        if (fieldId != null) {
            Field field = fieldRepository.findById(fieldId).orElse(null);
            conversation.setField(field);
        }

        conversation.setCreatedAt(LocalDateTime.now());

        return conversationRepository.save(conversation);
    }

    /**
     * Get all conversations for a user
     */
    public List<ConversationDTO> getConversationsForUser(Integer userId) {
        List<Conversation> conversations = conversationRepository.findByUserId(userId);
        return conversations.stream()
                .map(c -> toConversationDTO(c, "USER"))
                .collect(Collectors.toList());
    }

    /**
     * Get all conversations for an owner
     */
    public List<ConversationDTO> getConversationsForOwner(Integer ownerId) {
        List<Conversation> conversations = conversationRepository.findByOwnerId(ownerId);
        return conversations.stream()
                .map(c -> toConversationDTO(c, "OWNER"))
                .collect(Collectors.toList());
    }

    /**
     * Get all conversations for an owner by email
     */
    public List<ConversationDTO> getConversationsForOwnerByEmail(String email) {
        Optional<Owner> ownerOpt = ownerRepository.findByEmail(email);
        if (ownerOpt.isEmpty()) {
            return List.of();
        }
        return getConversationsForOwner(ownerOpt.get().getId());
    }

    /**
     * Get owner ID by email
     */
    public Integer getOwnerIdByEmail(String email) {
        Optional<Owner> ownerOpt = ownerRepository.findByEmail(email);
        return ownerOpt.map(Owner::getId).orElse(null);
    }

    /**
     * Get messages for a conversation
     */
    public List<MessageDTO> getMessages(Long conversationId) {
        List<Message> messages = messageRepository.findByConversationId(conversationId);
        return messages.stream()
                .map(this::toMessageDTO)
                .collect(Collectors.toList());
    }

    /**
     * Send a message
     */
    @Transactional
    public MessageDTO sendMessage(Long conversationId, String senderType, Integer senderId, String content) {
        Conversation conversation = conversationRepository.findById(conversationId)
                .orElseThrow(() -> new RuntimeException("Conversation not found"));

        Message message = new Message();
        message.setConversation(conversation);
        message.setSenderType(senderType);
        message.setSenderId(senderId);
        message.setContent(content);
        message.setSentAt(LocalDateTime.now());
        message.setIsRead(false);

        Message saved = messageRepository.save(message);

        // Update conversation last message
        conversation.setLastMessage(content.length() > 100 ? content.substring(0, 100) + "..." : content);
        conversation.setLastMessageTime(LocalDateTime.now());

        // Update unread count
        if ("USER".equals(senderType)) {
            conversation.setUnreadCountOwner(conversation.getUnreadCountOwner() + 1);
        } else {
            conversation.setUnreadCountUser(conversation.getUnreadCountUser() + 1);
        }

        conversationRepository.save(conversation);

        return toMessageDTO(saved);
    }

    /**
     * Mark messages as read
     */
    @Transactional
    public void markAsRead(Long conversationId, String readerType) {
        // Mark messages from the OTHER party as read
        String senderType = "USER".equals(readerType) ? "OWNER" : "USER";
        messageRepository.markAsRead(conversationId, senderType);

        // Reset unread count
        Conversation conversation = conversationRepository.findById(conversationId).orElse(null);
        if (conversation != null) {
            if ("USER".equals(readerType)) {
                conversation.setUnreadCountUser(0);
            } else {
                conversation.setUnreadCountOwner(0);
            }
            conversationRepository.save(conversation);
        }
    }

    /**
     * Send booking notification message to chat
     * Called when a user books a field - creates a system message in the
     * conversation
     */
    @Transactional
    public void sendBookingNotificationMessage(Integer userId, Integer ownerId, Integer fieldId,
            String fieldName, String fromTime, String toTime, String customerName) {
        try {
            // Get or create conversation
            Conversation conversation = getOrCreateConversation(userId, ownerId, fieldId);

            // Create notification message content - từ phía chủ sân xác nhận đặt sân
            String messageContent = "🎉 Xác nhận đặt sân thành công!\n\n" +
                    "📍 Sân: " + fieldName + "\n" +
                    "👤 Khách hàng: " + customerName + "\n" +
                    "🕐 Thời gian: " + fromTime + " - " + toTime + "\n\n" +
                    "Cảm ơn quý khách đã đặt sân! Hẹn gặp bạn tại sân.";

            // Gửi từ phía OWNER để người đặt sân nhận được thông báo
            Message message = new Message();
            message.setConversation(conversation);
            message.setSenderType("OWNER"); // Gửi từ phía owner để user nhận được thông báo
            message.setSenderId(ownerId);
            message.setContent(messageContent);
            message.setSentAt(LocalDateTime.now());
            message.setIsRead(false);

            messageRepository.save(message);

            // Update conversation - tăng unread cho USER
            conversation.setLastMessage("🎉 Xác nhận đặt sân thành công!");
            conversation.setLastMessageTime(LocalDateTime.now());
            conversation.setUnreadCountUser(conversation.getUnreadCountUser() + 1);
            conversationRepository.save(conversation);

        } catch (Exception e) {
            // Log error but don't fail the booking
            System.err.println("Error sending booking notification message: " + e.getMessage());
        }
    }

    // Helper methods
    private ConversationDTO toConversationDTO(Conversation c, String viewerType) {
        ConversationDTO dto = new ConversationDTO();
        dto.setId(c.getId());
        dto.setUserId(c.getUser().getId());
        dto.setUserName(c.getUser().getName());
        dto.setUserPictureUrl(c.getUser().getPictureUrl());
        dto.setOwnerId(c.getOwner().getId());
        dto.setOwnerName(c.getOwner().getOwnerName());

        if (c.getField() != null) {
            dto.setFieldId(c.getField().getId());
            dto.setFieldName(c.getField().getName());
        }

        dto.setLastMessage(c.getLastMessage());
        dto.setLastMessageTime(c.getLastMessageTime());
        dto.setCreatedAt(c.getCreatedAt());

        // Set unread count based on viewer type
        if ("USER".equals(viewerType)) {
            dto.setUnreadCount(c.getUnreadCountUser());
        } else {
            dto.setUnreadCount(c.getUnreadCountOwner());
        }

        return dto;
    }

    private MessageDTO toMessageDTO(Message m) {
        MessageDTO dto = new MessageDTO();
        dto.setId(m.getId());
        dto.setConversationId(m.getConversation().getId());
        dto.setSenderType(m.getSenderType());
        dto.setSenderId(m.getSenderId());
        dto.setContent(m.getContent());
        dto.setSentAt(m.getSentAt());
        dto.setIsRead(m.getIsRead());

        // Get sender name
        if ("USER".equals(m.getSenderType())) {
            userRepository.findById(m.getSenderId())
                    .ifPresent(user -> dto.setSenderName(user.getName()));
        } else {
            ownerRepository.findById(m.getSenderId())
                    .ifPresent(owner -> dto.setSenderName(owner.getOwnerName()));
        }

        return dto;
    }
}
