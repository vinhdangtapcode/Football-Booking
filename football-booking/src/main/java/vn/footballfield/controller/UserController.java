package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.config.JwtUtil;
import vn.footballfield.dto.LoginRequest;
import vn.footballfield.dto.LoginResponse;
import vn.footballfield.entity.User;
import vn.footballfield.service.UserService;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
public class UserController {

	private final UserService userService;
	private final AuthenticationManager authenticationManager;
	private final JwtUtil jwtUtil;

	@Autowired
	private vn.footballfield.repository.NotificationRepository notificationRepository;

	public UserController(UserService userService,
			AuthenticationManager authenticationManager,
			JwtUtil jwtUtil) {
		this.userService = userService;
		this.authenticationManager = authenticationManager;
		this.jwtUtil = jwtUtil;
	}

	@PostMapping("/register")
	public ResponseEntity<User> register(@Valid @RequestBody User user) {
		return new ResponseEntity<>(userService.registerUser(user), HttpStatus.CREATED);
	}

	@PostMapping("/login")
	public ResponseEntity<LoginResponse> login(@RequestBody LoginRequest request) {
		Authentication authentication = authenticationManager.authenticate(
				new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
		User user = userService.findByEmail(request.getEmail())
				.orElseThrow(() -> new RuntimeException("User not found"));
		String token = jwtUtil.generateToken(user.getEmail(), user.getRole());
		return new ResponseEntity<>(new LoginResponse(token, user.getRole()), HttpStatus.OK);
	}

	@GetMapping
	public ResponseEntity<List<User>> getAllUsers() {
		return new ResponseEntity<>(userService.getAllUsers(), HttpStatus.OK);
	}

	@GetMapping("/{id:\\d+}")
	public ResponseEntity<User> getUserById(@PathVariable Integer id) {
		// chỉ khớp khi id là số
		return userService.getUserById(id)
				.map(user -> new ResponseEntity<>(user, HttpStatus.OK))
				.orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
	}

	// API tạo người dùng mới với ID cụ thể (dành cho Admin)
	@PostMapping("/{id:\\d+}")
	public ResponseEntity<User> createUserWithId(@PathVariable Integer id, @Valid @RequestBody User user) {
		user.setId(id);
		return new ResponseEntity<>(userService.registerUser(user), HttpStatus.CREATED);
	}

	@PutMapping("/{id:\\d+}")
	public ResponseEntity<User> updateUser(@PathVariable Integer id, @Valid @RequestBody User user) {
		User updated = userService.updateUser(id, user);
		return updated != null
				? new ResponseEntity<>(updated, HttpStatus.OK)
				: new ResponseEntity<>(HttpStatus.NOT_FOUND);
	}

	@DeleteMapping("/{id:\\d+}")
	public ResponseEntity<Void> deleteUser(@PathVariable Integer id) {
		userService.deleteUser(id);
		return new ResponseEntity<>(HttpStatus.NO_CONTENT);
	}

	// API: Get current user's profile (not admin, not by id)
	@GetMapping("/me")
	public ResponseEntity<User> getCurrentUserProfile() {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		return userService.findByEmail(email)
				.map(user -> new ResponseEntity<>(user, HttpStatus.OK))
				.orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
	}

	@PutMapping
	public ResponseEntity<User> updateCurrentUser(@RequestBody User userUpdate) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		User user = userService.findByEmail(email).orElse(null);
		if (user == null)
			return new ResponseEntity<>(HttpStatus.UNAUTHORIZED);
		user.setName(userUpdate.getName());
		user.setEmail(userUpdate.getEmail());
		user.setPhone(userUpdate.getPhone());
		User updated = userService.updateUser(user.getId(), user);
		return new ResponseEntity<>(updated, HttpStatus.OK);
	}

	@PostMapping("/change-password")
	public ResponseEntity<?> changePassword(@RequestBody vn.footballfield.dto.ChangePasswordRequest request) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		try {
			userService.changePassword(email, request.getOldPassword(), request.getNewPassword());
			return ResponseEntity.ok().build();
		} catch (RuntimeException e) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
		}
	}

	// ADMIN reset password cho user khác
	@PostMapping("/{id:\\d+}/reset-password")
	public ResponseEntity<?> adminResetPassword(@PathVariable Integer id,
			@Valid @RequestBody vn.footballfield.dto.AdminResetPasswordRequest request) {
		try {
			userService.adminResetPassword(id, request.getNewPassword());
			return ResponseEntity.ok("Password has been reset successfully");
		} catch (RuntimeException e) {
			return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(e.getMessage());
		}
	}

	// Lấy thông báo của user
	@GetMapping("/notifications")
	public ResponseEntity<List<vn.footballfield.entity.Notification>> getUserNotifications() {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		vn.footballfield.entity.User user = userService.findByEmail(email).orElse(null);
		if (user == null)
			return ResponseEntity.notFound().build();
		List<vn.footballfield.entity.Notification> notifications = notificationRepository
				.findByUserIdOrderByCreatedAtDesc(user.getId());
		return ResponseEntity.ok(notifications);
	}

	// Đánh dấu thông báo là đã đọc
	@PutMapping("/notifications/{id}")
	public ResponseEntity<?> markNotificationAsRead(@PathVariable Integer id) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		vn.footballfield.entity.User user = userService.findByEmail(email).orElse(null);
		if (user == null)
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		var notiOpt = notificationRepository.findById(id);
		if (notiOpt.isEmpty() || !notiOpt.get().getUserId().equals(user.getId())) {
			return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification not found or not yours");
		}
		var noti = notiOpt.get();
		noti.setRead(true);
		notificationRepository.save(noti);
		return ResponseEntity.ok().build();
	}

	// Xóa thông báo
	@DeleteMapping("/notifications/{id}")
	public ResponseEntity<?> deleteNotification(@PathVariable Integer id) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		vn.footballfield.entity.User user = userService.findByEmail(email).orElse(null);
		if (user == null)
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		var notiOpt = notificationRepository.findById(id);
		if (notiOpt.isEmpty() || !notiOpt.get().getUserId().equals(user.getId())) {
			return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification not found or not yours");
		}
		notificationRepository.deleteById(id);
		return ResponseEntity.noContent().build();
	}

	// Cập nhật FCM token cho push notifications
	@PutMapping("/fcm-token")
	public ResponseEntity<?> updateFcmToken(@RequestBody java.util.Map<String, String> request) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication()
				.getName();
		User user = userService.findByEmail(email).orElse(null);
		if (user == null)
			return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();

		String fcmToken = request.get("fcmToken");
		if (fcmToken == null || fcmToken.isEmpty()) {
			return ResponseEntity.badRequest().body("FCM token is required");
		}

		user.setFcmToken(fcmToken);
		userService.updateUser(user.getId(), user);
		return ResponseEntity.ok().build();
	}
}
