package vn.footballfield.dto;

import java.time.LocalDateTime;

public class BookingHistoryDTO {
    private Integer id;
    private Integer fieldId;
    private String fieldName;
    private LocalDateTime fromTime;
    private LocalDateTime toTime;
    private String additional;
    private String customerName;
    private String customerPhone;

    public BookingHistoryDTO(Integer id, Integer fieldId, String fieldName, LocalDateTime fromTime, LocalDateTime toTime, String additional, String customerName, String customerPhone) {
        this.id = id;
        this.fieldId = fieldId;
        this.fieldName = fieldName;
        this.fromTime = fromTime;
        this.toTime = toTime;
        this.additional = additional;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getFieldId() { return fieldId; }
    public void setFieldId(Integer fieldId) { this.fieldId = fieldId; }
    public String getFieldName() { return fieldName; }
    public void setFieldName(String fieldName) { this.fieldName = fieldName; }
    public LocalDateTime getFromTime() { return fromTime; }
    public void setFromTime(LocalDateTime fromTime) { this.fromTime = fromTime; }
    public LocalDateTime getToTime() { return toTime; }
    public void setToTime(LocalDateTime toTime) { this.toTime = toTime; }
    public String getAdditional() { return additional; }
    public void setAdditional(String additional) { this.additional = additional; }
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    public String getCustomerPhone() { return customerPhone; }
    public void setCustomerPhone(String customerPhone) { this.customerPhone = customerPhone; }
}

