// lib/core/providers/firebase_providers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 1. Provider untuk instance FirebaseAuth
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// 2. StreamProvider untuk mendengarkan perubahan status autentikasi
// Ini adalah provider utama yang akan kita gunakan di seluruh aplikasi.
// Ia akan secara otomatis memberitahu kita saat pengguna login atau logout.
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges();
});

// 2. Provider untuk instance FirebaseFirestore (INI YANG HILANG)
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});