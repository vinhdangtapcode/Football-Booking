package vn.footballfield.config;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleAllExceptions(Exception ex) {
        ex.printStackTrace();
        String message = ex.getMessage();
        if (message == null || message.trim().isEmpty()) {
            message = "Đã xảy ra lỗi hệ thống!";
        }
        
        // Làm sạch thông báo lỗi
        message = message.replace("java.lang.RuntimeException: ", "")
                         .replace("RuntimeException: ", "");
                         
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("message", message));
    }
}
