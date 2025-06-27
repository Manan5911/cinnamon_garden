class MenuItemModel {
  final String name;
  final int quantity;
  final double? price; // For dine-in. Null for catering.

  MenuItemModel({required this.name, required this.quantity, this.price});

  factory MenuItemModel.fromMap(Map<String, dynamic> map) {
    return MenuItemModel(
      name: map['name'],
      quantity: map['quantity'],
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      if (price != null) 'price': price,
    };
  }
}
