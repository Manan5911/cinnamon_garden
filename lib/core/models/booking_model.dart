import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item_model.dart';

enum BookingType { dineIn, catering }

class BookingModel {
  final String id;
  final BookingType type;
  final DateTime date;
  final int members;
  final String restaurantId;
  final String? tableNumber;
  final String? extraDetails;
  final String guideName;
  final String guideMobile;
  final String? companyName;
  final String? assignedManagerId;
  final List<MenuItemModel> menuItems;
  final double? ratePerPerson; // Only for catering
  final bool isClosed;

  BookingModel({
    required this.id,
    required this.type,
    required this.date,
    required this.members,
    required this.restaurantId,
    this.tableNumber,
    this.extraDetails,
    required this.guideName,
    required this.guideMobile,
    this.companyName,
    this.assignedManagerId,
    required this.menuItems,
    this.ratePerPerson,
    this.isClosed = false,
  });

  BookingModel copyWith({
    String? id,
    BookingType? type,
    DateTime? date,
    int? members,
    String? restaurantId,
    String? tableNumber,
    String? extraDetails,
    String? guideName,
    String? guideMobile,
    String? companyName,
    String? assignedManagerId,
    List<MenuItemModel>? menuItems,
    double? ratePerPerson,
    bool? isClosed,
  }) {
    return BookingModel(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      members: members ?? this.members,
      restaurantId: restaurantId ?? this.restaurantId,
      tableNumber: tableNumber ?? this.tableNumber,
      extraDetails: extraDetails ?? this.extraDetails,
      guideName: guideName ?? this.guideName,
      guideMobile: guideMobile ?? this.guideMobile,
      companyName: companyName ?? this.companyName,
      assignedManagerId: assignedManagerId ?? this.assignedManagerId,
      menuItems: menuItems ?? this.menuItems,
      ratePerPerson: ratePerPerson ?? this.ratePerPerson,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      type: BookingType.values.firstWhere((e) => e.name == map['type']),
      date: (map['date'] as Timestamp).toDate(),
      members: map['members'],
      restaurantId: map['restaurantId'],
      tableNumber: map['tableNumber'],
      extraDetails: map['extraDetails'],
      guideName: map['guideName'],
      guideMobile: map['guideMobile'],
      companyName: map['companyName'],
      assignedManagerId: map['assignedManagerId'],
      menuItems: (map['menuItems'] as List<dynamic>)
          .map((e) => MenuItemModel.fromMap(e))
          .toList(),
      ratePerPerson: map['ratePerPerson']?.toDouble(),
      isClosed: map['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'members': members,
      'restaurantId': restaurantId,
      'tableNumber': tableNumber,
      'extraDetails': extraDetails,
      'guideName': guideName,
      'guideMobile': guideMobile,
      'companyName': companyName,
      'assignedManagerId': assignedManagerId,
      'menuItems': menuItems.map((e) => e.toMap()).toList(),
      'ratePerPerson': ratePerPerson,
      'isClosed': isClosed,
    };
  }
}
