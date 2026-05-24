package vn.footballfield.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

	private static final Logger logger = LoggerFactory.getLogger(JwtAuthenticationFilter.class);

	@Autowired
	private JwtUtil jwtUtil;

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
			throws ServletException, IOException {

		String path = request.getRequestURI();

		// Bỏ qua các endpoint public không cần JWT
		if (path.startsWith("/api/users/register") || path.startsWith("/api/users/login")) {
			chain.doFilter(request, response);
			return;
		}

		// Tiếp tục xử lý JWT nếu không phải endpoint public
		String header = request.getHeader("Authorization");
		String jwt = null;
		String email = null;

		if (header != null && header.startsWith("Bearer ") && header.length() > 7) {
			jwt = header.substring(7);
			try {
				if (jwtUtil.validateToken(jwt)) {
					email = jwtUtil.getEmailFromToken(jwt);
					String role = jwtUtil.getRoleFromToken(jwt);

					if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {
						UsernamePasswordAuthenticationToken authentication =
								new UsernamePasswordAuthenticationToken(
										email, null, Collections.singletonList(new SimpleGrantedAuthority("ROLE_" + role)));
						authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
						SecurityContextHolder.getContext().setAuthentication(authentication);
						logger.debug("Authenticated user: {}", email);
					}
				} else {
					logger.warn("Invalid JWT token: {}", jwt);
				}
			} catch (Exception e) {
				logger.error("JWT token validation failed: {}", e.getMessage());
			}
		} else {
			logger.debug("No valid Bearer token found in request");
		}

		chain.doFilter(request, response);
	}
}
