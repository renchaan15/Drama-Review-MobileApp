// lib/features/auth/presentation/screens/auth_checker.dart

import 'package:drama_review_app/features/auth/presentation/screens/login_screen.dart';
import 'package:drama_review_app/features/home/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drama_review_app/core/providers/firebase_providers.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tonton (watch) status autentikasi
    final authState = ref.watch(authStateChangesProvider);

    // Gunakan .when() untuk menangani semua kemungkinan state:
    // data (user ada atau null), loading, dan error.
    return authState.when(
      data: (user) {
        if (user != null) {
          // Jika user ada (sudah login), tampilkan MainScreen
          return const MainScreen();
        } else {
          // Jika user null (belum login), tampilkan LoginScreen
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}