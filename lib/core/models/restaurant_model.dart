class Restaurant {
  final String id;
  final String name;
  final String address;

  Restaurant({required this.id, required this.name, required this.address});

  factory Restaurant.fromMap(Map<String, dynamic> data, String id) {
    return Restaurant(id: id, name: data['name'], address: data['address']);
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'address': address};
  }
}
