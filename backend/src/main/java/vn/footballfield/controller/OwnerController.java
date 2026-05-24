// File: src/main/java/vn/footballfield/controller/OwnerController.java
package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.entity.Book;
import vn.footballfield.entity.Field;
import vn.footballfield.entity.Owner;
import vn.footballfield.service.FieldService;
import vn.footballfield.service.OwnerService;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/owner")
public class OwnerController {

	@Autowired
	private FieldService fieldService;

	@Autowired
	private OwnerService ownerService;

	@Autowired
	private vn.footballfield.repository.NotificationRepository notificationRepository;

	@Autowired
	private vn.footballfield.service.UserService userService;

	// Lấy danh sách sân của chủ sân
	@GetMapping("/fields")
	public ResponseEntity<List<Field>> getOwnerFields() {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		Owner owner = ownerService.getOwnerByEmail(email);
		List<Field> fields = fieldService.getFieldsByOwner(owner);
		return new ResponseEntity<>(fields, HttpStatus.OK);
	}

	// Thêm sân cho thuê
	@PostMapping("/fields")
	public ResponseEntity<Field> createField(@Valid @RequestBody Field field) {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		Owner owner = ownerService.getOwnerByEmail(email);
		field.setOwner(owner);
		Field createdField = fieldService.createField(field);
		return new ResponseEntity<>(createdField, HttpStatus.CREATED);
	}

	// Cập nhật thông tin sân của chủ sân
	@PutMapping("/fields/{id}")
	public ResponseEntity<Field> updateField(@PathVariable Integer id, @Valid @RequestBody Field field) {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		Owner owner = ownerService.getOwnerByEmail(email);
		Optional<Field> existingOpt = fieldService.getFieldById(id);
		if (existingOpt.isPresent()) {
			Field existingField = existingOpt.get();
			if (!existingField.getOwner().getId().equals(owner.getId())) {
				return new ResponseEntity<>(HttpStatus.FORBIDDEN);
			}
			// Cập nhật các thông tin của sân, không thay đổi owner
			existingField.setName(field.getName());
			existingField.setAddress(field.getAddress());
			existingField.setType(field.getType());
			existingField.setLength(field.getLength());
			existingField.setWidth(field.getWidth());
			existingField.setGrassType(field.getGrassType());
			existingField.setFacilities(field.getFacilities());
			existingField.setPricePerHour(field.getPricePerHour());
			existingField.setOpeningTime(field.getOpeningTime());
			existingField.setClosingTime(field.getClosingTime());
			existingField.setAvailable(field.getAvailable());
			existingField.setOutdoor(field.getOutdoor());
			Field updatedField = fieldService.updateField(id, existingField);
			return new ResponseEntity<>(updatedField, HttpStatus.OK);
		} else {
			return new ResponseEntity<>(HttpStatus.NOT_FOUND);
		}
	}

	// Xóa sân đã đăng
	@DeleteMapping("/fields/{id}")
	public ResponseEntity<Void> deleteField(@PathVariable Integer id) {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		Owner owner = ownerService.getOwnerByEmail(email);
		Optional<Field> existingOpt = fieldService.getFieldById(id);
		if (existingOpt.isPresent()) {
			Field existingField = existingOpt.get();
			if (!existingField.getOwner().getId().equals(owner.getId())) {
				return new ResponseEntity<>(HttpStatus.FORBIDDEN);
			}
			fieldService.deleteField(id);
			return new ResponseEntity<>(HttpStatus.NO_CONTENT);
		} else {
			return new ResponseEntity<>(HttpStatus.NOT_FOUND);
		}
	}

	// API: Lịch sử đặt sân của 1 sân cụ thể mà chủ sân sở hữu
	@GetMapping("/fields/{fieldId}/bookings")
	public ResponseEntity<List<Book>> getBookingsForField(@PathVariable Integer fieldId) {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		Owner owner = ownerService.getOwnerByEmail(email);
		Optional<Field> fieldOpt = fieldService.getFieldById(fieldId);
		if (fieldOpt.isEmpty()) {
			return new ResponseEntity<>(HttpStatus.NOT_FOUND);
		}
		Field field = fieldOpt.get();
		if (!field.getOwner().getId().equals(owner.getId())) {
			return new ResponseEntity<>(HttpStatus.FORBIDDEN);
		}
		return new ResponseEntity<>(field.getBookings(), HttpStatus.OK);
	}

	// Lấy thông báo của chủ sân
	@GetMapping("/notifications")
	public ResponseEntity<List<vn.footballfield.entity.Notification>> getOwnerNotifications() {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
		vn.footballfield.entity.Owner owner = ownerService.getOwnerByEmail(email);
		if (owner == null) return ResponseEntity.notFound().build();
		vn.footballfield.entity.User user = userService.findByEmail(owner.getEmail()).orElse(null);
		if (user == null) return ResponseEntity.notFound().build();
		List<vn.footballfield.entity.Notification> notifications = notificationRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
		return ResponseEntity.ok(notifications);
	}

	// Đánh dấu thông báo là đã đọc
	@PutMapping("/notifications/{id}")
	public ResponseEntity<?> markOwnerNotificationAsRead(@PathVariable Integer id) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
		vn.footballfield.entity.Owner owner = ownerService.getOwnerByEmail(email);
		if (owner == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		vn.footballfield.entity.User user = userService.findByEmail(owner.getEmail()).orElse(null);
		if (user == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		var notiOpt = notificationRepository.findById(id);
		if (notiOpt.isEmpty() || !notiOpt.get().getUserId().equals(user.getId())) {
			return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification not found or not yours");
		}
		var noti = notiOpt.get();
		noti.setRead(true);
		notificationRepository.save(noti);
		return ResponseEntity.ok().build();
	}

	// Xóa thông báo của chủ sân
	@DeleteMapping("/notifications/{id}")
	public ResponseEntity<?> deleteOwnerNotification(@PathVariable Integer id) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
		vn.footballfield.entity.Owner owner = ownerService.getOwnerByEmail(email);
		if (owner == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		vn.footballfield.entity.User user = userService.findByEmail(owner.getEmail()).orElse(null);
		if (user == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		var notiOpt = notificationRepository.findById(id);
		if (notiOpt.isEmpty() || !notiOpt.get().getUserId().equals(user.getId())) {
			return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Notification not found or not yours");
		}
		notificationRepository.deleteById(id);
		return ResponseEntity.noContent().build();
	}

	@PutMapping
	public ResponseEntity<?> updateCurrentOwner(@RequestBody vn.footballfield.entity.Owner ownerUpdate) {
		String email = org.springframework.security.core.context.SecurityContextHolder.getContext().getAuthentication().getName();
		vn.footballfield.entity.Owner owner = ownerService.getOwnerByEmail(email);
		if (owner == null) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
		owner.setOwnerName(ownerUpdate.getOwnerName());
		owner.setEmail(ownerUpdate.getEmail());
		owner.setContactNumber(ownerUpdate.getContactNumber());
		ownerService.updateOwner(owner);
		return ResponseEntity.ok(owner);
	}
}
