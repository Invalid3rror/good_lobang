import 'package:goodlobang/models/listing.dart';

class CartItem {
  final Listing listing;
  int quantity;

  CartItem({required this.listing, this.quantity = 1});
}

class Cart {
  List<CartItem> items = [];

  void addItem(Listing listing) {
    final existingItem = items.firstWhere(
      (item) => item.listing.id == listing.id,
      orElse: () => CartItem(listing: listing, quantity: 0),
    );

    if (existingItem.quantity == 0) {
      items.add(existingItem);
    }

    existingItem.quantity++;
  }

  void removeItem(String listingId) {
    items.removeWhere((item) => item.listing.id == listingId);
  }

  double get totalPrice {
    return items.fold(0,
        (total, current) => total + (current.listing.price * current.quantity));
  }

  int get itemCount {
    return items.fold(0, (total, current) => total + current.quantity);
  }

  void clear() {
    items.clear();
  }
}
