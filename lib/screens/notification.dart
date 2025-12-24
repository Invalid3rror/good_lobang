import 'package:flutter/material.dart';
import 'package:goodlobang/screens/navigation_bar.dart';
import 'package:goodlobang/screens/order_details.dart';
import 'package:goodlobang/services/firebase_service.dart';
import 'package:goodlobang/models/order.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const String routeName = '/notification-screen';

  @override
  Widget build(BuildContext context) {
    return const BaseScreen(
      content: NotificationScreenContent(),
      selectedIndex: 2,
    );
  }
}

class NotificationScreenContent extends StatelessWidget {
  const NotificationScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService fbService = FirebaseService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Orders'),
      ),
      body: StreamBuilder<List<PurchaseOrder>>(
        stream: fbService.getUserOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final order = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Order ID: ${order.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${order.orderDate.toString()}'),
                      Text('Status: ${order.status}'),
                      Text('Total: \$${order.total.toStringAsFixed(2)}'),
                      Text('Delivery Date: ${order.deliveryDate.toString()}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OrderDetailScreen(order: order),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
