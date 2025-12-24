import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:goodlobang/models/cart.dart';
import 'package:goodlobang/models/category.dart';
import 'package:path/path.dart';
import 'package:goodlobang/models/order.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:goodlobang/models/listing.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void addListingSync(
      String id,
      String category,
      DateTime expireDate,
      String itemDescription,
      String dealMethod,
      double price,
      String imageUrl) {
    debugPrint('addListing function is called');
  }

  Stream<List<Listing>> getListing() {
    return FirebaseFirestore.instance
        .collection('listing')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Listing(
                  id: doc.id,
                  userId: doc.data()['userId'] ?? '',
                  category: doc.data()['category'] ?? '',
                  itemDescription: doc.data()['itemDescription'] ?? '',
                  dealMethod: doc.data()['dealMethod'] ?? '',
                  price: doc.data()['price'].toDouble(),
                  imageUrl: doc.data()['imageUrl'] ?? '',
                  expireDate: (doc.data()['expireDate'] as Timestamp).toDate(),
                ))
            .toList());
  }

  Stream<List<Listing>> getUserListings(String userId) {
    return FirebaseFirestore.instance
        .collection('listing')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Listing(
                  id: doc.id,
                  userId: doc.data()['userId'] ?? '',
                  category: doc.data()['category'] ?? '',
                  itemDescription: doc.data()['itemDescription'] ?? '',
                  dealMethod: doc.data()['dealMethod'] ?? '',
                  price: doc.data()['price'].toDouble(),
                  imageUrl: doc.data()['imageUrl'] ?? '',
                  expireDate: (doc.data()['expireDate'] as Timestamp).toDate(),
                ))
            .toList());
  }

  Future<void> updateListing(
      String id,
      String? category,
      DateTime? expireDate,
      String? itemDescription,
      String? dealMethod,
      double? price,
      String imageUrl) {
    return FirebaseFirestore.instance.collection('listing').doc(id).update({
      'category': category,
      'expireDate': expireDate,
      'itemDescription': itemDescription,
      'dealMethod': dealMethod,
      'price': price,
      'imageUrl': imageUrl,
    });
  }

  Future<void> deleteListing(String id) {
    return FirebaseFirestore.instance.collection('listing').doc(id).delete();
  }

  Future<void> addListing(
      String id,
      String userId,
      String category,
      DateTime expireDate,
      String itemDescription,
      String dealMethod,
      double price,
      String imageUrl) async {
    await FirebaseFirestore.instance.collection('listing').doc(id).set({
      'id': id,
      'userId': userId,
      'category': category,
      'expireDate': expireDate,
      'itemDescription': itemDescription,
      'dealMethod': dealMethod,
      'price': price,
      'imageUrl': imageUrl,
    });
  }

  Future<UserCredential> login(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> forgotPassword(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Stream<User?> getAuthUser() {
    return FirebaseAuth.instance.authStateChanges();
  }

  Future<void> logOut() {
    return FirebaseAuth.instance.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data() as Map<String, dynamic>?;
  }

  Future<bool> isUsernameUnique(String username) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return result.docs.isEmpty;
  }

  Future<UserCredential> register(
      String name, String username, String email, String password) async {
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    // Add user details to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCredential.user!.uid)
        .set({
      'name': name,
      'username': username,
      'email': email,
    });

    return userCredential;
  }

  Future<String?> addReceiptPhoto(File receiptPhoto) {
    return FirebaseStorage.instance
        .ref()
        .child('${DateTime.now()}_${basename(receiptPhoto.path)}')
        .putFile(receiptPhoto)
        .then((task) {
      return task.ref.getDownloadURL().then((imageUrl) {
        return imageUrl;
      });
    });
  }

  Future<List<Listing>> searchListings(String query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('listing')
        .where('itemDescription', isGreaterThanOrEqualTo: query)
        .where('itemDescription', isLessThanOrEqualTo: '$query\uf8ff')
        .get();
    return snapshot.docs
        .map((doc) => Listing(
              id: doc.id,
              userId: doc.data()['userId'] ?? '',
              category: doc.data()['category'] ?? '',
              itemDescription: doc.data()['itemDescription'] ?? '',
              dealMethod: doc.data()['dealMethod'] ?? '',
              price: doc.data()['price'].toDouble(),
              imageUrl: doc.data()['imageUrl'] ?? '',
              expireDate: (doc.data()['expireDate'] as Timestamp).toDate(),
            ))
        .toList();
  }

  Future<List<String>> fetchRecentSearches() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    DocumentSnapshot<Map<String, dynamic>> doc =
        await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data()!.containsKey('recentSearches')) {
      return List<String>.from(doc.data()!['recentSearches']);
    } else {
      return [];
    }
  }

  Future<void> saveRecentSearch(String searchQuery) async {
    User? user = _auth.currentUser;
    if (user == null) {
      return;
    }

    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(userDoc);

      if (!snapshot.exists) {
        transaction.set(userDoc, {
          'recentSearches': [searchQuery]
        });
      } else {
        List<String> recentSearches =
            List<String>.from(snapshot.data()!['recentSearches'] ?? []);

        // Add the new search query at the beginning of the list
        recentSearches.insert(0, searchQuery);

        // Ensure there are no duplicate entries
        recentSearches = recentSearches.toSet().toList();

        transaction.update(userDoc, {'recentSearches': recentSearches});
      }
    });
  }

  Future<void> removeRecentSearch(String searchQuery) async {
    User? user = _auth.currentUser;
    if (user == null) {
      return;
    }

    DocumentReference<Map<String, dynamic>> userDoc =
        _firestore.collection('users').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(userDoc);

      if (!snapshot.exists) {
        return;
      }

      List<String> recentSearches =
          List<String>.from(snapshot.data()!['recentSearches'] ?? []);

      recentSearches.removeWhere((s) => s == searchQuery);

      transaction.update(userDoc, {'recentSearches': recentSearches});
    });
  }

  Future<void> addCategory(String name, String imageUrl) async {
    await FirebaseFirestore.instance.collection('categories').add({
      'name': name,
      'imageUrl': imageUrl,
    });
  }

  // Update the fetchCategories method
  Future<List<Category>> fetchCategories() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('categories').get();
      List<Category> categories = querySnapshot.docs.map((doc) {
        return Category(
          id: doc.id,
          name: doc['name'],
          imageUrl: doc['imageUrl'],
        );
      }).toList();
      return categories;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<Cart> getUserCart() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    DocumentSnapshot cartDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc('current')
        .get();

    if (!cartDoc.exists) {
      return Cart();
    }

    Map<String, dynamic> cartData = cartDoc.data() as Map<String, dynamic>;
    List<CartItem> items = [];

    for (var item in cartData['items']) {
      DocumentSnapshot listingDoc =
          await _firestore.collection('listing').doc(item['listingId']).get();

      if (listingDoc.exists) {
        Listing listing = Listing.fromFirestore(listingDoc);
        items.add(CartItem(listing: listing, quantity: item['quantity']));
      }
    }

    return Cart()..items = items;
  }

  // Add item to cart
  Future<void> addToCart(Listing listing) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    DocumentReference cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc('current');

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot cartSnapshot = await transaction.get(cartRef);

      if (!cartSnapshot.exists) {
        transaction.set(cartRef, {
          'items': [
            {'listingId': listing.id, 'quantity': 1}
          ]
        });
      } else {
        List<dynamic> items = List.from(cartSnapshot.get('items') as List);
        int index = items.indexWhere((item) => item['listingId'] == listing.id);

        if (index != -1) {
          items[index]['quantity'] += 1;
        } else {
          items.add({'listingId': listing.id, 'quantity': 1});
        }

        transaction.update(cartRef, {'items': items});
      }
    });
  }

  // Remove item from cart
  Future<void> removeFromCart(String listingId) async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    DocumentReference cartRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc('current');

    await _firestore.runTransaction((transaction) async {
      DocumentSnapshot cartSnapshot = await transaction.get(cartRef);

      if (cartSnapshot.exists) {
        List<dynamic> items = List.from(cartSnapshot.get('items') as List);
        items.removeWhere((item) => item['listingId'] == listingId);
        transaction.update(cartRef, {'items': items});
      }
    });
  }

  // Clear cart
  Future<void> clearCart() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc('current')
        .delete();
  }

Future<void> createOrder({
  required double total,
  required String paymentMethod,
  required String status,
  required List<OrderItem> items,
}) async {
  final user = _auth.currentUser;
  if (user != null) {
    final order = PurchaseOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      orderDate: DateTime.now(),
      paymentMethod: paymentMethod,
      status: status,
      deliveryDate: DateTime.now().add(const Duration(days: 7)),
      total: total,
      items: items,
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .add(order.toMap());
  }
}

  Stream<List<PurchaseOrder>> getUserOrders() {
    final user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => PurchaseOrder.fromMap(doc.data())).toList());
    }
    return Stream.value([]);
  }

Future<void> saveGoogleSignInUserData(User user) async {
    DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);

    // Check if the user document already exists
    DocumentSnapshot userDoc = await userDocRef.get();

    if (!userDoc.exists) {
      // If the user doesn't exist, create a new document with a unique username
      String username = user.displayName ?? user.email?.split('@')[0] ?? 'user${user.uid.substring(0, 5)}';
      
      // Check if the username already exists
      bool isUnique = await isUsernameUnique(username);
      int counter = 1;
      
      // If the username is not unique, append a number to it
      while (!isUnique) {
        String newUsername = '$username$counter';
        isUnique = await isUsernameUnique(newUsername);
        if (isUnique) {
          username = newUsername;
        }
        counter++;
      }

      await userDocRef.set({
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        // Add any other initial user data you want to save
      });
    } 
  }
Future<void> changePassword(String currentPassword, String newPassword) async {
  User? user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }

  AuthCredential credential = EmailAuthProvider.credential(
    email: user.email!,
    password: currentPassword,
  );

  try {
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  } catch (e) {
    throw Exception('Failed to change password: ${e.toString()}');
  }
}
}