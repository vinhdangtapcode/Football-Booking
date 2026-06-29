package vn.footballfield.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import javax.validation.constraints.NotBlank;

@Entity
@Table(name = "field_image")
public class FieldImage {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "field_id", nullable = false)
	@JsonIgnore
	private Field field;

	@NotBlank
	@Column(length = 500)
	private String imageUrl;

	private Integer displayOrder;

	private Boolean isPrimary;

	// Constructors
	public FieldImage() {}

	public FieldImage(Field field, String imageUrl, Integer displayOrder, Boolean isPrimary) {
		this.field = field;
		this.imageUrl = imageUrl;
		this.displayOrder = displayOrder;
		this.isPrimary = isPrimary;
	}

	// Getters and Setters
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	@com.fasterxml.jackson.annotation.JsonIgnore
	public Field getField() { return field; }
	public void setField(Field field) { this.field = field; }
	public String getImageUrl() { return imageUrl; }
	public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }
	public Integer getDisplayOrder() { return displayOrder; }
	public void setDisplayOrder(Integer displayOrder) { this.displayOrder = displayOrder; }
	public Boolean getIsPrimary() { return isPrimary; }
	public void setIsPrimary(Boolean isPrimary) { this.isPrimary = isPrimary; }
}
