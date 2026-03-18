// import 'package:flutter/material.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Inventory & Finance System'),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: GridView.count(
//           crossAxisCount: 3,
//           mainAxisSpacing: 20,
//           crossAxisSpacing: 20,
//           children: [
//             _buildMenuButton(context, 'Product', '/product'),
//             _buildMenuButton(context, 'New Account', '/new_account'),
//             _buildMenuButton(context, 'Purchase Invoice', '/purchase_invoice'),
//             _buildMenuButton(context, 'Sales Invoice', '/sales_invoice'),
//             _buildMenuButton(context, 'Reports', '/reports'),
//             _buildMenuButton(context, 'Cashbook', '/cashbook'),
//             _buildMenuButton(context, 'Account Ledger', '/account_ledger'),
//             _buildMenuButton(context, 'Stock', '/stock'),
//             _buildMenuButton(context, 'Sales Return', '/sales_return'),
//             _buildMenuButton(context, 'Purchase Return', '/purchase_return'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMenuButton(BuildContext context, String title, String route) {
//     return ElevatedButton(
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.all(20),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         backgroundColor: Colors.blueAccent,
//       ),
//       onPressed: () {
//         Navigator.pushNamed(context, route);
//       },
//       child: Text(
//         title,
//         style: const TextStyle(fontSize: 18, color: Colors.white),
//         textAlign: TextAlign.center,
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Inventory & Finance System',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 25,
              crossAxisSpacing: 25,
              childAspectRatio: 1.3,
              children: [
                _buildMenuCard(context, 'Product', '/product', Icons.shopping_bag),
                _buildMenuCard(context, 'New Account', '/new_account', Icons.person_add_alt_1),
                _buildMenuCard(context, 'Purchase Invoice', '/purchase_invoice', Icons.receipt_long),
                _buildMenuCard(context, 'Sales Invoice', '/sales_invoice', Icons.point_of_sale),
                _buildMenuCard(context, 'Reports', '/reports', Icons.bar_chart),
                _buildMenuCard(context, 'Cashbook', '/cashbook', Icons.book),
                _buildMenuCard(context, 'Account Ledger', '/account_ledger', Icons.account_balance_wallet),
                _buildMenuCard(context, 'Stock', '/stock', Icons.inventory_2),
                _buildMenuCard(context, 'Sales Return', '/sales_return', Icons.assignment_return),
                _buildMenuCard(context, 'Purchase Return', '/purchase_return', Icons.assignment_return_outlined),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, String route, IconData icon) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
