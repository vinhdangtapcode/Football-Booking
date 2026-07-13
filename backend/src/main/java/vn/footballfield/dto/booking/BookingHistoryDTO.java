package vn.footballfield.dto.booking;

import java.time.LocalDateTime;

public class BookingHistoryDTO {
    private Integer id;
    private Integer fieldId;
    private String fieldName;
    private String fieldAddress;
    private Double pricePerHour;
    private LocalDateTime fromTime;
    private LocalDateTime toTime;
    private String additional;
    private String customerName;
    private String customerPhone;

    private String status;
    private Double totalPrice;
    private String paymentUrl;
    private String fieldImageUrl;
    private String ownerName;
    private String ownerPhone;

    public BookingHistoryDTO(Integer id, Integer fieldId, String fieldName, String fieldAddress, Double pricePerHour, LocalDateTime fromTime, LocalDateTime toTime, String additional, String customerName, String customerPhone, String status, Double totalPrice, String paymentUrl, String fieldImageUrl, String ownerName, String ownerPhone) {
        this.id = id;
        this.fieldId = fieldId;
        this.fieldName = fieldName;
        this.fieldAddress = fieldAddress;
        this.pricePerHour = pricePerHour;
        this.fromTime = fromTime;
        this.toTime = toTime;
        this.additional = additional;
        this.customerName = customerName;
        this.customerPhone = customerPhone;
        this.status = status;
        this.totalPrice = totalPrice;
        this.paymentUrl = paymentUrl;
        this.fieldImageUrl = fieldImageUrl;
        this.ownerName = ownerName;
        this.ownerPhone = ownerPhone;
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getFieldId() { return fieldId; }
    public void setFieldId(Integer fieldId) { this.fieldId = fieldId; }
    public String getFieldName() { return fieldName; }
    public void setFieldName(String fieldName) { this.fieldName = fieldName; }
    public String getFieldAddress() { return fieldAddress; }
    public void setFieldAddress(String fieldAddress) { this.fieldAddress = fieldAddress; }
    public Double getPricePerHour() { return pricePerHour; }
    public void setPricePerHour(Double pricePerHour) { this.pricePerHour = pricePerHour; }
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
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public Double getTotalPrice() { return totalPrice; }
    public void setTotalPrice(Double totalPrice) { this.totalPrice = totalPrice; }
    public String getPaymentUrl() { return paymentUrl; }
    public void setPaymentUrl(String paymentUrl) { this.paymentUrl = paymentUrl; }
    public String getFieldImageUrl() { return fieldImageUrl; }
    public void setFieldImageUrl(String fieldImageUrl) { this.fieldImageUrl = fieldImageUrl; }
    public String getOwnerName() { return ownerName; }
    public void setOwnerName(String ownerName) { this.ownerName = ownerName; }
    public String getOwnerPhone() { return ownerPhone; }
    public void setOwnerPhone(String ownerPhone) { this.ownerPhone = ownerPhone; }
}


