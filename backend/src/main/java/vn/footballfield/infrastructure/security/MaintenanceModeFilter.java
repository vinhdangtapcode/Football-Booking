package vn.footballfield.infrastructure.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;
import vn.footballfield.entity.SystemConfig;
import vn.footballfield.repository.SystemConfigRepository;

import java.io.IOException;
import java.util.Optional;

public class MaintenanceModeFilter extends OncePerRequestFilter {

    private final SystemConfigRepository systemConfigRepository;

    public MaintenanceModeFilter(SystemConfigRepository systemConfigRepository) {
        this.systemConfigRepository = systemConfigRepository;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String path = request.getRequestURI();

        // 1. Cho phép các đường dẫn Auth, Admin, Webhook, Static resources, Swagger
        if (path.startsWith("/api/auth") || 
            path.startsWith("/api/users/login") || 
            path.startsWith("/api/admin") || 
            path.startsWith("/api/payment/webhook") || 
            path.startsWith("/payment/") || 
            path.startsWith("/uploads/") || 
            path.startsWith("/swagger-ui") || 
            path.startsWith("/v3/api-docs") || 
            path.startsWith("/error")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 2. Cho phép nếu người dùng hiện tại là ADMIN
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.isAuthenticated() && 
            auth.getAuthorities().stream().anyMatch(a -> a.getAuthority().equals("ROLE_ADMIN"))) {
            filterChain.doFilter(request, response);
            return;
        }

        // 3. Kiểm tra cấu hình maintenance_mode
        Optional<SystemConfig> configOpt = systemConfigRepository.findById("maintenance_mode");
        if (configOpt.isPresent() && "true".equalsIgnoreCase(configOpt.get().getConfigValue())) {
            response.setStatus(503);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write("{\"maintenance\":true,\"message\":\"Hệ thống đang bảo trì thiết bị định kỳ. Vui lòng quay lại sau!\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }
}
