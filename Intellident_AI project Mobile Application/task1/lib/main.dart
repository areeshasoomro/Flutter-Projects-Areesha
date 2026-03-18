import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IntelliDent Internship',
      theme: ThemeData(primarySwatch: Colors.teal),

      home: const OnboardingScreen(),  // as app starts here
    );
  }
}
