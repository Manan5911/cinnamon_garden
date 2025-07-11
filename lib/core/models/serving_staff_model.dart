class ServingStaffModel {
  final String name;
  final String phoneNumber;

  ServingStaffModel({required this.name, required this.phoneNumber});

  factory ServingStaffModel.fromMap(Map<String, dynamic> map) {
    return ServingStaffModel(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'phoneNumber': phoneNumber};
  }
}
