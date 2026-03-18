// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class NewSalesman extends StatefulWidget {
//   @override
//   _NewSalesmanState createState() => _NewSalesmanState();
// }
//
// class _NewSalesmanState extends State<NewSalesman> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _codeController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Add New Salesman'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: <Widget>[
//               TextFormField(
//                 controller: _codeController,
//                 decoration: InputDecoration(labelText: 'Salesman Code (2 digits)'),
//                 maxLength: 2,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a code';
//                   }
//                   if (value.length != 2) {
//                     return 'Code must be 2 digits';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(labelText: 'Salesman Name'),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a name';
//                   }
//                   return null;
//                 },
//               ),
//               TextFormField(
//                 controller: _contactController,
//                 decoration: InputDecoration(labelText: 'Contact'),
//                  keyboardType: TextInputType.phone,
//               ),
//               TextFormField(
//                 controller: _addressController,
//                 decoration: InputDecoration(labelText: 'Address'),
//               ),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveSalesman,
//                 child: Text('Save Salesman'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _saveSalesman() {
//     if (_formKey.currentState!.validate()) {
//       FirebaseFirestore.instance.collection('salesmen').add({
//         'code': _codeController.text,
//         'name': _nameController.text,
//         'contact': _contactController.text,
//         'address': _addressController.text,
//       }).then((value) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Salesman added successfully')),
//         );
//         Navigator.pop(context);
//       }).catchError((error) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to add salesman: $error')),
//         );
//       });
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewSalesman extends StatefulWidget {
  const NewSalesman({Key? key}) : super(key: key);

  @override
  _NewSalesmanState createState() => _NewSalesmanState();
}

class _NewSalesmanState extends State<NewSalesman> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f9fb),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        title: const Text(
          'Add New Salesman',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shadowColor: Colors.blue.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Salesman Information",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff2c3e50),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Code Field
                    _buildTextField(
                      controller: _codeController,
                      label: 'Salesman Code (2 digits)',
                      icon: Icons.confirmation_number_outlined,
                      maxLength: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a code';
                        }
                        if (value.length != 2) {
                          return 'Code must be 2 digits';
                        }
                        return null;
                      },
                    ),

                    // Name Field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Salesman Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),

                    // Contact Field
                    _buildTextField(
                      controller: _contactController,
                      label: 'Contact',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    // Address Field
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_outlined),
                        label: const Text(
                          'Save Salesman',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 6,
                        ),
                        onPressed: _saveSalesman,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLength: maxLength,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          labelText: label,
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
          ),
        ),
      ),
    );
  }

  void _saveSalesman() {
    if (_formKey.currentState!.validate()) {
      FirebaseFirestore.instance.collection('salesmen').add({
        'code': _codeController.text,
        'name': _nameController.text,
        'contact': _contactController.text,
        'address': _addressController.text,
      }).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salesman added successfully')),
        );
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add salesman: $error')),
        );
      });
    }
  }
}
