import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hafizapp/account_ledger.dart';
import 'package:hafizapp/cashbook.dart';
import 'package:hafizapp/homescreen.dart';
import 'package:hafizapp/new_account.dart';
import 'package:hafizapp/product.dart';
import 'package:hafizapp/purchase_invoice.dart';
import 'package:hafizapp/purchase_return.dart';
import 'package:hafizapp/reports.dart';
import 'package:hafizapp/sales_invoice.dart';
import 'package:hafizapp/sales_return.dart';
import 'package:hafizapp/stock_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC18eAQowwm_dMi-zLNM8luYW4TLpVqIvM",
      authDomain: "shaikhapp-a0eb8.firebaseapp.com",
      projectId: "shaikhapp-a0eb8",
      storageBucket: "shaikhapp-a0eb8.appspot.com",
      messagingSenderId: "519161630529",
      appId: "1:519161630529:web:4fceb75b6adb024f339bc0",
      measurementId: "G-E3FLYTCD99",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inventory & Finance System',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/product': (context) => const ProductPage(),
        '/new_account': (context) => const NewAccountPage(),
        '/purchase_invoice': (context) => const PurchaseInvoicePage(),
        '/sales_invoice': (context) => SalesInvoice(),

        '/cashbook': (context) => const CashbookPage(),
        '/account_ledger': (context) => const AccountLedgerPage(),
        '/stock': (context) => const StockPage(),
        '/purchase_return': (context) => const PurchaseReturnPage(),
        '/sales_return': (context) => const SalesReturnPage(),
        '/reports': (context) => const ReportsPage(),
      },
    );
  }
}
