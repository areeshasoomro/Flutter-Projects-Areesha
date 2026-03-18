import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum DateFilter { Today, ThisWeek, ThisMonth, Custom }

class RecentInvoicesPage extends StatefulWidget {
  @override
  _RecentInvoicesPageState createState() => _RecentInvoicesPageState();
}

class _RecentInvoicesPageState extends State<RecentInvoicesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _accounts = [];
  DateTime? _startDate;
  DateTime? _endDate;
  DateFilter _selectedFilter = DateFilter.ThisMonth;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _applyDateFilter(_selectedFilter);
  }

  Future<void> _fetchAccounts() async {
    final accountsSnapshot = await _firestore.collection('accounts').get();
    if (mounted) {
      setState(() {
        _accounts = accountsSnapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      });
    }
  }

  void _applyDateFilter(DateFilter filter) {
    final now = DateTime.now();
    DateTime start, end;
    switch (filter) {
      case DateFilter.Today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case DateFilter.ThisWeek:
        start = now.subtract(Duration(days: now.weekday - 1));
        start = DateTime(start.year, start.month, start.day);
        end = start.add(const Duration(days: 7));
        break;
      case DateFilter.ThisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case DateFilter.Custom:
        _selectCustomDateRange();
        return;
    }

    setState(() {
      _startDate = start;
      _endDate = end;
      _selectedFilter = filter;
    });
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(days: 1)); // Ensure the end day is inclusive
        _selectedFilter = DateFilter.Custom;
      });
    }
  }

  Stream<QuerySnapshot> _getFilteredStream() {
    Query query = _firestore.collection('sales_invoices').orderBy('createdAt', descending: true);
    if (_startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate != null) {
      query = query.where('createdAt', isLessThan: _endDate);
    }
    return query.limit(100).snapshots();
  }


  Future<void> _deleteInvoice(String invoiceId) async {
    if (!mounted) return;
    try {
      await FirebaseFirestore.instance.collection('sales_invoices').doc(invoiceId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice deleted successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting invoice: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null || amount is! num) return '0.00';
    return NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Sales Invoices'),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || _accounts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No invoices found for the selected criteria.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final invoice = doc.data() as Map<String, dynamic>;
                    final account = _accounts.firstWhere((a) => a['id'] == invoice['accountId'], orElse: () => {'accountName': 'N/A'});

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      elevation: 2,
                      child: ListTile(
                        title: Text('#${invoice['invoiceNumber']} - ${account['accountName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${DateFormat('dd-MM-yyyy').format((invoice['invoiceDate'] as Timestamp).toDate())}'),
                            Text('Total: ${_formatCurrency(invoice['totalAmount'])} | Pending: ${_formatCurrency(invoice['pendingAmount'])}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Theme.of(context).primaryColor, size: 20),
                              tooltip: 'Edit Invoice',
                              onPressed: () => Navigator.of(context).pop({'id': doc.id, ...invoice}),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent, size: 20),
                              tooltip: 'Delete Invoice',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text('Are you sure you want to delete this invoice? This action cannot be undone.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete'), style: TextButton.styleFrom(foregroundColor: Colors.red)),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  _deleteInvoice(doc.id);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        alignment: WrapAlignment.center,
        children: DateFilter.values.map((filter) {
          return ActionChip(
            avatar: Icon(Icons.calendar_today, size: 16),
            label: Text(filter.name.replaceAll('This', ' ')),
            backgroundColor: _selectedFilter == filter ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[200],
            onPressed: () => _applyDateFilter(filter),
          );
        }).toList(),
      ),
    );
  }
}
