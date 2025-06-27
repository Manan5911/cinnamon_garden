import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  final _restaurantCollection = FirebaseFirestore.instance.collection(
    'restaurants',
  );

  /// 🔹 Create new restaurant
  Future<void> createRestaurant(Restaurant restaurant) async {
    await _restaurantCollection.doc(restaurant.id).set(restaurant.toMap());
  }

  /// 🔹 Update restaurant
  Future<void> updateRestaurant(Restaurant restaurant) async {
    await _restaurantCollection.doc(restaurant.id).update(restaurant.toMap());
  }

  /// 🔹 Delete restaurant
  Future<void> deleteRestaurant(String id) async {
    await _restaurantCollection.doc(id).delete();
  }

  /// 🔹 Get all restaurants
  Future<List<Restaurant>> getAllRestaurants() async {
    final query = await _restaurantCollection.get();
    return query.docs
        .map((doc) => Restaurant.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// 🔹 Get restaurant by ID
  Future<Restaurant?> getRestaurantById(String id) async {
    final doc = await _restaurantCollection.doc(id).get();
    if (!doc.exists) return null;
    return Restaurant.fromMap(doc.data()!, doc.id);
  }
}
