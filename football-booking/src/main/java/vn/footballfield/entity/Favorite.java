package vn.footballfield.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "favor")
public class Favorite {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@Column(name = "customer_id")
	private Integer customerId;

	@ManyToOne
	@JoinColumn(name = "field_id", nullable = false)
	private Field field;

	// Getters and Setters
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	public Integer getCustomerId() { return customerId; }
	public void setCustomerId(Integer customerId) { this.customerId = customerId; }
//	public Integer getFieldId() { return fieldId; }
//	public void setFieldId(Integer fieldId) { this.fieldId = fieldId; }

	public Field getField() {
		return field;
	}

	public void setField(Field field) {
		this.field = field;
	}
}