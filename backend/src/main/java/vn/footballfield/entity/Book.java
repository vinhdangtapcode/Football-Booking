package vn.footballfield.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "booking")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Book {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@Column(name = "customer_id")
	private Integer customerId;

	@ManyToOne
	@JoinColumn(name = "field_id", nullable = false)
	private Field field;

	@Column(name = "\"from\"")
	private LocalDateTime fromTime;

	@Column(name = "\"to\"")
	private LocalDateTime toTime;

	@Column(name = "additional", columnDefinition = "TEXT")
	private String additional;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "customer_id", referencedColumnName = "id", insertable = false, updatable = false)
	@com.fasterxml.jackson.annotation.JsonIgnore
	private User customer;

	@Transient
	private String customerName;

	@Transient
	private String customerPhone;

	@Column(name = "status")
	private String status = "PENDING_PAYMENT";

	@Column(name = "payment_link_id")
	private String paymentLinkId;

	@Column(name = "payment_url", length = 1024)
	private String paymentUrl;

	@Column(name = "total_price")
	private Double totalPrice;

	@Column(name = "created_at", nullable = false, updatable = false)
	private LocalDateTime createdAt = LocalDateTime.now();

	@Column(name = "settled")
	private Boolean settled = false;

	// Getters and Setters (as you have them)
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	public Integer getCustomerId() { return customerId; }
	public void setCustomerId(Integer customerId) { this.customerId = customerId; }
	public LocalDateTime getFromTime() { return fromTime; }
	public void setFromTime(LocalDateTime fromTime) { this.fromTime = fromTime; }
	public LocalDateTime getToTime() { return toTime; }
	public void setToTime(LocalDateTime toTime) { this.toTime = toTime; }

	public LocalDateTime getCreatedAt() { return createdAt; }
	public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

	public String getStatus() { return status; }
	public void setStatus(String status) { this.status = status; }

	public String getPaymentLinkId() { return paymentLinkId; }
	public void setPaymentLinkId(String paymentLinkId) { this.paymentLinkId = paymentLinkId; }

	public String getPaymentUrl() { return paymentUrl; }
	public void setPaymentUrl(String paymentUrl) { this.paymentUrl = paymentUrl; }

	public Double getTotalPrice() { return totalPrice; }
	public void setTotalPrice(Double totalPrice) { this.totalPrice = totalPrice; }

	public Field getField() {
		return field;
	}

	public void setField(Field field) {
		this.field = field;
	}

	public String getAdditional() { return additional; }
	public void setAdditional(String additional) { this.additional = additional; }

	@com.fasterxml.jackson.annotation.JsonIgnore
	public User getCustomer() { return customer; }
	public void setCustomer(User customer) { this.customer = customer; }

	public String getCustomerName() {
		return customer != null ? customer.getName() : null;
	}

	public String getCustomerPhone() {
		return customer != null ? customer.getPhone() : null;
	}

	public Boolean getSettled() { return settled; }
	public void setSettled(Boolean settled) { this.settled = settled; }
}
