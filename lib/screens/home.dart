// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:goodlobang/models/listing.dart';
import 'package:goodlobang/models/category.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:goodlobang/widgets/build_product_item.dart';

class HomeScreen extends StatelessWidget {
  final String searchQuery;

  const HomeScreen({super.key, this.searchQuery = ''});

  static const String routeName = '/home-screen';

  @override
  Widget build(BuildContext context) {
    final FirebaseService fbService = GetIt.instance<FirebaseService>();

return StreamBuilder<User?>(
      stream: fbService.getAuthUser(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        } else if (userSnapshot.hasData) {
          final userId = userSnapshot.data!.uid;
          return FutureBuilder<Map<String, dynamic>?>(
            future: fbService.getUserData(userId),
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (userDataSnapshot.hasError) {
                return Center(child: Text('Error: ${userDataSnapshot.error}'));
              } else if (userDataSnapshot.hasData) {
                final username = userDataSnapshot.data?['name'] ?? 'Guest';
                return HomeScreenContent(
                  name: username,
                  fbService: fbService,
                  initialSearchQuery: searchQuery,
                );
              } else {
                return const Center(child: Text('No user data found'));
              }
            },
          );
        } else {
          return const Center(child: Text('No user logged in'));
        }
      },
    );
  }
}

class HomeScreenContent extends StatefulWidget {
  final String name;
  final FirebaseService fbService;
  final String initialSearchQuery;

  const HomeScreenContent({
    super.key,
    required this.name,
    required this.fbService,
    required this.initialSearchQuery,
  });

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  late String _searchQuery;
  String? _sortCriteria;
  Map<String, dynamic>? _filterCriteria;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Welcome back, ${widget.name}!'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(
                color: Colors.grey,
                height: 2,
                thickness: 1,
              ),
              _buildCategories(),
              const Divider(
                color: Colors.grey,
                height: 2,
                thickness: 1,
              ),
              const Text(
                'Near-Expired Products',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBE1414),
                    ),
                  ),
                  IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list)),
                ],
              ),
              _buildSortOptions(),
              const Text(
                'Buy what you need, don\'t overbuy*',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              _buildListings(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return FutureBuilder<List<Category>>(
      future: widget.fbService.fetchCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          List<Category> categories = snapshot.data!;
          return Column(
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length > 3 ? 4 : categories.length,
                  itemBuilder: (context, index) {
                    if (index == 3 && categories.length > 3) {
                      // 'See All' button
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showAllCategories(categories),
                              child: const CircleAvatar(
                                backgroundColor: Colors.grey,
                                radius: 30,
                                child: Icon(Icons.arrow_forward_ios,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'See All',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () => _filterByCategory(categories[index].name),
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  NetworkImage(categories[index].imageUrl),
                              radius: 30,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              categories[index].name,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          return const Text('No categories found');
        }
      },
    );
  }

  void _showAllCategories(List<Category> categories) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'All Categories',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _filterByCategory(categories[index].name);
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage(categories[index].imageUrl),
                            radius: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            categories[index].name,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOptions() {
    return DropdownButton<String>(
      value: _sortCriteria,
      hint: const Text('Sort by'),
      onChanged: (String? newValue) {
        setState(() {
          _sortCriteria = newValue;
        });
      },
      items: <String>[
        'Price: Low to High',
        'Price: High to Low',
        'Expiry Date: Soonest First',
        'Expiry Date: Latest First'
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildListings() {
    return StreamBuilder<List<Listing>>(
      stream: widget.fbService.getListing(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No listings available');
        } else {
          List<Listing> listings = snapshot.data!;
          listings = _filterListings(listings);
          listings = _sortListings(listings);

          return Column(
            children: listings
                .map((listing) => GestureDetector(
                      onTap: () => _showListingDetails(listing),
                      child: buildProductItem(widget.fbService, listing, context),
                    ))
                .toList(),
          );
        }
      },
    );
  }

  void _showFilterDialog() {
    String? selectedCategory;
    String? selectedDealMethod;
    double? maxPrice;
    DateTime? selectedExpiryDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Products'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<List<Category>>(
                      future: widget.fbService.fetchCategories(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (snapshot.hasData) {
                          List<Category> categories = snapshot.data!;
                          return DropdownButtonFormField<String>(
                            value: selectedCategory,
                            hint: const Text('Category'),
                            items: categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(category.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                          );
                        } else {
                          return const Text('No categories found');
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDealMethod,
                      hint: const Text('Deal Method'),
                      items: <String>[
                        'Delivery',
                        'Pick Up',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDealMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Max Price',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          maxPrice = double.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedExpiryDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && picked != selectedExpiryDate) {
                          setState(() {
                            selectedExpiryDate = picked;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Expiry Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              selectedExpiryDate != null
                                  ? '${selectedExpiryDate!.year}-${selectedExpiryDate!.month}-${selectedExpiryDate!.day}'
                                  : 'Select Date',
                            ),
                            const Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedCategory = null;
                      selectedDealMethod = null;
                      maxPrice = null;
                      selectedExpiryDate = null;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters(
                      selectedCategory,
                      selectedDealMethod,
                      maxPrice,
                      selectedExpiryDate,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _applyFilters(
    String? selectedCategory,
    String? selectedDealMethod,
    double? maxPrice,
    DateTime? selectedExpiryDate,
  ) {
    setState(() {
      _filterCriteria = {
        'category': selectedCategory,
        'dealMethod': selectedDealMethod,
        'maxPrice': maxPrice,
        'expiryDate': selectedExpiryDate,
      };
    });
  }

  void _filterByCategory(String categoryName) {
    setState(() {
      _filterCriteria = {
        'category': categoryName,
        'dealMethod': null,
        'maxPrice': null,
        'expiryDate': null,
      };
    });
  }

  void _showListingDetails(Listing listing) {
    final FirebaseService fbService = GetIt.instance<FirebaseService>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(listing.itemDescription),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(listing.imageUrl),
                const SizedBox(height: 10),
                Text('Price: \$${listing.price.toStringAsFixed(2)}'),
                Text('Category: ${listing.category}'),
                Text('Expiry Date: ${listing.expireDate.toString()}'),
                const SizedBox(height: 10),
                Text('Description: ${listing.itemDescription}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  await fbService.addToCart(listing);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('${listing.itemDescription} added to cart')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add item to cart: $e')),
                  );
                }
              },
              child: const Text('Add to Cart'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<Listing> _filterListings(List<Listing> listings) {
    if (_searchQuery.isNotEmpty) {
      listings = listings
          .where((listing) => listing.itemDescription
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_filterCriteria != null) {
      if (_filterCriteria!['category'] != null) {
        listings = listings
            .where((listing) => listing.category
                .toLowerCase()
                .contains(_filterCriteria!['category'].toLowerCase()))
            .toList();
      }
      if (_filterCriteria!['maxPrice'] != null) {
        listings = listings
            .where((listing) => listing.price <= _filterCriteria!['maxPrice'])
            .toList();
      }
    }

    return listings;
  }

  List<Listing> _sortListings(List<Listing> listings) {
    switch (_sortCriteria) {
      case 'Price: Low to High':
        listings.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        listings.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Expiry Date: Soonest First':
        listings.sort((a, b) => a.expireDate.compareTo(b.expireDate));
        break;
      case 'Expiry Date: Latest First':
        listings.sort((a, b) => b.expireDate.compareTo(a.expireDate));
        break;
    }
    return listings;
  }
}


//to add category if any
// void addInitialCategories() async {
//   FirebaseService fbService = GetIt.instance<FirebaseService>();

//   await fbService.addCategory('Beer, Wine & Spirits',
//       'https://media.nedigital.sg/fairprice/images/6fe0713d-b81f-4628-a641-3429c7fe4851/L1_BeerWine&Spirits_120522.jpg');
//   await fbService.addCategory('Food Cupboard',
//       'https://media.nedigital.sg/fairprice/images/46ab2fba-6c64-414e-8ebd-6f48e93ad825/L1_FoodCupboard_110522.jpg');

//   print('Initial categories added successfully');
// }
