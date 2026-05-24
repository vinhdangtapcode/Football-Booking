package vn.footballfield.dto;

import lombok.Getter;
import lombok.Setter;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Setter
@Getter
public class AdminResetPasswordRequest {

    @NotBlank(message = "New password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String newPassword;

    public AdminResetPasswordRequest() {}

    public AdminResetPasswordRequest(String newPassword) {
        this.newPassword = newPassword;
    }

}
