import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  String id;
  String userId;
  String category;
  DateTime expireDate;
  String itemDescription;
  String dealMethod;
  double price;
  String imageUrl;

  Listing({
    required this.id,
    required this.userId,
    required this.category,
    required this.expireDate,
    required this.itemDescription,
    required this.dealMethod,
    required this.price,
    required this.imageUrl,
  });

  factory Listing.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Listing(
      id: doc.id,
      userId: data['userId'] ?? '',
      category: data['category'] ?? '',
      expireDate: (data['expireDate'] as Timestamp).toDate(),
      itemDescription: data['itemDescription'] ?? '',
      dealMethod: data['dealMethod'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
    );
  }
}
