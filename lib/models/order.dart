import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseOrder {
  final String id;
  final DateTime orderDate;
  final String paymentMethod;
  final String status;
  final DateTime deliveryDate;
  final double total;
  final List<OrderItem> items;

  PurchaseOrder({
    required this.id,
    required this.orderDate,
    required this.paymentMethod,
    required this.status,
    required this.deliveryDate,
    required this.total,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderDate': orderDate,
      'paymentMethod': paymentMethod,
      'status': status,
      'deliveryDate': deliveryDate,
      'total': total,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'],
      orderDate: (map['orderDate'] as Timestamp).toDate(),
      paymentMethod: map['paymentMethod'],
      status: map['status'],
      deliveryDate: (map['deliveryDate'] as Timestamp).toDate(),
      total: map['total'],
      items: (map['items'] as List).map((item) => OrderItem.fromMap(item)).toList(),
    );
  }
}

class OrderItem {
  final String listingId;
  final String itemDescription;
  final int quantity;
  final double price;
  final String imageUrl;

  OrderItem({
    required this.listingId,
    required this.itemDescription,
    required this.quantity,
    required this.price,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'listingId': listingId,
      'itemDescription': itemDescription,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      listingId: map['listingId'],
      itemDescription: map['itemDescription'],
      quantity: map['quantity'],
      price: map['price'],
      imageUrl: map['imageUrl'],
    );
  }
}