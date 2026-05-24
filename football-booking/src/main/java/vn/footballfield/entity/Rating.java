package vn.footballfield.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "rating")
public class Rating {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@Column(name = "customer_id")
	private Integer customerId;

	//	@Column(name = "field_id")
	//	private Integer fieldId;
	@ManyToOne
	@JoinColumn(name = "field_id", nullable = false)
	private Field field;

	private Integer score;

	private String comment;

	@Column(name = "is_anonymous")
	private Boolean isAnonymous = false;

	@Transient
	private String customerName;

	// Getters and Setters
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	public Integer getCustomerId() { return customerId; }
	public void setCustomerId(Integer customerId) { this.customerId = customerId; }
//	public Integer getFieldId() { return fieldId; }
//	public void setFieldId(Integer fieldId) { this.fieldId = fieldId; }
	public Integer getScore() { return score; }
	public void setScore(Integer score) { this.score = score; }
	public String getComment() { return comment; }
	public void setComment(String comment) { this.comment = comment; }

	public Field getField() {
		return field;
	}

	public void setField(Field field) {
		this.field = field;
	}

	public String getCustomerName() {
		return customerName;
	}

	public void setCustomerName(String customerName) {
		this.customerName = customerName;
	}

	public Boolean getIsAnonymous() {
		return isAnonymous;
	}

	public void setIsAnonymous(Boolean isAnonymous) {
		this.isAnonymous = isAnonymous;
	}
}
