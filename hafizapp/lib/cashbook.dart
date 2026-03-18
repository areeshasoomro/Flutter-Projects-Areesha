import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CashbookPage extends StatefulWidget {
  const CashbookPage({Key? key}) : super(key: key);

  @override
  _CashbookPageState createState() => _CashbookPageState();
}

class _CashbookPageState extends State<CashbookPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbook'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select Date',
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate != null) {
                setState(() {
                  _selectedDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Entries for ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          _buildFinancialSummary(),
          const Divider(height: 20, thickness: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('cashbook')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)))
                  .where('date', isLessThan: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).add(const Duration(days: 1))))
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading entries'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No entries for this date.', style: TextStyle(fontSize: 16, color: Colors.grey)));
                }
                final entries = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index].data() as Map<String, dynamic>;
                    final bool isDebit = entry['type'] == 'debit';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isDebit ? Colors.red[100] : Colors.green[100]),
                          child: Icon(isDebit ? Icons.arrow_downward : Icons.arrow_upward, color: isDebit ? Colors.red : Colors.green, size: 20),
                        ),
                        title: Text(entry['description'] ?? 'No description'),
                        subtitle: Text(DateFormat('hh:mm a').format((entry['date'] as Timestamp).toDate())),
                        trailing: Text(
                          '${isDebit ? '-' : '+'} ${_formatCurrency(entry['amount'])}',
                          style: TextStyle(
                            color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addManualEntry,
        child: const Icon(Icons.add),
        tooltip: 'Add Manual Entry',
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('cashbook')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)))
          .where('date', isLessThan: Timestamp.fromDate(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day).add(const Duration(days: 1))))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        double totalDebit = 0;
        double totalCredit = 0;

        for (var doc in snapshot.data!.docs) {
          final entry = doc.data() as Map<String, dynamic>;
          if (entry['type'] == 'debit') {
            totalDebit += entry['amount'] ?? 0;
          } else {
            totalCredit += entry['amount'] ?? 0;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(child: _buildSummaryCard('Expenses (Debit)', totalDebit, Colors.red.shade700)),
              Expanded(child: _buildSummaryCard('Income (Credit)', totalCredit, Colors.green.shade700)),
              Expanded(child: _buildSummaryCard('Net Balance', totalCredit - totalDebit, Colors.blue.shade700)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(_formatCurrency(amount), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _addManualEntry() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'debit'; // Default to debit

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Manual Entry'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Type:'),
                        Radio<String>(value: 'debit', groupValue: type, onChanged: (v) => setState(() => type = v!)),
                        const Text('Expense'),
                        Radio<String>(value: 'credit', groupValue: type, onChanged: (v) => setState(() => type = v!)),
                        const Text('Income'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (descriptionController.text.isNotEmpty && amount != null && amount > 0) {
                  await _firestore.collection('cashbook').add({
                    'date': Timestamp.now(),
                    'description': descriptionController.text,
                    'amount': amount,
                    'type': type,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null || amount is! num) return 'PKR 0.00';
    return NumberFormat.currency(locale: 'en_PK', symbol: 'PKR ', decimalDigits: 2).format(amount);
  }
}
