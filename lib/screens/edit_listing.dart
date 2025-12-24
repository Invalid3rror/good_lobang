import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/models/category.dart';
import 'package:goodlobang/models/listing.dart';
import 'package:goodlobang/screens/profile_screen.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';

class EditListingScreen extends StatefulWidget {
  static String routeName = '/edit-listing';
  final Listing listing;

  const EditListingScreen({super.key, required this.listing});

  @override
  // ignore: library_private_types_in_public_api
  _EditListingScreenState createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  final TextEditingController _expireDateController = TextEditingController();

  var form = GlobalKey<FormState>();
  late String category;
  late DateTime _expireDate;
  late String itemDescription;
  late String dealMethod;
  late double price;
  File? imageFile;
  String? currentImageUrl;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    // Initialize fields with listing data
    category = widget.listing.category;
    _expireDate = widget.listing.expireDate;
    itemDescription = widget.listing.itemDescription;
    dealMethod = widget.listing.dealMethod;
    price = widget.listing.price;
    currentImageUrl = widget.listing.imageUrl;
    _expireDateController.text = _expireDate.toString();

    // Fetch categories from Firebase
    fetchCategoriesFromFirebase();
  }

  Future<void> fetchCategoriesFromFirebase() async {
    try {
      List<Category> fetchedCategories = await fbService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        // Set default category if needed
        if (categories.isNotEmpty) {
          category = categories[0].name;
        }
      });
    } catch (error) {
      print('Error fetching categories: $error');
      // Handle error appropriately, show message to user, retry mechanism, etc.
    }
  }

  void updateForm() {
    if (form.currentState!.validate()) {
      form.currentState!.save();
      void updateListing(String? imageUrl) {
        fbService
            .updateListing(
          widget.listing.id,
          category,
          _expireDate,
          itemDescription,
          dealMethod,
          price,
          imageUrl ?? currentImageUrl!,
        )
            .then((value) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Listing updated!')));
          Navigator.of(context).pushNamed(ProfileScreen.routeName);
        }).onError((error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $error'),
          ));
        });
      }

      if (imageFile != null) {
        fbService.addReceiptPhoto(imageFile!).then((imageUrl) {
          if (imageUrl != null) {
            updateListing(imageUrl);
          } else {
            throw Exception('Failed to upload image');
          }
        });
      } else {
        updateListing(null);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  void _pickExpireDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _expireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _expireDate) {
      setState(() {
        _expireDate = pickedDate;
        _expireDateController.text = _expireDate.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Edit Listing'),
      ),
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Form(
          key: form,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              const Text('Photo'),
              imageFile == null
                  ? InkWell(
                      onTap: _pickImage,
                      child: Image.network(currentImageUrl!),
                    )
                  : InkWell(
                      onTap: _pickImage,
                      child: Image.file(imageFile!),
                    ),
              const SizedBox(height: 20),
              const Text('Category'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Select Category'),
                ),
                value: category,
                items: categories.map((Category value) {
                  return DropdownMenuItem<String>(
                    value: value.name,
                    child: Text(value.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    category = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select a category.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Expire Date'),
              TextFormField(
                readOnly: true,
                controller: _expireDateController,
                onTap: _pickExpireDate,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Item Description'),
              TextFormField(
                initialValue: itemDescription,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Item Description',
                ),
                onSaved: (value) {
                  itemDescription = value!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please provide an item description.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Deal Method'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Select Deal Method'),
                ),
                value: dealMethod,
                items: const [
                  DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'Pick Up', child: Text('Pick Up')),
                ],
                onChanged: (value) {
                  setState(() {
                    dealMethod = value!;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select a deal method.";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text('Price'),
              TextFormField(
                initialValue: price.toString(),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Price',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ], // Allows only digits
                onSaved: (value) {
                  price = double.tryParse(value!)!;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please provide a price.";
                  }
                  if (double.tryParse(value) == null) {
                    return "Please enter a valid number.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: ElevatedButton(
          onPressed: updateForm,
          child: const Text('Update'),
        ),
      ),
    );
  }
}
