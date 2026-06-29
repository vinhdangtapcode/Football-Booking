package vn.footballfield.entity;

import jakarta.persistence.*;
import javax.validation.constraints.Email;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

@Entity
@Table(name = "owner")
@com.fasterxml.jackson.annotation.JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
public class Owner {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer id;

	@NotBlank
	@Size(max = 50)
	@Column(name = "owner_name")
	private String ownerName;

	@Email
	@Size(max = 50)
	private String email;

	@Size(max = 15)
	@Column(name = "contact_number")
	private String contactNumber;

	@Size(max = 50)
	@Column(name = "bank_name")
	private String bankName;

	@Size(max = 50)
	@Column(name = "bank_account_no")
	private String bankAccountNo;

	@Size(max = 100)
	@Column(name = "bank_account_name")
	private String bankAccountName;

	// Getters and Setters
	public Integer getId() { return id; }
	public void setId(Integer id) { this.id = id; }
	public String getOwnerName() { return ownerName; }
	public void setOwnerName(String ownerName) { this.ownerName = ownerName; }
	public String getEmail() { return email; }
	public void setEmail(String email) { this.email = email; }
	public String getContactNumber() { return contactNumber; }
	public void setContactNumber(String contactNumber) { this.contactNumber = contactNumber; }
	public String getBankName() { return bankName; }
	public void setBankName(String bankName) { this.bankName = bankName; }
	public String getBankAccountNo() { return bankAccountNo; }
	public void setBankAccountNo(String bankAccountNo) { this.bankAccountNo = bankAccountNo; }
	public String getBankAccountName() { return bankAccountName; }
	public void setBankAccountName(String bankAccountName) { this.bankAccountName = bankAccountName; }
}