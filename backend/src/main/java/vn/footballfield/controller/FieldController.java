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
}