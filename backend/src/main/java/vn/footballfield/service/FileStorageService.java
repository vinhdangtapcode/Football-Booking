package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

@Service
public class FileStorageService {

	@Value("${file.upload-dir:uploads/field-images}")
	private String uploadDir;

	@Value("${file.base-url:http://localhost:8080}")
	private String baseUrl;

	private static final List<String> ALLOWED_EXTENSIONS = Arrays.asList("jpg", "jpeg", "png", "webp", "gif");
	private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

	/**
	 * Upload file, trả về URL public
	 */
	public String storeFile(MultipartFile file) throws IOException {
		validateFile(file);

		// Tạo thư mục nếu chưa tồn tại
		Path uploadPath = Paths.get(uploadDir);
		if (!Files.exists(uploadPath)) {
			Files.createDirectories(uploadPath);
		}

		// Tạo tên file unique
		String originalFilename = file.getOriginalFilename();
		String extension = getFileExtension(originalFilename);
		String newFilename = UUID.randomUUID().toString() + "." + extension;

		// Lưu file
		Path targetPath = uploadPath.resolve(newFilename);
		Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);

		// Trả về URL public
		return baseUrl + "/uploads/field-images/" + newFilename;
	}

	/**
	 * Xóa file theo URL
	 */
	public boolean deleteFile(String fileUrl) {
		try {
			// Trích xuất filename từ URL
			String filename = fileUrl.substring(fileUrl.lastIndexOf("/") + 1);
			Path filePath = Paths.get(uploadDir).resolve(filename);

			if (Files.exists(filePath)) {
				Files.delete(filePath);
				return true;
			}
		} catch (IOException e) {
			System.err.println("Error deleting file: " + e.getMessage());
		}
		return false;
	}

	/**
	 * Validate file (check size, extension)
	 */
	private void validateFile(MultipartFile file) {
		if (file.isEmpty()) {
			throw new IllegalArgumentException("File không được rỗng");
		}

		if (file.getSize() > MAX_FILE_SIZE) {
			throw new IllegalArgumentException("File quá lớn. Tối đa 5MB");
		}

		String extension = getFileExtension(file.getOriginalFilename());
		if (!ALLOWED_EXTENSIONS.contains(extension.toLowerCase())) {
			throw new IllegalArgumentException("Định dạng file không được hỗ trợ. Chỉ chấp nhận: " + String.join(", ", ALLOWED_EXTENSIONS));
		}
	}

	/**
	 * Lấy phần mở rộng của file
	 */
	private String getFileExtension(String filename) {
		if (filename == null || !filename.contains(".")) {
			return "";
		}
		return filename.substring(filename.lastIndexOf(".") + 1);
	}
}
