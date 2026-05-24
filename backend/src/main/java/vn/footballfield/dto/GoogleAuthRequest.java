package vn.footballfield.dto;

/**
 * DTO for Google OAuth authentication request from Flutter
 */
public class GoogleAuthRequest {
    private String idToken;

    public GoogleAuthRequest() {
    }

    public GoogleAuthRequest(String idToken) {
        this.idToken = idToken;
    }

    public String getIdToken() {
        return idToken;
    }

    public void setIdToken(String idToken) {
        this.idToken = idToken;
    }
}
