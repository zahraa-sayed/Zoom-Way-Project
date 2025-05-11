class DriverRegistration {
  String name;
  String email;
  String phoneNumber;
  String carModel;
  String password;
  String passwordConfirmation;
  String address;
  String licenseNumber;
  String drivingExperience;
  String licensePlate;
  String carColor;
  String manufacturingYear;

  DriverRegistration({
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.carModel,
    required this.password,
    required this.passwordConfirmation,
    required this.address,
    required this.licenseNumber,
    required this.drivingExperience,
    required this.licensePlate,
    required this.carColor,
    required this.manufacturingYear,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'car_model': carModel,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'address': address,
      'license_number': licenseNumber,
      'driving_experience': drivingExperience,
      'license_plate': licensePlate,
      'car_color': carColor,
      'manufacturing_year': manufacturingYear,
      'user_type': 'driver',
    };
  }
}
 
