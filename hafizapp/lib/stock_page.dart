import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockPage extends StatelessWidget {
  const StockPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Stock Levels'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('stock', isGreaterThan: 0) // Only show products with stock > 0
            .orderBy('stock', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong!'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No products are currently in stock.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index].data() as Map<String, dynamic>;
              final productName = product['productName'] ?? 'No Name';
              final stock = product['stock'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                child: ListTile(
                  title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(
                    stock.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  subtitle: const Text('Cartons in Stock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
