import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hafizapp/new_salesman.dart';
import 'package:hafizapp/recent_invoices.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';

class SalesInvoice extends StatefulWidget {
  @override
  _SalesInvoiceState createState() => _SalesInvoiceState();
}

class _SalesInvoiceState extends State<SalesInvoice> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _transportNameController = TextEditingController();
  final TextEditingController _godamNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _amountPaidController = TextEditingController();
  final TextEditingController _pricePerCartonController = TextEditingController();
  final TextEditingController _noOfCartonController = TextEditingController();

  // State
  String? _editingInvoiceId;
  List<Map<String, dynamic>> _originalInvoiceItems = []; // For stock adjustment on edit
  int _invoiceNumber = 0;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedSalesman;
  Map<String, dynamic>? _selectedAccount;
  Map<String, dynamic>? _selectedProduct;
  List<Map<String, dynamic>> _invoiceItems = [];
  double _itemsSubtotal = 0.0, _previousPendingAmount = 0.0, _grandTotal = 0.0, _finalPendingAmount = 0.0;
  String _paymentType = 'Cash';

  // Firestore data
  List<Map<String, dynamic>> _salesmen = [], _accounts = [], _products = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
    _generateInvoiceNumber();
  }

  Future<void> _fetchData() async {
    final salesmenSnapshot = await FirebaseFirestore.instance.collection('salesmen').get();
    final accountsSnapshot = await FirebaseFirestore.instance.collection('accounts').get();
    final productsSnapshot = await FirebaseFirestore.instance.collection('products').get();
    if (mounted) {
      setState(() {
        _salesmen = salesmenSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        _accounts = accountsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
        _products = productsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      });
    }
  }

  Future<void> _generateInvoiceNumber() async {
    if (_editingInvoiceId != null) return;
    final snapshot = await FirebaseFirestore.instance.collection('sales_invoices').orderBy('invoiceNumber', descending: true).limit(1).get();
    if (mounted) {
      setState(() {
        _invoiceNumber = snapshot.docs.isNotEmpty ? (snapshot.docs.first['invoiceNumber'] as int) + 1 : 1;
      });
    }
  }

  Future<void> _fetchPreviousPendingAmount(String? accountId) async {
    if (accountId == null) return;
    final snapshot = await FirebaseFirestore.instance.collection('sales_invoices').where('accountId', isEqualTo: accountId).get();
    double totalPending = 0.0;
    for (var doc in snapshot.docs) {
      if (doc.id != _editingInvoiceId) {
        totalPending += (doc['pendingAmount'] as num? ?? 0).toDouble();
      }
    }
    if (mounted) {
      setState(() {
        _previousPendingAmount = totalPending;
        _calculateTotals();
      });
    }
  }

  void _calculateTotals() {
    _itemsSubtotal = _invoiceItems.fold(0.0, (sum, item) => sum + (item['price'] * item['quantity']));
    _grandTotal = _itemsSubtotal + _previousPendingAmount;
    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    _finalPendingAmount = _grandTotal - amountPaid;
    setState(() {});
  }

  void _addItemToInvoice() {
    if (_selectedProduct == null || _noOfCartonController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a product and enter quantity.')));
        return;
    }

    final quantity = int.tryParse(_noOfCartonController.text) ?? 0;
    if (quantity <= 0) return;

    final productInList = _products.firstWhere((p) => p['id'] == _selectedProduct!['id']);
    final currentStock = (productInList['stock'] ?? 0) as int;

    if (currentStock < quantity) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not enough stock. Only $currentStock available.'), backgroundColor: Colors.red));
        return;
    }
    final price = double.tryParse(_pricePerCartonController.text) ?? 0.0;

    setState(() {
      _invoiceItems.add({
        'productId': _selectedProduct!['id'],
        'productName': _selectedProduct!['productName'],
        'price': price,
        'quantity': quantity,
      });
      // Decrement local stock count for immediate feedback
      productInList['stock'] = currentStock - quantity;

      _selectedProduct = null;
      _pricePerCartonController.clear();
      _noOfCartonController.clear();
      _calculateTotals();
    });
  }

  void _removeItem(int index) {
    final item = _invoiceItems[index];
    final productInList = _products.firstWhere((p) => p['id'] == item['productId']);

    setState(() {
      // Increment local stock count back
      productInList['stock'] = (productInList['stock'] ?? 0) + item['quantity'];
      _invoiceItems.removeAt(index);
      _calculateTotals();
    });
  }

  void _populateFormForEdit(Map<String, dynamic> invoiceData) {
    _clearForm(generateNewInvoiceNumber: false);
    setState(() {
      _editingInvoiceId = invoiceData['id'];
       _originalInvoiceItems = List<Map<String, dynamic>>.from(invoiceData['items'] ?? []);
      _invoiceNumber = invoiceData['invoiceNumber'] ?? 0;
      _transportNameController.text = invoiceData['transportName'] ?? '';
      _godamNameController.text = invoiceData['godamName'] ?? '';
      _companyNameController.text = invoiceData['companyName'] ?? '';
      _amountPaidController.text = (invoiceData['amountPaid'] ?? 0.0).toString();
      _paymentType = invoiceData['paymentType'] ?? 'Cash';
      _selectedDate = (invoiceData['invoiceDate'] as Timestamp).toDate();

      _selectedSalesman = _salesmen.firstWhere((s) => s['id'] == invoiceData['salesmanId'], orElse: () => {});
      _selectedAccount = _accounts.firstWhere((a) => a['id'] == invoiceData['accountId'], orElse: () => {});

      if (invoiceData['items'] is List) {
        _invoiceItems = List<Map<String, dynamic>>.from(invoiceData['items']);
      }

      _fetchPreviousPendingAmount(_selectedAccount?['id']);
    });
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate() || _selectedSalesman == null || _selectedAccount == null || _invoiceItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields and add at least one item.')));
        return;
    }

    final amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;

    final invoiceData = {
      'invoiceNumber': _invoiceNumber,
      'salesmanId': _selectedSalesman!['id'],
      'accountId': _selectedAccount!['id'],
      'invoiceDate': Timestamp.fromDate(_selectedDate),
      'transportName': _transportNameController.text,
      'godamName': _godamNameController.text,
      'companyName': _companyNameController.text,
      'items': _invoiceItems,
      'subtotal': _itemsSubtotal,
      'previousPending': _previousPendingAmount,
      'totalAmount': _grandTotal,
      'paymentType': _paymentType,
      'amountPaid': amountPaid,
      'pendingAmount': _finalPendingAmount,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
            // If editing, revert old stock changes first
            if (_editingInvoiceId != null) {
                for (final item in _originalInvoiceItems) {
                    final productRef = FirebaseFirestore.instance.collection('products').doc(item['productId']);
                    transaction.update(productRef, {'stock': FieldValue.increment(item['quantity'])});
                }
            }

            // Apply new stock changes
            for (final item in _invoiceItems) {
                final productRef = FirebaseFirestore.instance.collection('products').doc(item['productId']);
                 transaction.update(productRef, {'stock': FieldValue.increment(-item['quantity'])});
            }

            // Add to cashbook
            if (amountPaid > 0) {
                final cashbookEntry = {
                  'date': invoiceData['createdAt'],
                  'description': 'Payment from ${_selectedAccount!['accountName']} for Invoice #${_invoiceNumber}',
                  'amount': amountPaid,
                  'type': 'credit',
                };
                final cashbookDoc = FirebaseFirestore.instance.collection('cashbook').doc();
                transaction.set(cashbookDoc, cashbookEntry);
            }

            // Save the invoice
            if (_editingInvoiceId == null) {
                final invoiceRef = FirebaseFirestore.instance.collection('sales_invoices').doc();
                transaction.set(invoiceRef, invoiceData);
            } else {
                final invoiceRef = FirebaseFirestore.instance.collection('sales_invoices').doc(_editingInvoiceId);
                transaction.update(invoiceRef, invoiceData);
            }
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice saved and stock updated!'), backgroundColor: Colors.green,));
        _clearForm();
        _fetchData(); // Refresh product data to get updated stock
    } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
}

  void _clearForm({bool generateNewInvoiceNumber = true}) {
    _formKey.currentState?.reset();
    _transportNameController.clear();_godamNameController.clear();_companyNameController.clear();
    _pricePerCartonController.clear();_noOfCartonController.clear();_amountPaidController.clear();
    setState(() {
      _editingInvoiceId = null;
      _originalInvoiceItems.clear();
      _selectedSalesman = null;_selectedAccount = null;_selectedProduct = null;
      _invoiceItems.clear();_itemsSubtotal = 0.0;_previousPendingAmount = 0.0;_grandTotal = 0.0;_finalPendingAmount = 0.0;
      _paymentType = 'Cash';_selectedDate = DateTime.now();
    });
    if (generateNewInvoiceNumber) _generateInvoiceNumber();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingInvoiceId == null ? 'Create Sales Invoice' : 'Edit Sales Invoice'),
        actions: [
          IconButton(icon: Icon(Icons.person_add_alt_1), tooltip: 'Add New Salesman', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NewSalesman()))),
          IconButton(icon: Icon(Icons.history), tooltip: 'Recent Invoices', onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => RecentInvoicesPage()));
              if (result is Map<String, dynamic>) {
                _populateFormForEdit(result);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildInfoCard(),
              _buildItemEntryCard(),
              if (_invoiceItems.isNotEmpty) _buildItemsListCard(),
              _buildTotalsCard(),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(icon: Icon(Icons.save), onPressed: _saveInvoice, label: Text(_editingInvoiceId == null ? 'Save Invoice' : 'Update Invoice')),
                  ElevatedButton.icon(icon: Icon(Icons.clear), onPressed: () => _clearForm(), label: Text('Clear'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice Details', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            Text('Invoice No: $_invoiceNumber  |  Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}'),
            SizedBox(height: 12),
            DropdownSearch<Map<String, dynamic>>(items: _salesmen, selectedItem: _selectedSalesman, itemAsString: (i) => i!['name'] ?? '', onChanged: (i) => setState(() => _selectedSalesman = i), popupProps: PopupProps.menu(showSearchBox: true), dropdownDecoratorProps: DropDownDecoratorProps(dropdownSearchDecoration: InputDecoration(labelText: 'Salesman', border: OutlineInputBorder()))),
            SizedBox(height: 12),
            DropdownSearch<Map<String, dynamic>>(items: _accounts, selectedItem: _selectedAccount, itemAsString: (i) => i!['accountName'] ?? '', onChanged: (item) { setState(() => _selectedAccount = item); _fetchPreviousPendingAmount(item?['id']); }, popupProps: PopupProps.menu(showSearchBox: true), dropdownDecoratorProps: DropDownDecoratorProps(dropdownSearchDecoration: InputDecoration(labelText: 'Account Name', border: OutlineInputBorder()))),
            SizedBox(height: 12),
            TextFormField(controller: _transportNameController, decoration: InputDecoration(labelText: 'Transport Name', border: OutlineInputBorder())),
            SizedBox(height: 12),
            Row(children: [Expanded(child: TextFormField(controller: _godamNameController, decoration: InputDecoration(labelText: 'Godam Name', border: OutlineInputBorder()))), SizedBox(width: 8), Expanded(child: TextFormField(controller: _companyNameController, decoration: InputDecoration(labelText: 'Company Name', border: OutlineInputBorder()))) ]),
          ],
        ),
      ),
    );
  }

  Widget _buildItemEntryCard() {
    // Find the stock for the currently selected product
    final selectedProductStock = _selectedProduct != null ? (_products.firstWhere((p) => p['id'] == _selectedProduct!['id'], orElse: () => {'stock': 0})['stock'] ?? 0) : 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Products', style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 12),
            DropdownSearch<Map<String, dynamic>>(
                items: _products.where((p) => (p['stock'] ?? 0) > 0).toList(),
                selectedItem: _selectedProduct,
                itemAsString: (i) => "${i!['productName']} (Stock: ${i['stock'] ?? 0})",
                onChanged: (item) { setState(() { _selectedProduct = item; _pricePerCartonController.text = item != null ? item['sellingPrice'].toString() : ''; }); },
                popupProps: PopupProps.menu(showSearchBox: true, searchFieldProps: TextFieldProps(decoration: InputDecoration(labelText: 'Search Products'))),
                dropdownDecoratorProps: DropDownDecoratorProps(dropdownSearchDecoration: InputDecoration(labelText: 'Select Product', border: OutlineInputBorder()))),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _pricePerCartonController, decoration: InputDecoration(labelText: 'Price', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                SizedBox(width: 8),
                Expanded(child: TextFormField(controller: _noOfCartonController, decoration: InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(icon: Icon(Icons.add_shopping_cart), onPressed: _addItemToInvoice, label: Text('Add Item'))),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsListCard() {
     return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Invoice Items', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [DataColumn(label: Text('Product')), DataColumn(label: Text('Qty')), DataColumn(label: Text('Price')), DataColumn(label: Text('Total')), DataColumn(label: Text(' '))],
                    rows: _invoiceItems.asMap().entries.map((entry) {
                        int idx = entry.key;
                        Map<String, dynamic> item = entry.value;
                        return DataRow(
                            cells: [
                                DataCell(Text(item['productName'])),
                                DataCell(Text(item['quantity'].toString())),
                                DataCell(Text(_formatCurrency(item['price']))),
                                DataCell(Text(_formatCurrency(item['quantity'] * item['price']))),
                                DataCell(IconButton(icon: Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _removeItem(idx), tooltip: 'Remove Item')),
                            ],
                        );
                    }).toList(),
                 ),)
            ]))
     );
  }

  Widget _buildTotalsCard() {
      return Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('Payment & Totals', style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 12),
                ListTile(title: Text('Subtotal'), trailing: Text(_formatCurrency(_itemsSubtotal))),
                ListTile(title: Text('Previous Pending'), trailing: Text(_formatCurrency(_previousPendingAmount))),
                ListTile(title: Text('Grand Total', style: Theme.of(context).textTheme.bodyLarge), trailing: Text(_formatCurrency(_grandTotal), style: Theme.of(context).textTheme.bodyLarge)),
                Divider(),
                Row(children: [ Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Radio(value: 'Cash', groupValue: _paymentType, onChanged: (v) => setState(()=>_paymentType=v!)), Text('Cash'), SizedBox(width: 16), Radio(value: 'Bank', groupValue: _paymentType, onChanged: (v) => setState(()=>_paymentType=v!)), Text('Bank')])), Expanded(child: TextFormField(controller: _amountPaidController, decoration: InputDecoration(labelText: 'Amount Paid', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (_)=>_calculateTotals()))]),
                SizedBox(height: 12),
                ListTile(title: Text('Net Pending Amount', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), trailing: Text(_formatCurrency(_finalPendingAmount), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red))),
            ]))
      );
  }

  String _formatCurrency(dynamic amount) {
      if (amount == null || amount is! num) return 'PKR 0.00';
      return NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2).format(amount);
  }
}

