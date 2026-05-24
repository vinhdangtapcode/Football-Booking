package vn.footballfield.entity;

import jakarta.persistence.*;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Entity
@Table(name = "users")
public class User {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@NotBlank
	@Size(max = 50)
	private String name;

	@NotBlank
	@Email
	@Size(max = 50)
	@Column(unique = true)
	private String email;

	// Password can be null for OAuth users
	@Size(max = 255)
	private String password;

	@Size(max = 15)
	private String phone;

	@NotBlank
	@Size(max = 20)
	private String role;

	// Google OAuth fields
	@Size(max = 100)
	@Column(name = "google_id", unique = true)
	private String googleId;

	@Size(max = 500)
	@Column(name = "picture_url")
	private String pictureUrl;

	// FCM token for push notifications
	@Size(max = 500)
	@Column(name = "fcm_token")
	private String fcmToken;

	// Getters and Setters
	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getEmail() {
		return email;
	}

	public void setEmail(String email) {
		this.email = email;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}

	public String getPhone() {
		return phone;
	}

	public void setPhone(String phone) {
		this.phone = phone;
	}

	public String getRole() {
		return role;
	}

	public void setRole(String role) {
		this.role = role;
	}

	public String getGoogleId() {
		return googleId;
	}

	public void setGoogleId(String googleId) {
		this.googleId = googleId;
	}

	public String getPictureUrl() {
		return pictureUrl;
	}

	public void setPictureUrl(String pictureUrl) {
		this.pictureUrl = pictureUrl;
	}

	public String getFcmToken() {
		return fcmToken;
	}

	public void setFcmToken(String fcmToken) {
		this.fcmToken = fcmToken;
	}
}
