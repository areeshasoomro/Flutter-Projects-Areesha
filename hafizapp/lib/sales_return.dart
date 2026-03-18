import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SalesReturnPage extends StatefulWidget {
  const SalesReturnPage({Key? key}) : super(key: key);

  @override
  _SalesReturnPageState createState() => _SalesReturnPageState();
}

class _SalesReturnPageState extends State<SalesReturnPage> {
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
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid invoice number.')));
       setState(() => _isLoading = false);
       return;
    }

    final snapshot = await _firestore
        .collection('sales_invoices')
        .where('invoiceNumber', isEqualTo: invoiceNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice not found.')));
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
        title: const Text('Confirm Sales Return'),
        content: Text('Are you sure you want to process a return for Invoice #${_foundInvoice!['invoiceNumber']}? This will update stock and reverse financial entries.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    try {
      await _firestore.runTransaction((transaction) async {
        final invoiceRef = _firestore.collection('sales_invoices').doc(_foundInvoiceId!);
        final invoiceData = _foundInvoice!;

        // 1. Restore stock for each item
        for (final item in (invoiceData['items'] as List)) {
          final productRef = _firestore.collection('products').doc(item['productId']);
          transaction.update(productRef, {'stock': FieldValue.increment(item['quantity'])});
        }

        // 2. Create cashbook debit entry for the refund
        final amountPaid = (invoiceData['amountPaid'] as num? ?? 0).toDouble();
        if (amountPaid > 0) {
          final cashbookEntry = {
            'date': Timestamp.now(),
            'description': 'Sales Return for Invoice #${invoiceData['invoiceNumber']}',
            'amount': amountPaid,
            'type': 'debit',
          };
          transaction.set(_firestore.collection('cashbook').doc(), cashbookEntry);
        }

        // 3. Mark the invoice as returned to nullify its financial impact
        transaction.update(invoiceRef, {'status': 'returned'});
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sales return processed successfully!'), backgroundColor: Colors.green));
      setState(() {
        _foundInvoice = null;
        _foundInvoiceId = null;
        _invoiceNumberController.clear();
        _isLoading = false;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing return: $e'), backgroundColor: Colors.red));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Return'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchCard(),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_foundInvoice != null)
              _buildInvoiceDetailsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _invoiceNumberController,
                decoration: const InputDecoration(labelText: 'Enter Sales Invoice Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _searchInvoice,
              icon: const Icon(Icons.search),
              label: const Text('Find'),
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
          child: Padding(padding: const EdgeInsets.all(16.0), child: Center(child: Text('This invoice has already been marked as returned.', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold))))
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #${_foundInvoice!['invoiceNumber']}', style: Theme.of(context).textTheme.headlineSmall),
            Text('Date: ${DateFormat('dd-MM-yyyy').format((_foundInvoice!['invoiceDate'] as Timestamp).toDate())}'),
            const Divider(height: 24),
            Text('Items:', style: Theme.of(context).textTheme.titleLarge),
            ...(_foundInvoice!['items'] as List).map((item) => ListTile(
                  title: Text(item['productName'] ?? 'N/A'),
                  trailing: Text('Quantity: ${item['quantity']}'),
                )),
            const Divider(height: 24),
            _buildSummaryRow('Total Amount', _foundInvoice!['totalAmount'] ?? 0.0),
            _buildSummaryRow('Amount Paid', _foundInvoice!['amountPaid'] ?? 0.0),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _processReturn,
                icon: const Icon(Icons.undo),
                label: const Text('Process Return'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: const TextStyle(fontWeight: FontWeight.bold)), Text(NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ').format(amount))],
      ),
    );
  }
}
