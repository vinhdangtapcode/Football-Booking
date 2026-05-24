package vn.footballfield.dto;

import javax.validation.constraints.NotNull;
import java.time.LocalDateTime;

public class TimeShift {

	@NotNull
	private LocalDateTime fromTime;

	@NotNull
	private LocalDateTime toTime;

	public TimeShift() {}

	public TimeShift(LocalDateTime fromTime, LocalDateTime toTime) {
		this.fromTime = fromTime;
		this.toTime = toTime;
	}

	public LocalDateTime getFromTime() {
		return fromTime;
	}

	public void setFromTime(LocalDateTime fromTime) {
		this.fromTime = fromTime;
	}

	public LocalDateTime getToTime() {
		return toTime;
	}

	public void setToTime(LocalDateTime toTime) {
		this.toTime = toTime;
	}
}