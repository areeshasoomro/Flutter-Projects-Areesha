import 'package:data_vault/screens/auth/login_screen.dart';
import 'package:data_vault/screens/home/home_screen.dart';
import 'package:data_vault/screens/onboarding/splash_screen.dart';
import 'package:data_vault/screens/guest/secure_access_screen.dart';
import 'package:data_vault/services/auth_service.dart';
import 'package:data_vault/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/**
 * DataVault Entry Point
 * Handles Cross-Platform Firebase Initialization and Global State Management
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase based on platform (Web vs Android/iOS)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyD7tNi7MgMCtrlHOkdHh5KgZiL-IhKGjyQ",
          authDomain: "datavault-76ca3.firebaseapp.com",
          projectId: "datavault-76ca3",
          storageBucket: "datavault-76ca3.firebasestorage.app",
          messagingSenderId: "761745910025",
          appId: "1:761745910025:web:4bc86aaa854cad1a308bd8",
          measurementId: "G-D9S9VS3GR8"),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Link Capture Logic (Web Portal)
    // Extracts the file ID from URL parameters (e.g., ?id=xyz)
    String? fileId;
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('id')) {
        fileId = uri.queryParameters['id'];
      }
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'DataVault',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFA3E635), // Brand Primary: Cyber Neon Green
            secondary: Color(0xFFA3E635),
            surface: Color(0xFF121212), 
            onSurface: Colors.white,
            onPrimary: Colors.black,
          ),
          useMaterial3: true,
          // Global UI Component Styling
          cardTheme: CardThemeData(
            color: const Color(0xFF121212),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA3E635),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFFA3E635), width: 1.5),
            ),
          ),
        ),
        // 2. Intelligent Routing
        // If a file ID is present, we bypass the owner app and open the Guest Portal
        initialRoute: fileId != null ? '/access' : '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
          '/access': (context) => SecureAccessScreen(fileId: fileId ?? ''),
        },
      ),
    );
  }
}

/**
 * Session Gatekeeper
 * Directs users to the Dashboard if logged in, or the Onboarding Splash if not.
 */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user != null) {
      return const HomeScreen();
    }
    return const SplashScreen();
  }
}
