package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.entity.Book;
import vn.footballfield.service.BookingService;
import vn.payos.PayOS;
import vn.payos.model.webhooks.Webhook;
import vn.payos.model.webhooks.WebhookData;

import java.util.Map;

@Controller
public class PaymentController {

    @Autowired
    private PayOS payOS;

    @Autowired
    private BookingService bookingService;

    @PostMapping("/api/payment/webhook")
    public ResponseEntity<?> handlePayOSWebhook(@RequestBody Webhook body) {
        try {
            // Verify signature using PayOS SDK
            WebhookData webhookData = payOS.webhooks().verify(body);
            
            // Get orderCode from PayOS transaction details (this is our booking ID)
            long orderCode = webhookData.getOrderCode();
            int bookingId = (int) orderCode;

            // Find the booking
            Book booking = bookingService.getBookingById(bookingId).orElse(null);
            if (booking == null) {
                return ResponseEntity.ok(Map.of("success", true, "message", "Webhook verified but booking ID " + bookingId + " not found (likely test webhook)"));
            }

            // Only transition from PENDING_PAYMENT to APPROVED
            if ("PENDING_PAYMENT".equals(booking.getStatus())) {
                bookingService.confirmAndNotifyBooking(booking);
            }

            return ResponseEntity.ok(Map.of("success", true, "message", "Webhook verified and processed successfully"));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(400).body(Map.of("success", false, "message", "Signature verification failed: " + e.getMessage()));
        }
    }

    @GetMapping("/payment/success")
    @ResponseBody
    public String paymentSuccess() {
        return "<html><head><meta charset='UTF-8'>" +
               "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" +
               "<style>" +
               "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; text-align: center; margin-top: 60px; padding: 20px; background-color: #f7f9fc; }" +
               ".card { background: white; padding: 30px; border-radius: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); max-width: 400px; margin: 0 auto; }" +
               ".success-icon { font-size: 50px; margin-bottom: 20px; }" +
               "h2 { color: #2e7d32; margin-top: 0; }" +
               "p { color: #555; font-size: 15px; line-height: 1.6; }" +
               ".btn { display: inline-block; background-color: #2e7d32; color: white; padding: 12px 24px; border-radius: 10px; text-decoration: none; font-weight: bold; margin-top: 15px; border: none; cursor: pointer; }" +
               ".countdown { font-size: 13px; color: #888; margin-top: 20px; }" +
               "</style>" +
               "<script>" +
               "var count = 5;" +
               "function startCountdown() {" +
               "  var timer = setInterval(function() {" +
               "    count--;" +
               "    document.getElementById('timer').textContent = count;" +
               "    if (count <= 0) {" +
               "      clearInterval(timer);" +
               "      window.location.href = 'footballbooking://payment/success';" +
               "    }" +
               "  }, 1000);" +
               "}" +
               "window.onload = startCountdown;" +
               "</script>" +
               "</head><body>" +
               "<div class='card'>" +
               "  <div class='success-icon'>⚽</div>" +
               "  <h2>Thanh toán thành công!</h2>" +
               "  <p>Cảm ơn bạn. Khoản cọc đặt sân bóng đã được thanh toán và duyệt thành công.</p>" +
               "  <a href='footballbooking://payment/success' class='btn'>Về lại ứng dụng</a>" +
               "  <div class='countdown'>Hệ thống sẽ đưa bạn về lại ứng dụng sau <span id='timer'>5</span> giây...</div>" +
               "</div>" +
               "</body></html>";
    }

    @GetMapping("/payment/cancel")
    @ResponseBody
    public String paymentCancel() {
        return "<html><head><meta charset='UTF-8'>" +
               "<meta name='viewport' content='width=device-width, initial-scale=1.0'>" +
               "<style>" +
               "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; text-align: center; margin-top: 60px; padding: 20px; background-color: #f7f9fc; }" +
               ".card { background: white; padding: 30px; border-radius: 20px; box-shadow: 0 4px 15px rgba(0,0,0,0.05); max-width: 400px; margin: 0 auto; }" +
               ".cancel-icon { font-size: 50px; margin-bottom: 20px; }" +
               "h2 { color: #d32f2f; margin-top: 0; }" +
               "p { color: #555; font-size: 15px; line-height: 1.6; }" +
               ".btn { display: inline-block; background-color: #d32f2f; color: white; padding: 12px 24px; border-radius: 10px; text-decoration: none; font-weight: bold; margin-top: 15px; border: none; cursor: pointer; }" +
               ".countdown { font-size: 13px; color: #888; margin-top: 20px; }" +
               "</style>" +
               "<script>" +
               "var count = 5;" +
               "function startCountdown() {" +
               "  var timer = setInterval(function() {" +
               "    count--;" +
               "    document.getElementById('timer').textContent = count;" +
               "    if (count <= 0) {" +
               "      clearInterval(timer);" +
               "      window.location.href = 'footballbooking://payment/cancel';" +
               "    }" +
               "  }, 1000);" +
               "}" +
               "window.onload = startCountdown;" +
               "</script>" +
               "</head><body>" +
               "<div class='card'>" +
               "  <div class='cancel-icon'>❌</div>" +
               "  <h2>Thanh toán đã bị hủy</h2>" +
               "  <p>Lịch đặt sân chưa được thanh toán cọc. Bạn có thể thực hiện thanh toán lại bất kỳ lúc nào.</p>" +
               "  <a href='footballbooking://payment/cancel' class='btn'>Về lại ứng dụng</a>" +
               "  <div class='countdown'>Hệ thống sẽ đưa bạn về lại ứng dụng sau <span id='timer'>5</span> giây...</div>" +
               "</div>" +
               "</body></html>";
    }
}
