import 'package:flutter/material.dart';
import 'package:goodlobang/models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  static const routeName = '/order-detail';

  final PurchaseOrder order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Date: ${order.orderDate.toString()}'),
            Text('Status: ${order.status}'),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
            Text('Delivery Date: ${order.deliveryDate.toString()}'),
            const SizedBox(height: 20),
            const Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: order.items.length,
                itemBuilder: (context, index) {
                  final item = order.items[index];
                  return ListTile(
                                leading: Image.network(item.imageUrl),

                    title: Text(item.itemDescription),
                    subtitle: Text('Quantity: ${item.quantity}, Price: \$${item.price.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
