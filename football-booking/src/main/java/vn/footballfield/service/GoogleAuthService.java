package vn.footballfield.service;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.User;
import vn.footballfield.repository.UserRepository;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.Collections;
import java.util.Optional;
import java.util.UUID;

/**
 * Service for handling Google OAuth authentication
 */
@Service
public class GoogleAuthService {

    @Value("${google.client.id:}")
    private String googleClientId;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * Verify Google ID token and return user info
     * 
     * @param idTokenString The ID token from Google Sign-In
     * @return GoogleIdToken.Payload containing user info, or null if invalid
     */
    public GoogleIdToken.Payload verifyGoogleToken(String idTokenString) {
        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(),
                    GsonFactory.getDefaultInstance())
                    .setAudience(Collections.singletonList(googleClientId))
                    .build();

            GoogleIdToken idToken = verifier.verify(idTokenString);
            if (idToken != null) {
                return idToken.getPayload();
            }
        } catch (GeneralSecurityException | IOException e) {
            System.err.println("Error verifying Google token: " + e.getMessage());
        }
        return null;
    }

    /**
     * Find or create user from Google OAuth data
     * 
     * @param payload The verified Google token payload
     * @return User entity
     */
    public User findOrCreateUserFromGoogle(GoogleIdToken.Payload payload) {
        String googleId = payload.getSubject();
        String email = payload.getEmail();
        String name = (String) payload.get("name");
        String pictureUrl = (String) payload.get("picture");

        // First, try to find by Google ID
        Optional<User> existingByGoogleId = userRepository.findByGoogleId(googleId);
        if (existingByGoogleId.isPresent()) {
            User user = existingByGoogleId.get();
            // Update picture URL if changed
            if (pictureUrl != null && !pictureUrl.equals(user.getPictureUrl())) {
                user.setPictureUrl(pictureUrl);
                userRepository.save(user);
            }
            return user;
        }

        // Then, try to find by email (link existing account)
        Optional<User> existingByEmail = userRepository.findByEmail(email);
        if (existingByEmail.isPresent()) {
            User user = existingByEmail.get();
            // Link Google account to existing user
            user.setGoogleId(googleId);
            if (pictureUrl != null) {
                user.setPictureUrl(pictureUrl);
            }
            return userRepository.save(user);
        }

        // Create new user
        User newUser = new User();
        newUser.setEmail(email);
        newUser.setName(name != null ? name : email.split("@")[0]);
        newUser.setGoogleId(googleId);
        newUser.setPictureUrl(pictureUrl);
        newUser.setRole("USER"); // Default role for Google sign-in users
        // Set a random password for OAuth users (they won't use it)
        newUser.setPassword(passwordEncoder.encode(UUID.randomUUID().toString()));

        return userRepository.save(newUser);
    }
}
