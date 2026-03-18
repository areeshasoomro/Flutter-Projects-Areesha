// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
//
// class NewAccountPage extends StatefulWidget {
//   const NewAccountPage({Key? key}) : super(key: key);
//
//   @override
//   State<NewAccountPage> createState() => _NewAccountPageState();
// }
//
// class _NewAccountPageState extends State<NewAccountPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   // Add / Edit account dialog
//   Future<void> _showAccountDialog({DocumentSnapshot? existingDoc}) async {
//     final formKey = GlobalKey<FormState>();
//
//     DateTime selectedDate = existingDoc == null
//         ? DateTime.now()
//         : (existingDoc['startDate'] is Timestamp)
//         ? (existingDoc['startDate'] as Timestamp).toDate()
//         : DateTime.tryParse(existingDoc['startDate'].toString()) ??
//         DateTime.now();
//
//     TextEditingController dateController =
//     TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate));
//     TextEditingController accountHeadController =
//     TextEditingController(text: existingDoc?['accountHead'] ?? '');
//     TextEditingController areaController =
//     TextEditingController(text: existingDoc?['area'] ?? '');
//     TextEditingController accountCodeController =
//     TextEditingController(text: existingDoc?['accountCode'] ?? '');
//     TextEditingController accountNameController =
//     TextEditingController(text: existingDoc?['accountName'] ?? '');
//     TextEditingController proprietorController =
//     TextEditingController(text: existingDoc?['proprietor'] ?? '');
//     TextEditingController addressController =
//     TextEditingController(text: existingDoc?['address'] ?? '');
//     TextEditingController cityController =
//     TextEditingController(text: existingDoc?['city'] ?? '');
//     TextEditingController contactController =
//     TextEditingController(text: existingDoc?['contact'] ?? '');
//
//     await showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text(existingDoc == null ? 'Add New Account' : 'Edit Account'),
//           content: SingleChildScrollView(
//             child: Form(
//               key: formKey,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildField(
//                     dateController,
//                     'Start Date',
//                     readOnly: true,
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: context,
//                         initialDate: selectedDate,
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime(2100),
//                       );
//                       if (picked != null) {
//                         setState(() {
//                           selectedDate = picked;
//                           dateController.text =
//                               DateFormat('yyyy-MM-dd').format(picked);
//                         });
//                       }
//                     },
//                   ),
//                   _buildField(accountHeadController, 'Account Head',
//                       required: true),
//                   _buildField(areaController, 'Area'),
//                   _buildField(accountCodeController, 'Account Code',
//                       required: true,
//                       keyboardType: TextInputType.number,
//                       maxLength: 2),
//                   _buildField(accountNameController, 'Account Name',
//                       required: true),
//                   _buildField(proprietorController, 'Proprietor'),
//                   _buildField(addressController, 'Address'),
//                   _buildField(cityController, 'City'),
//                   _buildField(contactController, 'Contact',
//                       keyboardType: TextInputType.phone),
//                 ],
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.pop(context),
//             ),
//             ElevatedButton(
//               child: Text(existingDoc == null ? 'Save' : 'Update'),
//               onPressed: () async {
//                 if (!formKey.currentState!.validate()) return;
//
//                 final data = {
//                   'startDate': Timestamp.fromDate(selectedDate),
//                   'accountHead': accountHeadController.text.trim(),
//                   'area': areaController.text.trim(),
//                   'accountCode': accountCodeController.text.trim(),
//                   'accountName': accountNameController.text.trim(),
//                   'proprietor': proprietorController.text.trim(),
//                   'address': addressController.text.trim(),
//                   'city': cityController.text.trim(),
//                   'contact': contactController.text.trim(),
//                   'createdAt': FieldValue.serverTimestamp(),
//                 };
//
//                 if (existingDoc == null) {
//                   await _firestore.collection('accounts').add(data);
//                 } else {
//                   await _firestore
//                       .collection('accounts')
//                       .doc(existingDoc.id)
//                       .update(data);
//                 }
//
//                 Navigator.pop(context);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   // Compact input field
//   Widget _buildField(
//       TextEditingController controller,
//       String label, {
//         bool required = false,
//         bool readOnly = false,
//         VoidCallback? onTap,
//         TextInputType? keyboardType,
//         int? maxLength,
//       }) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: TextFormField(
//         controller: controller,
//         readOnly: readOnly,
//         onTap: onTap,
//         keyboardType: keyboardType,
//         maxLength: maxLength,
//         validator: required
//             ? (v) => v!.trim().isEmpty ? '$label is required' : null
//             : null,
//         decoration: InputDecoration(
//           labelText: label,
//           counterText: "",
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(6),
//           ),
//           contentPadding:
//           const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
//         ),
//         style: const TextStyle(fontSize: 14),
//       ),
//     );
//   }
//
//   Future<void> _deleteAccount(String id) async {
//     await _firestore.collection('accounts').doc(id).delete();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Accounts Management'),
//         centerTitle: true,
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showAccountDialog(),
//         icon: const Icon(Icons.add),
//         label: const Text('Add Account'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('accounts')
//             .orderBy('createdAt', descending: true)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return const Center(child: Text('Error loading accounts'));
//           }
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           final accounts = snapshot.data!.docs;
//
//           if (accounts.isEmpty) {
//             return const Center(child: Text('No accounts added yet.'));
//           }
//
//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columnSpacing: 20,
//               headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
//               columns: const [
//                 DataColumn(label: Text('Start Date')),
//                 DataColumn(label: Text('Account Head')),
//                 DataColumn(label: Text('Area')),
//                 DataColumn(label: Text('Code')),
//                 DataColumn(label: Text('Account Name')),
//                 DataColumn(label: Text('Proprietor')),
//                 DataColumn(label: Text('Address')),
//                 DataColumn(label: Text('City')),
//                 DataColumn(label: Text('Contact')),
//                 DataColumn(label: Text('Actions')),
//               ],
//               rows: accounts.map((doc) {
//                 final data = doc.data() as Map<String, dynamic>;
//
//                 // ✅ Safely handle both Timestamp and String types
//                 String formattedDate;
//                 final startDate = data['startDate'];
//                 if (startDate is Timestamp) {
//                   formattedDate =
//                       DateFormat('yyyy-MM-dd').format(startDate.toDate());
//                 } else if (startDate is String) {
//                   formattedDate = startDate;
//                 } else {
//                   formattedDate = '';
//                 }
//
//                 return DataRow(
//                   cells: [
//                     DataCell(Text(formattedDate)),
//                     DataCell(Text(data['accountHead'] ?? '')),
//                     DataCell(Text(data['area'] ?? '')),
//                     DataCell(Text(data['accountCode'] ?? '')),
//                     DataCell(Text(data['accountName'] ?? '')),
//                     DataCell(Text(data['proprietor'] ?? '')),
//                     DataCell(Text(data['address'] ?? '')),
//                     DataCell(Text(data['city'] ?? '')),
//                     DataCell(Text(data['contact'] ?? '')),
//                     DataCell(Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(Icons.edit, color: Colors.blue),
//                           onPressed: () => _showAccountDialog(existingDoc: doc),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.delete, color: Colors.red),
//                           onPressed: () => _deleteAccount(doc.id),
//                         ),
//                       ],
//                     )),
//                   ],
//                 );
//               }).toList(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NewAccountPage extends StatefulWidget {
  const NewAccountPage({Key? key}) : super(key: key);

  @override
  State<NewAccountPage> createState() => _NewAccountPageState();
}

class _NewAccountPageState extends State<NewAccountPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ------------------- ACCOUNT DIALOG -------------------
  Future<void> _showAccountDialog({DocumentSnapshot? existingDoc}) async {
    final formKey = GlobalKey<FormState>();

    DateTime selectedDate = existingDoc == null
        ? DateTime.now()
        : (existingDoc['startDate'] is Timestamp)
        ? (existingDoc['startDate'] as Timestamp).toDate()
        : DateTime.tryParse(existingDoc['startDate'].toString()) ??
        DateTime.now();

    // TEXT CONTROLLERS
    final dateCtrl =
    TextEditingController(text: DateFormat('yyyy-MM-dd').format(selectedDate));
    final headCtrl = TextEditingController(text: existingDoc?['accountHead'] ?? '');
    final areaCtrl = TextEditingController(text: existingDoc?['area'] ?? '');
    final codeCtrl = TextEditingController(text: existingDoc?['accountCode'] ?? '');
    final nameCtrl = TextEditingController(text: existingDoc?['accountName'] ?? '');
    final proprietorCtrl = TextEditingController(text: existingDoc?['proprietor'] ?? '');
    final addressCtrl = TextEditingController(text: existingDoc?['address'] ?? '');
    final cityCtrl = TextEditingController(text: existingDoc?['city'] ?? '');
    final contactCtrl = TextEditingController(text: existingDoc?['contact'] ?? '');

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          elevation: 10,
          insetPadding: const EdgeInsets.all(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            width: 620,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ------------------- TITLE -------------------
                Row(
                  children: [
                    Icon(
                      existingDoc == null ? Icons.add : Icons.edit,
                      color: Colors.blueAccent,
                      size: 30,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      existingDoc == null ? "Create New Account" : "Edit Account",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),

                const SizedBox(height: 10),

                // ---------------- FORM ----------------
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _txt(dateCtrl, "Start Date",
                              readOnly: true, onTap: () async {
                                final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100));
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                    dateCtrl.text =
                                        DateFormat('yyyy-MM-dd').format(picked);
                                  });
                                }
                              })),
                          const SizedBox(width: 16),
                          Expanded(child: _txt(headCtrl, "Account Head", required: true)),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _txt(areaCtrl, "Area")),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _txt(codeCtrl, "Account Code",
                                required: true, maxLength: 3, keyboard: TextInputType.number),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _txt(nameCtrl, "Account Name", required: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _txt(proprietorCtrl, "Proprietor")),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(child: _txt(addressCtrl, "Address")),
                          const SizedBox(width: 16),
                          Expanded(child: _txt(cityCtrl, "City")),
                        ],
                      ),

                      const SizedBox(height: 12),
                      _txt(contactCtrl, "Contact", keyboard: TextInputType.phone),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // ------------------- BUTTONS -------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                      onPressed: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      label: Text(
                        existingDoc == null ? "Save Account" : "Update Account",
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final data = {
                          'startDate': Timestamp.fromDate(selectedDate),
                          'accountHead': headCtrl.text.trim(),
                          'area': areaCtrl.text.trim(),
                          'accountCode': codeCtrl.text.trim(),
                          'accountName': nameCtrl.text.trim(),
                          'proprietor': proprietorCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                          'contact': contactCtrl.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        if (existingDoc == null) {
                          await _firestore.collection('accounts').add(data);
                        } else {
                          await _firestore
                              .collection('accounts')
                              .doc(existingDoc.id)
                              .update(data);
                        }

                        Navigator.pop(context);
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ----------------------- INPUT FIELD STYLE -----------------------
  Widget _txt(
      TextEditingController c,
      String label, {
        bool required = false,
        bool readOnly = false,
        VoidCallback? onTap,
        TextInputType? keyboard,
        int? maxLength,
      }) {
    return TextFormField(
      controller: c,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboard,
      maxLength: maxLength,
      validator: required
          ? (v) => v!.isEmpty ? "$label is required" : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        counterText: "",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.7),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      style: const TextStyle(fontSize: 14.5),
    );
  }

  // ----------------------- DELETE -----------------------
  Future<void> _deleteAccount(String id) async {
    await _firestore.collection('accounts').doc(id).delete();
  }

  // ----------------------- PAGE UI -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F7),
      appBar: AppBar(
        elevation: 3,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Accounts Management",
          style: TextStyle(
              color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAccountDialog(),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text("New Account"),
      ),

      // ---------------------- TABLE ----------------------
      body: Padding(
        padding: const EdgeInsets.all(26),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('accounts')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const Center(child: Text("Error loading data"));
            }

            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No accounts found."));
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 32,
                  headingRowHeight: 55,
                  dataRowHeight: 50,
                  headingRowColor:
                  MaterialStateProperty.all(const Color(0xFFF0F2F6)),

                  headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87),

                  columns: const [
                    DataColumn(label: Text("Start Date")),
                    DataColumn(label: Text("Head")),
                    DataColumn(label: Text("Area")),
                    DataColumn(label: Text("Code")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Proprietor")),
                    DataColumn(label: Text("Address")),
                    DataColumn(label: Text("City")),
                    DataColumn(label: Text("Contact")),
                    DataColumn(label: Text("Actions")),
                  ],

                  rows: docs.map((d) {
                    final x = d.data() as Map<String, dynamic>;

                    String date = "";
                    if (x['startDate'] is Timestamp) {
                      date = DateFormat('yyyy-MM-dd')
                          .format((x['startDate'] as Timestamp).toDate());
                    } else {
                      date = x['startDate'] ?? "";
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text(date)),
                        DataCell(Text(x['accountHead'] ?? "")),
                        DataCell(Text(x['area'] ?? "")),
                        DataCell(Text(x['accountCode'] ?? "")),
                        DataCell(Text(x['accountName'] ?? "")),
                        DataCell(Text(x['proprietor'] ?? "")),
                        DataCell(Text(x['address'] ?? "")),
                        DataCell(Text(x['city'] ?? "")),
                        DataCell(Text(x['contact'] ?? "")),
                        DataCell(Row(
                          children: [
                            IconButton(
                              tooltip: "Edit",
                              icon: const Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () => _showAccountDialog(existingDoc: d),
                            ),
                            IconButton(
                              tooltip: "Delete",
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteAccount(d.id),
                            ),
                          ],
                        )),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
