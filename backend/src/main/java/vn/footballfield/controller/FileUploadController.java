package vn.footballfield.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import vn.footballfield.entity.Field;
import vn.footballfield.entity.FieldImage;
import vn.footballfield.repository.FieldImageRepository;
import vn.footballfield.service.FieldService;
import vn.footballfield.service.FileStorageService;

import java.io.IOException;
import java.util.*;

@RestController
@RequestMapping("/api/images")
public class FileUploadController {

	@Autowired
	private FileStorageService fileStorageService;

	@Autowired
	private FieldService fieldService;

	@Autowired
	private FieldImageRepository fieldImageRepository;

	/**
	 * Upload 1 ảnh
	 * POST /api/images/upload
	 */
	@PostMapping("/upload")
	public ResponseEntity<?> uploadImage(@RequestParam("file") MultipartFile file) {
		try {
			String imageUrl = fileStorageService.storeFile(file);
			Map<String, String> response = new HashMap<>();
			response.put("url", imageUrl);
			return ResponseEntity.ok(response);
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		} catch (IOException e) {
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Map.of("error", "Lỗi khi lưu file: " + e.getMessage()));
		}
	}

	/**
	 * Upload nhiều ảnh
	 * POST /api/images/upload-multiple
	 */
	@PostMapping("/upload-multiple")
	public ResponseEntity<?> uploadMultipleImages(@RequestParam("files") MultipartFile[] files) {
		if (files.length > 5) {
			return ResponseEntity.badRequest().body(Map.of("error", "Tối đa 5 ảnh"));
		}

		List<Map<String, String>> uploadedFiles = new ArrayList<>();
		try {
			for (MultipartFile file : files) {
				String imageUrl = fileStorageService.storeFile(file);
				Map<String, String> fileInfo = new HashMap<>();
				fileInfo.put("url", imageUrl);
				fileInfo.put("originalName", file.getOriginalFilename());
				uploadedFiles.add(fileInfo);
			}
			return ResponseEntity.ok(uploadedFiles);
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		} catch (IOException e) {
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Map.of("error", "Lỗi khi lưu file: " + e.getMessage()));
		}
	}

	/**
	 * Upload ảnh và gắn vào sân bóng
	 * POST /api/images/field/{fieldId}/upload
	 */
	@PostMapping("/field/{fieldId}/upload")
	public ResponseEntity<?> uploadFieldImages(
			@PathVariable Integer fieldId,
			@RequestParam("files") MultipartFile[] files) {

		if (files.length > 5) {
			return ResponseEntity.badRequest().body(Map.of("error", "Tối đa 5 ảnh"));
		}

		Optional<Field> fieldOpt = fieldService.getFieldById(fieldId);
		if (fieldOpt.isEmpty()) {
			return ResponseEntity.notFound().build();
		}

		Field field = fieldOpt.get();

		// Kiểm tra tổng số ảnh hiện có + ảnh mới <= 5
		List<FieldImage> existingImages = fieldImageRepository.findByFieldId(fieldId);
		if (existingImages.size() + files.length > 5) {
			return ResponseEntity.badRequest()
					.body(Map.of("error", "Tổng số ảnh không được vượt quá 5. Hiện có " + existingImages.size() + " ảnh."));
		}

		List<Map<String, Object>> uploadedImages = new ArrayList<>();
		try {
			int nextOrder = existingImages.size();
			for (int i = 0; i < files.length; i++) {
				String imageUrl = fileStorageService.storeFile(files[i]);

				FieldImage fieldImage = new FieldImage();
				fieldImage.setField(field);
				fieldImage.setImageUrl(imageUrl);
				fieldImage.setDisplayOrder(nextOrder + i);
				fieldImage.setIsPrimary(existingImages.isEmpty() && i == 0); // Ảnh đầu tiên là primary nếu chưa có ảnh nào
				fieldImageRepository.save(fieldImage);

				// Nếu là ảnh primary, cập nhật imageUrl của field
				if (fieldImage.getIsPrimary()) {
					field.setImageUrl(imageUrl);
					fieldService.updateField(fieldId, field);
				}

				Map<String, Object> imgInfo = new HashMap<>();
				imgInfo.put("id", fieldImage.getId());
				imgInfo.put("url", imageUrl);
				imgInfo.put("displayOrder", fieldImage.getDisplayOrder());
				imgInfo.put("isPrimary", fieldImage.getIsPrimary());
				uploadedImages.add(imgInfo);
			}

			return ResponseEntity.ok(uploadedImages);
		} catch (IllegalArgumentException e) {
			return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
		} catch (IOException e) {
			return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
					.body(Map.of("error", "Lỗi khi lưu file: " + e.getMessage()));
		}
	}

	/**
	 * Lấy danh sách ảnh của 1 sân
	 * GET /api/images/field/{fieldId}
	 */
	@GetMapping("/field/{fieldId}")
	public ResponseEntity<?> getFieldImages(@PathVariable Integer fieldId) {
		List<FieldImage> images = fieldImageRepository.findByFieldIdOrderByDisplayOrderAsc(fieldId);
		List<Map<String, Object>> result = new ArrayList<>();
		for (FieldImage img : images) {
			Map<String, Object> imgInfo = new HashMap<>();
			imgInfo.put("id", img.getId());
			imgInfo.put("url", img.getImageUrl());
			imgInfo.put("displayOrder", img.getDisplayOrder());
			imgInfo.put("isPrimary", img.getIsPrimary());
			result.add(imgInfo);
		}
		return ResponseEntity.ok(result);
	}

	/**
	 * Xóa 1 ảnh của sân
	 * DELETE /api/images/{imageId}
	 */
	@DeleteMapping("/{imageId}")
	public ResponseEntity<?> deleteFieldImage(@PathVariable Integer imageId) {
		Optional<FieldImage> imageOpt = fieldImageRepository.findById(imageId);
		if (imageOpt.isEmpty()) {
			return ResponseEntity.notFound().build();
		}

		FieldImage image = imageOpt.get();
		// Xóa file vật lý
		fileStorageService.deleteFile(image.getImageUrl());
		// Xóa record trong DB
		fieldImageRepository.delete(image);

		// Nếu ảnh bị xóa là primary, đặt ảnh đầu tiên còn lại làm primary
		if (Boolean.TRUE.equals(image.getIsPrimary())) {
			Field field = image.getField();
			List<FieldImage> remainingImages = fieldImageRepository.findByFieldIdOrderByDisplayOrderAsc(field.getId());
			if (!remainingImages.isEmpty()) {
				FieldImage newPrimary = remainingImages.get(0);
				newPrimary.setIsPrimary(true);
				fieldImageRepository.save(newPrimary);
				field.setImageUrl(newPrimary.getImageUrl());
			} else {
				field.setImageUrl(null);
			}
			fieldService.updateField(field.getId(), field);
		}

		return ResponseEntity.noContent().build();
	}

	/**
	 * Đặt 1 ảnh làm ảnh đại diện (primary)
	 * PUT /api/images/{imageId}/set-primary
	 */
	@PutMapping("/{imageId}/set-primary")
	public ResponseEntity<?> setPrimaryImage(@PathVariable Integer imageId) {
		Optional<FieldImage> imageOpt = fieldImageRepository.findById(imageId);
		if (imageOpt.isEmpty()) {
			return ResponseEntity.notFound().build();
		}

		FieldImage image = imageOpt.get();
		Field field = image.getField();

		// Bỏ primary của tất cả ảnh khác
		List<FieldImage> allImages = fieldImageRepository.findByFieldId(field.getId());
		for (FieldImage img : allImages) {
			img.setIsPrimary(false);
			fieldImageRepository.save(img);
		}

		// Đặt ảnh này làm primary
		image.setIsPrimary(true);
		fieldImageRepository.save(image);

		// Cập nhật imageUrl của field
		field.setImageUrl(image.getImageUrl());
		fieldService.updateField(field.getId(), field);

		return ResponseEntity.ok(Map.of("message", "Đã đặt ảnh làm ảnh đại diện"));
	}
}
