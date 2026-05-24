package vn.footballfield.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "conversations")
public class Conversation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "owner_id", nullable = false)
    private Owner owner;

    @ManyToOne
    @JoinColumn(name = "field_id")
    private Field field;

    @Column(name = "last_message", length = 500)
    private String lastMessage;

    @Column(name = "last_message_time")
    private LocalDateTime lastMessageTime;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "unread_count_user")
    private Integer unreadCountUser = 0;

    @Column(name = "unread_count_owner")
    private Integer unreadCountOwner = 0;

    // Constructors
    public Conversation() {
        this.createdAt = LocalDateTime.now();
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Owner getOwner() {
        return owner;
    }

    public void setOwner(Owner owner) {
        this.owner = owner;
    }

    public Field getField() {
        return field;
    }

    public void setField(Field field) {
        this.field = field;
    }

    public String getLastMessage() {
        return lastMessage;
    }

    public void setLastMessage(String lastMessage) {
        this.lastMessage = lastMessage;
    }

    public LocalDateTime getLastMessageTime() {
        return lastMessageTime;
    }

    public void setLastMessageTime(LocalDateTime lastMessageTime) {
        this.lastMessageTime = lastMessageTime;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public Integer getUnreadCountUser() {
        return unreadCountUser;
    }

    public void setUnreadCountUser(Integer unreadCountUser) {
        this.unreadCountUser = unreadCountUser;
    }

    public Integer getUnreadCountOwner() {
        return unreadCountOwner;
    }

    public void setUnreadCountOwner(Integer unreadCountOwner) {
        this.unreadCountOwner = unreadCountOwner;
    }
}
