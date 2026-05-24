package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.dto.RatingForm;
import vn.footballfield.entity.Field;
import vn.footballfield.entity.Rating;
import vn.footballfield.service.FieldService;
import vn.footballfield.service.RatingService;
import vn.footballfield.service.UserService;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/danh-gia-san")
public class RatingController {

	@Autowired
	private RatingService ratingService;

	@Autowired
	private UserService userService;

	@Autowired
	private FieldService fieldService;


	@GetMapping("/{fieldId}")
	public ResponseEntity<List<Rating>> getRatingsByField(@PathVariable Integer fieldId) {
		List<Rating> ratings = ratingService.getRatingsByField(fieldId);
		for (Rating rating : ratings) {
			if (Boolean.TRUE.equals(rating.getIsAnonymous())) {
				rating.setCustomerName(null);
			} else {
				String customerName = userService.getUserNameById(rating.getCustomerId());
				rating.setCustomerName(customerName);
			}
		}
		return new ResponseEntity<>(ratings, HttpStatus.OK);
	}

	@GetMapping("/danh-gia-cua-toi")
	public ResponseEntity<List<Rating>> getRatingsByCustomer() {
		Integer customerId = getCurrentUserId();
		List<Rating> ratings = ratingService.getRatingsByCustomer(customerId);
		for (Rating rating : ratings) {
			if (Boolean.TRUE.equals(rating.getIsAnonymous())) {
				rating.setCustomerName(null);
			} else {
				String customerName = userService.getUserNameById(rating.getCustomerId());
				rating.setCustomerName(customerName);
			}
		}
		return new ResponseEntity<>(ratings, HttpStatus.OK);
	}

	@PostMapping("/them-danh-gia")
	public ResponseEntity<Rating> addRating(@Valid @RequestBody RatingForm form, @RequestParam Integer fieldId) {
		Integer customerId = getCurrentUserId();
		Rating rating = new Rating();
		Field field = fieldService.getFieldById(fieldId)
				.orElseThrow(() -> new RuntimeException("Field not found"));
		rating.setField(field);
		rating.setScore(form.getScore());
		rating.setComment(form.getComment());
		rating.setIsAnonymous(form.getIsAnonymous());
		Rating saved = ratingService.createRating(rating, customerId);
		if (Boolean.TRUE.equals(saved.getIsAnonymous())) {
			saved.setCustomerName(null);
		} else {
			String customerName = userService.getUserNameById(saved.getCustomerId());
			saved.setCustomerName(customerName);
		}
		return new ResponseEntity<>(saved, HttpStatus.CREATED);
	}

	@PutMapping("/cap-nhat-danh-gia/{ratingId}")
	public ResponseEntity<Rating> updateRating(@PathVariable Integer ratingId, @Valid @RequestBody RatingForm form) {
		Integer customerId = getCurrentUserId();
		Rating updated = ratingService.updateRating(ratingId, customerId, form);
		if (updated == null) {
			return new ResponseEntity<>(HttpStatus.NOT_FOUND);
		}
		if (Boolean.TRUE.equals(updated.getIsAnonymous())) {
			updated.setCustomerName(null);
		} else {
			String customerName = userService.getUserNameById(updated.getCustomerId());
			updated.setCustomerName(customerName);
		}
		return new ResponseEntity<>(updated, HttpStatus.OK);
	}

	@DeleteMapping("/xoa-danh-gia/{ratingId}")
	public ResponseEntity<Void> deleteRating(@PathVariable Integer ratingId) {
		Integer customerId = getCurrentUserId();
		boolean deleted = ratingService.deleteRating(ratingId, customerId);
		if (deleted) {
			return new ResponseEntity<>(HttpStatus.NO_CONTENT);
		} else {
			return new ResponseEntity<>(HttpStatus.NOT_FOUND);
		}
	}

	private Integer getCurrentUserId() {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		return userService.getUserIdByEmail(email);
	}
}

