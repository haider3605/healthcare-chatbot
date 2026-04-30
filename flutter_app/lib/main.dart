import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/health_risk_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pxdiazjwizaoopvcjlkc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4ZGlhemp3aXphb29wdmNqbGtjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY5MzExMjAsImV4cCI6MjA5MjUwNzEyMH0.3JIjJksbLpRIo1v41hNatHtHRK6iAUzt7dXtEPPjrpM',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF0D9488),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D9488),
          surface: Color(0xFF1E293B),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/chat': (context) => const HomeScreen(), // temporary
        '/health-risk': (context) => const HomeScreen(), // temporary
        '/history': (context) => const HomeScreen(), // temporary
        '/chat': (context) => const ChatScreen(),
        '/health-risk': (context) => const HealthRiskScreen(),
        '/history': (context) => const HistoryScreen(),
      },
    );
  }
}
