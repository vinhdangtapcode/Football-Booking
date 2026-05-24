package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import vn.footballfield.entity.Favorite;
import vn.footballfield.entity.Field;
import vn.footballfield.repository.FavoriteRepository;
import vn.footballfield.repository.FieldRepository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class FavoriteService {

	@Autowired
	private FavoriteRepository favoriteRepository;

	@Autowired
	private FieldRepository fieldRepository;

	public List<Field> getFavoritesByCustomer(Integer customerId) {
		List<Favorite> favorites = favoriteRepository.findByCustomerId(customerId);
		List<Field> favoriteFields = new ArrayList<>();
		for (Favorite favorite : favorites) {
			if (favorite.getField() != null) {
				favoriteFields.add(favorite.getField());
			}
		}
		return favoriteFields;
	}

	public Favorite addFavorite(Integer customerId, Integer fieldId) {
		Optional<Field> fieldOpt = fieldRepository.findById(fieldId);
		if (!fieldOpt.isPresent()) {
			throw new RuntimeException("Field not found");
		}
		Favorite favorite = new Favorite();
		favorite.setCustomerId(customerId);
		// Gán đối tượng Field lấy được thay vì fieldId
		favorite.setField(fieldOpt.get());
		return favoriteRepository.save(favorite);
	}

	@Transactional
	public void removeFavorite(Integer customerId, Integer fieldId) {
		favoriteRepository.deleteByCustomerIdAndField_Id(customerId, fieldId);
	}
}