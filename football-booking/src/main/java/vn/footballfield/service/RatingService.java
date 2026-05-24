package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.Rating;
import vn.footballfield.repository.FieldRepository;
import vn.footballfield.repository.RatingRepository;

import javax.validation.Valid;
import java.util.List;
import java.util.Optional;

@Service
public class RatingService {

	@Autowired
	private RatingRepository ratingRepository;

	@Autowired
	private FieldRepository fieldRepository;

	public Rating createRating(@Valid Rating rating, Integer customerId) {
		// Kiểm tra xem đối tượng Field có được gán hay không
		if (rating.getField() == null || rating.getField().getId() == null) {
			throw new RuntimeException("Field not provided");
		}
		Integer fieldId = rating.getField().getId();
		// Kiểm tra trường có tồn tại không
		if (!fieldRepository.existsById(fieldId)) {
			throw new RuntimeException("Field not found");
		}
		// Kiểm tra số điểm đánh giá hợp lệ
		if (rating.getScore() < 1 || rating.getScore() > 5) {
			throw new RuntimeException("Score must be between 1 and 5");
		}
		// Gán CustomerId cho rating
		rating.setCustomerId(customerId);
		// Lưu Rating
		Rating savedRating = ratingRepository.save(rating);
		// Cập nhật rating trung bình cho Field dựa vào fieldId
//		updateFieldRating(fieldId);
		return savedRating;
	}

	public Rating updateRating(Integer ratingId, Integer customerId, vn.footballfield.dto.RatingForm form) {
		Optional<Rating> optionalRating = ratingRepository.findById(ratingId);
		if (optionalRating.isEmpty()) {
			return null;
		}
		Rating rating = optionalRating.get();
		if (!rating.getCustomerId().equals(customerId)) {
			return null;
		}
		rating.setScore(form.getScore());
		rating.setComment(form.getComment());
		rating.setIsAnonymous(form.getIsAnonymous());
		return ratingRepository.save(rating);
	}

	public boolean deleteRating(Integer ratingId, Integer customerId) {
		Optional<Rating> optionalRating = ratingRepository.findById(ratingId);
		if (optionalRating.isEmpty()) {
			return false;
		}
		Rating rating = optionalRating.get();
		if (!rating.getCustomerId().equals(customerId)) {
			return false;
		}
		ratingRepository.deleteById(ratingId);
		return true;
	}

	public List<Rating> getRatingsByField(Integer fieldId) {
		return ratingRepository.findByFieldId(fieldId);
	}

	public List<Rating> getRatingsByCustomer(Integer customerId) {
		return ratingRepository.findByCustomerId(customerId);
	}

//	private void updateFieldRating(Integer fieldId) {
//		List<Rating> ratings = ratingRepository.findByFieldId(fieldId);
//		float averageRating = (float) ratings.stream()
//				.mapToInt(Rating::getScore)
//				.average()
//				.orElse(0.0);
//		fieldRepository.findById(fieldId).ifPresent(field -> {
//			field.setRating(averageRating);
//			fieldRepository.save(field);
//		});
//	}
}

