package vn.footballfield.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.*;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;
import vn.footballfield.entity.User;
import vn.footballfield.repository.UserRepository;

import java.util.Collections;

@Service
public class CustomUserDetailsService implements UserDetailsService {

	@Autowired
	private UserRepository userRepository;

	@Override
	public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
		User user = userRepository.findByEmail(email)
				.orElseThrow(() -> new UsernameNotFoundException("User not found"));
		// Nếu role đã có tiền tố "ROLE_", giữ nguyên. Nếu không thì thêm tiền tố.
		String role = user.getRole().startsWith("ROLE_") ? user.getRole() : "ROLE_" + user.getRole();
		return new org.springframework.security.core.userdetails.User(
				user.getEmail(),
				user.getPassword(),
				Collections.singletonList(new SimpleGrantedAuthority(role))
		);
	}
}
