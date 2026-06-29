package vn.footballfield;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
@org.springframework.scheduling.annotation.EnableScheduling
public class FootballBookingApplication {

	public static void main(String[] args) {
		SpringApplication.run(FootballBookingApplication.class, args);
	}
}