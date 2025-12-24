// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/models/cart.dart';
import 'package:goodlobang/screens/auth_ui/change_password.dart';
import 'package:goodlobang/screens/auth_ui/login/login.dart';
import 'package:goodlobang/screens/home.dart';
import 'package:goodlobang/screens/listing_screen.dart';
import 'package:goodlobang/screens/notification.dart';
import 'package:goodlobang/screens/payment.dart';
import 'package:goodlobang/screens/profile_screen.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:goodlobang/services/theme_service.dart';
import 'dart:async';

import 'package:goodlobang/widgets/search.dart';

class BaseScreen extends StatefulWidget {
  final Widget content;
  final int selectedIndex;
  final String initialSearchQuery;

  const BaseScreen({
    super.key,
    required this.content,
    required this.selectedIndex,
    this.initialSearchQuery = '',
  });

  @override
  // ignore: library_private_types_in_public_api
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  late FirebaseService fbService;
  late ThemeService themeService;

  late int _selectedIndex;
  late String _searchQuery;
  Timer? _debounce;

  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    fbService = GetIt.instance<FirebaseService>();
    themeService = GetIt.instance<ThemeService>();

    _selectedIndex = widget.selectedIndex;
    _searchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: _searchQuery);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => _buildSelectedScreen(index)),
    );
  }

  void _onSearchTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchScreen(
          initialQuery: _searchController.text,
          onSearch: (query) {
            setState(() {
              _searchQuery = query;
              _searchController.text = query;
            });
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => _buildSelectedScreen(0),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedScreen(int index) {
    switch (index) {
      case 0:
        return BaseScreen(
          content: HomeScreen(searchQuery: _searchQuery),
          selectedIndex: 0,
          initialSearchQuery: _searchQuery,
        );
      case 1:
        return const ListingScreen();
      case 2:
        return const NotificationScreen();
      case 3:
        return const ProfileScreen();
      default:
        return BaseScreen(
          content: HomeScreen(searchQuery: _searchQuery),
          selectedIndex: 0,
          initialSearchQuery: _searchQuery,
        );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<Cart>(
              future: fbService.getUserCart(),
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
                              leading: Image.network(
                                  item.listing.imageUrl), // Display image
                              title: Text(item.listing.itemDescription),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Quantity: ${item.quantity}'),
                                  Text(
                                      'Price: \$${item.listing.price.toStringAsFixed(2)}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle),
                                onPressed: () async {
                                  await fbService
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
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '\$${cart.totalPrice.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge,
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
void _showMenu() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Change Password'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, ChangePasswordScreen.routeName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: const Text('Change Theme'),
                onTap: () {
                  Navigator.pop(context);
                  _showThemeOptions();
                },
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Logout'),
                onTap: () async {
                  await fbService.logOut();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(Colors.black, 'Black'),
              _buildThemeOption(Colors.white, 'white'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(Color color, String name) {
    return GestureDetector(
      onTap: () {
        themeService.setTheme(_createThemeData(color), name.toLowerCase().replaceAll(' ', ''));
        Navigator.of(context).pop();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 15),
            const SizedBox(width: 10),
            Text(name),
          ],
        ),
      ),
    );
  }

  ThemeData _createThemeData(Color primaryColor) {
    bool isDark = primaryColor == Colors.black;
    return ThemeData(
      primaryColor: primaryColor,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? Colors.black : Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.black : primaryColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
      ).copyWith(surface: isDark ? Colors.black : Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 100.0,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: _showMenu,
                    icon: const Icon(Icons.menu),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search GoodLobang',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _onSearchTapped,
                              icon: const Icon(Icons.mic),
                            ),
                          ],
                        ),
                      ),
                      onTap: _onSearchTapped,
                    ),
                  ),
                  IconButton(
                    onPressed: _showCart,
                    icon: const Icon(Icons.shopping_cart),
                  ),
                ],
              ),
            )
          : null,
      body: widget.content,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add),
            label: 'Sell',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        //selectedItemColor: const Color(0xFFBE1414),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}
