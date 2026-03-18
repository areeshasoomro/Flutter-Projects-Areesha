// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class ProductPage extends StatefulWidget {
//   const ProductPage({Key? key}) : super(key: key);
//
//   @override
//   State<ProductPage> createState() => _ProductPageState();
// }
//
// class _ProductPageState extends State<ProductPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   List<Map<String, dynamic>> products = [];
//
//   @override
//   void initState() {
//     super.initState();
//     loadProducts();
//   }
//
//   Future<void> loadProducts() async {
//     final snapshot = await _firestore.collection('products').orderBy('createdAt', descending: true).get();
//     if (mounted) {
//       setState(() {
//         products = snapshot.docs.map((doc) {
//           final data = doc.data();
//           return {
//             'id': doc.id,
//             'itemHead': data['itemHead'] ?? '',
//             'productName': data['productName'] ?? '',
//             'purchasePrice': (data['purchasePrice'] ?? 0).toString(),
//             'sellingPrice': (data['sellingPrice'] ?? 0).toString(),
//             'stock': (data['stock'] ?? 0).toString(), // Load stock
//           };
//         }).toList();
//       });
//     }
//   }
//
//   void addRow() {
//     setState(() {
//       products.insert(0, {
//         'id': null,
//         'itemHead': '-',
//         'productName': '-',
//         'purchasePrice': '0',
//         'sellingPrice': '0',
//         'stock': '0', // Default stock for new row
//       });
//     });
//   }
//
//   Future<void> saveProduct(int index) async {
//     final product = products[index];
//
//     if (product['productName'].toString().isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Product Name is required!')));
//       return;
//     }
//
//     try {
//       final dataToSave = {
//         'itemHead': product['itemHead'],
//         'productName': product['productName'],
//         'purchasePrice': double.tryParse(product['purchasePrice']) ?? 0,
//         'sellingPrice': double.tryParse(product['sellingPrice']) ?? 0,
//         'stock': int.tryParse(product['stock']) ?? 0, // Save stock
//       };
//
//       if (product['id'] == null) {
//         dataToSave['createdAt'] = FieldValue.serverTimestamp();
//         final doc = await _firestore.collection('products').add(dataToSave);
//         products[index]['id'] = doc.id;
//       } else {
//         await _firestore.collection('products').doc(product['id']).update(dataToSave);
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Product saved successfully!')));
//       if (mounted) setState(() {});
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
//     }
//   }
//
//   Future<void> deleteProduct(int index) async {
//     final product = products[index];
//     if (product['id'] != null) {
//       await _firestore.collection('products').doc(product['id']).delete();
//     }
//     setState(() {
//       products.removeAt(index);
//     });
//     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Product deleted!')));
//   }
//
//   Widget buildEditableCell(String key, int index, {bool isNumeric = false}) {
//     return TextFormField(
//       initialValue: products[index][key],
//       keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
//       decoration: const InputDecoration(
//         border: OutlineInputBorder(),
//         contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       ),
//       onChanged: (value) => products[index][key] = value,
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: const Text('Product Management'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Container(
//               color: Colors.blueGrey[100],
//               padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//               child: Row(
//                 children: const [
//                   Expanded(flex: 2, child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
//                   Expanded(flex: 2, child: Text('Item Head', style: TextStyle(fontWeight: FontWeight.bold))),
//                   Expanded(child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
//                   Expanded(child: Text('Purchase', style: TextStyle(fontWeight: FontWeight.bold))),
//                   Expanded(child: Text('Selling', style: TextStyle(fontWeight: FontWeight.bold))),
//                   SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
//                 ],
//               ),
//             ),
//             const Divider(height: 1, color: Colors.black26),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: products.length,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     padding: const EdgeInsets.all(8),
//                     color: index % 2 == 0 ? Colors.white : Colors.blueGrey[50],
//                     child: Row(
//                       children: [
//                         Expanded(flex: 2, child: buildEditableCell('productName', index)),
//                         const SizedBox(width: 6),
//                         Expanded(flex: 2, child: buildEditableCell('itemHead', index)),
//                         const SizedBox(width: 6),
//                         Expanded(child: buildEditableCell('stock', index, isNumeric: true)),
//                         const SizedBox(width: 6),
//                         Expanded(child: buildEditableCell('purchasePrice', index, isNumeric: true)),
//                         const SizedBox(width: 6),
//                         Expanded(child: buildEditableCell('sellingPrice', index, isNumeric: true)),
//                         const SizedBox(width: 8),
//                         SizedBox(
//                           width: 110,
//                           child: Row(
//                             children: [
//                               IconButton(icon: const Icon(Icons.save, color: Colors.green), tooltip: 'Save', onPressed: () => saveProduct(index)),
//                               IconButton(icon: const Icon(Icons.delete, color: Colors.red), tooltip: 'Delete', onPressed: () => deleteProduct(index)),
//                             ],
//                           ),
//                         )
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ),
//             const SizedBox(height: 10),
//             ElevatedButton.icon(
//               onPressed: addRow,
//               icon: const Icon(Icons.add),
//               label: const Text('Add New Product'),
//               style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//





import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({Key? key}) : super(key: key);

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Each row will contain TextEditingControllers instead of raw values
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final snapshot = await _firestore.collection('products').orderBy('createdAt', descending: true).get();
    if (mounted) {
      setState(() {
        products = snapshot.docs.map((doc) {
          final data = doc.data();
          return Map<String, dynamic>.from({
            'id': doc.id,
            'itemHead': TextEditingController(text: data['itemHead'] ?? ''),
            'productName': TextEditingController(text: data['productName'] ?? ''),
            'purchasePrice': TextEditingController(text: (data['purchasePrice'] ?? 0).toString()),
            'sellingPrice': TextEditingController(text: (data['sellingPrice'] ?? 0).toString()),
            'stock': TextEditingController(text: (data['stock'] ?? 0).toString()),
          });
        }).toList();

      });
    }
  }

  void addRow() {
    setState(() {
      products.insert(
        0,
        Map<String, dynamic>.from({
          'id': null,
          'itemHead': TextEditingController(),
          'productName': TextEditingController(),
          'purchasePrice': TextEditingController(),
          'sellingPrice': TextEditingController(),
          'stock': TextEditingController(),
        }),
      );
    });
  }


  Future<void> saveProduct(int index) async {
    final product = products[index];

    if (product['productName'].text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Product Name is required!')));
      return;
    }

    try {
      final dataToSave = {
        'itemHead': product['itemHead'].text,
        'productName': product['productName'].text,
        'purchasePrice': double.tryParse(product['purchasePrice'].text) ?? 0,
        'sellingPrice': double.tryParse(product['sellingPrice'].text) ?? 0,
        'stock': int.tryParse(product['stock'].text) ?? 0,
      };

      if (product['id'] == null) {
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        final doc = await _firestore.collection('products').add(dataToSave);
        products[index]['id'] = doc.id;
      } else {
        await _firestore.collection('products').doc(product['id']).update(dataToSave);
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Product saved successfully!')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
    }
  }

  void deleteRow(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Confirmation'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final product = products[index];
              if (product['id'] != null) {
                await _firestore.collection('products').doc(product['id']).delete();
              }

              products[index].forEach((key, controller) {
                if (controller is TextEditingController) controller.dispose();
              });

              setState(() {
                products.removeAt(index);
              });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🗑️ Product deleted!')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildEditableCell(String key, int index, {bool isNumeric = false, String? hint}) {
    return SizedBox(
      width: 130,
      height: 38,
      child: TextFormField(
        controller: products[index][key],
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => saveProduct(index),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue.shade700, width: 1.2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Product Management'),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.blue.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
              ),
              child: Row(
                children: const [
                  Expanded(flex: 2, child: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(flex: 2, child: Text('Item Head', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(child: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(child: Text('Purchase', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  Expanded(child: Text('Selling', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  SizedBox(width: 120, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return MouseRegion(
                    onEnter: (_) => setState(() {}),
                    onExit: (_) => setState(() {}),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: buildEditableCell('productName', index)),
                          const SizedBox(width: 6),
                          Expanded(flex: 2, child: buildEditableCell('itemHead', index)),
                          const SizedBox(width: 6),
                          Expanded(child: buildEditableCell('stock', index, isNumeric: true, hint: "0")),
                          const SizedBox(width: 6),
                          Expanded(child: buildEditableCell('purchasePrice', index, isNumeric: true, hint: "0.0")),
                          const SizedBox(width: 6),
                          Expanded(child: buildEditableCell('sellingPrice', index, isNumeric: true, hint: "0.0")),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.save, color: Colors.green), onPressed: () => saveProduct(index)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteRow(index)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: addRow,
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
