package vn.footballfield.entity;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.persistence.*;
import javax.validation.constraints.*;
import java.math.BigDecimal;
import java.sql.Time;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Entity
@Table(name = "field")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Field {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@NotBlank
	@Size(max = 255)
	private String name;

	@NotBlank
	@Size(max = 255)
	private String address;

	@Size(max = 20)
	private String type; // 5/7/11 players

	@Positive
	private Integer length;

	@Positive
	private Integer width;

	@Size(max = 50)
	private String grassType;

	private String facilities;

	@Positive
	private BigDecimal pricePerHour;

	@Column(name = "deposit_amount", nullable = false)
	private BigDecimal depositAmount = BigDecimal.ZERO;

	private Time openingTime;

	private Time closingTime;

	@NotNull
	private Boolean available;

	@NotNull
	private Boolean outdoor;

	@Size(max = 500)
	private String imageUrl; // URL ảnh đại diện chính

	@ManyToOne
	@JoinColumn(name = "owner_id", nullable = true)
	private Owner owner;

	@OneToMany(mappedBy = "field", cascade = CascadeType.ALL, orphanRemoval = true)
	@com.fasterxml.jackson.annotation.JsonIgnore
	private List<Rating> ratings = new ArrayList<>();

	@OneToMany(mappedBy = "field", cascade = CascadeType.ALL, orphanRemoval = true)
	@com.fasterxml.jackson.annotation.JsonIgnore
	private List<Book> bookings = new ArrayList<>();

	@OneToMany(mappedBy = "field", cascade = CascadeType.ALL, orphanRemoval = true)
	@com.fasterxml.jackson.annotation.JsonIgnore
	private List<Favorite> favorites = new ArrayList<>();

	@OneToMany(mappedBy = "field", cascade = CascadeType.ALL, orphanRemoval = true)
	private List<FieldImage> images = new ArrayList<>();

	// Getters and Setters
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	public String getName() { return name; }
	public void setName(String name) { this.name = name; }
	public String getAddress() { return address; }
	public void setAddress(String address) { this.address = address; }
	public String getType() { return type; }
	public void setType(String type) { this.type = type; }
	public Integer getLength() { return length; }
	public void setLength(Integer length) { this.length = length; }
	public Integer getWidth() { return width; }
	public void setWidth(Integer width) { this.width = width; }
	public String getGrassType() { return grassType; }
	public void setGrassType(String grassType) { this.grassType = grassType; }
	public String getFacilities() { return facilities; }
	public void setFacilities(String facilities) { this.facilities = facilities; }
	public BigDecimal getPricePerHour() { return pricePerHour; }
	public void setPricePerHour(BigDecimal pricePerHour) { this.pricePerHour = pricePerHour; }
	public BigDecimal getDepositAmount() { return depositAmount; }
	public void setDepositAmount(BigDecimal depositAmount) { this.depositAmount = depositAmount; }
	public Time getOpeningTime() { return openingTime; }
	public void setOpeningTime(Time openingTime) { this.openingTime = openingTime; }
	public Time getClosingTime() { return closingTime; }
	public void setClosingTime(Time closingTime) { this.closingTime = closingTime; }

	public Owner getOwner() {
		return owner;
	}

	public void setOwner(Owner owner) {
		this.owner = owner;
	}

	public Boolean getAvailable() { return available; }
	public void setAvailable(Boolean available) { this.available = available; }
	public Boolean getOutdoor() { return outdoor; }
	public void setOutdoor(Boolean outdoor) { this.outdoor = outdoor; }

	public String getImageUrl() { return imageUrl; }
	public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

	public List<FieldImage> getImages() { return images; }
	public void setImages(List<FieldImage> images) { this.images = images; }

	@JsonProperty("imageUrls")
	public List<String> getImageUrls() {
		if (images == null || images.isEmpty()) {
			return new ArrayList<>();
		}
		return images.stream()
				.sorted((a, b) -> {
					int orderA = a.getDisplayOrder() != null ? a.getDisplayOrder() : 0;
					int orderB = b.getDisplayOrder() != null ? b.getDisplayOrder() : 0;
					return Integer.compare(orderA, orderB);
				})
				.map(FieldImage::getImageUrl)
				.collect(Collectors.toList());
	}

	@com.fasterxml.jackson.annotation.JsonIgnore
	public List<Book> getBookings() {
		return bookings;
	}

	@JsonProperty("rating")
	public Float getRating() {
		if (ratings == null || ratings.isEmpty()) {
			return 0.0f;
		}
		float total = 0.0f;
		for (Rating r : ratings) {
			// Giả sử Rating có method getScore() trả về điểm đánh giá kiểu Integer hoặc Float
			total += (r.getScore() != null ? r.getScore() : 0);
		}
		return total / ratings.size();
	}

}
