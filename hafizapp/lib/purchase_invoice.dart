import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hafizapp/recent_purchases.dart';
import 'package:intl/intl.dart';

class PurchaseInvoicePage extends StatefulWidget {
  const PurchaseInvoicePage({Key? key}) : super(key: key);

  @override
  State<PurchaseInvoicePage> createState() => _PurchaseInvoicePageState();
}

class _PurchaseInvoicePageState extends State<PurchaseInvoicePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime invoiceDate = DateTime.now();
  final TextEditingController accountController = TextEditingController();
  final TextEditingController godownController = TextEditingController();
  final TextEditingController companyController = TextEditingController();

  List<Map<String, dynamic>> _accounts = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _resetForm();
  }

  void _resetForm() {
    invoiceDate = DateTime.now();
    accountController.clear();
    godownController.clear();
    companyController.clear();
    for (var r in rows) {
      (r['cartonsCtrl'] as TextEditingController).dispose();
      (r['priceCtrl'] as TextEditingController).dispose();
    }
    rows = [_emptyRow()];
    if (mounted) setState(() {});
  }

  Map<String, dynamic> _emptyRow() {
    return {
      'productId': null,
      'productName': '',
      'cartonsCtrl': TextEditingController(),
      'priceCtrl': TextEditingController(),
      'value': 0.0,
    };
  }

  Future<void> _loadData() async {
    await _loadAccounts();
    await _loadProducts();
  }

  Future<void> _loadAccounts() async {
    final snap = await _firestore.collection('accounts').get();
    _accounts = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    if(mounted) setState(() {});
  }

  Future<void> _loadProducts() async {
    final snap = await _firestore.collection('products').get();
    _products = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    if(mounted) setState(() {});
  }

  List<String> _accountSuggestions(String q) {
    if (q.trim().isEmpty) return _accounts.map((a) => '${a['accountCode']} - ${a['accountName']}').toList();
    final s = q.toLowerCase();
    return _accounts.where((a) {
      final code = (a['accountCode'] ?? '').toString().toLowerCase();
      final name = (a['accountName'] ?? '').toString().toLowerCase();
      return code == s || name.contains(s) || name.startsWith(s);
    }).map((a) => '${a['accountCode']} - ${a['accountName']}').toList();
  }

  void _onSelectProductForRow(int rowIndex, String? productId) {
    final row = rows[rowIndex];
    if (productId == null) {
      row['productId'] = null;
      row['productName'] = '';
    } else {
      final p = _products.firstWhere((x) => x['id'] == productId, orElse: () => {});
      row['productId'] = productId;
      row['productName'] = p.isNotEmpty ? p['productName'] : '';
      if (p.isNotEmpty && p['purchasePrice'] != null) {
        (row['priceCtrl'] as TextEditingController).text = (p['purchasePrice']).toString();
      }
    }
    _recalcRow(rowIndex);
  }

  void _recalcRow(int i) {
    final row = rows[i];
    final cartons = double.tryParse((row['cartonsCtrl'] as TextEditingController).text) ?? 0.0;
    final price = double.tryParse((row['priceCtrl'] as TextEditingController).text) ?? 0.0;
    row['value'] = cartons * price;
    setState(() {});
  }

  double _invoiceTotal() => rows.fold(0.0, (sum, r) => sum + (r['value'] ?? 0.0));

  Future<void> _saveInvoice() async {
    try {
      if (accountController.text.trim().isEmpty) throw 'Please select an account';

      final invoiceLines = rows.where((r) => r['productId'] != null).map((r) {
        final cartons = int.tryParse(r['cartonsCtrl'].text) ?? 0;
        final price = double.tryParse(r['priceCtrl'].text) ?? 0;
        return {
          'productId': r['productId'],
          'productName': r['productName'],
          'cartons': cartons,
          'pricePerCarton': price,
          'valuePrice': cartons * price,
        };
      }).where((line) => line['cartons'] as int > 0).toList();

      if (invoiceLines.isEmpty) throw 'Please add at least one product';

      final totalAmount = invoiceLines.fold<double>(0.0, (sum, line) => sum + (line['valuePrice'] as double));

      String accountCode = '', accountName = accountController.text;
      if (accountController.text.contains('-')) {
        final parts = accountController.text.split('-');
        accountCode = parts.first.trim();
        accountName = parts.length > 1 ? parts[1].trim() : '';
      }
      
      int newInvoiceNumber = 0;
      await _firestore.runTransaction((transaction) async {
        final countersRef = _firestore.collection('counters').doc('purchases');
        final counterSnap = await transaction.get(countersRef);
        newInvoiceNumber = (counterSnap.data()?['lastNumber'] ?? 0) + 1;

        final invoiceData = {
          'invoiceNumber': newInvoiceNumber,
          'date': invoiceDate,
          'accountSearchText': accountController.text,
          'accountCode': accountCode,
          'accountName': accountName,
          'godown': godownController.text,
          'company': companyController.text,
          'lines': invoiceLines,
          'totalAmount': totalAmount,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final purchaseDoc = _firestore.collection('purchases').doc();
        transaction.set(purchaseDoc, invoiceData);

        for (final line in invoiceLines) {
          final productRef = _firestore.collection('products').doc(line['productId']);
          transaction.update(productRef, {'stock': FieldValue.increment(line['cartons'] as int)});
        }

        transaction.set(_firestore.collection('cashbook').doc(), {
          'date': FieldValue.serverTimestamp(),
          'description': 'Purchase Invoice #${newInvoiceNumber} from $accountName',
          'amount': totalAmount,
          'type': 'debit',
        });

        transaction.set(countersRef, {'lastNumber': newInvoiceNumber});
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice #${newInvoiceNumber} saved!'), backgroundColor: Colors.green));
      _resetForm();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Recent Purchases',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentPurchasesPage())),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView( 
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Purchase Invoice', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(height: 24, thickness: 1),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(
                        width: 150,
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: invoiceDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                            if (picked != null) setState(() => invoiceDate = picked);
                          },
                          child: InputDecorator(
                            decoration: _denseInputDecoration('Date'),
                            child: Text(DateFormat('yyyy-MM-dd').format(invoiceDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue txt) => _accountSuggestions(txt.text),
                        onSelected: (val) => accountController.text = val,
                        fieldViewBuilder: (context, ctrl, focusNode, onEditingComplete) {
                          ctrl.text = accountController.text;
                          return TextField(controller: ctrl, focusNode: focusNode, decoration: _denseInputDecoration('Account (code or name)'));
                        },
                      )),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _smallTextField('Godown', godownController)),
                      const SizedBox(width: 10),
                      Expanded(child: _smallTextField('Company', companyController)),
                    ]),
                    const Divider(height: 24, thickness: 1),
                    _buildInvoiceLines(),
                    const Divider(height: 24, thickness: 1),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Total: PKR ${NumberFormat('#,##0.00').format(_invoiceTotal())}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      Row(children: [
                        ElevatedButton.icon(onPressed: _saveInvoice, icon: const Icon(Icons.save, size: 18), label: const Text('Save Invoice')),
                        const SizedBox(width: 8),
                        TextButton(onPressed: _resetForm, child: const Text('Reset')),
                      ]),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceLines() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length,
          itemBuilder: (context, i) => _buildRow(i),
          separatorBuilder: (context, index) => const SizedBox(height: 8),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Row'),
            onPressed: () => setState(() => rows.add(_emptyRow())),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(int i) {
    final r = rows[i];
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        flex: 3,
        child: DropdownSearch<String>(
          items: _products.map<String>((p) => p['id'] as String).toList(),
          itemAsString: (id) => _products.firstWhere((p) => p['id'] == id, orElse: () => {'productName': ''})['productName'],
          onChanged: (val) => _onSelectProductForRow(i, val),
          selectedItem: r['productId'],
          popupProps: PopupProps.menu(showSearchBox: true, searchFieldProps: TextFieldProps(decoration: InputDecoration(labelText: 'Search Products'))),
          dropdownDecoratorProps: DropDownDecoratorProps(dropdownSearchDecoration: _denseInputDecoration('Select Product')),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: r['cartonsCtrl'], decoration: _denseInputDecoration('Cartons'), keyboardType: TextInputType.number, onChanged: (_) => _recalcRow(i))),
      const SizedBox(width: 8),
      Expanded(child: TextField(controller: r['priceCtrl'], decoration: _denseInputDecoration('Price'), keyboardType: TextInputType.number, onChanged: (_) => _recalcRow(i))),
      const SizedBox(width: 8),
      Expanded(child: InputDecorator(decoration: _denseInputDecoration('Value'), child: Text(NumberFormat('#,##0.00').format(r['value'] ?? 0)))),
      SizedBox(
        width: 48,
        child: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () {
          setState(() {
            if (rows.length > 1) {
              (r['cartonsCtrl'] as TextEditingController).dispose();
              (r['priceCtrl'] as TextEditingController).dispose();
              rows.removeAt(i);
            } else {
              _resetForm();
            }
          });
        }),
      ),
    ]);
  }

  InputDecoration _denseInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _smallTextField(String label, TextEditingController ctrl) {
    return TextField(controller: ctrl, decoration: _denseInputDecoration(label));
  }
}

String _formatAnyDate(dynamic d) {
  if (d is Timestamp) return DateFormat('yyyy-MM-dd').format(d.toDate());
  if (d is DateTime) return DateFormat('yyyy-MM-dd').format(d);
  if (d is String) return d;
  return '';
}
