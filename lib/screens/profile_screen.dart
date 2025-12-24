import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/models/cart.dart';
import 'package:goodlobang/models/listing.dart';
import 'package:goodlobang/screens/edit_listing.dart';
import 'package:goodlobang/screens/navigation_bar.dart';
import 'package:goodlobang/screens/payment.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:share_plus/share_plus.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const String routeName = '/profile-screen';

  @override
  Widget build(BuildContext context) {
    return const BaseScreen(
      content: ProfileScreenContent(),
      selectedIndex: 3,
    );
  }
}

class ProfileScreenContent extends StatelessWidget {
  const ProfileScreenContent({super.key});

  static const String routeName = '/profile-screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        automaticallyImplyLeading: false,
        toolbarHeight: 100.0,
        title: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            final userId = userSnapshot.data?.uid;
            return FutureBuilder<Map<String, dynamic>?>(
              future: userId != null
                  ? GetIt.instance<FirebaseService>().getUserData(userId)
                  : null,
              builder: (context, userDataSnapshot) {
                final username = userDataSnapshot.data?['username'] ?? 'Guest';
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showCart(context);
            },
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return _buildProfileContent(context, null);
            }

            final userId = userSnapshot.data!.uid;
            return FutureBuilder<Map<String, dynamic>?>(
              future: GetIt.instance<FirebaseService>().getUserData(userId),
              builder: (context, userDataSnapshot) {
                return _buildProfileContent(context, userDataSnapshot.data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
      BuildContext context, Map<String, dynamic>? userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 30,
          backgroundColor: Colors.white,
          backgroundImage: AssetImage('images/logo.png'),
        ),
        const SizedBox(height: 20),
        Text(
          userData?['name'] ?? 'Guest',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(userData?['verified'] == true ? 'Verified' : 'Not Verified'),
            const SizedBox(width: 10),
            if (userData?['phone'] != null)
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFBE1414),
                foregroundColor: Colors.white,
                child: Icon(Icons.phone),
              ),
            const SizedBox(width: 10),
            if (userData?['email'] != null)
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFBE1414),
                foregroundColor: Colors.white,
                child: Icon(Icons.email),
              ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Listing',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(
          color: Colors.grey,
          height: 2,
          thickness: 1,
        ),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, userSnapshot) {
              final userId = userSnapshot.data?.uid;
              return StreamBuilder<List<Listing>>(
                stream: userId != null
                    ? GetIt.instance<FirebaseService>().getUserListings(userId)
                    : null,
                builder: (context, listingSnapshot) {
                  if (listingSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!listingSnapshot.hasData ||
                      listingSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No listings available'));
                  }

                  final listings = listingSnapshot.data!;

                  return GridView.builder(
                    itemCount: listings.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: MediaQuery.of(context).size.width /
                          (MediaQuery.of(context).size.height / 1.5),
                    ),
                    itemBuilder: (context, index) {
                      Listing listing = listings[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            child: Image.network(
                              listing.imageUrl,
                              width: 180,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  listing.itemDescription,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (String value) {
                                  if (value == 'share') {
                                    Share.share(
                                      '${listing.itemDescription}\n\nPrice: \$${listing.price.toStringAsFixed(2)}\n\nCheck out this listing on Good Lobang!',
                                      subject: listing.itemDescription,
                                    );
                                  } else if (value == 'edit') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditListingScreen(listing: listing),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: const Text(
                                              'Are you sure you want to delete this listing?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                GetIt.instance<
                                                        FirebaseService>()
                                                    .deleteListing(listing.id)
                                                    .then((value) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                        content: Text(
                                                            'Listing deleted!')),
                                                  );
                                                  Navigator.of(context).pop();
                                                }).onError((error, stackTrace) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            'Error: $error')),
                                                  );
                                                });
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                                itemBuilder: (BuildContext context) {
                                  return <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'share',
                                      child: ListTile(
                                        title: Text(
                                          'Share',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: ListTile(
                                        title: Text(
                                          'Edit Listing Details',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: ListTile(
                                        title: Text(
                                          'Delete Listing',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                                icon: const Icon(Icons.more_vert),
                              ),
                            ],
                          ),
                          Text(
                            listing.price.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<Cart>(
              future: GetIt.instance<FirebaseService>().getUserCart(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.items.isEmpty) {
                  return const Center(child: Text('Your cart is empty'));
                }

                Cart cart = snapshot.data!;

                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Cart',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final item = cart.items[index];
                            return ListTile(
                              title: Text(item.listing.itemDescription),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              trailing: Text(
                                  '\$${(item.listing.price * item.quantity).toStringAsFixed(2)}'),
                              leading: IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () async {
                                  await GetIt.instance<FirebaseService>()
                                      .removeFromCart(item.listing.id);
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '\$${cart.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, PaymentScreen.routeName);
                        },
                        child: const Text('Proceed to Checkout'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
