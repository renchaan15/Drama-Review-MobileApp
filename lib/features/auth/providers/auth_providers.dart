// lib/features/auth/providers/auth_providers.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drama_review_app/core/providers/firebase_providers.dart';
import 'package:drama_review_app/features/auth/services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider untuk instance Firestore
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Provider untuk AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthService(auth, firestore);
});