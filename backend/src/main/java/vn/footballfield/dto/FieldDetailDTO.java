package vn.footballfield.dto;

import vn.footballfield.entity.Field;

public class FieldDetailDTO {

	private Field field;

	public FieldDetailDTO(Field field) {
		this.field = field;
	}

	public Field getField() {
		return field;
	}

	public void setField(Field field) {
		this.field = field;
	}
}