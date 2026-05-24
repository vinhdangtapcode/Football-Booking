package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import vn.footballfield.entity.Field;
import vn.footballfield.service.FieldService;

import java.util.List;

@RestController
public class PublicFieldController {

	@Autowired
	private FieldService fieldService;

	@GetMapping("/danh-sach-san")
	public ResponseEntity<List<Field>> getPublicFieldList() {
		List<Field> fields = fieldService.getAllFields();
		return new ResponseEntity<>(fields, HttpStatus.OK);
	}
}
