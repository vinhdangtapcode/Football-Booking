package vn.footballfield.dto;

import java.time.LocalDateTime;

public class TimeRangeDTO {
    private LocalDateTime fromTime;
    private LocalDateTime toTime;

    public TimeRangeDTO(LocalDateTime fromTime, LocalDateTime toTime) {
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

