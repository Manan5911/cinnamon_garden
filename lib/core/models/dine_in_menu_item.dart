class DineInMenuItem {
  final String name;
  final int quantity;
  final double price;

  DineInMenuItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory DineInMenuItem.fromMap(Map<String, dynamic> data) {
    return DineInMenuItem(
      name: data['name'],
      quantity: data['quantity'],
      price: (data['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'quantity': quantity, 'price': price};
  }
}
