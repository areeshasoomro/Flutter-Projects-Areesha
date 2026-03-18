import 'package:flutter/material.dart';
import 'package:task1/features/dental_tips/dental_tips_landing_screen.dart';
class sucess extends StatefulWidget {
  const sucess({super.key});

  @override
  State<sucess> createState() => _sucessState();
}

class _sucessState extends State<sucess> {
  // Official Brand Logo Colors
  static const Color logoDeepBlue = Color(0xFF0077B6);
  static const Color logoLightBlue = Color(0xFF48CAE4);
  static const Color logoAccentBlue = Color(0xFF90E0EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              logoAccentBlue.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Animated/Static Icon
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: logoDeepBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: logoDeepBlue,
                size: 100,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Success Message
            const Text(
              'Login Successful!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: logoDeepBlue,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Welcome back to IntelliDent. Your smart dental companion is ready.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Continue Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: logoDeepBlue,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DentalTipsLandingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
