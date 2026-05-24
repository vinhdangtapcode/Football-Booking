package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.entity.Favorite;
import vn.footballfield.entity.Field;
import vn.footballfield.service.FavoriteService;
import vn.footballfield.service.UserService;

import java.util.List;

@RestController
@RequestMapping("/yeu-thich")
public class FavoriteController {

	@Autowired
	private FavoriteService favoriteService;

	@Autowired
	private UserService userService;

	@GetMapping
	public ResponseEntity<List<Field>> getFavorites() {
		Integer customerId = getCurrentUserId();
		return new ResponseEntity<>(favoriteService.getFavoritesByCustomer(customerId), HttpStatus.OK);
	}

	@PostMapping
	public ResponseEntity<Favorite> addFavorite(@RequestParam Integer fieldId) {
		Integer customerId = getCurrentUserId();
		return new ResponseEntity<>(favoriteService.addFavorite(customerId, fieldId), HttpStatus.CREATED);
	}

	@DeleteMapping
	public ResponseEntity<Void> removeFavorite(@RequestParam Integer fieldId) {
		Integer customerId = getCurrentUserId();
		favoriteService.removeFavorite(customerId, fieldId);
		return new ResponseEntity<>(HttpStatus.NO_CONTENT);
	}

	private Integer getCurrentUserId() {
		String email = SecurityContextHolder.getContext().getAuthentication().getName();
		return userService.getUserIdByEmail(email);
	}
}