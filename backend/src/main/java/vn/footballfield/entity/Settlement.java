package vn.footballfield.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "settlements")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Settlement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "owner_id", nullable = false)
    private Integer ownerId;

    @Column(name = "amount", nullable = false)
    private Double amount;

    @Column(name = "settled_at", nullable = false)
    private LocalDateTime settledAt = LocalDateTime.now();

    @Column(name = "booking_ids", length = 2000)
    private String bookingIds;

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public Integer getOwnerId() { return ownerId; }
    public void setOwnerId(Integer ownerId) { this.ownerId = ownerId; }

    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }

    public LocalDateTime getSettledAt() { return settledAt; }
    public void setSettledAt(LocalDateTime settledAt) { this.settledAt = settledAt; }

    public String getBookingIds() { return bookingIds; }
    public void setBookingIds(String bookingIds) { this.bookingIds = bookingIds; }
}
