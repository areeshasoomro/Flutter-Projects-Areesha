import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AccountLedgerPage extends StatefulWidget {
  const AccountLedgerPage({Key? key}) : super(key: key);

  @override
  _AccountLedgerPageState createState() => _AccountLedgerPageState();
}

class _AccountLedgerPageState extends State<AccountLedgerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _accounts = [];
  Map<String, dynamic>? _selectedAccount;
  List<Map<String, dynamic>> _ledgerEntries = [];
  bool _isLoading = false;
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    final accountsSnapshot = await _firestore.collection('accounts').orderBy('accountName').get();
    if (mounted) {
      setState(() {
        _accounts = accountsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      });
    }
  }

  Future<void> _fetchLedgerForAccount(String accountId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _ledgerEntries = [];
      _totalBalance = 0.0;
    });

    List<Map<String, dynamic>> entries = [];

    final salesSnapshot = await _firestore.collection('sales_invoices').where('accountId', isEqualTo: accountId).get();
    for (var doc in salesSnapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'returned') continue;

      entries.add({
        'date': (data['invoiceDate'] as Timestamp).toDate(),
        'description': 'Sale - Invoice #${data['invoiceNumber']}',
        'debit': data['totalAmount'] ?? 0.0,
        'credit': 0.0,
        'paymentMethod': '-',
      });

      if ((data['amountPaid'] ?? 0.0) > 0) {
         entries.add({
           'date': (data['invoiceDate'] as Timestamp).toDate(),
           'description': 'Payment Received (Inv #${data['invoiceNumber']})',
           'debit': 0.0,
           'credit': data['amountPaid'] ?? 0.0,
           'paymentMethod': data['paymentType'] ?? 'N/A',
         });
      }
    }

    final accountName = _selectedAccount!['accountName'];
    final purchaseSnapshot = await _firestore.collection('purchases').where('accountName', isEqualTo: accountName).get();
    for (var doc in purchaseSnapshot.docs) {
      final data = doc.data();
       if (data['status'] == 'returned') continue;

      entries.add({
        'date': (data['date'] as Timestamp).toDate(),
        'description': 'Purchase - Invoice #${data['invoiceNumber']}',
        'debit': 0.0,
        'credit': data['totalAmount'] ?? 0.0,
         'paymentMethod': '-',
      });
    }

    entries.sort((a, b) => a['date'].compareTo(b['date']));

    double runningBalance = 0;
    for (var entry in entries) {
      runningBalance += (entry['debit'] - entry['credit']);
      entry['balance'] = runningBalance;
    }

    if (mounted) {
      setState(() {
        _ledgerEntries = entries;
        _totalBalance = runningBalance;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Ledger'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownSearch<Map<String, dynamic>>(
              items: _accounts,
              selectedItem: _selectedAccount,
              itemAsString: (account) => account!['accountName'] as String,
              onChanged: (account) {
                if (account != null) {
                  setState(() {
                    _selectedAccount = account;
                    _fetchLedgerForAccount(account['id']);
                  });
                }
              },
              popupProps: const PopupProps.menu(showSearchBox: true, searchFieldProps: TextFieldProps(decoration: InputDecoration(labelText: 'Search Account'))),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(labelText: 'Select an Account', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedAccount != null)
              Expanded(
                child: ListView( // Makes the content scrollable
                  children: [
                    _buildAccountDetailsCard(),
                    _buildBalanceSummaryCard(),
                    const SizedBox(height: 20),
                    Text('Transaction History', style: Theme.of(context).textTheme.titleLarge),
                    const Divider(),
                    if (_isLoading)
                      const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator()))
                    else if (_ledgerEntries.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(50), child: Text('No transactions found for this account.')))
                    else
                      _buildDataTable(),
                  ],
                ),
              )
            else if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
            else
                const Expanded(child: Center(child: Text('Please select an account to view the ledger.'))),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountDetailsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_selectedAccount!['accountName'] ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            _buildDetailRow('Proprietor', _selectedAccount!['proprietor'] ?? 'N/A'),
            _buildDetailRow('Address', '${_selectedAccount!['address'] ?? 'N/A'}, ${_selectedAccount!['city'] ?? 'N/A'}'),
            _buildDetailRow('Contact', _selectedAccount!['contact'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSummaryCard() {
    return Card(
      color: _totalBalance >= 0 ? Colors.red[50] : Colors.green[50],
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Current Outstanding Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _formatCurrency(_totalBalance.abs()),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _totalBalance >= 0 ? Colors.red.shade800 : Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Payment Method')),
            DataColumn(label: Text('Debit')),
            DataColumn(label: Text('Credit')),
            DataColumn(label: Text('Balance')),
          ],
          rows: _ledgerEntries.map((entry) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat('dd-MM-yy').format(entry['date']))),
                DataCell(SizedBox(width: 200, child: Text(entry['description'], overflow: TextOverflow.ellipsis))),
                DataCell(Text(entry['paymentMethod']?.toString() ?? '-')),
                DataCell(Text(_formatCurrency(entry['debit']), style: TextStyle(color: Colors.red[700]))),
                DataCell(Text(_formatCurrency(entry['credit']), style: TextStyle(color: Colors.green[700]))),
                DataCell(Text(_formatCurrency(entry['balance']), style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            );
          }).toList(),
        ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null || amount == 0) return '-';
    return NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2).format(amount);
  }
}
