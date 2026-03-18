// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class PurchaseReturnPage extends StatefulWidget {
//   const PurchaseReturnPage({Key? key}) : super(key: key);
//
//   @override
//   _PurchaseReturnPageState createState() => _PurchaseReturnPageState();
// }
//
// class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final TextEditingController _invoiceNumberController = TextEditingController();
//   Map<String, dynamic>? _foundInvoice;
//   String? _foundInvoiceId;
//   bool _isLoading = false;
//
//   Future<void> _searchInvoice() async {
//     if (_invoiceNumberController.text.isEmpty) return;
//     setState(() => _isLoading = true);
//
//     final invoiceNumber = int.tryParse(_invoiceNumberController.text);
//     if (invoiceNumber == null) {
//        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid invoice number.')));
//        setState(() => _isLoading = false);
//        return;
//     }
//
//     final snapshot = await _firestore
//         .collection('purchases')
//         .where('invoiceNumber', isEqualTo: invoiceNumber)
//         .limit(1)
//         .get();
//
//     if (snapshot.docs.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice not found.')));
//       setState(() {
//         _foundInvoice = null;
//         _foundInvoiceId = null;
//         _isLoading = false;
//       });
//     } else {
//       final doc = snapshot.docs.first;
//       setState(() {
//         _foundInvoice = doc.data();
//         _foundInvoiceId = doc.id;
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _processReturn() async {
//     if (_foundInvoice == null || _foundInvoiceId == null) return;
//
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Purchase Return'),
//         content: Text('Are you sure you want to process a return for Invoice #${_foundInvoice!['invoiceNumber']}? This will update stock and reverse financial entries.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
//           TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm Return')),
//         ],
//       ),
//     ) ?? false;
//
//     if (!confirm) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       await _firestore.runTransaction((transaction) async {
//         final invoiceRef = _firestore.collection('purchases').doc(_foundInvoiceId!);
//         final invoiceData = _foundInvoice!;
//
//         // 1. Decrease stock for each returned item
//         for (final item in (invoiceData['lines'] as List)) {
//           final productRef = _firestore.collection('products').doc(item['productId']);
//           transaction.update(productRef, {'stock': FieldValue.increment(-(item['cartons'] as int))});
//         }
//
//         // 2. Create cashbook credit entry for the refund
//         final totalAmount = (invoiceData['totalAmount'] as num? ?? 0).toDouble();
//         if (totalAmount > 0) {
//           final cashbookEntry = {
//             'date': Timestamp.now(),
//             'description': 'Purchase Return for Invoice #${invoiceData['invoiceNumber']}',
//             'amount': totalAmount,
//             'type': 'credit', // Credit as we are getting money back
//           };
//           transaction.set(_firestore.collection('cashbook').doc(), cashbookEntry);
//         }
//
//         // 3. Mark the purchase invoice as returned
//         transaction.update(invoiceRef, {'status': 'returned'});
//       });
//
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase return processed successfully!'), backgroundColor: Colors.green));
//       setState(() {
//         _foundInvoice = null;
//         _foundInvoiceId = null;
//         _invoiceNumberController.clear();
//         _isLoading = false;
//       });
//
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing return: $e'), backgroundColor: Colors.red));
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Purchase Return'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildSearchCard(),
//             const SizedBox(height: 20),
//             if (_isLoading)
//               const Center(child: CircularProgressIndicator())
//             else if (_foundInvoice != null)
//               _buildInvoiceDetailsCard(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSearchCard() {
//     return Card(
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Expanded(
//               child: TextField(
//                 controller: _invoiceNumberController,
//                 decoration: const InputDecoration(labelText: 'Enter Purchase Invoice Number', border: OutlineInputBorder()),
//                 keyboardType: TextInputType.number,
//               ),
//             ),
//             const SizedBox(width: 12),
//             ElevatedButton.icon(
//               onPressed: _searchInvoice,
//               icon: const Icon(Icons.search),
//               label: const Text('Find'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInvoiceDetailsCard() {
//     if (_foundInvoice!['status'] == 'returned') {
//       return Card(
//           color: Colors.orange[50],
//           child: Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('This purchase has already been marked as returned.', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold))))
//       );
//     }
//
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Invoice #${_foundInvoice!['invoiceNumber']}', style: Theme.of(context).textTheme.headlineSmall),
//             Text('Date: ${DateFormat('dd-MM-yyyy').format((_foundInvoice!['date'] as Timestamp).toDate())}'),
//             Text('Account: ${_foundInvoice!['accountName']}'),
//             const Divider(height: 24),
//             Text('Items:', style: Theme.of(context).textTheme.titleLarge),
//             ...(_foundInvoice!['lines'] as List).map((item) => ListTile(
//                   title: Text(item['productName'] ?? 'N/A'),
//                   trailing: Text('Quantity: ${item['cartons']}'),
//                 )),
//             const Divider(height: 24),
//             _buildSummaryRow('Total Amount', _foundInvoice!['totalAmount'] ?? 0.0),
//             const SizedBox(height: 24),
//             Center(
//               child: ElevatedButton.icon(
//                 onPressed: _processReturn,
//                 icon: const Icon(Icons.undo),
//                 label: const Text('Process Purchase Return'),
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSummaryRow(String label, double amount) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), Text(NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ').format(amount))],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({Key? key}) : super(key: key);

  @override
  _PurchaseReturnPageState createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _invoiceNumberController = TextEditingController();
  Map<String, dynamic>? _foundInvoice;
  String? _foundInvoiceId;
  bool _isLoading = false;

  Future<void> _searchInvoice() async {
    if (_invoiceNumberController.text.isEmpty) return;
    setState(() => _isLoading = true);

    final invoiceNumber = int.tryParse(_invoiceNumberController.text);
    if (invoiceNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid invoice number.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final snapshot = await _firestore
        .collection('purchases')
        .where('invoiceNumber', isEqualTo: invoiceNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice not found.')),
      );
      setState(() {
        _foundInvoice = null;
        _foundInvoiceId = null;
        _isLoading = false;
      });
    } else {
      final doc = snapshot.docs.first;
      setState(() {
        _foundInvoice = doc.data();
        _foundInvoiceId = doc.id;
        _isLoading = false;
      });
    }
  }

  Future<void> _processReturn() async {
    if (_foundInvoice == null || _foundInvoiceId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase Return'),
        content: Text(
          'Are you sure you want to process a return for Invoice #${_foundInvoice!['invoiceNumber']}?\n\n'
              'This will update stock and reverse financial entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Return'),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.runTransaction((transaction) async {
        final invoiceRef = _firestore.collection('purchases').doc(_foundInvoiceId!);
        final invoiceData = _foundInvoice!;

        // 1. Decrease stock for each returned item
        for (final item in (invoiceData['lines'] as List)) {
          final productRef = _firestore.collection('products').doc(item['productId']);
          transaction.update(productRef, {'stock': FieldValue.increment(-(item['cartons'] as int))});
        }

        // 2. Create cashbook credit entry
        final totalAmount = (invoiceData['totalAmount'] as num? ?? 0).toDouble();
        if (totalAmount > 0) {
          final cashbookEntry = {
            'date': Timestamp.now(),
            'description': 'Purchase Return for Invoice #${invoiceData['invoiceNumber']}',
            'amount': totalAmount,
            'type': 'credit',
          };
          transaction.set(_firestore.collection('cashbook').doc(), cashbookEntry);
        }

        // 3. Mark purchase as returned
        transaction.update(invoiceRef, {'status': 'returned'});
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Purchase return processed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _foundInvoice = null;
        _foundInvoiceId = null;
        _invoiceNumberController.clear();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing return: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Purchase Return'),
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSearchCard(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _foundInvoice != null
                  ? _buildInvoiceDetailsCard()
                  : Center(
                child: Text(
                  'Search for an invoice to process a return.',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _invoiceNumberController,
                decoration: InputDecoration(
                  labelText: 'Enter Purchase Invoice Number',
                  prefixIcon: const Icon(Icons.receipt_long),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _searchInvoice,
              icon: const Icon(Icons.search),
              label: const Text('Find'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailsCard() {
    if (_foundInvoice!['status'] == 'returned') {
      return Card(
        color: Colors.orange[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              '⚠️ This purchase has already been marked as returned.',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #${_foundInvoice!['invoiceNumber']}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Date: ${DateFormat('dd-MM-yyyy').format((_foundInvoice!['date'] as Timestamp).toDate())}',
              style: const TextStyle(color: Colors.black87),
            ),
            Text('Account: ${_foundInvoice!['accountName']}',
                style: const TextStyle(color: Colors.black87)),
            const Divider(height: 28, thickness: 1),
            Text('Items',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: (_foundInvoice!['lines'] as List).map((item) {
                  return ListTile(
                    leading: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.blueAccent),
                    title: Text(
                      item['productName'] ?? 'N/A',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    trailing: Text('Qty: ${item['cartons']}',
                        style: const TextStyle(fontSize: 15)),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 28, thickness: 1),
            _buildSummaryRow('Total Amount',
                (_foundInvoice!['totalAmount'] as num?)?.toDouble() ?? 0.0),
            const SizedBox(height: 26),
            Center(
              child: ElevatedButton.icon(
                onPressed: _processReturn,
                icon: const Icon(Icons.undo),
                label: const Text('Process Purchase Return'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(
            NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ')
                .format(amount),
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
