// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:goodlobang/screens/home.dart';
import 'package:goodlobang/screens/navigation_bar.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:goodlobang/models/cart.dart';
import 'package:goodlobang/models/order.dart';
import 'stripe_service.dart';

class PaymentScreen extends StatefulWidget {
  static const routeName = '/payment';

  const PaymentScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  static final TextEditingController _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalcodeController = TextEditingController();
  final _currencyList = 'SGD';
  bool _hasDonated = false;

  final FirebaseService fbService = FirebaseService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Cart? _cart;

  @override
  void initState() {
    super.initState();
    _fetchCartData();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showPaymentSuccessfulNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'payment_channel',
      'Payment Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Payment Successful',
      'Your payment of ${_amountController.text} $_currencyList has been processed successfully.',
      platformChannelSpecifics,
    );
  }

  Future<void> _fetchCartData() async {
    try {
      final cartData = await fbService.getUserCart();
      setState(() {
        _cart = cartData;
        _amountController.text = cartData.totalPrice.toStringAsFixed(0);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch cart data: $e')),
      );
    }
  }

  Future<void> _initPaymentSheet() async {
    try {
      final data = await StripeService().createPaymentIntent(
        amount: (int.parse(_amountController.text) * 100).toString(),
        currency: _currencyList,
        name: _nameController.text,
        address: _addressController.text,
        pin: _postalcodeController.text,
        city: _unitController.text,
        state: _phoneController.text,
        country: _countryController.text,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          customFlow: false,
          merchantDisplayName: 'Test Merchant',
          paymentIntentClientSecret: data['client_secret'],
          customerEphemeralKeySecret: data['ephemeralKey'],
          customerId: data['id'],
          style: ThemeMode.dark,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      rethrow;
    }
  }

  Future<void> _createOrderWithCartItems() async {
    if (_cart == null) return;

    final total = _cart!.totalPrice;

    List<OrderItem> orderItems = _cart!.items.map((cartItem) => OrderItem(
      listingId: cartItem.listing.id,
      itemDescription: cartItem.listing.itemDescription,
      quantity: cartItem.quantity,
      price: cartItem.listing.price,
      imageUrl: cartItem.listing.imageUrl,
    )).toList();

await fbService.createOrder(
    total: total,
    paymentMethod: 'Stripe',
    status: 'Paid',
    items: orderItems,
  );

  // Clear the cart after successful order creation
  await fbService.clearCart();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _hasDonated
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Thanks for your ${_amountController.text} $_currencyList payment",
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text("We appreciate your support", style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.shade400),
                        child: const Text("Shop again", style: TextStyle(color: Colors.white, fontSize: 16)),
                        onPressed: () {
                          setState(() {
                            _hasDonated = false;
                            _amountController.clear();
                          });
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const BaseScreen(
                                content: HomeScreen(searchQuery: ''),
                                selectedIndex: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ... (keep existing form fields)
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent.shade400),
                          child: const Text("Proceed to Pay", style: TextStyle(color: Colors.white, fontSize: 16)),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              await _initPaymentSheet();
                              try {
                                await Stripe.instance.presentPaymentSheet();
                                await _createOrderWithCartItems();
                                await fbService.clearCart();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Payment Done", style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {
                                  _hasDonated = true;
                                });
                                _nameController.clear();
                                _addressController.clear();
                                _unitController.clear();
                                _phoneController.clear();
                                _countryController.clear();
                                _postalcodeController.clear();

                                await _showPaymentSuccessfulNotification();

                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Payment Failed", style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}