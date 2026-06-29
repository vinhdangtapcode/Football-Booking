package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.entity.Field;
import vn.footballfield.service.FieldService;

import javax.validation.Valid;
import java.util.List;

@RestController
@RequestMapping("/api/stadiums")
public class FieldController {

	@Autowired
	private FieldService fieldService;

	@GetMapping
	public ResponseEntity<List<Field>> getAllFields() {
		return new ResponseEntity<>(fieldService.getAllFields(), HttpStatus.OK);
	}

	@GetMapping("/{id}")
	public ResponseEntity<Field> getFieldById(@PathVariable Integer id) {
		return fieldService.getFieldById(id)
				.map(field -> new ResponseEntity<>(field, HttpStatus.OK))
				.orElse(new ResponseEntity<>(HttpStatus.NOT_FOUND));
	}

	@GetMapping("/danh-sach-san")
	public ResponseEntity<List<Field>> getPublicFieldList() {
		List<Field> fields = fieldService.getAllFields();
		return new ResponseEntity<>(fields, HttpStatus.OK);
	}

	@PostMapping
	public ResponseEntity<Field> createField(@Valid @RequestBody Field field) {
		return new ResponseEntity<>(fieldService.createField(field), HttpStatus.CREATED);
	}

	@PutMapping("/{id}")
	public ResponseEntity<Field> updateField(@PathVariable Integer id, @Valid @RequestBody Field field) {
		Field updated = fieldService.updateField(id, field);
		return updated != null
				? new ResponseEntity<>(updated, HttpStatus.OK)
				: new ResponseEntity<>(HttpStatus.NOT_FOUND);
	}

	@DeleteMapping("/{id}")
	public ResponseEntity<Void> deleteField(@PathVariable Integer id) {
		fieldService.deleteField(id);
		return new ResponseEntity<>(HttpStatus.NO_CONTENT);
	}

	@Autowired
	private vn.footballfield.service.BookingService bookingService;

	@GetMapping("/admin/revenue")
	public ResponseEntity<?> getAdminRevenue() {
		List<vn.footballfield.entity.Book> allBookings = bookingService.getAllBookings();
		double totalPlatformHeld = allBookings.stream()
				.filter(b -> ("APPROVED".equals(b.getStatus()) || ("CANCELLED".equals(b.getStatus()) && b.getTotalPrice() != null && b.getTotalPrice() > 0))
						&& !Boolean.TRUE.equals(b.getSettled()))
				.mapToDouble(b -> b.getTotalPrice() != null ? b.getTotalPrice() : 0.0)
				.sum();
		return ResponseEntity.ok(java.util.Map.of(
				"totalPlatformHeld", totalPlatformHeld,
				"bookings", allBookings
		));
	}

	@Autowired
	private vn.footballfield.repository.OwnerRepository ownerRepository;

	@GetMapping("/admin/owners-revenue")
	public ResponseEntity<?> getAdminOwnersRevenue() {
		List<vn.footballfield.entity.Owner> owners = ownerRepository.findAll();
		java.util.List<java.util.Map<String, Object>> result = new java.util.ArrayList<>();
		
		for (vn.footballfield.entity.Owner owner : owners) {
			List<vn.footballfield.entity.Book> ownerBookings = bookingService.getBookingsByOwner(owner.getId());
			
			double unsettledAmount = ownerBookings.stream()
					.filter(b -> ("APPROVED".equals(b.getStatus()) || ("CANCELLED".equals(b.getStatus()) && b.getTotalPrice() != null && b.getTotalPrice() > 0))
							&& !Boolean.TRUE.equals(b.getSettled()))
					.mapToDouble(b -> b.getTotalPrice() != null ? b.getTotalPrice() : 0.0)
					.sum();
					
			List<vn.footballfield.entity.Settlement> settlements = bookingService.getSettlementsByOwner(owner.getId());
			
			java.util.Map<String, Object> map = new java.util.HashMap<>();
			map.put("ownerId", owner.getId());
			map.put("ownerName", owner.getOwnerName());
			map.put("email", owner.getEmail());
			map.put("contactNumber", owner.getContactNumber() != null ? owner.getContactNumber() : "");
			map.put("unsettledAmount", unsettledAmount);
			map.put("settlements", settlements);
			map.put("bookingsCount", ownerBookings.size());
			map.put("bankName", owner.getBankName() != null ? owner.getBankName() : "");
			map.put("bankAccountNo", owner.getBankAccountNo() != null ? owner.getBankAccountNo() : "");
			map.put("bankAccountName", owner.getBankAccountName() != null ? owner.getBankAccountName() : "");
			result.add(map);
		}
		
		return ResponseEntity.ok(result);
	}

	@PostMapping("/admin/settle/{ownerId}")
	public ResponseEntity<?> settleOwner(@PathVariable Integer ownerId) {
		try {
			vn.footballfield.entity.Settlement settlement = bookingService.settleOwnerBookings(ownerId);
			return ResponseEntity.ok(settlement);
		} catch (Exception e) {
			return ResponseEntity.badRequest().body(java.util.Map.of("message", e.getMessage()));
		}
	}
}