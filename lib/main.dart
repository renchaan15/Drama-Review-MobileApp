// lib/main.dart

import 'package:drama_review_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:drama_review_app/core/services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // --- INISIALISASI NOTIFIKASI DI SINI ---
  await NotificationService().initNotifications();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- DEFINISI SISTEM DESAIN BARU KITA ---
    final baseTheme = ThemeData.dark();
    const primaryColor = Color(0xFFFFD700); // Aksen Emas yang Mewah
    const backgroundColor = Color(0xFF121212); // Hitam Pekat
    const surfaceColor = Color(0xFF1E1E1E); // Warna Permukaan (Kartu, dll)

    return MaterialApp(
      title: 'Filmory',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: baseTheme.copyWith(
    // SKEMA WARNA
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: surfaceColor, // ganti background -> surface
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),


        // TIPOGRAFI
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
          bodyColor: Colors.white.withValues(alpha: 0.87),
          displayColor: Colors.white,
        ),

        // TEMA KOMPONEN SPESIFIK
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Transparan agar menyatu
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: surfaceColor,
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
           style: FilledButton.styleFrom(
            backgroundColor: primaryColor.withValues(alpha: 0.1),
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceColor,
          prefixIconColor: Colors.grey[500],
          labelStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryColor, width: 2),
          ),
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}