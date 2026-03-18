import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PurchaseHistoryPage extends StatelessWidget {
  const PurchaseHistoryPage({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _invoiceStream() {
    return FirebaseFirestore.instance
        .collection('purchases')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _formatAnyDate(dynamic d) {
    if (d is Timestamp) return DateFormat('yyyy-MM-dd').format(d.toDate());
    if (d is DateTime) return DateFormat('yyyy-MM-dd').format(d);
    if (d is String) return d;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recent Purchases"),
        centerTitle: true,
        elevation: 3,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: _invoiceStream(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text('No invoices found'));
              }

              return Scrollbar(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 25,
                      headingRowHeight: 40,
                      dataRowHeight: 45,
                      border: TableBorder.all(
                          color: Colors.grey.shade300, width: 0.6),
                      columns: const [
                        DataColumn(
                            label: Text('Invoice #',
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Date',
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Account',
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Items',
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(
                            label: Text('Total',
                                style:
                                TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(Text(
                                (d['invoiceNumber'] ?? '').toString())),
                            DataCell(Text(_formatAnyDate(d['date']))),
                            DataCell(Text(d['accountName'] ?? '')),
                            DataCell(SizedBox(
                              width: 300,
                              child: Text(
                                ((d['lines'] ?? []) as List<dynamic>)
                                    .map((l) => l['productName'])
                                    .join(', '),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                            DataCell(Text(
                                'PKR ${NumberFormat('#,##0.00').format(d['totalAmount'] ?? 0)}')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
