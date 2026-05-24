// File: src/main/java/vn/footballfield/config/SecurityConfig.java
package vn.footballfield.config;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

	@Autowired
	private JwtAuthenticationFilter jwtAuthenticationFilter;

	@Bean
	public PasswordEncoder passwordEncoder() {
		return new BCryptPasswordEncoder();
	}

	@Bean
	public CorsConfigurationSource corsConfigurationSource() {
		CorsConfiguration configuration = new CorsConfiguration();
		// Cho phép tất cả origins (Flutter app, web, mobile, etc.)
		configuration.setAllowedOriginPatterns(List.of("*"));
		configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
		configuration.setAllowedHeaders(List.of("Origin", "Content-Type", "Accept", "Authorization"));
		configuration.setAllowCredentials(true);

		UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
		source.registerCorsConfiguration("/**", configuration);
		return source;
	}

	@Bean
	public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
		// Không cần gọi http.cors() nữa vì bean corsConfigurationSource đã được đăng
		// ký.
		http
				.csrf(AbstractHttpConfigurer::disable)
				.sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
				.authorizeHttpRequests(authorize -> authorize
						// Public endpoints - không cần đăng nhập
						.requestMatchers(
								"/api/users/register",
								"/api/users/login",
								"/api/auth/**",
								"/danh-sach-san",
								"/swagger-ui.html",
								"/swagger-ui/**",
								"/v3/api-docs/**",
								"/api-docs/**")
						.permitAll()

						// ADMIN only - quản lý hệ thống
						.requestMatchers("/api/stadiums/**").hasRole("ADMIN")
						.requestMatchers(HttpMethod.GET, "/api/users").hasRole("ADMIN")
						.requestMatchers(HttpMethod.GET, "/api/users/{id:\\d+}").hasRole("ADMIN")
						.requestMatchers(HttpMethod.PUT, "/api/users/{id:\\d+}").hasRole("ADMIN")
						.requestMatchers(HttpMethod.DELETE, "/api/users/{id:\\d+}").hasRole("ADMIN")
						.requestMatchers(HttpMethod.POST, "/api/users/{id:\\d+}/reset-password").hasRole("ADMIN")

						// OWNER only - quản lý sân của chủ sân
						.requestMatchers("/api/owner/**").hasRole("OWNER")

						// USER only - các chức năng người dùng
						.requestMatchers("/dat-san/**", "/yeu-thich/**", "/danh-gia-san/**").hasRole("USER")

						// Authenticated users - thông tin cá nhân
						.requestMatchers(
								"/api/users/me",
								"/api/users/change-password",
								"/api/users/notifications/**")
						.authenticated()
						.requestMatchers(HttpMethod.PUT, "/api/users").authenticated()

						// Mặc định yêu cầu đăng nhập
						.anyRequest().authenticated())
				.addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

		return http.build();
	}
}
