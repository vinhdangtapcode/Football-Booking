package vn.footballfield.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

	@Value("${file.upload-dir:uploads/field-images}")
	private String uploadDir;

	@Override
	public void addResourceHandlers(ResourceHandlerRegistry registry) {
		// Serve uploaded images as static resources
		registry.addResourceHandler("/uploads/**")
				.addResourceLocations("file:./" + uploadDir + "/../");
	}
}
