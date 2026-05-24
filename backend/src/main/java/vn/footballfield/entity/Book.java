package vn.footballfield.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "booking")
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

	// Getters and Setters (as you have them)
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	public Integer getCustomerId() { return customerId; }
	public void setCustomerId(Integer customerId) { this.customerId = customerId; }
	public LocalDateTime getFromTime() { return fromTime; }
	public void setFromTime(LocalDateTime fromTime) { this.fromTime = fromTime; }
	public LocalDateTime getToTime() { return toTime; }
	public void setToTime(LocalDateTime toTime) { this.toTime = toTime; }

	public Field getField() {
		return field;
	}

	public void setField(Field field) {
		this.field = field;
	}

	public String getAdditional() { return additional; }
	public void setAdditional(String additional) { this.additional = additional; }

	public User getCustomer() { return customer; }
	public void setCustomer(User customer) { this.customer = customer; }

	public String getCustomerName() {
		return customer != null ? customer.getName() : null;
	}

	public String getCustomerPhone() {
		return customer != null ? customer.getPhone() : null;
	}
}
