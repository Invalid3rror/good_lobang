// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:goodlobang/models/category.dart';
import 'package:goodlobang/screens/listing_screen.dart';
import 'package:goodlobang/screens/profile_screen.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddListingScreen extends StatefulWidget {
  static String routeName = '/add-listing';

  const AddListingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AddListingScreenState createState() => _AddListingScreenState();
}

class _AddListingScreenState extends State<AddListingScreen> {
  final FirebaseService fbService = GetIt.instance<FirebaseService>();
  var form = GlobalKey<FormState>();
  String? category;
  DateTime? expireDate;
  String? itemDescription;
  String? dealMethod;
  double? price;
  File? imageFile;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
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

  void saveForm() async {
    bool isValid = form.currentState!.validate();
    if (isValid) {
      form.currentState!.save();

      String id = DateTime.now().millisecondsSinceEpoch.toString();
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String userId = currentUser.uid;

        try {
          String? imageUrl = await fbService.addReceiptPhoto(imageFile!);
          if (imageUrl != null) {
            await fbService.addListing(
              id,
              userId,
              category!, // Ensure category is not null here
              expireDate!,
              itemDescription!,
              dealMethod!,
              price!,
              imageUrl,
            );

            FocusScope.of(context).unfocus();
            form.currentState!.reset();
            setState(() {
              imageFile = null;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listing added!')),
            );
            Navigator.of(context).pushNamed(ProfileScreen.routeName);
          } else {
            throw Exception('Failed to upload image');
          }
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User is not authenticated.'),
          ),
        );
      }
    }
  }

  void _pickExpireDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        expireDate = pickedDate;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text('Camera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
            Navigator.of(context)
                .pushReplacementNamed(ListingScreen.routeName);
          },
        ),
        title: const Text('Add Listing'),
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
                  ? TextFormField(
                      onTap: _showImageSourceDialog,
                      decoration: const InputDecoration(
                        labelText: 'Pick an image',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (imageFile == null) {
                          return 'Please select an image.';
                        }
                        return null;
                      })
                  : InkWell(
                      onTap: _showImageSourceDialog,
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
                    category = value;
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
                  onTap: _pickExpireDate,
                  decoration: InputDecoration(
                    labelText: expireDate == null
                        ? 'Pick a date'
                        : expireDate.toString(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (expireDate == null) {
                      return 'Please select an expire date.';
                    }
                    return null;
                  }),
              const SizedBox(height: 20),
              const Text('Item Description'),
              TextFormField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Item Description',
                ),
                onSaved: (value) {
                  itemDescription = value;
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
                items: const [
                  DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
                  DropdownMenuItem(value: 'Pick Up', child: Text('Pick Up')),
                ],
                onChanged: (value) {
                  setState(() {
                    dealMethod = value;
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Price',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ], // Allows only digits
                onSaved: (value) {
                  price = double.tryParse(value!);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please provide a price.";
                  }
                  if (int.tryParse(value) == null) {
                    return "Please enter a valid integer.";
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
          onPressed: saveForm,
          child: const Text('Add'),
        ),
      ),
    );
  }
}
