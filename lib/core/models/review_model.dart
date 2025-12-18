// lib/core/models/review_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userId;
  final String username;
  final int tmdbId;
  final double rating;
  final String reviewText;
  final Timestamp createdAt;
  // --- TAMBAHAN BARU ---
  final List<String> likedBy; // Daftar userId yang menyukai
  final int commentCount; // Penghitung jumlah komentar
  final String photoUrl;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.tmdbId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
    required this.likedBy,
    required this.commentCount,
    required this.photoUrl,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      tmdbId: data['tmdbId'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewText: data['reviewText'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      // --- TAMBAHAN BARU ---
      // Konversi 'likedBy' dari List<dynamic> menjadi List<String>
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  // --- HELPER BARU ---
  // Helper untuk mengecek apakah pengguna saat ini menyukai review ini
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  // Helper untuk mendapatkan jumlah suka
  int get likeCount {
    return likedBy.length;
  }
}