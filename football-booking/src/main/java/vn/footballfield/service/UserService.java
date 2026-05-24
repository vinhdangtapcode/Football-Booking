// File: src/main/java/vn/footballfield/service/UserService.java
package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.footballfield.entity.Owner;
import vn.footballfield.entity.User;
import vn.footballfield.repository.BookingRepository;
import vn.footballfield.repository.FavoriteRepository;
import vn.footballfield.repository.OwnerRepository;
import vn.footballfield.repository.RatingRepository;
import vn.footballfield.repository.UserRepository;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@Service
public class UserService {

	@Autowired
	private UserRepository userRepository;

	@Autowired
	private OwnerRepository ownerRepository;

	@Autowired
	private PasswordEncoder passwordEncoder;

	@Autowired
	private BookingRepository bookingRepository;

	@Autowired
	private RatingRepository ratingRepository;

	@Autowired
	private FavoriteRepository favoriteRepository;

	public User registerUser(@Valid User user) {
		if (userRepository.findByEmail(user.getEmail()).isPresent()) {
			throw new RuntimeException("Email already exists");
		}
		// Nếu role không được cung cấp hoặc rỗng, mặc định là "USER"
		if (user.getRole() == null || user.getRole().trim().isEmpty()) {
			user.setRole("USER");
		} else if (user.getRole().startsWith("ROLE_")) {
			// Loại bỏ tiền tố nếu có để chỉ lưu "USER", "ADMIN" hay "OWNER".
			user.setRole(user.getRole().substring(5));
		}
		// Mã hóa mật khẩu trước khi lưu
		user.setPassword(passwordEncoder.encode(user.getPassword()));

		// Lưu vào bảng user
		User savedUser = userRepository.save(user);

		// Nếu role là OWNER thì lưu thêm thông tin vào bảng owner
		if ("OWNER".equalsIgnoreCase(user.getRole())) {
			Owner owner = new Owner();
			owner.setOwnerName(user.getName());
			owner.setEmail(user.getEmail());
			// Nếu có thông tin số điện thoại, bạn có thể set vào đây
			owner.setContactNumber(user.getPhone());
			ownerRepository.save(owner);
		}
		return savedUser;
	}

	// Các phương thức khác
	public Optional<User> findByEmail(String email) {
		return userRepository.findByEmail(email);
	}

	public Integer getUserIdByEmail(String email) {
		return userRepository.findByEmail(email)
				.map(User::getId)
				.orElseThrow(() -> new RuntimeException("User not found"));
	}

	public List<User> getAllUsers() {
		return userRepository.findAll();
	}

	public Optional<User> getUserById(Integer id) {
		return userRepository.findById(id);
	}

	public User updateUser(Integer id, @Valid User user) {
		Optional<User> existing = userRepository.findById(id);
		if (existing.isPresent()) {
			User updated = existing.get();
			updated.setName(user.getName());
			updated.setEmail(user.getEmail());
			updated.setPhone(user.getPhone());
			if (user.getRole() == null || user.getRole().trim().isEmpty()) {
				updated.setRole("USER");
			} else if (user.getRole().startsWith("ROLE_")) {
				updated.setRole(user.getRole().substring(5));
			} else {
				updated.setRole(user.getRole());
			}
			return userRepository.save(updated);
		}
		return null;
	}

	@Transactional
	public void deleteUser(Integer id) {
		// Check if user exists
		Optional<User> userOptional = userRepository.findById(id);
		if (userOptional.isEmpty()) {
			throw new RuntimeException("User not found with id: " + id);
		}

		User user = userOptional.get();

		// Delete all related records first to avoid foreign key constraint violations

		// 1. Delete all bookings by this customer
		bookingRepository.deleteAll(bookingRepository.findByCustomerId(id));

		// 2. Delete all ratings by this customer
		ratingRepository.deleteAll(ratingRepository.findByCustomerId(id));

		// 3. Delete all favorites by this customer
		favoriteRepository.deleteAll(favoriteRepository.findByCustomerId(id));

		// 4. If the user is an owner, delete owner record
		ownerRepository.findByEmail(user.getEmail())
			.ifPresent(owner -> ownerRepository.delete(owner));

		// 5. Finally, delete the user
		userRepository.deleteById(id);
	}

	public String getUserNameById(Integer id) {
		return userRepository.findById(id)
			.map(User::getName)
			.orElse("");
	}

	public void changePassword(String email, String oldPassword, String newPassword) {
		User user = userRepository.findByEmail(email)
				.orElseThrow(() -> new RuntimeException("User not found"));
		if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
			throw new RuntimeException("Old password is incorrect");
		}
		user.setPassword(passwordEncoder.encode(newPassword));
		userRepository.save(user);
	}

	// ADMIN reset password for any user (không cần mật khẩu cũ)
	public void adminResetPassword(Integer userId, String newPassword) {
		User user = userRepository.findById(userId)
				.orElseThrow(() -> new RuntimeException("User not found"));
		user.setPassword(passwordEncoder.encode(newPassword));
		userRepository.save(user);
	}
}
