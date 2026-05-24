package vn.footballfield.controller;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import vn.footballfield.config.JwtUtil;
import vn.footballfield.dto.GoogleAuthRequest;
import vn.footballfield.dto.LoginResponse;
import vn.footballfield.entity.User;
import vn.footballfield.service.GoogleAuthService;

/**
 * Controller for handling OAuth authentication
 */
@RestController
@RequestMapping("/api/auth")
public class OAuthController {

    @Autowired
    private GoogleAuthService googleAuthService;

    @Autowired
    private JwtUtil jwtUtil;

    /**
     * Authenticate user with Google ID token
     * 
     * @param request Contains the Google ID token from Flutter
     * @return JWT token and user info if successful
     */
    @PostMapping("/google")
    public ResponseEntity<?> authenticateWithGoogle(@RequestBody GoogleAuthRequest request) {
        try {
            // Verify Google token
            GoogleIdToken.Payload payload = googleAuthService.verifyGoogleToken(request.getIdToken());

            if (payload == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body("Invalid Google token");
            }

            // Find or create user
            User user = googleAuthService.findOrCreateUserFromGoogle(payload);

            // Generate JWT token
            String token = jwtUtil.generateToken(user.getEmail(), user.getRole());

            // Return JWT token and role
            LoginResponse response = new LoginResponse(token, user.getRole());
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.err.println("Google authentication error: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("Authentication failed: " + e.getMessage());
        }
    }
}
