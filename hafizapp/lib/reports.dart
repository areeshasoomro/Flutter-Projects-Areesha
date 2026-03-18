import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Main Hub Page
class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildReportCategory(
            context,
            title: 'Sales Reports',
            icon: Icons.point_of_sale,
            reports: {
              'Sales Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DateRangeSummaryPage(title: 'Sales Summary', collection: 'sales_invoices'))),
              'Daily Sales Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailySalesReportPage())),
              'Salesman Wise Sale Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => SalesmanWiseReportPage())),
              'Customer Wise Sale Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerWiseReportPage())),
              'Item Wise Sale Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemWiseSaleReportPage())),
            },
          ),
          _buildReportCategory(
            context,
            title: 'Purchase Reports',
            icon: Icons.shopping_cart,
            reports: {
               'Purchase Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DateRangeSummaryPage(title: 'Purchase Summary', collection: 'purchases'))),
              'Daily Purchase Summary': () => Navigator.push(context, MaterialPageRoute(builder: (_) => DailyPurchaseReportPage())),
            },
          ),
           _buildReportCategory(
            context,
            title: 'Accounts Reports',
            icon: Icons.account_balance_wallet,
            reports: {
              'Balance Sheet': () => Navigator.push(context, MaterialPageRoute(builder: (_) => BalanceSheetPage())),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategory(BuildContext context, {required String title, required IconData icon, required Map<String, VoidCallback> reports}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        children: reports.entries.map((entry) {
          return ListTile(
            title: Text(entry.key),
            onTap: entry.value,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          );
        }).toList(),
      ),
    );
  }
}


// --- NEW: Generic Date Range Summary Page ---
class DateRangeSummaryPage extends StatefulWidget {
  final String title;
  final String collection;

  const DateRangeSummaryPage({Key? key, required this.title, required this.collection}) : super(key: key);

  @override
  _DateRangeSummaryPageState createState() => _DateRangeSummaryPageState();
}

class _DateRangeSummaryPageState extends State<DateRangeSummaryPage> {
  DateTimeRange? _selectedDateRange;
  List<Map<String, dynamic>> _reportData = [];
  bool _isLoading = false;

  Future<void> _generateReport() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date range.')));
      return;
    }
    setState(() => _isLoading = true);

    final dateField = widget.collection == 'purchases' ? 'date' : 'invoiceDate';
    final snapshot = await FirebaseFirestore.instance
        .collection(widget.collection)
        .where(dateField, isGreaterThanOrEqualTo: _selectedDateRange!.start)
        .where(dateField, isLessThanOrEqualTo: _selectedDateRange!.end.add(const Duration(days: 1)))
        .get();

    setState(() {
      _reportData = snapshot.docs.map((doc) => doc.data()).toList();
      _isLoading = false;
    });
  }

  Future<void> _printReport() async {
    final doc = pw.Document();
    final totalAmount = _reportData.fold<double>(0, (sum, item) => sum + (item['totalAmount'] ?? 0));

    doc.addPage(pw.Page(
      build: (pw.Context context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(widget.title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Text('Period: ${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'),
          pw.Divider(height: 20),
          pw.Table.fromTextArray(
            headers: ['Inv #', 'Date', 'Account', 'Amount'],
            data: _reportData.map((invoice) => [
                  (invoice['invoiceNumber'] ?? 'N/A').toString(),
                  _formatDate(invoice[widget.collection == 'purchases' ? 'date' : 'invoiceDate']),
                  (invoice['accountName'] ?? 'N/A').toString(),
                  _formatCurrency(invoice['totalAmount'])
                ]).toList(),
          ),
          pw.Divider(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Total: ${_formatCurrency(totalAmount)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))
          )
        ],
      ),
    ));

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.date_range),
                      label: Text(_selectedDateRange == null 
                          ? 'Select Date Range' 
                          : '${DateFormat('dd/MM/yy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_selectedDateRange!.end)}'),
                      onPressed: () async {
                        final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
                        if(picked != null) setState(() => _selectedDateRange = picked);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(icon: const Icon(Icons.search), label: const Text('Generate'), onPressed: _generateReport),
                        if(_reportData.isNotEmpty) ...[
                           const SizedBox(width: 8),
                           ElevatedButton.icon(icon: const Icon(Icons.print), label: const Text('Print'), onPressed: _printReport, style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                        ]
                      ],
                    )
                  ],
                ),
              ),
            ),
            const Divider(height: 24, thickness: 1),
            if(_isLoading) const Expanded(child: Center(child: CircularProgressIndicator()))
            else Expanded(
              child: ListView.builder(
                itemCount: _reportData.length,
                itemBuilder: (context, index) {
                  final invoice = _reportData[index];
                  return ListTile(
                    title: Text('Invoice #${invoice['invoiceNumber']}'),
                    subtitle: Text(invoice['accountName'] ?? 'N/A'),
                    trailing: Text(_formatCurrency(invoice['totalAmount'] ?? 0)),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// --- Existing Report Pages and Helper Functions ---
class BalanceSheetPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
 /* ... */ }
class _BalanceSheetPageState extends State<BalanceSheetPage> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
 /* ... */ }
class DailySalesReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
 /* ... */ }
class DailyPurchaseReportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
 /* ... */ }
class SalesmanWiseReportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
 /* ... */ }
class CustomerWiseReportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
 /* ... */ }
class ItemWiseSaleReportPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
 /* ... */ }

// Stubs for brevity as they are unchanged
class _DailyReportPage extends StatefulWidget { final String title; final String collection; const _DailyReportPage({Key? key, required this.title, required this.collection}) : super(key: key); @override __DailyReportPageState createState() => __DailyReportPageState(); }
class __DailyReportPageState extends State<_DailyReportPage> { @override Widget build(BuildContext context) => Container(); }
class _SalesmanWiseReportPageState extends State<SalesmanWiseReportPage> { @override Widget build(BuildContext context) => Container(); }
class _CustomerWiseReportPageState extends State<CustomerWiseReportPage> { @override Widget build(BuildContext context) => Container(); }
class _ItemWiseSaleReportPageState extends State<ItemWiseSaleReportPage> { @override Widget build(BuildContext context) => Container(); }

String _formatCurrency(dynamic amount) {
  if (amount == null || amount is! num) return 'PKR 0.00';
  return NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2).format(amount);
}
String _formatDate(dynamic date) {
  if (date is Timestamp) return DateFormat('dd/MM/yy').format(date.toDate());
  return 'N/A';
}
