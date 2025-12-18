// lib/core/models/user_profile_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String username;  
  final String email;
  final String? photoUrl;

  UserProfile({required this.uid, required this.username, required this.email, this.photoUrl});

  factory UserProfile.fromFirestore(DocumentSnapshot doc, String email) {
    Map data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      username: data['username'] ?? '',
      email: email, // Email didapat dari FirebaseAuth
      photoUrl: data['photoUrl'],
    );
  }
}