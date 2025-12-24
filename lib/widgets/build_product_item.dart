// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:goodlobang/models/listing.dart';
import 'package:goodlobang/services/firebase_service.dart'; // Import your Firebase service

Widget buildProductItem(FirebaseService fbService, Listing listing, BuildContext context) { // Add FirebaseService as a parameter
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: NetworkImage(listing.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                listing.itemDescription,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '\$${listing.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Expiring in ${listing.expireDate.difference(DateTime.now()).inDays} days',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await fbService.addToCart(listing);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${listing.itemDescription} added to cart'),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to add item to cart: $e'),
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
          ),
          child: const Text(
            'ADD CART',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );
}
