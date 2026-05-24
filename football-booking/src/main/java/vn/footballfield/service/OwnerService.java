package vn.footballfield.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.Owner;
import vn.footballfield.repository.OwnerRepository;

import java.util.Optional;

@Service
public class OwnerService {

	@Autowired
	private OwnerRepository ownerRepository;

	public Owner getOwnerByEmail(String email) {
		Optional<Owner> opt = ownerRepository.findByEmail(email);
		return opt.orElseThrow(() -> new RuntimeException("Owner not found for email: " + email));
	}

	public Owner updateOwner(Owner owner) {
		return ownerRepository.save(owner);
	}
}
